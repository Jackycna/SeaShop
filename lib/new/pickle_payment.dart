// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/all_fish/allfish.dart';
import 'package:sea_shop/src/fish%20show/payment_methodnew.dart';

class PicklePayment extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final String imageUrl;
  final String ownerId;
  final String fishid;
  final String type;
  final double distance;

  const PicklePayment({
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

class PaymentPageState extends State<PicklePayment> {
  String? userName;
  String? userPhone;
  String? userAddress2;
  String? shopAddress;
  bool isLoading = true;
  List<String> alternatePhoneNumbers = [];
  List<Map<String, dynamic>> addedItems = [];
  List<String> addedFishNames = [];
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  void saveAddress() {
    setState(() {
      userAddress2 = addressController.text; // Save the entered address
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: Text(
          LocalizationService().translate('ordersummary'),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF003780)),
        ),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        padding: const EdgeInsets.all(25.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: "Enter Delivery Address",
                        hintText: userAddress2 ?? "Enter your delivery address",
                        prefixIcon: const Icon(Icons
                            .location_on), // Location icon for better clarity
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 20.0),
                      ),
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        saveAddress(); // Save address as user types
                      },
                    ),

                    const SizedBox(height: 20),
                    Text(
                      LocalizationService().translate('mobile'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          LocalizationService().translate('orderdetails'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                backgroundColor: Colors.green,
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              child: Text(
                                LocalizationService().translate('add1'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
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
                              icon: const Icon(Icons.remove_circle),
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
                      height: 10,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // Confirm Payment Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showSplashMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          backgroundColor: const Color(0xFF003780),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: Text(
                          LocalizationService().translate('continue'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void confirmPayment(BuildContext context) {
    // Validate delivery address
    if (userAddress2 == null ||
        userAddress2!.trim().isEmpty ||
        userAddress2!.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid delivery address ."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop further execution if validation fails
    }

    double totalPrice = widget.fishPricePerKg +
        addedItems.fold(0.0, (sum, item) {
          return sum +
              (double.tryParse(item['price_per_kilogram'].toString()) ?? 0.0);
        });

    String combinedFishNames = addedFishNames.join(', ');

    Map<String, dynamic> orderDetails = {
      'fishName': widget.fishName,
      'fishPricePerKg': widget.fishPricePerKg,
      'totalPrice': totalPrice,
      'ownerId': widget.ownerId,
      'shopAddress': shopAddress,
      'customerId': FirebaseAuth.instance.currentUser?.uid,
      'status': 'Pending',
      'fishId': widget.fishid,
      'deliveryCharge': 80.0,
      'userPhone': userPhone,
      'Name': userName,
      'deliveryAddress': userAddress2,
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

          // Extract user address

          setState(() {
            userName = data['name'];
            userPhone = data['phone'];
          });
        }
      } catch (error) {
        print('Error fetching user details: $error');
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void showSplashMessage() {
    confirmPayment(context);
  }
}
