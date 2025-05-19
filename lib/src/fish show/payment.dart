// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sea_shop/src/fish%20show/location_pick.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sea_shop/src/fish%20show/payment_methodnew.dart';

class PaymentPage extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final double quantity;
  final String timeSlot;
  final String preparation;
  final String imageUrl;
  final String ownerId;
  final String shopAddress;
  final String fishid;

  const PaymentPage({
    super.key,
    required this.fishName,
    required this.fishPricePerKg,
    required this.quantity,
    required this.timeSlot,
    required this.preparation,
    required this.imageUrl,
    required this.ownerId,
    required this.shopAddress,
    required this.fishid,
  });

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  String? userName;
  String? userPhone;
  String? userAddress;
  var deliveryCharge = 0.0;
  bool _isLoading = true;
  List<String> alternatePhoneNumbers = [];
  // ignore: prefer_typing_uninitialized_variables
  var distanceInKm;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
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
          setState(() {
            userName = data['name'];
            userPhone = data['phone'];
            userAddress = data['address'];
            _isLoading = false;
          });

          // Calculate delivery charge based on distance
          await calculateDeliveryCharge();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (error) {
        print('Error fetching user details: $error');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addAlternatePhoneNumber() async {
    String? newPhoneNumber = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String phoneNumber = '';
        return AlertDialog(
          title: const Text('Add Alternate Phone Number'),
          content: TextField(
            onChanged: (value) {
              phoneNumber = value;
            },
            decoration: const InputDecoration(hintText: 'Enter phone number'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (phoneNumber.isNotEmpty) {
                  Navigator.of(context).pop(phoneNumber);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newPhoneNumber != null) {
      setState(() {
        alternatePhoneNumbers.add(newPhoneNumber);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alternate phone number added!')),
      );
    }
  }

  // Track if the loading indicator should be shown

  Future<void> calculateDeliveryCharge() async {
    setState(() {
      _isLoading = true; // Show the loading indicator when calculation starts
    });

    // Allow the UI to rebuild before heavy computations
    await Future.delayed(const Duration(milliseconds: 100));

    // Start a timer to ensure a minimum delay of 5 seconds
    final minimumLoadingTime = Future.delayed(const Duration(seconds: 5));

    try {
      // Get user's location
      List<Location> userLocations = await locationFromAddress(userAddress!);
      double userLat = userLocations.first.latitude;
      double userLng = userLocations.first.longitude;

      // Get shop's location
      List<Location> shopLocations =
          await locationFromAddress(widget.shopAddress);
      double shopLat = shopLocations.first.latitude;
      double shopLng = shopLocations.first.longitude;

      // Google Distance Matrix API request
      const apiKey =
          'AIzaSyApo_S_3M7xDCzgddlyLFtn8lQULF2XXQs'; // Replace with your actual API key
      final url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$userLat,$userLng&destinations=$shopLat,$shopLng&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check if the response has valid distance data
        var elements = jsonResponse['rows'][0]['elements'][0];

        // Handle the case where there's no valid route (e.g., sea location or no route)
        if (elements['status'] == 'ZERO_RESULTS' ||
            elements['distance'] == null) {
          // If there's no route, delivery is not possible
          deliveryCharge = 0; // Representing no delivery
          setState(() {});
          return;
        }

        var distanceInMeters = elements['distance']['value'];
        distanceInKm = distanceInMeters / 1000; // Convert to kilometers

        // Update delivery charge based on distance
        if (distanceInKm > 10 && distanceInKm <= 20) {
          deliveryCharge = 15;
        } else if (distanceInKm > 15) {
          deliveryCharge = 0; // If the distance is more than 15 km, charge is 0
        } else {
          deliveryCharge = 10; // Default charge
        }

        setState(() {});
      } else {
        print('Failed to load distance data');
        deliveryCharge = -1; // In case of failure, assume no delivery possible
        setState(() {});
      }
    } catch (error) {
      print('Error calculating delivery charge: $error');
      deliveryCharge = -1; // Set to -1 in case of error
      setState(() {});
    }

    // Wait for the minimum loading time to complete
    await minimumLoadingTime;

    setState(() {
      _isLoading = false; // Hide the loading indicator when calculation ends
    });
  }

  void _showSplashMessage() {
    if (deliveryCharge != 10 && deliveryCharge != 15) {
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
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 70,
                ),
                SizedBox(height: 16),
                Text(
                  'Service Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.black87,
                    letterSpacing: 0.5, // Slight letter spacing for elegance
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Your location is currently beyond our delivery area. We are actively working to improve our services and hope to reach your area soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                    Navigator.of(context)
                        .pop(); // Navigate to the previous page
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
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
    Map<String, dynamic> orderDetails = {
      'fishName': widget.fishName,
      'fishPricePerKg': widget.fishPricePerKg,
      'quantity': widget.quantity,
      'totalPrice':
          (((widget.fishPricePerKg) * (widget.quantity)) + deliveryCharge),
      'ownerId': widget.ownerId,
      'shopAddress': widget.shopAddress,
      'customerId': FirebaseAuth.instance.currentUser?.uid,
      'status': 'Pending',
      'timeSlot': widget.timeSlot,
      'fishId': widget.fishid,
      'preparation': widget.preparation,
      'userPhone': userPhone,
      'Name': userName,
      'deliveryAddress': userAddress,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodPage(
          orderDetails: orderDetails,
          ownerId: widget.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice =
        ((widget.fishPricePerKg) * (widget.quantity)) + deliveryCharge;

    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: const Text(
          'Order Summary',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF003780)),
        ),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        padding: const EdgeInsets.all(25.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Color.fromARGB(255, 0, 0, 0)),
                          onPressed: () async {
                            String? newAddress = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationPickerPage(
                                  onLocationSelected: (selectedLocation) {
                                    setState(
                                      () {
                                        userAddress = selectedLocation;
                                        calculateDeliveryCharge();
                                      },
                                    );
                                  },
                                  initialAddress: userAddress,
                                ),
                              ),
                            );

                            if (newAddress != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Address updated!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
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
                          child: Text(
                            userAddress ?? 'Fetching address...',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Contact Number',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  userPhone ?? 'Fetching phone...',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                ...alternatePhoneNumbers.map((phone) => Text(
                                      phone,
                                      style: const TextStyle(fontSize: 14.0),
                                    )),
                              ],
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.add, color: Color(0xFF003780)),
                            onPressed: _addAlternatePhoneNumber,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Order Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fish: ${widget.fishName}',
                            style: const TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Price per Pack: ₹${widget.fishPricePerKg}',
                            style: const TextStyle(
                              fontSize: 20.0,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Quantity: ${(widget.quantity).toInt()} packs',
                            style: const TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          Text(
                            'Fish price: ₹${((widget.fishPricePerKg) * ((widget.quantity))).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Delivery Charge: ₹${deliveryCharge.toInt()}',
                            style: const TextStyle(fontSize: 20.0),
                          ),
                          // Hint message about delivery charge

                          const SizedBox(height: 10),
                          const Divider(),
                          Text(
                            'Total  Price: ₹ ${totalPrice.toInt()}',
                            style: const TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _showSplashMessage(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          backgroundColor: const Color(0xFF003780),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text(
                          'Proceed to Payment',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 500,
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
