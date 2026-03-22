import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AlertService {
  // 1. Get available locations
  static Future<List<String>> getLocations() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/alerts/locations');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['locations']);
      }
      return [];
    } catch (e) {
      print("Error fetching locations: $e");
      return [];
    }
  }

  // 2. Get user's active alerts
  static Future<List<dynamic>> getMyAlerts(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/alerts/my-alerts?userId=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['alerts'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error fetching alerts: $e");
      return [];
    }
  }

  // 3. Get user's subscriptions
  static Future<List<String>> getMySubscriptions(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/alerts/my-subscriptions?userId=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['subscribedLocations'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error fetching subscriptions: $e");
      return [];
    }
  }

  // 4. Subscribe to locations
  static Future<bool> subscribeLocations(String userId, List<String> locations) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/alerts/subscribe');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'locations': locations,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating subscriptions: $e");
      return false;
    }
  }
}
