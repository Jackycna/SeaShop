import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/language_selection.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/profile/deletion_page.dart';

// Import the LanguageSelectionPage

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String? shopAddress;
  String currentLanguage = 'en'; // Default to English

  @override
  void initState() {
    super.initState();
    fetchShopAddress();
    _loadLanguage();
  }

  Future<void> fetchShopAddress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          shopAddress = doc.data()?['shopLocation'] ?? 'Select Nearest Shop';
        });
      }
    }
  }

// Helper method to show AlertDialog
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    String savedLanguage = await LocalizationService().getSavedLanguage();
    setState(() {
      currentLanguage = savedLanguage;
    });
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    await LocalizationService().loadLanguage(languageCode);
    setState(() {
      currentLanguage = languageCode;
    });
  }

  // Show LanguageSelectionPage
  void showLanguageSelector() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(
            onLanguageSelected: (languageCode) {
              changeLanguage(languageCode);
            },
          ),
        ),
      );
    }
  }

  void navigateToDeletionPage() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AccountDeletionPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('settings'),
          style: const TextStyle(
            color: Color(0xFF003780),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Selection Section

              // Language Selection Section
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: Colors.white,
                leading: const Icon(
                  Icons.language,
                  color: Color(0xFF003780),
                  size: 40,
                ),
                title: Text(
                  LocalizationService().translate('lang'),
                  style: const TextStyle(
                    color: Color(0xFF003780),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  currentLanguage == 'en' ? 'English' : 'தமிழ்',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Color(0xFF003780),
                  ),
                  onPressed: showLanguageSelector,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                horizontalTitleGap: 10,
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      ),
    );
  }
}
