import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/order/order_details.dart';

class PendingOrdersPage extends StatelessWidget {
  const PendingOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Pending Orders"),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("You are not logged in."),
        ),
      );
    }

    final CollectionReference ordersCollection =
        FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('porder'),
          style: const TextStyle(
              color: Color(0xFF003780),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Pending and Packed Orders List
              StreamBuilder<QuerySnapshot>(
                stream: ordersCollection
                    .where('customerId', isEqualTo: userId)
                    .where('status',
                        whereIn: ['Pending', 'Packed', 'Picked']).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 70,
                          ),
                          // Displaying the image
                          SizedBox(
                            height: 300,
                            width: 350,
                            child: Image.asset(
                              'assets/images/nono.png', // Replace with your asset path
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocalizationService().translate('empty'),
                            style: const TextStyle(
                                color: Color(0xFF003780),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            LocalizationService().translate('find'),
                            style: const TextStyle(
                                color: Color(0xFF003780),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          // Displaying the ElevatedButton
                          ElevatedButton(
                            onPressed: () {
                              // Define your action for the button tap
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              ); // Example: Navigate back
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003780),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              LocalizationService().translate('ordernow'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap:
                        true, // Ensure the ListView doesn't take up all available space
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent scrolling independently
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order =
                          orders[index].data() as Map<String, dynamic>;
                      return _buildOrderTile(order, context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Using ListTile and Container for each order
  Widget _buildOrderTile(Map<String, dynamic> order, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2, // Adjust the proportion of the text column
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['fishName'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003780),
                    ),
                    maxLines: 1, // Restrict to one line
                    overflow:
                        TextOverflow.ellipsis, // Add ellipsis for overflow
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        LocalizationService().translate('status'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF003780),
                        ),
                      ),
                      Text(
                        ' : ${order['status'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF003780),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10), // Add spacing between text and image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: SizedBox(
                height: 80,
                width: 80, // Explicitly set constraints
                child: CachedNetworkImage(
                  imageUrl: order['image'] ?? '',
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
