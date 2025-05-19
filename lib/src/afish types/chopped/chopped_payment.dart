// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sea_shop/src/all_fish/allfish.dart';
import 'package:sea_shop/src/fish%20show/payment_methodnew.dart';

class ChoppedPaymentPage extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final String imageUrl;
  final String ownerId;
  final String fishid;
  final String type;
  final double distance;

  const ChoppedPaymentPage({
    super.key,
    required this.fishName,
    required this.fishPricePerKg,
    required this.imageUrl,
    required this.ownerId,
    required this.fishid,
    required this.type,
    required this.distance,
  });

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<ChoppedPaymentPage> {
  String? userName;
  String? userPhone;
  String? userAddress;
  String? shopAddress;
  var deliveryCharge = 0.0;
  bool isLoading = true;
  List<String> alternatePhoneNumbers = [];
  LatLng? userLatLng;
  LatLng shopLatLng = const LatLng(12.971598, 77.594566);
  GoogleMapController? mapController;
  List<Map<String, dynamic>> addedItems = [];
  List<String> addedFishNames = [];
  String? deliveryChargeMessage;
  bool _isAddPressed = false;
  bool _isContinuePressed = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    calculateDeliveryCharge();
  }

  Future<void> fetchUserInfo() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>;

          String? userAddress = data['address']; // Extract user address

          setState(() {
            userName = data['name'];
            userPhone = data['phone'];
            this.userAddress = userAddress;
          });

          // Convert address to LatLng
          if (userAddress != null && userAddress.isNotEmpty) {
            List<Location> userLocations =
                await locationFromAddress(userAddress);
            double userLat = userLocations.first.latitude;
            double userLng = userLocations.first.longitude;

            setState(() {
              userLatLng = LatLng(userLat, userLng);
            });

            // Calculate delivery charge based on distance
            await calculateDeliveryCharge();
          }
        }
      } catch (error) {
        print('Error fetching user details: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: Text(
          LocalizationService().translate(''),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF003780)),
        ),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        padding: const EdgeInsets.all(15.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFF003780),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      LocalizationService()
                                          .translate('deliveryaddress'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003780)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const SizedBox(width: 20),
                                const SizedBox(height: 8),
                                userLatLng == null
                                    ? Container(
                                        height: 200,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Fetching ...',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                          child: GoogleMap(
                                            onMapCreated: (controller) {
                                              mapController = controller;
                                            },
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: userLatLng!,
                                              zoom: 18,
                                            ),
                                            mapType: MapType.hybrid,
                                            markers: {
                                              Marker(
                                                markerId: const MarkerId(
                                                    'userLocation'),
                                                position: userLatLng!,
                                                infoWindow: InfoWindow(
                                                  title: 'Your Location',
                                                  snippet: userAddress,
                                                ),
                                              ),
                                            },
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xFF003780),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          LocalizationService().translate('mobile'),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003780)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userPhone ?? 'Fetching ...',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                ...alternatePhoneNumbers.map((phone) => Text(
                                      phone,
                                      style: const TextStyle(fontSize: 14.0),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF003780),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          LocalizationService().translate('orderdetails'),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003780)),
                        ),
                        const SizedBox(width: 30),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            widget.imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          widget.fishName,
                          style: const TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Price: ₹ ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003780),
                                      fontSize: 20),
                                ),
                                Text(
                                  widget.fishPricePerKg.toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003780),
                                      fontSize: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Show Added Fish Items
                    if (addedItems.isNotEmpty)
                      ...addedItems.map((item) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Image.network(item['imageUrl'] ?? ''),
                            title: Text(
                              item['name'] ?? 'No name',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: Text(
                              'Price: ₹${item['selected_price']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003780),
                                  fontSize: 20),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  addedItems.remove(item);
                                });
                              },
                            ),
                          ),
                        );
                      }),

                    const SizedBox(
                      height: 30,
                    ),

                    Center(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _isAddPressed = true),
                        onTapUp: (_) => setState(() => _isAddPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: _isAddPressed
                              ? Matrix4.identity()
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF003780), Color(0xFF0077B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllFishDetailsPage(
                                    ownerId: widget.ownerId,
                                    onFishSelected: (selectedFish) {
                                      setState(() {
                                        addedItems.add(selectedFish);
                                        addedFishNames
                                            .add(selectedFish['name']);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text(
                              LocalizationService().translate('add1'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

// Confirm Payment Button
                    Center(
                      child: GestureDetector(
                        onTapDown: (_) =>
                            setState(() => _isContinuePressed = true),
                        onTapUp: (_) =>
                            setState(() => _isContinuePressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: _isContinuePressed
                              ? Matrix4.identity()
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF003780), Color(0xFF0077B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              showSplashMessage();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text(
                              LocalizationService().translate('continue'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> calculateDeliveryCharge() async {
    try {
      // Fetch shop data from Firestore
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('owners')
          .doc(widget.ownerId)
          .get();

      if (!shopSnapshot.exists) {
        throw Exception("Shop not found for ownerId: ${widget.ownerId}");
      }

      final shopData = shopSnapshot.data();
      if (shopData == null) {
        throw Exception("No data found for ownerId: ${widget.ownerId}");
      }

      // Fetch delivery settings
      double chargePerKm = (shopData['chargeperkm'] ?? 0).toDouble();
      double freeDistance = (shopData['freedistance'] ?? 0).toDouble();
      double maxDistance = (shopData['maxdistance'] ?? 0).toDouble();

      double distanceInKm = widget.distance;

      if (distanceInKm > maxDistance) {
        setState(() {
          deliveryCharge = -1;
        });
      } else if (distanceInKm <= freeDistance) {
        setState(() {
          deliveryCharge = 0;
        });
      } else {
        double extraKm = distanceInKm - freeDistance;
        double totalCharge = extraKm * chargePerKm;

        setState(() {
          deliveryCharge = totalCharge.roundToDouble();
        });
      }
    } catch (error) {
      print('Error calculating delivery charge: $error');
      setState(() {
        deliveryCharge = -1;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSplashMessage() {
    if (deliveryCharge == -1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
            backgroundColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationService().translate('serviceunavail'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.black87,
                    letterSpacing: 0.5, // Slight letter spacing for elegance
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  LocalizationService().translate('serviceunavail2'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5, // Increase line height for readability
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pop(); // Navigate to the previous page
                  },
                  child: Text(
                    LocalizationService().translate('ok'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      _confirmPayment(context);
    }
  }

  void _confirmPayment(BuildContext context) {
    double totalPrice = widget.fishPricePerKg +
        addedItems.fold(0.0, (sum, item) {
          return sum +
              (double.tryParse(item['selected_price'].toString()) ?? 0.0);
        });

    String combinedFishNames = addedFishNames.join(', ');
    Map<String, dynamic> orderDetails = {
      'fishName': widget.fishName,
      'fishPricePerKg': widget.fishPricePerKg,
      'totalPrice': (totalPrice),
      'ownerId': widget.ownerId,
      'shopAddress': shopAddress,
      'customerId': FirebaseAuth.instance.currentUser?.uid,
      'status': 'Pending',
      'fishId': widget.fishid,
      'deliveryCharge': deliveryCharge,
      'userPhone': userPhone,
      'Name': userName,
      'deliveryAddress': userAddress,
      'type': widget.type,
      'addedFishNames': combinedFishNames,
      'image': widget.imageUrl,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodPage(
            orderDetails: orderDetails, ownerId: widget.ownerId),
      ),
    );
  }
}
