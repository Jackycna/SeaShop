import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/order/compOrders_detail.dart';

class CompletedOrdersPage extends StatelessWidget {
  final String userId;

  const CompletedOrdersPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference ordersCollection =
        FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('corder'),
          style: const TextStyle(
              color: Color(0xFF003780),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Container(
        color: const Color(0xFFEae6de),
        child: StreamBuilder<QuerySnapshot>(
          stream: ordersCollection
              .where('customerId', isEqualTo: userId)
              .where('status', isEqualTo: 'delivered')
              // Ensure 'deliveredAt' exists
              .snapshots(),
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
                    const SizedBox(height: 10),
                    Text(
                      LocalizationService().translate('cfind'),
                      style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 30),
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
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    // Navigate to order details page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(order: order),
                      ),
                    );
                  },
                  child: _buildOrderCard(order),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Text(
                LocalizationService().translate('totalprice'),
                style: const TextStyle(fontSize: 16, color: Color(0xFF003780)),
              ),
              Text(
                ' : ₹${order['totalPrice'] ?? '0'}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF003780)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                LocalizationService().translate('status'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF003780)),
              ),
              Text(
                ' : ${order['status'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF003780)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
