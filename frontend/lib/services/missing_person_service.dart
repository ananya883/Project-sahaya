import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MissingPersonService {
  static final String baseUrl =
      "${ApiConfig.baseUrl.replaceFirst(':5000', ':5001')}/api/missing";

  static Future<void> registerMissingPerson({
    required String name,
    required String age,
    required String gender,
    required String height,
    required String weight,
    required String birthmark,
    required String lastSeenLocation,
    required String lastSeenDate,
    required File image,
    required String registeredBy,
  }) async {
    final uri = Uri.parse("$baseUrl/register");
    final request = http.MultipartRequest("POST", uri);

    request.fields.addAll({
      "name": name,
      "age": age,
      "gender": gender,
      "height": height,
      "weight": weight,
      "birthmark": birthmark,
      "lastSeenLocation": lastSeenLocation,
      "lastSeenDate": lastSeenDate,
      "registeredBy": registeredBy,
    });

    request.files.add(
      await http.MultipartFile.fromPath("photo", image.path),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception(body);
    }
  }
}
