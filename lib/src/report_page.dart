import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  ReportProblemPageState createState() => ReportProblemPageState();
}

class ReportProblemPageState extends State<ReportProblemPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedIssue;
  File? _imageFile;
  String? _userName;
  String? _userPhone;
  String? _userId;
  bool isLoading = false;
  bool isPickingImage = false;

  final List<String> _issueTypes = [
    "App Bug",
    "Payment Issue",
    "Delivery Problem",
    "Wrong Order",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  Future<void> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userId = user.uid;
          _userName = userDoc.get('name') ?? "Unknown";
          _userPhone = userDoc.get('phone') ?? "Not Provided";
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (isPickingImage) return; // Prevent multiple taps
    isPickingImage = true;

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking image: $e");
      }
    } finally {
      isPickingImage = false; // Reset flag
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = "report_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child("reports/$fileName");
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print("Error uploading image: $e");
      }
      return null;
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      isLoading = true;
    });
    if (_selectedIssue == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    try {
      await FirebaseFirestore.instance.collection("reports").add({
        "user_id": _userId,
        "user_name": _userName,
        "user_phone": _userPhone,
        "issue_type": _selectedIssue,
        "description": _descriptionController.text,
        "image_url": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Submitted Successfully")),
        );
      }

      setState(() {
        _selectedIssue = null;
        _descriptionController.clear();
        _imageFile = null;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error submitting report: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit report")),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: const Text(
          "Report a Problem",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF003780),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEae6de),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003780)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Issue Type Dropdown
                  buildSectionTitle("Select Issue Type"),
                  const SizedBox(height: 8),
                  buildDropdown(),

                  const SizedBox(height: 20),

                  // 🔹 Problem Description
                  buildSectionTitle("Describe the Problem"),
                  const SizedBox(height: 8),
                  buildTextField(),

                  const SizedBox(height: 30),

                  // 🔹 Attach Screenshot
                  buildSectionTitle("Attach a Screenshot (Optional)"),
                  const SizedBox(height: 8),
                  buildImageUploader(),

                  const SizedBox(height: 30),

                  // 🔹 Submit Button with Animation
                  Center(child: buildSubmitButton()),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

// ✅ Section Titles
  Widget buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF003780),
      ),
    );
  }

// ✅ Dropdown UI
  Widget buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Row(
        children: [
          const Icon(Icons.report_problem, color: Color(0xFF003780)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedIssue,
                hint: const Text("Choose an issue"),
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedIssue = newValue;
                  });
                },
                items: _issueTypes.map((String issue) {
                  return DropdownMenuItem<String>(
                    value: issue,
                    child: Text(issue),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ Stylish TextField
  Widget buildTextField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Enter details...",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
        prefixIcon: const Icon(Icons.description, color: Color(0xFF003780)),
      ),
    );
  }

// ✅ Image Upload Box
  Widget buildImageUploader() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: _imageFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  SizedBox(height: 5),
                  Text("Tap to upload image",
                      style: TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              ),
      ),
    );
  }

// ✅ Animated Submit Button
  Widget buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _submitReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003780),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shadowColor: Colors.grey.shade600,
        elevation: 6,
      ),
      icon: const Icon(Icons.send, color: Colors.white),
      label: const Text(
        "Submit",
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
