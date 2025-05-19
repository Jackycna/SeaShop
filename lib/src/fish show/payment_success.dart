import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/home.dart';

import 'package:sea_shop/src/shop_review.dart';

class PaymentSuccess extends StatelessWidget {
  final String ownerId;
  final String? userId;

  const PaymentSuccess({
    super.key,
    required this.ownerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/placed.png'),
            const SizedBox(height: 40),
            Text(
              LocalizationService().translate('placed'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStyledButton(
                  context,
                  text: LocalizationService().translate('continue'),
                  color: Colors.blue.shade800,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const Nav()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(width: 20),
                _buildStyledButton(
                  context,
                  text: LocalizationService().translate('Add Review'),
                  color: Colors.orange.shade700,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewUploadPage(ownerId: ownerId, userId: userId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledButton(BuildContext context,
      {required String text,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(140, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black54,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
