// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sea_shop/src/home.dart';
import 'package:sea_shop/user_map.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  UserDetailsPageState createState() => UserDetailsPageState();
}

class UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? userId;
  bool _isLoading = false;
  bool _isAddressReadOnly = true;
  LatLng? _currentLocation;
  String? _selectedShopLocation;
  Map<String, dynamic> initialData = {};

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });
    if (userId != null) {
      _loadUserDetails();
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        initialData = userDoc.data() as Map<String, dynamic>;

        // Set the initial data into controllers
        nameController.text = initialData['name'] ?? '';
        _phoneController.text = initialData['phone'] ?? '';
        addressController.text = initialData['address'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user details: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true; // Show loading indicator when fetching location
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showLocationPermissionDialog();
      // _showAlertDialog('Error', 'Location services are not enabled.');
      setState(() {
        _isLoading = false; // Show loading indicator when fetching location
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showAlertDialog('Error', 'Location permission denied.');
        setState(() {
          _isLoading = false; // Show loading indicator when fetching location
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        addressController.text = '${position.latitude},${position.longitude}';
        _isAddressReadOnly = true;
        _isLoading = false; // Hide loading indicator after getting location
      });

      // Proceed to open Google Map with current location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GoogleMapScreen(initialPosition: _currentLocation!),
        ),
      );
    } else {
      _showAlertDialog('Error', 'Could not fetch current location');
      setState(() {
        _isLoading = false; // Hide loading indicator if there's an error
      });
    }
  }

  Future<void> _saveUserDetails() async {
    if (userId == null) return;

    if (nameController.text.trim().isEmpty ||
        nameController.text.trim().length < 5) {
      _showAlertDialog(
          'Input Error', 'Name must be at least 5 characters long.');
      return;
    }

    if (addressController.text.trim().isEmpty) {
      _showAlertDialog('Input Error', 'Address is required.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch owner ID where `address` matches the selected shop location
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('owners')
          .where('address', isEqualTo: _selectedShopLocation)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showAlertDialog(
            "Error", "No owner found with the provided shop address.");
        setState(() => _isLoading = false);
        return;
      }

      // Assuming the first match is the correct owner
      String ownerId = querySnapshot.docs.first.id;

      // Fetch existing user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': addressController.text.trim(),
        'shopLocation': _selectedShopLocation,
        'ownerId': ownerId, // Save ownerId with user details
        'detailsSaved': true,
      };

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> existingData =
            userDoc.data() as Map<String, dynamic>;
        if (existingData.containsKey('fcmToken')) {
          userData['fcmToken'] = existingData['fcmToken'];
        }
      }

      // Save user details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));

      // Navigate to the Language Selection Page

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Nav()),
        (Route<dynamic> route) => false,
      );

      // Show success message
      _showAlertDialog("Success", "User details saved successfully.");
    } catch (e) {
      debugPrint("Error saving user details: $e");
      _showAlertDialog("Error", "Failed to save user details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> saveDetailsState(bool state) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'detailsSaved': state,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Error updating detailsSaved state: $e");
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Color(0xFF003780),
                size: 60.0,
              ),
              SizedBox(height: 20.0),
              Text(
                'Enable Location Access',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.0),
              Text(
                'To provide you with a better experience, we need access to your location. '
                'Please enable location permissions in your device settings.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: const Text('User Details',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF003780))),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTextField(
                      controller: nameController,
                      label: 'Name',
                      icon: Icons.person),
                  const SizedBox(height: 25),
                  _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone),
                  const SizedBox(height: 40),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveUserDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003780),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon, // Added Icon
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Color(0xFF003780)), // Added Icon Here
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _getCurrentLocation,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              AbsorbPointer(
                child: _buildTextField(
                  controller: addressController,
                  label: 'Address',
                  readOnly: _isAddressReadOnly,
                  icon: Icons.location_on, // Address Icon
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
