import 'package:shared_preferences/shared_preferences.dart';

class CampSession {
  static const String _campIdKey = 'camp_id';
  static const String _campNameKey = 'camp_name';
  static const String _managerNameKey = 'manager_name';
  static const String _emailKey = 'email';
  static const String _locationKey = 'location';

  // Save session after login
  static Future<void> saveSession({
    required String campId,
    required String campName,
    required String managerName,
    required String email,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_campIdKey, campId);
    await prefs.setString(_campNameKey, campName);
    await prefs.setString(_managerNameKey, managerName);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_locationKey, location);
  }

  // Get camp ID
  static Future<String?> getCampId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_campIdKey);
  }

  // Get camp name
  static Future<String?> getCampName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_campNameKey);
  }

  // Get manager name
  static Future<String?> getManagerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_managerNameKey);
  }

  // Get email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Get location
  static Future<String?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationKey);
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final campId = await getCampId();
    return campId != null && campId.isNotEmpty;
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_campIdKey);
    await prefs.remove(_campNameKey);
    await prefs.remove(_managerNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_locationKey);
  }
}
