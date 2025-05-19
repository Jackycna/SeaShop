import 'package:flutter/material.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/home.dart';

class LanguageSelectionPage extends StatefulWidget {
  final Function(String) onLanguageSelected;

  const LanguageSelectionPage({super.key, required this.onLanguageSelected});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String selectedLanguage = ''; // Default language

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              LocalizationService().translate('language'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003780)),
            ),
            const SizedBox(height: 20),
            RadioListTile<String>(
              title: const Text(
                'English',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: 'en',
              groupValue: selectedLanguage,
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text(
                'தமிழ்',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: 'ta',
              groupValue: selectedLanguage,
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onLanguageSelected(selectedLanguage);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const Nav()), // Replace with your first page
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003780),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                LocalizationService().translate('save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
