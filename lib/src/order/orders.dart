import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/order/completed_orders.dart';
import 'package:sea_shop/src/order/pending_orders.dart';

class OrdersPagea extends StatelessWidget {
  const OrdersPagea({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            LocalizationService().translate('orders'),
            style: const TextStyle(
              color: Color(0xFF003780),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "You are not logged in.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('orders'),
          style: const TextStyle(
            color: Color(0xFF003780),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEae6de),
        elevation: 0, // Remove app bar shadow for a cleaner look
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 30),

            /// **Pending Orders Card**
            _buildOrderCard(
              context: context,
              title: LocalizationService().translate('porder'),
              imagePath: 'assets/images/pending.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingOrdersPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// **Completed Orders Card**
            _buildOrderCard(
              context: context,
              title: LocalizationService().translate('corder'),
              imagePath: 'assets/images/completed1.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompletedOrdersPage(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **Reusable Card Widget for Orders**
  Widget _buildOrderCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Row(
            children: [
              /// **Image**
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  height: 100.0,
                  width: 100.0,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),

              /// **Title**
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003780),
                  ),
                ),
              ),

              /// **Arrow Icon**
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF003780)),
            ],
          ),
        ),
      ),
    );
  }
}
