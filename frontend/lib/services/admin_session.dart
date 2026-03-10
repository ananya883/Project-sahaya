
import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  static const String _usernameKey = 'admin_username';
  static const String _isAdminKey = 'is_admin';

  // Save admin session
  static Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setBool(_isAdminKey, true);
  }

  // Check if admin is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  // Get admin username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_isAdminKey);
  }
}
