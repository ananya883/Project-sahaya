import 'package:flutter/material.dart';
import 'camp_manager_login.dart';
import 'admin_login.dart';
import 'Login.dart';
import 'registration.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Your Role"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoleButton(
                context,
                title: "Login as Normal User",
                icon: Icons.person,
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage(targetRole: 'user')),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildRoleButton(
                context,
                title: "Login as Volunteer",
                icon: Icons.volunteer_activism,
                color: Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage(targetRole: 'volunteer')),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildRoleButton(
                context,
                title: "Login as Donor",
                icon: Icons.favorite,
                color: Colors.pink,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage(targetRole: 'donor')),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildRoleButton(
                context,
                title: "Login as Camp Manager",
                icon: Icons.admin_panel_settings,
                color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CampManagerLoginPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildRoleButton(
                context,
                title: "Login as Admin",
                icon: Icons.shield,
                color: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminLoginPage()),
                  );
                },
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
