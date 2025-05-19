import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sea_shop/localization/localization_service.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  LogoutPageState createState() => LogoutPageState();
}

class LogoutPageState extends State<LogoutPage> {
  bool _isLoading = false;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Define FirebaseAuth instance

  Future<void> _logOut() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Sign out from Firebase Auth
      await _auth.signOut();

      // Simulate a delay (optional, for user experience)
      await Future.delayed(const Duration(seconds: 1));

      // Clear any app-specific data if necessary
      // Example: SharedPreferences or local cache clearing

      // Navigate to the SignInPage
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/sign_in',
          (route) => false,
        );
      }
    } catch (e) {
      // Handle any errors during sign-out
      // print('Error during logout: $e');
      if (mounted) {
        _showAlertDialog(
            'Logout Error', 'Failed to log out. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset(
                    'assets/images/last.png',
                    height: 180,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                LocalizationService().translate('ld1'),
                style: const TextStyle(
                    color: Color(0xFF003780),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                LocalizationService().translate('ld2'),
                style: const TextStyle(
                    color: Color(0xFF003780),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 80),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003780),
                  side: const BorderSide(color: Color(0xFF003780), width: 2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 45),
                ),
                child: Text(
                  LocalizationService().translate('lno'),
                  style:
                      const TextStyle(color: Color(0xFFEae6de), fontSize: 24),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed:
                    _isLoading ? null : _logOut, // Disable button while loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF003780), width: 2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF003780)),
                      )
                    : Text(
                        LocalizationService().translate('lyes'),
                        style: const TextStyle(
                            color: Color(0xFF003780), fontSize: 24),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
