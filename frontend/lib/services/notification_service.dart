import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class NotificationService {
  static final String baseUrl =
      "${ApiConfig.baseUrl.replaceFirst(':5000', ':5001')}/api/notifications";

  static Future<List<dynamic>> fetchNotifications(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/$userId"));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load notifications");
    }
  }
}