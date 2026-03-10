import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camp_manager_login.dart';
import '../services/api_config.dart';

class CampManagerRegister extends StatefulWidget {
  const CampManagerRegister({super.key});

  @override
  State<CampManagerRegister> createState() => _CampManagerRegisterState();
}

class _CampManagerRegisterState extends State<CampManagerRegister> {
  final TextEditingController _campNameController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final campName = _campNameController.text.trim();
    final managerName = _managerNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final location = _locationController.text.trim();
    final contact = _contactController.text.trim();

    if (campName.isEmpty || managerName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.campManagerRegister),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "campName": campName,
          "managerName": managerName,
          "email": email,
          "password": password,
          "location": location,
          "contactNumber": contact,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Show success message with camp ID
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registration Successful!"),
            content: Text(
              "Your camp has been registered.\n\nCamp ID: ${data['campId']}\nCamp Name: ${data['campName']}\n\nPlease login to continue.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CampManagerLoginPage()),
                  );
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error["message"] ?? "Registration failed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _campNameController.dispose();
    _managerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Camp"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Create New Camp Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            _buildTextField(
              controller: _campNameController,
              label: "Camp Name *",
              icon: Icons.business,
              hint: "e.g., Relief Camp Alpha",
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _managerNameController,
              label: "Manager Name *",
              icon: Icons.person,
              hint: "Your full name",
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: "Email *",
              icon: Icons.email,
              hint: "your@email.com",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              label: "Password *",
              icon: Icons.lock,
              hint: "Enter password",
              obscureText: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationController,
              label: "Location",
              icon: Icons.location_on,
              hint: "City, District",
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _contactController,
              label: "Contact Number",
              icon: Icons.phone,
              hint: "10-digit number",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E88E5),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Register",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
