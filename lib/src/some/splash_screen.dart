import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Import the device info package
import 'package:in_app_update/in_app_update.dart'; // Import in_app_update for update functionality
import 'package:sea_shop/connectivity_plus.dart';
import 'package:sea_shop/src/home.dart';
import 'package:sea_shop/src/sign_in/signin_page.dart';
import 'package:sea_shop/src/some/sp.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool isOffline = false;
  bool _isEmulator = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity(); // Initial connectivity check
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectivityStatus(result.first);
    });
    _checkIfEmulator(); // Check if the app is running on an emulator
    _navigateToNextScreen(); // Attempt navigation based on connectivity status
  }

  // Check if the app is running on an emulator
  Future<void> _checkIfEmulator() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceData = await deviceInfoPlugin.androidInfo;

    setState(() {
      _isEmulator = deviceData.isPhysicalDevice ==
          false; // If it's not a physical device, it's an emulator
    });
    checkForUpdate();
  }

  // Check initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  // Update connectivity status on network changes
  void _updateConnectivityStatus(ConnectivityResult result) {
    if (!mounted) {
      return;
    }

    setState(() {
      isOffline = result == ConnectivityResult.none;
    });

    if (isOffline && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoNetworkPage()),
      );
    }
  }

  Future<void> checkForUpdate() async {
    if (_isEmulator) return;

    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Show a blocking update dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent closing dialog
            builder: (context) => AlertDialog(
              title: const Text("Update Required"),
              content: const Text(
                  "A new version of the app is available. Please update to continue."),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await InAppUpdate.performImmediateUpdate();
                    } catch (e) {
                      if (kDebugMode) {
                        print("Update failed: $e");
                      }
                    }
                  },
                  child: const Text("Update Now"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("In-app update check failed: $e");
      }
    }
  }

  // Navigate to next screen based on network and authentication status
  Future<void> _navigateToNextScreen() async {
    if (isOffline) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NoNetworkPage()),
        );
      }
      return;
    }

    bool isFirstLaunch = await SharedPreferencesHelper.isFirstLaunch();
    User? user = FirebaseAuth.instance.currentUser;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Nav()),
      );
    } else if (isFirstLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your animated fish images here
            Image.asset(
              'assets/images/lo.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}
