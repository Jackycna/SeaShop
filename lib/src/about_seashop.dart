import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: const Text(
          "Sea Shop",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003780)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ImageCard(
                  assetPath: 'assets/images/fresh.jpg',
                  title: 'Fresh Fish',
                  description:
                      'We provide the freshest seafood directly from certified sellers.'),
              ImageCard(
                  assetPath: 'assets/images/shop.jpg',
                  title: 'Certified Shops',
                  description:
                      'All listed shops are certified, ensuring quality and safety.'),
              ImageCard(
                  assetPath: 'assets/images/safe.jpg',
                  title: 'Safe Payments',
                  description:
                      'We use a secure payment system to keep transactions safe.'),
              ImageCard(
                  assetPath: 'assets/images/affordable.jpg',
                  title: 'Affordable Prices',
                  description:
                      'Shop owners handle deliveries, reducing costs for customers.'),
              ImageCard(
                  assetPath: 'assets/images/privacy.webp',
                  title: 'Customer Privacy',
                  description:
                      'Your personal details are never shared with anyone.'),
              ImageCard(
                  assetPath: 'assets/images/bike.webp',
                  title: 'Fast Delivery',
                  description:
                      'Get your seafood delivered quickly by local shop owners.'),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String description;

  const ImageCard(
      {super.key,
      required this.assetPath,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              assetPath,
              fit: BoxFit.fill,
              width: double.infinity,
              height: 250, // Fixed height for consistency
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF003780)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
