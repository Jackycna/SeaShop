// ignore_for_file: prefer_final_fields, avoid_print, prefer_const_constructors, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddressEntryPage extends StatefulWidget {
  const AddressEntryPage({super.key});

  @override
  AddressEntryPageState createState() => AddressEntryPageState();
}

class AddressEntryPageState extends State<AddressEntryPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  TextEditingController _pincodeController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _houseNoController = TextEditingController();
  TextEditingController _buildingNameController = TextEditingController();
  TextEditingController _areaController = TextEditingController();

  bool isLoading = false;

  // Use this method to fetch current location
  Future<void> _useCurrentLocation() async {
    // Implement logic for fetching current location
    print("Fetching current location...");
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userId = user.uid;
        String fullAddress =
            "${_houseNoController.text}, ${_buildingNameController.text}, ${_areaController.text}, ${_cityController.text}, ${_stateController.text}, ${_pincodeController.text}";

        // Save the address in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'address': fullAddress,
          'name': _nameController.text,
          'mobile': _mobileController.text,
        }, SetOptions(merge: true));

        setState(() {
          isLoading = false;
        });

        // Navigate back to the previous page
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Address")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(labelText: 'Mobile Number'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter mobile number' : null,
                    ),
                    TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(labelText: 'Pincode'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter pincode' : null,
                    ),
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(labelText: 'State'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter state' : null,
                    ),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: 'City'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter city' : null,
                    ),
                    TextFormField(
                      controller: _houseNoController,
                      decoration: InputDecoration(labelText: 'House No.'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter house number' : null,
                    ),
                    TextFormField(
                      controller: _buildingNameController,
                      decoration: InputDecoration(
                          labelText: 'Building Name (Optional)'),
                    ),
                    TextFormField(
                      controller: _areaController,
                      decoration: InputDecoration(labelText: 'Area/Colony'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter area/colony' : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.location_on),
                      label: Text("Use My Location"),
                      onPressed: _useCurrentLocation,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveAddress,
                      child: Text("Save Address"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
