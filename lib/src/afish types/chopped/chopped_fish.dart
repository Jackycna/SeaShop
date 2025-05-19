import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/afish%20types/chopped/chopped_checkou.dart';

class ChoppedFishDetailsPage extends StatefulWidget {
  final String ownerId;
  final double distance;
  const ChoppedFishDetailsPage({
    super.key,
    required this.ownerId,
    required this.distance,
  });

  @override
  SpecialShopFishDetailsPageState createState() =>
      SpecialShopFishDetailsPageState();
}

class SpecialShopFishDetailsPageState extends State<ChoppedFishDetailsPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _fishStream;
  String? ownerId;
  String? userId;
  String? shopAddress;
  String searchQuery = '';
  String selectedType = "All";
  bool isFavor = false;
  bool isLoading = false;
  bool _isFavPressed = false;

  @override
  void initState() {
    super.initState();
    getOwnerId();
    getUserId();
  }

  Future<void> getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      checkFavoriteStatus(); // Check favorite status after getting userId
    }
  }

  Future<void> checkFavoriteStatus() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      List favorites = userDoc.data()?['favoriteShops'] ?? [];
      if (favorites.contains(widget.ownerId)) {
        if (mounted) {
          setState(() {
            isFavor = true;
          });
        }
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isLoading = true;
    });
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    if (isFavor) {
      // 🔻 Remove from favorites
      await userRef.update({
        'favoriteShops': FieldValue.arrayRemove([widget.ownerId])
      });
      setState(() {
        isFavor = false;
        isLoading = false;
      });
    } else {
      // 🔺 Add to favorites
      await userRef.update({
        'favoriteShops': FieldValue.arrayUnion([widget.ownerId])
      });
      setState(() {
        isFavor = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: LocalizationService().translate('search'),
                    hintStyle: const TextStyle(color: Color(0xFF003780)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                          color: Color(0xFF003780), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                          const BorderSide(color: Color(0xFF003780), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF003780)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  style: const TextStyle(color: Color(0xFF003780)),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFFEae6de),
              onSelected: (String value) {
                setState(() {
                  selectedType = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'All',
                  child: Container(
                    color: selectedType == 'All'
                        ? const Color(0xFF003780)
                        : Colors.white, // Background color
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text(
                      'All',
                      style: TextStyle(
                        fontWeight: selectedType == 'All'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedType == 'All'
                            ? Colors.white
                            : Colors.black, // Highlight color
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Fishes',
                  child: Container(
                    color: selectedType == 'Fishes'
                        ? const Color(0xFF003780)
                        : Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text(
                      'Fishes',
                      style: TextStyle(
                        fontWeight: selectedType == 'Fishes'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedType == 'Fishes'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Pickle',
                  child: Container(
                    color: selectedType == 'Pickle'
                        ? const Color(0xFF003780)
                        : Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Text(
                      'Pickle',
                      style: TextStyle(
                        fontWeight: selectedType == 'Pickle'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedType == 'Pickle'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
              icon: const Icon(
                Icons.filter_list,
                color: Color(0xFF003780),
                size: 30,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      backgroundColor: const Color(0xFFEae6de),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _fishStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Error fetching fish details',
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF003780)),
                            ),
                          );
                        }

                        List<Map<String, dynamic>> fishList = snapshot
                            .data!.docs
                            .map((fishDoc) =>
                                {...fishDoc.data(), 'id': fishDoc.id})
                            .where((fish) =>
                                fish['isOutOfStock'] != true &&
                                fish['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery) &&
                                (selectedType == 'All' ||
                                    fish['type'] == selectedType))
                            .toList();

                        fishList.sort((a, b) {
                          if (a['type'] == 'Fishes' && b['type'] == 'Pickle') {
                            return -1;
                          } else if (a['type'] == 'Pickle' &&
                              b['type'] == 'Fishes') {
                            return 1;
                          }
                          return 0;
                        });

                        if (fishList.isEmpty) {
                          return SingleChildScrollView(
                            child: Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Image.asset(
                                    'assets/images/empty.png',
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 40),
                                  Center(
                                    child: Text(
                                      LocalizationService()
                                          .translate('nofish1'),
                                      style: const TextStyle(
                                          color: Color(0xFF003780),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      LocalizationService()
                                          .translate('nofish2'),
                                      style: const TextStyle(
                                          color: Color(0xFF003780),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(5),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 0,
                            childAspectRatio: 1.9,
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
                                          builder: (context) =>
                                              ChoppedCheckoutPage(
                                            fishName: fish['name'],
                                            fishPricePerKg: double.tryParse(
                                                    fish['price_per_kilogram']
                                                        .toString()) ??
                                                0.0,
                                            cartItemId: fish['id'],
                                            image: fish['imageUrl'],
                                            prepare:
                                                fish['preparation'] ?? false,
                                            type: fish['type'],
                                            ownerId: widget.ownerId,
                                            distance: widget.distance,
                                            availableGrams: List<int>.from(
                                                fish['available_grams'] ?? []),
                                          ),
                                        ),
                                      );
                                    },
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: const Color(
                                          0xFFEae6de), // Background color for better contrast
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                          spreadRadius: 2,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Fish Image
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: CachedNetworkImage(
                                            width: 160, // Slightly bigger image
                                            height: 160,
                                            imageUrl: fish['imageUrl'] ?? '',
                                            placeholder: (context, url) =>
                                                const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error,
                                                        size: 40),
                                            fit: BoxFit.fill,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                14), // Space between image and text

                                        // Fish Name and Price
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Fish Name with a Stylish Font
                                              Text(
                                                fish['name'] ?? 'Unknown Fish',
                                                style: const TextStyle(
                                                  fontSize: 20, // Bigger text
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(
                                                      0xFF003780), // Deep Blue (Matches Theme)
                                                  letterSpacing: 0.5,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),

                                              // 20% Off Label - Sleek and Modern
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                      0xFF003780), // Deep Blue Background
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(
                                                              0.2), // Subtle shadow
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(2, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.local_offer,
                                                        color: Colors.white,
                                                        size: 20), // White Icon
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "20% OFF!",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .white, // Bright White Text
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                  ),
                  Row(
                    children: [
                      // ⭐ "Add Review" Button with Modern Design

                      // ❤️ "Favorite Shop" Button with Modern Look
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isFavPressed = true),
                            onTapUp: (_) =>
                                setState(() => _isFavPressed = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              transform: _isFavPressed
                                  ? Matrix4.identity()
                                  : Matrix4.identity(),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: isFavor
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5252),
                                          Color(0xFFD50000)
                                        ], // Red gradient for favorite
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFBDBDBD),
                                          Color(0xFF757575)
                                        ], // Grey gradient for non-favorite
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    userId == null ? null : _toggleFavorite,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isFavor
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isFavor ? "Fav Shop" : "Add to Favshop",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16, // Increased font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> getOwnerId() async {
    _fishStream = FirebaseFirestore.instance
        .collection('owners')
        .doc(widget.ownerId)
        .collection('fishes')
        .snapshots();
  }
}
