import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sea_shop/new/revie_show.dart';
import 'package:sea_shop/src/afish%20types/chopped/chopped_fish.dart';

class FishShops extends StatefulWidget {
  const FishShops({super.key});

  @override
  OwnerDetailsPageState createState() => OwnerDetailsPageState();
}

class OwnerDetailsPageState extends State<FishShops>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userLocationString;
  String? _currentUserId;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      fetchUserLocation();
    }
  }

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
          });
        }
      }
    }
  }

  Stream<List<Map<String, dynamic>>> fetchShopsStream() {
    return _firestore
        .collection('owners')
        .where('storetype', isEqualTo: 'Fish Mart')
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> shops = [];
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        var ownerData = doc.data() as Map<String, dynamic>?;

        if (ownerData != null && ownerData.containsKey('shopLocation')) {
          String shopLocation = ownerData['shopLocation'];
          double distance = calculateDistance(shopLocation);
          bool isClosed = ownerData['holiday'] == true;

          if (!isClosed && ownerData.containsKey('timeSlots')) {
            List<dynamic> timeSlots = ownerData['timeSlots'];
            bool withinTimeSlot = false;

            for (String slot in timeSlots) {
              List<String> times = slot.split(' - ');
              if (times.length == 2) {
                DateTime startTime = parseTime(times[0], now);
                DateTime endTime = parseTime(times[1], now);

                // Handle time slot spanning midnight
                if (endTime.isBefore(startTime)) {
                  // If endTime is before startTime, it means it spans midnight
                  if (now.isAfter(startTime) || now.isBefore(endTime)) {
                    withinTimeSlot = true;
                    break;
                  }
                } else {
                  if (now.isAfter(startTime) && now.isBefore(endTime)) {
                    withinTimeSlot = true;
                    break;
                  }
                }
              }
            }

            if (!withinTimeSlot) {
              isClosed = true;
            }
          }

          shops.add({
            "id": doc.id,
            "data": ownerData,
            "distance": distance,
            "isClosed": isClosed,
          });
        }
      }

      // Sort shops by distance
      shops.sort((a, b) => a["distance"].compareTo(b["distance"]));
      return shops;
    });
  }

// Corrected parseTime function that sets the correct date
  DateTime parseTime(String timeString, DateTime referenceDate) {
    final format = DateFormat.jm(); // '6:00 AM'
    DateTime parsedTime = format.parse(timeString);

    return DateTime(referenceDate.year, referenceDate.month, referenceDate.day,
        parsedTime.hour, parsedTime.minute);
  }

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
          1000;
    } catch (e) {
      return double.infinity;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/lo.png', // Replace with your image path
                        height: 100, // Adjust size as needed
                      ),
                      const SizedBox(width: 8), // Space between image and text
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFFEae6de),
      body: _userLocationString == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchShopsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No Fish Mart available.'));
                }

                List<Map<String, dynamic>> shops = snapshot.data!;

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    var shop = shops[index];
                    var ownerData = shop["data"];
                    String ownerId = shop["id"];
                    double distance = shop["distance"];
                    double freeDistance =
                        (ownerData["freedistance"] ?? 0).toDouble();
                    double maxDistance =
                        (ownerData["maxdistance"] ?? 0).toDouble();
                    bool isClosed = shop["isClosed"] ?? false;

                    String? imageUrl = ownerData['profileImage'] != null &&
                            ownerData['profileImage'].toString().isNotEmpty
                        ? ownerData['profileImage']
                        : null;

                    return GestureDetector(
                      onTap: isClosed || (maxDistance < distance)
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChoppedFishDetailsPage(
                                      ownerId: ownerId, distance: distance),
                                ),
                              );
                            },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📸 Shop Image (Left Side)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      bottomLeft: Radius.circular(15)),
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          height: 120,
                                          width:
                                              120, // Fixed width for uniformity
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 120,
                                          width: 120,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                bottomLeft:
                                                    Radius.circular(15)),
                                          ),
                                          child: const Icon(Icons.store,
                                              color: Color(0xFF003780),
                                              size: 50),
                                        ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewPage(
                                            ownerId: ownerId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.star,
                                      size: 20,
                                      color: Colors.amber,
                                    ),
                                    label: const Text(
                                      "Reviews",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEae6de),
                                      foregroundColor: const Color(0xFF003780),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 4),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),

                            // 📌 Shop Details (Right Side)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 📍 Shop Name
                                    Text(
                                      ownerData['displayName'] ??
                                          'Unknown Shop',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003780),
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // 📍 Distance
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.red, size: 16),
                                        const SizedBox(width: 5),
                                        Text(
                                          "${distance.toStringAsFixed(1)} km  away",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // 🚚 Free Delivery Badge (If applicable)
                                    if (distance <= freeDistance && !isClosed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[700],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "Free Delivery 🚚",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),

                                    if (isClosed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF003780),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "Closed Now ❌",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),

                                    if (!isClosed &&
                                        distance > maxDistance &&
                                        distance != 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF003780),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "🚫 Delivery Unavailable",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (!isClosed && distance < maxDistance)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF003780)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: const Text(
                                            '25-30 MINS',
                                            style: TextStyle(
                                              color: Color(0xFF003780),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
