// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/fish%20show/profile_map.dart';
import 'package:sea_shop/src/styles/app_bar_style.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isEditing = false;
  bool isLoadingLocation = false;

  Future<Map<String, dynamic>?> _fetchProfileDetails() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  String? _validateProfileDetails() {
    if (_nameController.text.length < 5) {
      return 'Name must be at least 5 characters long';
    }
    if (_addressController.text.isEmpty) {
      return 'Address cannot be empty';
    }
    return null;
  }

  Future<void> _saveProfileDetails() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String? validationMessage = _validateProfileDetails();
      if (validationMessage != null) {
        _showSplashMessage(validationMessage);
        return;
      }

      final uid = currentUser.uid;
      await _firestore.collection('users').doc(uid).set({
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _mobileController.text,
      }, SetOptions(merge: true));

      _showSplashMessage('Profile updated successfully!');

      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _navigateToMapPicker() async {
    final pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialPosition: _addressController.text,
        ),
      ),
    );

    // If the user picked a location, update the address field and Firestore
    if (pickedLocation != null) {
      setState(() {
        _addressController.text = pickedLocation; // Update the address
      });

      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'address': pickedLocation,
        }, SetOptions(merge: true));
      }

      _showSplashMessage(
          'Location updated successfully!We use your latitude and longitude to ensure fast and accurate delivery. This helps us reach you quickly and efficiently. Your privacy is important, and location data is only used for delivery purposes. ');
    }
  }

  Future<void> _sendInquiry(String inquiry) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('customer_reviews').add({
        'uid': currentUser.uid,
        'inquiry': inquiry,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showSplashMessage('Issue submitted successfully!');
    }
  }

  Future<void> _logout() async {
    // Show a confirmation dialog
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // If the user confirmed the logout
    if (confirmLogout ?? false) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Wait for 5 seconds before logging out
      await Future.delayed(const Duration(seconds: 5));

      // Sign out the user
      await _auth.signOut();

      // Close the loading indicator dialog
      Navigator.of(context).pop();

      // Navigate to the sign-in page
      Navigator.of(context).pushReplacementNamed('/sign_in');
    }
  }

  void _showSplashMessage(String message) {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: MediaQuery.of(context).size.width * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('profile'),
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF003780),
            ),
            onPressed: () {
              if (_isEditing) {
                _saveProfileDetails();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFEae6de),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchProfileDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No profile data found.'));
            }

            final profileData = snapshot.data!;
            _nameController.text = profileData['name'] ?? '';
            _mobileController.text = profileData['phone'] ?? '';
            _addressController.text = profileData['address'] ?? '';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/lo.png',
                    height: 200,
                    width: 200,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: LocalizationService().translate('name'),
                      labelStyle: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white70,
                      border: const OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                      labelText: LocalizationService().translate('mobile'),
                      labelStyle: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white70,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      AbsorbPointer(
                        absorbing:
                            !_isEditing, // Disable touch interaction when not editing
                        child: GestureDetector(
                          onTap: _isEditing
                              ? _navigateToMapPicker
                              : null, // Detect tap when editing is enabled
                          child: TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText:
                                  LocalizationService().translate('address'),
                              labelStyle: const TextStyle(
                                color: Color(0xFF003780),
                                fontWeight: FontWeight.bold,
                              ),
                              filled: true,
                              fillColor: Colors.white70,
                              border: const OutlineInputBorder(),
                            ),
                            readOnly:
                                true, // Make the field read-only if not editing
                            enabled:
                                _isEditing, // Only editable if _isEditing is true
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: isLoadingLocation
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: const Color(0xFF003780),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      _navigateToMapPicker, // The location button action
                                  child: const Text(
                                    'Get Location',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'The address will be save as a format of lattitude and longitude',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 90),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003780),
                      ),
                      onPressed: () async {
                        String? inquiry = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            final TextEditingController inquiryController =
                                TextEditingController();
                            return AlertDialog(
                              title: const Text(
                                'Submit an Issue',
                              ),
                              content: TextField(
                                controller: inquiryController,
                                decoration: const InputDecoration(
                                    hintText: 'Describe your issue...'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                      context, inquiryController.text),
                                  child: Text(LocalizationService()
                                      .translate('address')),
                                ),
                              ],
                            );
                          },
                        );

                        if (inquiry != null && inquiry.isNotEmpty) {
                          _sendInquiry(inquiry);
                        }
                      },
                      child: const Text(
                        'Submit Issue',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _logout,
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
