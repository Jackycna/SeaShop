import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String isFirstLaunchKey = 'is_first_launch';

  // Check if it's the first launch
  static Future<bool> isFirstLaunch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch =
        prefs.getBool(isFirstLaunchKey) ?? true; // Default is true

    if (isFirstLaunch) {
      // After the first launch, update the preference
      await prefs.setBool(isFirstLaunchKey, false);
    }

    return isFirstLaunch;
  }

  // Optionally, store sign-in status if required
  static Future<void> setSignedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isFirstLaunchKey, false); // User is no longer new
  }
}
