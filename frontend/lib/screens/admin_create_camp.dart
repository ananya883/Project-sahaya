import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class AdminCreateCamp extends StatefulWidget {
  const AdminCreateCamp({super.key});

  @override
  State<AdminCreateCamp> createState() => _AdminCreateCampState();
}

class _AdminCreateCampState extends State<AdminCreateCamp> {
  final TextEditingController _campNameController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createCamp() async {
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
        Uri.parse(ApiConfig.adminCreateCamp),
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
        final emailSent = data['emailSent'] ?? false;

        // Clear form
        _campNameController.clear();
        _managerNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _locationController.clear();
        _contactController.clear();

        // Show success dialog with credentials
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Expanded(child: Text("Camp Created!")),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: emailSent ? Colors.green.shade50 : Colors.orange.shade50,
                      border: Border.all(
                        color: emailSent ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          emailSent ? Icons.email : Icons.warning,
                          color: emailSent ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            emailSent
                                ? "✅ Credentials sent via email"
                                : "⚠️ Email failed - Share credentials manually",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: emailSent ? Colors.green.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Camp Details:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildCredentialRow("Camp ID", data['campId']),
                  _buildCredentialRow("Camp Name", data['campName']),

                  const Divider(height: 24),

                  const Text(
                    "Login Credentials:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildCredentialRow("Email", data['email']),
                  _buildCredentialRow("Password", data['password']),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "💡 Tip: Screenshot this for your records",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to dashboard
                },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error["message"] ?? "Failed to create camp")),
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
        title: const Text("Create New Camp"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Register New Camp Manager",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

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
              hint: "Full name",
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: "Email *",
              icon: Icons.email,
              hint: "manager@email.com",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              label: "Password *",
              icon: Icons.lock,
              hint: "Set initial password",
              obscureText: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationController,
              label: "Location *",
              icon: Icons.location_on,
              hint: "District, City",
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
              onPressed: _isLoading ? null : _createCamp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
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
                "Create Camp",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
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
