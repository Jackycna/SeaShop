import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/fish%20show/profile_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class ProfilePagess extends StatefulWidget {
  const ProfilePagess({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePagess>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool isLocation = false;
  bool isloading = true;
  bool isUpdating = false;
  bool isEditingName = false;
  late GoogleMapController mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchProfileDetails();
  }

  Future<Map<String, dynamic>?> _fetchProfileDetails() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      setState(() {
        isloading = false;
      });
    }
    return null;
  }

  String? _validateProfileDetails() {
    if (_nameController.text.length < 5) {
      return LocalizationService().translate('5char');
    }
    if (_addressController.text.isEmpty) {
      return LocalizationService().translate('emptyaddress');
    }
    return null;
  }

  Future<void> _saveProfileDetails() async {
    setState(() {
      isUpdating = true;
    });

    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String? validationMessage = _validateProfileDetails();
      if (validationMessage != null) {
        _showSplashMessage(validationMessage);
        setState(() {
          isUpdating = false;
        });
        return;
      }

      final uid = currentUser.uid;
      await _firestore.collection('users').doc(uid).set({
        'name': _nameController.text,
        'address': _addressController.text, // Save the address as is
        'phone': _mobileController.text,
        'location': _currentPosition != null
            ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
      }, SetOptions(merge: true));

      _showSplashMessage(LocalizationService().translate('profileupdated'));
    }

    setState(() {
      isUpdating = false;
    });
  }

  Future<void> _navigateToMapPicker() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      final pickedLocation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerPage(
            initialPosition: _addressController.text,
          ),
        ),
      );

      if (pickedLocation != null) {
        setState(() {
          _addressController.text = pickedLocation;
          _getCoordinatesFromAddress(pickedLocation);
        });

        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser.uid).set({
            'address': pickedLocation, // Save the picked location address
            'location': GeoPoint(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
          }, SetOptions(merge: true));
        }

        _showSplashMessage(LocalizationService().translate('locationupdated'));
      }
    } else if (status.isDenied) {
      _showSplashMessage(LocalizationService().translate('locationpermission'));
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _toggleEditName() async {
    if (isEditingName) {
      String? validationMessage = _validateProfileDetails();
      if (validationMessage != null) {
        _showSplashMessage(validationMessage);
        return;
      }
      await _saveProfileDetails();
    }
    setState(() {
      isEditingName = !isEditingName;
    });
  }

  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      setState(() {
        _currentPosition =
            LatLng(locations[0].latitude, locations[0].longitude);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error getting coordinates: $e");
      }
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
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('profile'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003780),
          ),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFFEae6de),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchProfileDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                  child: Text(LocalizationService().translate('noprofile')));
            }
            final profileData = snapshot.data!;
            _nameController.text = profileData['name'] ?? '';
            _mobileController.text = profileData['phone'] ?? '';
            _addressController.text = profileData['address'] ?? '';

            // Parse the stored address (latitude, longitude)
            if (profileData['address'] != null) {
              List<String> addressParts = profileData['address'].split(',');
              if (addressParts.length == 2) {
                try {
                  double latitude = double.parse(addressParts[0]);
                  double longitude = double.parse(addressParts[1]);
                  _currentPosition = LatLng(latitude, longitude);
                } catch (e) {
                  // print('Error parsing coordinates: $e');
                }
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/proo.png'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Name icon
                      const SizedBox(width: 8), // Spacing
                      Text(
                        LocalizationService().translate('name'),
                        style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(), // Pushes edit icon to the end
                      IconButton(
                        icon: Icon(
                          isEditingName ? Icons.check : Icons.edit,
                          color: const Color(0xFF003780),
                        ),
                        onPressed: _toggleEditName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person,
                          color: Color(0xFF003780)), // Person icon inside field
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF003780), width: 3.0),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF003780), width: 3.0),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF003780), width: 3.0),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    enabled: isEditingName,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Mobile icon
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService().translate('mobile'),
                        style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone,
                          color: Color(0xFF003780)), // Phone icon inside field
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF003780), width: 3.0),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF003780), width: 3.0),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: true,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService().translate('address'),
                            style: const TextStyle(
                              color: Color(0xFF003780),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _navigateToMapPicker,
                            child: AbsorbPointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 200,
                                  child: _currentPosition == null
                                      ? const Center(
                                          child: Text("Select a location"))
                                      : GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: _currentPosition!,
                                            zoom: 14,
                                          ),
                                          mapType:
                                              MapType.hybrid, // Use Hybrid Map
                                          onMapCreated:
                                              (GoogleMapController controller) {
                                            mapController = controller;
                                          },
                                          markers: {
                                            Marker(
                                              markerId: const MarkerId(
                                                  'selected-location'),
                                              position: _currentPosition!,
                                            ),
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isUpdating)
                        if (isUpdating) const CircularProgressIndicator(),
                    ],
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
