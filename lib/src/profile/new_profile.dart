import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/about_seashop.dart';
import 'package:sea_shop/src/order/orders.dart';
import 'package:sea_shop/src/profile/logout_page.dart';

import 'package:sea_shop/src/profile/user_profile.dart';
import 'package:sea_shop/src/report_page.dart';

class ProfilePages extends StatelessWidget {
  const ProfilePages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: SingleChildScrollView(
        // Makes the whole page scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage('assets/images/lo.png'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap:
                    true, // Ensures it fits inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disables inner scroll
                children: [
                  _buildOptionCard(
                      context, Icons.person, 'Profile', const ProfilePagess()),
                  _buildOptionCard(context, Icons.category_outlined, 'Orders',
                      const OrdersPagea()),
                  _buildOptionCard(context, Icons.report_problem, 'Report',
                      const ReportProblemPage()),
                  _buildOptionCard(context, Icons.info, 'About SeaShop',
                      const AboutUsPage()),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 200,
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4.0,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Color(0xFF003780),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                            color: Color(0xFF003780),
                            fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogoutPage()),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Extra spacing for better layout
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, IconData icon, String label, Widget page) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF003780), size: 40),
            const SizedBox(height: 10),
            Text(
              LocalizationService().translate(label),
              style: const TextStyle(
                  color: Color(0xFF003780), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
