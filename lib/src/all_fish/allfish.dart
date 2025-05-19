import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllFishDetailsPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onFishSelected;
  final String ownerId;

  const AllFishDetailsPage({
    super.key,
    required this.onFishSelected,
    required this.ownerId,
  });

  @override
  AllFishDetailsPageState createState() => AllFishDetailsPageState();
}

class AllFishDetailsPageState extends State<AllFishDetailsPage> {
  late Future<List<Map<String, dynamic>>> _fishFuture;
  String? shopAddress;
  String? ownerId;
  TextEditingController preparationController = TextEditingController();
  String searchQuery = "";
  String selectedSort = "All";

  @override
  void initState() {
    super.initState();
    getShopAddress();
  }

  Future<void> getShopAddress() async {
    setState(() {
      ownerId = widget.ownerId;
    });
    try {
      _fishFuture = _getFishData(widget.ownerId);
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
          .get();

      List<Map<String, dynamic>> fishListInStock = [];

      for (var fishDoc in fishSnapshot.docs) {
        final data = fishDoc.data();

        if (!data.containsKey('isOutOfStock') ||
            data['isOutOfStock'] == false) {
          var fishData = {
            'name': data['name'],
            'price_per_kilogram': data['price_per_kilogram'],
            'imageUrl': data['imageUrl'],
            'id': fishDoc.id,
            'ownerId': ownerId,
            'shopAddress': shopAddress,
            'available_grams': data['available_grams'] ?? [250, 500, 1000],
            'type': data['type'] ?? 'All'
          };

          fishListInStock.add(fishData);
        }
      }

      return fishListInStock;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching fish data: $e');
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEae6de), // Fill color for the search bar
            borderRadius: BorderRadius.circular(30), // Rounded edges
          ),
          child: TextField(
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Search ",
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.search, color: Colors.white), // Search icon
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedSort = value;
                _fishFuture = _getFishData(widget.ownerId); // Force UI update
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "All",
                child: Text(
                  "All",
                  style: TextStyle(
                    fontWeight: selectedSort == "All"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == "All"
                        ? const Color(0xFF003780)
                        : Colors.black, // Highlight color
                  ),
                ),
              ),
              PopupMenuItem(
                value: "Fishes",
                child: Text(
                  "Fishes",
                  style: TextStyle(
                    fontWeight: selectedSort == "Fishes"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == "Fishes"
                        ? const Color(0xFF003780)
                        : Colors.black,
                  ),
                ),
              ),
              PopupMenuItem(
                value: "pickle",
                child: Text(
                  "Pickle",
                  style: TextStyle(
                    fontWeight: selectedSort == "pickle"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == "pickle"
                        ? const Color(0xFF003780)
                        : Colors.black,
                  ),
                ),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
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
          List<Map<String, dynamic>> filteredFishList = fishListInStock
              .where((fish) => fish['name'].toLowerCase().contains(searchQuery))
              .toList();

          if (selectedSort == "Fishes") {
            filteredFishList = filteredFishList
                .where((fish) => fish['type'] == "Fishes") // Only show Fishes
                .toList();
          } else if (selectedSort == "pickle") {
            filteredFishList = filteredFishList
                .where((fish) => fish['type'] == "pickle") // Only show Pickle
                .toList();
          }

          if (filteredFishList.isEmpty) {
            return Center(
              child: Text(
                LocalizationService().translate('nofish1'),
                style: const TextStyle(
                  color: Color(0xFF003780),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredFishList.length,
            itemBuilder: (context, index) {
              final fish = filteredFishList[index];
              List<int> availableGrams =
                  List<int>.from(fish['available_grams'] ?? []);
              int? selectedGram;
              double pricePerKg =
                  double.tryParse(fish['price_per_kilogram'].toString()) ?? 0.0;
              double selectedPrice = 0.0;

              return StatefulBuilder(
                builder: (context, setState) {
                  return Card(
                    color: const Color(0xFFEae6de),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003780)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          if (selectedGram != null) ...[
                                            TextSpan(
                                              text:
                                                  '₹ ${(selectedPrice * 1.20).toStringAsFixed(2)} ', // Original price (20% extra)
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                                decoration: TextDecoration
                                                    .lineThrough, // Strike-through effect
                                              ),
                                            ),
                                            const TextSpan(
                                                text:
                                                    '  '), // Space between prices
                                            TextSpan(
                                              text:
                                                  '₹ ${selectedPrice.toStringAsFixed(2)}', // Discounted price (20% off)
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'Select Weight(gram)',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF003780),
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            children: availableGrams.map<Widget>((gram) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('$gram g'),
                                  selected: selectedGram == gram,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedGram = gram;
                                        selectedPrice =
                                            (pricePerKg / 1000) * selectedGram!;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          if (fish['type'] == 'Fishes') ...[
                            const SizedBox(
                              height: 10,
                            ),
                            Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Preparation Preference",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF003780),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.3)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.restaurant_menu,
                                                color: Color(0xFF003780)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    preparationController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      "Fillet, Whole, Slices...",
                                                  hintStyle: TextStyle(
                                                      color: Colors.grey[400]),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: selectedGram != null
                                ? () {
                                    setState(() {
                                      String preparation =
                                          preparationController.text.trim();
                                      fish['name'] =
                                          '${fish['name']} ${selectedGram}g${preparation.isNotEmpty ? " - $preparation" : ""}';
                                      fish['selected_gram'] = selectedGram;
                                      fish['selected_price'] = selectedPrice;
                                    });

                                    widget.onFishSelected(fish);
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003780),
                            ),
                            child: Center(
                              child: Text(
                                LocalizationService().translate('add'),
                                style: const TextStyle(color: Colors.white),
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
          );
        },
      ),
    );
  }
}
