// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';

class NoNetworkPage extends StatefulWidget {
  const NoNetworkPage({super.key});

  @override
  NoNetworkPageState createState() => NoNetworkPageState();
}

class NoNetworkPageState extends State<NoNetworkPage> {
  bool _isCheckingConnectivity = false;

  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnectivity = true;
    });

    bool hasInternet = await _hasInternetConnection();

    if (hasInternet) {
      // Navigate to the Home Page
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _isCheckingConnectivity = false;
      });
      // Stay on the same page if no internet
    }
  }

  /// Check if there is an active internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/wifi.png'),
                Text(
                  LocalizationService().translate('nonet'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003780),
                  ),
                  onPressed:
                      _isCheckingConnectivity ? null : _checkConnectivity,
                  child: Text(
                    LocalizationService().translate('retry'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isCheckingConnectivity)
            Stack(
              children: [
                ModalBarrier(
                  color: Colors.black.withOpacity(0.5),
                  dismissible: false,
                ),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
