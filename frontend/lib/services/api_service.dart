import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_config.dart';
import 'package:path/path.dart';

class ApiService {

  // ---------------- USER AUTH ----------------
  static Future<http.Response> loginUser(String email, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/login");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> registerUser({
    required String name,
    required String gender,
    required String dob,
    required String mobile,
    required String email,
    required String address,
    required String houseNo,
    required List<String> roles,
    String? password,
    // Guardian
    String? guardianName,
    String? guardianRelation,
    String? guardianMobile,
    String? guardianEmail,
    String? guardianAddress,
    // Volunteer
    List<String>? skills,
    bool? trainingAttended,
    String? serviceLocation,
    String? certifications,
    String? availability,
    List<String>? previousExperience,
    // Donor
    List<String>? itemsOfInterest,
    String? organizationName,
    String? taxId,
    String? donationType,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/register");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Name": name,
        "gender": gender,
        "dob": dob,
        "mobile": mobile,
        "email": email,
        "address": address,
        "houseNo": houseNo,
        "roles": roles,
        "password": password,
        "guardianName": guardianName,
        "guardianRelation": guardianRelation,
        "guardianMobile": guardianMobile,
        "guardianEmail": guardianEmail,
        "guardianAddress": guardianAddress,
        "skills": skills,
        "trainingAttended": trainingAttended,
        "serviceLocation": serviceLocation,
        "certifications": certifications,
        "availability": availability,
        "previousExperience": previousExperience,
        "itemsOfInterest": itemsOfInterest,
        "organizationName": organizationName,
        "taxId": taxId,
        "donationType": donationType,
      }),
    );
  }

  static Future<http.Response> sendOtp(String email) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/send-verification-otp");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<http.Response> verifyOtp(String email, String otp) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/verify-email-otp");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
  }

  static Future<http.Response> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/user/forgot-password");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  // ---------------- VOLUNTEER ----------------
  static Future<http.StreamedResponse> registerVolunteer({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String gender,
    required String dob,
    required String address,
    required String houseNo,
    required List<String> skills,
    required bool trainingAttended,
    required String serviceLocation,
    File? govtIdFile,
    File? certificateFile,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/volunteer/register");
    final request = http.MultipartRequest("POST", url);

    request.fields["Name"] = name;
    request.fields["email"] = email;
    request.fields["password"] = password;
    request.fields["mobile"] = mobile;
    request.fields["gender"] = gender;
    request.fields["dob"] = dob;
    request.fields["address"] = address;
    request.fields["houseNo"] = houseNo;
    request.fields["skills"] = jsonEncode(skills);
    request.fields["trainingAttended"] = trainingAttended.toString();
    request.fields["serviceLocation"] = serviceLocation;

    if (govtIdFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        "govtId",
        govtIdFile.path,
        filename: basename(govtIdFile.path),
      ));
    }

    if (certificateFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        "certificate",
        certificateFile.path,
        filename: basename(certificateFile.path),
      ));
    }

    return await request.send();
  }

  // ---------------- SOS ----------------
  static Future<http.Response> sendSos({
    required String emergencyType,
    required String disasterType,
    String? latitude,
    String? longitude,
    XFile? imageFile,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/sos/trigger");
    
    if (imageFile == null) {
      return await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emergencyType": emergencyType,
          "disasterType": disasterType,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );
    } else {
      final request = http.MultipartRequest("POST", url);
      request.fields["emergencyType"] = emergencyType;
      request.fields["disasterType"] = disasterType;
      if (latitude != null) request.fields["latitude"] = latitude;
      if (longitude != null) request.fields["longitude"] = longitude;

      request.files.add(await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
        filename: basename(imageFile.path),
      ));

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }
  }

  // ---------------- GET CAMP REQUESTS ----------------
  static Future<List<dynamic>> getCampRequests() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.campRequests))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load camp requests");
      }
    } catch (e) {
      throw Exception("Server error: $e");
    }
  }

  // ---------------- DONATE ITEM ----------------
  static Future<void> donateItem(String requestId, int qty) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/donor/donate-item"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requestId": requestId,
          "donateQty": qty,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception("Donation failed");
      }
    } catch (e) {
      throw Exception("Server error: $e");
    }
  }

  // ---------------- GET ALL CAMPS ----------------
  static Future<List<dynamic>> getCamps() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.camps))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load camps");
      }
    } catch (e) {
      throw Exception("Server error: $e");
    }
  }

  // ---------------- DONATE MONEY ----------------
  static Future<http.Response> donateMoney({
    required String donorName,
    required String amount,
    required String transactionId,
  }) async {
    final url = Uri.parse(ApiConfig.donorDonateDirect);
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "donorName": donorName,
        "amount": amount,
        "transactionId": transactionId,
      }),
    );
  }
}
