import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllFoods extends StatefulWidget {
  final Function(Map<String, dynamic>) onFishSelected;

  const AllFoods({super.key, required this.onFishSelected});

  @override
  SpecialShopFishDetailsPageState createState() =>
      SpecialShopFishDetailsPageState();
}

class SpecialShopFishDetailsPageState extends State<AllFoods> {
  late Future<List<Map<String, dynamic>>> _fishFuture;
  String? shopAddress;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    _getShopAddress();
  }

  Future<void> _getShopAddress() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          shopAddress = userDoc['shopLocation'];
          ownerId = userDoc['ownerId']; // Fetch ownerId from user document
        });

        // Fetch fish data once shop address and ownerId are available
        if (ownerId != null) {
          _fishFuture = _getFishData(ownerId!);
        } else {
          setState(() {
            shopAddress = 'Owner ID is missing';
          });
        }
      } else {
        setState(() {
          shopAddress = 'User document not found';
        });
      }
    } catch (e) {
      setState(() {
        shopAddress = 'Error fetching address: $e';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getFishData(String ownerId) async {
    try {
      var fishSnapshot = await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .collection('fishes')
          .where('type', isEqualTo: 'pickle')
          .get();

      List<Map<String, dynamic>> fishListInStock = [];

      for (var fishDoc in fishSnapshot.docs) {
        var fishData = {
          'name': fishDoc['name'],
          'price_per_kilogram': fishDoc['price_per_kilogram'],
          'imageUrl': fishDoc['imageUrl'],
          'id': fishDoc.id,
          'ownerId': ownerId,
          'shopAddress': shopAddress,
        };
        if (fishDoc['isOutOfStock'] == false) {
          fishListInStock.add(fishData);
        }
      }

      return fishListInStock;
    } catch (e) {
      return []; // Return an empty list in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shopAddress == null || ownerId == null) {
      return const SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFEae6de),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('allfishes'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF003780)),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      backgroundColor: const Color(0xFFEae6de),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fishFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error fetching fish details',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          List<Map<String, dynamic>> fishListInStock = snapshot.data ?? [];

          if (fishListInStock.isEmpty) {
            return Center(
              child: Text(
                LocalizationService().translate('nofish1'),
                style: const TextStyle(
                    color: Color(0xFF003780),
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: fishListInStock.length,
            itemBuilder: (context, index) {
              final fish = fishListInStock[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: fish['imageUrl'] ?? '',
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fish['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${((fish['price_per_kilogram']))}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onFishSelected(fish);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003780),
                        ),
                        child: Text(
                          LocalizationService().translate('add'),
                          style: const TextStyle(color: Colors.white),
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
