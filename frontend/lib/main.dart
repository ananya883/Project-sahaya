import 'package:flutter/material.dart';
import 'screens/Login.dart';
import 'screens/registration.dart';
import 'screens/forgot_password.dart';
import 'screens/homepage.dart';
import 'screens/sos_page.dart';
import 'screens/sahaya_title_page.dart';
import 'screens/role_selection.dart';
import 'screens/camp_manager_login.dart';
import 'screens/admin_login.dart';
import 'screens/donor_dashboard.dart';
import 'screens/early_warning.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahaya',
      debugShowCheckedModeBanner: false,

      // 🔵 Integrated Theme from both projects
      theme: ThemeData(
        useMaterial3: false, // Essential for maintaining the classic look
        primaryColor: const Color(0xFF1E88E5),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
        ),
      ),

      // 🔹 Application starts on the Title Page
      initialRoute: '/title',

      routes: {
        '/title': (context) => const SahayaTitlePage(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/sos': (context) => const SosPage(),
        '/camp_manager_login': (context) => const CampManagerLoginPage(),
        '/admin_login': (context) => const AdminLoginPage(),
        '/donor_dashboard': (context) => const DonorDashboard(),
        '/early_warning': (context) => const EarlyWarningPage(),
      },
    );
  }
}
