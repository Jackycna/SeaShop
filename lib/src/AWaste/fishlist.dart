import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:sea_shop/src/fish%20show/shopfish.dart';
import 'package:sea_shop/src/styles/app_bar_style.dart';

class FishDetailsPage extends StatefulWidget {
  const FishDetailsPage({super.key});

  @override
  FishDetailsPageState createState() => FishDetailsPageState();
}

class FishDetailsPageState extends State<FishDetailsPage> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('owners');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Locations',
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Stack(
        children: [
          StreamBuilder<DatabaseEvent>(
            stream: _databaseRef.onValue, // Listen for real-time updates
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Display blurred loading effect while waiting for data
                return Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: const Color(0xFFEae6de)
                            .withOpacity(0.9), // Semi-transparent background
                      ),
                    ),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF003780), // Customize color
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                // Handle any errors
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.children.isEmpty) {
                // Handle case when there are no shops
                return const Center(child: Text('No shops available.'));
              }

              // Parse the data from the snapshot
              List<Map<String, dynamic>> shops = [];
              for (var ownerSnapshot in snapshot.data!.snapshot.children) {
                for (var shopSnapshot
                    in ownerSnapshot.child('shops').children) {
                  String shopAddress = shopSnapshot.key!;
                  shops.add({'shopAddress': shopAddress});
                }
              }

              return Container(
                height: double.infinity,
                width: double.infinity,
                color: const Color(0xFFEae6de),
                child: ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: const Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.black38,
                        ),
                        title: GestureDetector(
                          onTap: () {
                            // Navigate to shop fish details page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopFishDetailsPage(
                                  shopAddress: shop['shopAddress'],
                                ),
                              ),
                            );
                          },
                          child: Text(
                            shop['shopAddress'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003780),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
