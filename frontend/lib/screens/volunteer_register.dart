import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class VolunteerRegisterPage extends StatefulWidget {
  const VolunteerRegisterPage({super.key});

  @override
  State<VolunteerRegisterPage> createState() => _VolunteerRegisterPageState();
}

class _VolunteerRegisterPageState extends State<VolunteerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _locationController = TextEditingController(); // Service Location
  final _skillsController = TextEditingController(); // Comma separated

  // OTP Related
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isEmailVerified = false;
  bool _isVerifyingOtp = false;

  String _gender = "Male";
  bool _trainingAttended = false;

  // Files
  File? _govtIdFile;
  File? _certFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile(bool isId) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isId) {
          _govtIdFile = File(picked.path);
        } else {
          _certFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email first")),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final response = await ApiService.sendOtp(_emailController.text.trim());
      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
          _isVerifyingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent to your email")),
        );
      } else {
        setState(() => _isVerifyingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isVerifyingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending OTP: $e")),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final response = await ApiService.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEmailVerified = true;
          _isVerifyingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email Verified Successfully!")),
        );
      } else {
        setState(() => _isVerifyingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isVerifyingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error verifying OTP: $e")),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your email first")),
      );
      return;
    }

    if (_govtIdFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload Government ID")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.registerVolunteer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        mobile: _mobileController.text.trim(),
        gender: _gender,
        dob: _dobController.text.trim(),
        address: _addressController.text.trim(),
        houseNo: _houseNoController.text.trim(),
        skills: _skillsController.text.split(',').map((e) => e.trim()).toList(),
        trainingAttended: _trainingAttended,
        serviceLocation: _locationController.text.trim(),
        govtIdFile: _govtIdFile,
        certificateFile: _certFile,
      );

      final respStr = await response.stream.bytesToString();

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Volunteer registered successfully! Please login."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Failed: $respStr")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Personal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                items: ["Male", "Female", "Other"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
                validator: (v) => v!.length != 10 ? "Invalid Mobile" : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _houseNoController,
                decoration: const InputDecoration(labelText: "House No / Building", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),
              const Text("Login Credentials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Email & OTP
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                      readOnly: _isEmailVerified, // Lock email after verification
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (_isEmailVerified || _isVerifyingOtp) ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                    child: _isVerifyingOtp
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEmailVerified ? "Verified" : (_otpSent ? "Resend" : "Verify")),
                  ),
                ],
              ),
              if (_otpSent && !_isEmailVerified) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        decoration: const InputDecoration(labelText: "Enter OTP", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
              ),

              const SizedBox(height: 20),
              const Text("Volunteer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: "Skills (comma separated)",
                  border: OutlineInputBorder(),
                  helperText: "e.g. First Aid, Swimming, Driving",
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Preferred Service Location", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("Attended Disaster Management Training?"),
                value: _trainingAttended,
                onChanged: (v) => setState(() => _trainingAttended = v!),
              ),
              const SizedBox(height: 10),

              const Text("Documents", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ListTile(
                leading: const Icon(Icons.badge),
                title: Text(_govtIdFile == null ? "Upload Govt ID" : "ID Selected"),
                subtitle: _govtIdFile != null ? Text(_govtIdFile!.path.split('/').last) : null,
                trailing: const Icon(Icons.upload_file),
                onTap: () => _pickFile(true),
              ),
              ListTile(
                leading: const Icon(Icons.card_membership),
                title: Text(_certFile == null ? "Upload Certificate (Optional)" : "Cert Selected"),
                subtitle: _certFile != null ? Text(_certFile!.path.split('/').last) : null,
                trailing: const Icon(Icons.upload_file),
                onTap: () => _pickFile(false),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isEmailVerified) ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: _isEmailVerified ? Colors.green : Colors.grey,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register as Volunteer", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
