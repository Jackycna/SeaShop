import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/src/order/completed_orders.dart';
import 'package:sea_shop/src/order/order_details.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          backgroundColor: const Color(0xFFEae6de),
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
        title: const Text(
          "My Orders",
          style:
              TextStyle(color: Color(0xFF003780), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Completed Orders Text inside a box
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CompletedOrdersPage(userId: userId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEae6de),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFF003780), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image for "Completed Orders"
                        Image.asset(
                          'assets/images/success.png', // Place your image here
                          height: 30.0,
                          width: 30.0,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Completed Orders",
                          style: TextStyle(
                            color: Color(0xFF003780),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 20,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Pending Orders",
                    style: TextStyle(
                      color: Color(0xFF003780),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Pending and Packed Orders List
              StreamBuilder<QuerySnapshot>(
                stream: ordersCollection
                    .where('customerId', isEqualTo: userId)
                    .where('status', whereIn: [
                  'Pending',
                  'Packed',
                  'Out for Delivery'
                ]).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return const Center(
                        child: Text("No pending or packed orders available."));
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
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
            ),
            const SizedBox(height: 8),
            Text(
              'Total Price: ₹${order['totalPrice'] ?? '0'}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF003780)),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${order['status'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
