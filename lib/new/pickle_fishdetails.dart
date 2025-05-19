import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/new/pickle_checkout.dart';

class PickleFishDetails extends StatefulWidget {
  final String ownerId;
  final double distance;
  const PickleFishDetails({
    super.key,
    required this.ownerId,
    required this.distance,
  });

  @override
  SpecialShopFishDetailsPageState createState() =>
      SpecialShopFishDetailsPageState();
}

class SpecialShopFishDetailsPageState extends State<PickleFishDetails> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _fishStream;
  String? ownerId;
  String? shopAddress;
  String searchQuery = ''; // Track the search query

  @override
  void initState() {
    super.initState();
    getOwnerId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16), // Add horizontal margin
          child: TextField(
            decoration: InputDecoration(
              hintText: LocalizationService().translate('search'),
              hintStyle: const TextStyle(color: Color(0xFF003780)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide:
                    const BorderSide(color: Color(0xFF003780), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide:
                    const BorderSide(color: Color(0xFF003780), width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFEFEFEF),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF003780)),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16), // Add padding
            ),
            style: const TextStyle(color: Color(0xFF003780)),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase(); // Update the search query
              });
            },
          ),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      backgroundColor: const Color(0xFFEae6de),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _fishStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error fetching fish details',
                  style: TextStyle(fontSize: 18, color: Color(0xFF003780)),
                ),
              );
            }

            List<Map<String, dynamic>> fishList = snapshot.data!.docs
                .map((fishDoc) => {
                      ...fishDoc.data(),
                      'id': fishDoc.id,
                    })
                .where((fish) =>
                    fish['isOutOfStock'] !=
                        true && // Exclude out-of-stock fishes
                    fish['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery)) // Filter by search query
                .toList();

            if (fishList.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/images/empty.png',
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      LocalizationService().translate('nofish1'),
                      style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      LocalizationService().translate('nofish2'),
                      style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 18,
                childAspectRatio: 0.99999,
              ),
              itemCount: fishList.length,
              itemBuilder: (context, index) {
                final fish = fishList[index];
                final isOutOfStock = fish['isOutOfStock'] == true;

                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PickleCheckout(
                                fishName: fish['name'],
                                fishPricePerKg: double.tryParse(
                                        fish['price_per_kilogram']
                                            .toString()) ??
                                    0.0,
                                cartItemId: fish['id'],
                                image: fish['imageUrl'],
                                prepare: fish['preparation'] ?? false,
                                type: fish['type'],
                                ownerId: widget.ownerId,
                                distance: widget.distance,
                                availableGrams: List<int>.from(
                                    fish['available_grams'] ?? []),
                              ),
                            ),
                          );
                        },
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fish Image with Overlay for Out of Stock
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: CachedNetworkImage(
                                height: 90,
                                width: double.infinity,
                                imageUrl: fish['imageUrl'] ?? '',
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                fit: BoxFit.fill,
                              ),
                            ),
                            if (isOutOfStock)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    LocalizationService().translate('ostock'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Fish Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fish['name'] ?? 'Unknown Fish',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003780),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
      ),
    );
  }

  Future<void> getOwnerId() async {
    _fishStream = FirebaseFirestore.instance
        .collection('owners')
        .doc(widget.ownerId)
        .collection('fishes')
        .where('type', isEqualTo: 'Fishes')
        .snapshots();
  }
}
