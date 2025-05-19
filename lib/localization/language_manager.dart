import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = "language";

  // Save selected language to SharedPreferences
  static Future<void> setLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Get the stored language, default to 'en' (English) if not set
  static Future<String> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en'; // Default to English
  }
}
