// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sea_shop/src/order/order_confirm/orderconfirm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:sea_shop/src/styles/app_bar_style.dart';

class ShopFishDetailsPage extends StatefulWidget {
  final String shopAddress;

  const ShopFishDetailsPage({super.key, required this.shopAddress});

  @override
  ShopFishDetailsPageState createState() => ShopFishDetailsPageState();
}

class ShopFishDetailsPageState extends State<ShopFishDetailsPage> {
  late Stream<DatabaseEvent> _fishStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream for fish details
    _fishStream = FirebaseDatabase.instance
        .ref('owners')
        .onValue; // Listen for changes in the owners node
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          ' ${widget.shopAddress}',
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _fishStream,
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
          } else if (!snapshot.hasData ||
              snapshot.data!.snapshot.children.isEmpty) {
            return const Center(
              child: Text(
                'No fishes available',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          // Process the snapshot data to build your fish list
          List<Map<String, dynamic>> fishListInStock = [];
          List<Map<String, dynamic>> fishListOutOfStock = [];

          for (var ownerSnapshot in snapshot.data!.snapshot.children) {
            var shopSnapshot =
                ownerSnapshot.child('shops').child(widget.shopAddress);
            for (var fishSnapshot in shopSnapshot.child('fishes').children) {
              Map<String, dynamic> fishData = {
                'name': fishSnapshot.child('name').value,
                'price_per_kilogram':
                    fishSnapshot.child('price_per_kilogram').value,
                'imageUrl': fishSnapshot.child('imageUrl').value,
                'isOutOfStock': fishSnapshot.child('isOutOfStock').value,
                'id': fishSnapshot.key,
                'ownerId': ownerSnapshot.key,
                'shopAddress': widget.shopAddress,
                'preparation': fishSnapshot.child('preparation').value,

                'AvailableKilogram': fishSnapshot
                    .child('available_kilogram')
                    .value, // Get the available kilograms
              };

              if (fishData['price_per_kilogram'] is int) {
                fishData['price_per_kilogram'] =
                    fishData['price_per_kilogram'].toString();
              }

              if (fishData['isOutOfStock'] == true) {
                fishListOutOfStock.add(fishData);
              } else {
                fishListInStock.add(fishData);
              }
            }
          }

          // Combine in-stock and out-of-stock fish lists for display
          List<Map<String, dynamic>> combinedFishList = [
            ...fishListInStock,
            ...fishListOutOfStock,
          ];

          return ListView.builder(
            itemCount: combinedFishList.length,
            itemBuilder: (context, index) {
              final fish = combinedFishList[index];
              final isOutOfStock = fish['isOutOfStock'] == true;
              final availableKilograms = fish['AvailableKilogram'] ?? 0;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: isOutOfStock
                          ? null
                          : () {
                              // Navigate to checkout page when image is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    fishName: fish['name'],
                                    fishPricePerKg: double.tryParse(
                                            fish['price_per_kilogram']
                                                .toString()) ??
                                        0.0,
                                    cartItemId: fish['id'],
                                    ownerId: fish['ownerId'],
                                    shopAddress: widget.shopAddress,
                                    image: fish['imageUrl'],
                                    avail: fish['AvailableKilogram'],
                                    prepare: fish['preparation'] ?? false,
                                  ),
                                ),
                              );
                            },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              height: 220,
                              width: 500,
                              imageUrl: fish['imageUrl'] ?? '',
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isOutOfStock)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Container(
                                color: Colors.white.withOpacity(0.5),
                                child: const Center(
                                  child: Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Color(0xFF003780),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Show limited stock label if available kilograms is less than 10
                          if (int.parse(availableKilograms) <= 10 &&
                              !isOutOfStock)
                            Positioned(
                              bottom: 0,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF003780),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Limited Stock ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            child: Text(
                              fish['name'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
