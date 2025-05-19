import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sea_shop/new/pickle_fishdetails.dart';

class PickleShops extends StatefulWidget {
  const PickleShops({super.key});

  @override
  OwnerDetailsPageState createState() => OwnerDetailsPageState();
}

class OwnerDetailsPageState extends State<PickleShops> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userLocationString;
  String? _currentUserId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  // 🔥 Fetch current user ID & location
  Future<void> fetchCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      fetchUserLocation();
    }
  }

  // 🔥 Fetch user's stored location (lat,lng) from Firestore
  Future<void> fetchUserLocation() async {
    if (_currentUserId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_currentUserId).get();

    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>?;
      if (userData != null && userData.containsKey('address')) {
        if (mounted) {
          setState(() {
            _userLocationString = userData['address']; // Stored as "lat,lng"
            fetchShops();
          });
        }
      }
    }
  }

  // 🔥 Fetch all shops and calculate distances
  Future<void> fetchShops() async {
    if (_userLocationString == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection('owners')
        .where('storetype', isEqualTo: 'Pickle Shop')
        .get();

    List<Map<String, dynamic>> shops = [];

    for (var doc in snapshot.docs) {
      var ownerData = doc.data() as Map<String, dynamic>?;

      if (ownerData != null && ownerData.containsKey('shopLocation')) {
        String shopLocation = ownerData['shopLocation'];
        double distance = calculateDistance(shopLocation);

        shops.add({
          "id": doc.id,
          "data": ownerData,
          "distance": distance,
        });
      }
    }

    shops.sort((a, b) => a["distance"].compareTo(b["distance"]));
    if (mounted) {
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    }
  }

  // 🔥 Convert string to lat/lng and calculate distance
  double calculateDistance(String? shopLocation) {
    if (_userLocationString == null || shopLocation == null) {
      return double.infinity;
    }

    try {
      List<String> userCoords = _userLocationString!.split(',');
      List<String> shopCoords = shopLocation.split(',');

      double userLat = double.parse(userCoords[0].trim());
      double userLng = double.parse(userCoords[1].trim());
      double shopLat = double.parse(shopCoords[0].trim());
      double shopLng = double.parse(shopCoords[1].trim());

      return Geolocator.distanceBetween(userLat, userLng, shopLat, shopLng) /
          1000; // Convert meters to km
    } catch (e) {
      return double.infinity; // Default if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Loading Indicator
          : _shops.isEmpty
              ? const Center(child: Text('No Pickle Shops available.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 0), // No extra horizontal padding
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    var shop = _shops[index];
                    var ownerData = shop["data"];
                    String ownerId = shop["id"];
                    double distance = shop["distance"];
                    String? imageUrl = ownerData['profileImage'] != null &&
                            ownerData['profileImage'].toString().isNotEmpty
                        ? ownerData['profileImage']
                        : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickleFishDetails(
                                ownerId: ownerId, distance: distance),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width, // Full Width
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10), // Small side margin
                        decoration: BoxDecoration(
                          color: const Color(0xFFEae6de),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Container with Free Delivery Badge
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15)),
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          height: 200, // Slightly larger image
                                          width: double.infinity,
                                          fit: BoxFit.fill,
                                        )
                                      : Container(
                                          height: 200,
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD1D1D1),
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(15)),
                                          ),
                                          child: const Icon(Icons.store,
                                              color: Colors.white, size: 80),
                                        ),
                                ),
                              ],
                            ),

                            // Name Section (Separate Background)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(
                                color:
                                    Color(0xFFEae6de), // Light Grey Background
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(15)),
                              ),
                              child: Center(
                                child: Text(
                                  ownerData['displayName'] ?? 'Unknown Shop',
                                  style: const TextStyle(
                                      fontSize: 22, // Slightly bigger font
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003780)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
