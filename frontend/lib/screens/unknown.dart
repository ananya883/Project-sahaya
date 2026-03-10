import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unknown_person_service.dart';

class RegisterUnknownPerson extends StatefulWidget {
  const RegisterUnknownPerson({super.key});

  @override
  State<RegisterUnknownPerson> createState() => _RegisterUnknownPersonState();
}

class _RegisterUnknownPersonState extends State<RegisterUnknownPerson> {
  final _formKey = GlobalKey<FormState>();

  final genderCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final foundLocationCtrl = TextEditingController();

  DateTime? foundDate;
  File? image;
  bool loading = false;

  final Color primaryBlue = Colors.blueAccent;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => foundDate = date);
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() ||
        image == null ||
        foundDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields & select image")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() => loading = true);

    await UnknownPersonService.registerUnknownPerson(
      gender: genderCtrl.text,
      age: ageCtrl.text,
      height: heightCtrl.text,
      weight: weightCtrl.text,
      foundLocation: foundLocationCtrl.text,
      foundDate: foundDate!.toIso8601String(),
      image: image!,
      reportedBy: userId,
    );

    setState(() => loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Unknown person registered successfully")),
    );

    // Navigate back to homepage to see match notifications
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Register Found Person"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              textField(genderCtrl, "Gender", Icons.people),
              textField(ageCtrl, "Approx Age", Icons.cake, number: true),
              textField(heightCtrl, "Height", Icons.height),
              textField(weightCtrl, "Weight", Icons.monitor_weight),
              textField(foundLocationCtrl, "Found Location", Icons.location_on),

              const SizedBox(height: 12),

              // Date Picker
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(color: primaryBlue),
                ),
                onPressed: pickDate,
                icon: const Icon(Icons.date_range),
                label: Text(
                  foundDate == null
                      ? "Select Found Date"
                      : foundDate!
                      .toLocal()
                      .toString()
                      .split(" ")[0],
                ),
              ),

              const SizedBox(height: 12),

              // Image Picker
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(color: primaryBlue),
                ),
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label:
                Text(image == null ? "Pick Image" : "Image Selected ✔"),
              ),

              const SizedBox(height: 24),

              loading
                  ? CircularProgressIndicator(color: primaryBlue)
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: submit,
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textField(TextEditingController ctrl, String label, IconData icon,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }
}
