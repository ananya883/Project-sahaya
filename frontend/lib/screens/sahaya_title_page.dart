import 'package:flutter/material.dart';

class SahayaTitlePage extends StatefulWidget {
  const SahayaTitlePage({super.key});

  @override
  State<SahayaTitlePage> createState() => _SahayaTitlePageState();
}

class _SahayaTitlePageState extends State<SahayaTitlePage> {
  @override
  void initState() {
    super.initState();
    // Navigate to Role Selection after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/role_selection');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              // Note: Ensure assets/images/sahaya_logo.png exists in your project
              Image.asset(
                'assets/images/sahaya_logo.png',
                height: 150,
                width: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.volunteer_activism, size: 100, color: Colors.blue);
                },
              ),
              const SizedBox(height: 20),

              // App Name
              const Text(
                'Sahaya',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Empowering Relief and Saving Lives',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
