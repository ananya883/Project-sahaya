class ApiConfig {
  // IMPORTANT: Update this IP address based on your network configuration
  //
  // For USB Debugging with Physical Device:
  // - Use your computer's local IP address (e.g., 192.168.x.x)
  // - Make sure your phone and computer are on the same WiFi network
  // - Run 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find your IP
  //
  // For Android Emulator:
  // - Use: http://10.0.2.2:5000
  //
  // Current network IP: 10.6.2.93

  static const String baseUrl = 'http://10.2.100.211:5000'; // For desktop/web testing
  // static const String baseUrl = 'http://10.6.2.93:5000'; // For mobile testing
  
  // New Endpoints
  static const String camps = '$baseUrl/api/camps/camps';
  static const String campRequests = '$baseUrl/api/camps/requests';

  // API Endpoints
  static const String adminLogin = '$baseUrl/api/admin/login';
  static const String adminCamps = '$baseUrl/api/admin/camps';
  static const String adminUsers = '$baseUrl/api/admin/users';
  static const String adminCreateCamp = '$baseUrl/api/admin/create-camp';
  static const String adminRegisterDisaster = '$baseUrl/api/admin/register-disaster';
  static const String adminDisasters = '$baseUrl/api/admin/disasters';

  static const String campManagerLogin = '$baseUrl/api/campmanager/auth/login';
  static const String campManagerRegister = '$baseUrl/api/campmanager/auth/register';

  static const String inventory = '$baseUrl/api/inventory';
  static const String campRequest = '$baseUrl/api/campmanager';
  static const String inmates = '$baseUrl/api/inmates';

  static const String donorDonateDirect = '$baseUrl/api/donor/donate-money';

  // Helper method to get disaster endpoint with ID
  static String adminDisaster(String disasterId) => '$baseUrl/api/admin/disaster/$disasterId';

  // Helper method to get inmate endpoint with ID
  static String inmateById(String inmateId) => '$baseUrl/api/inmates/$inmateId';

  // Helper method to get donation not-receive endpoint
  static String donationNotReceive(String donationId) => '$baseUrl/api/campmanager/donations/$donationId/not-receive';
}
