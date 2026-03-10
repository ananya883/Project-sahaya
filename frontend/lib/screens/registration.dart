import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color _primaryColor = Color(0xFF1E88E5);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Basic Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Step 2: Emergency
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianRelationController = TextEditingController();
  final TextEditingController _guardianPhoneController = TextEditingController();
  final TextEditingController _altContactController = TextEditingController();

  // Step 3: Role & Interests
  bool _isGeneralUser = true;
  bool _isDonor = false;
  bool _isVolunteer = false;

  // Volunteer Fields
  final Set<String> _volunteerSkills = {};
  final TextEditingController _certificationsController = TextEditingController();
  final TextEditingController _govtIdController = TextEditingController();
  String? _availability;
  final Set<String> _previousExperience = {};

  // Donor Fields
  String _donationType = 'funds'; // 'funds', 'goods', 'both'
  final Set<String> _itemsOfInterest = {};
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();

  // OTP
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isVerified = false;

  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _pincodeController.dispose();
    _guardianNameController.dispose();
    _guardianRelationController.dispose();
    _guardianPhoneController.dispose();
    _altContactController.dispose();
    _certificationsController.dispose();
    _govtIdController.dispose();
    _orgNameController.dispose();
    _taxIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before moving
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _emailController.text.isEmpty || _dobController.text.isEmpty || _pincodeController.text.isEmpty || _addressController.text.isEmpty || _houseNoController.text.isEmpty) {
        _showError("Please fill all basic info fields");
        return;
      }
    } else if (_currentStep == 1) {
      if (_guardianNameController.text.isEmpty || _guardianRelationController.text.isEmpty || _guardianPhoneController.text.isEmpty) {
        _showError("Please fill all emergency contact fields");
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showError("Enter email to send OTP");
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ApiService.sendOtp(_emailController.text.trim());
      if (response.statusCode == 200) {
        setState(() => _otpSent = true);
        _showSnackBar("OTP sent to your email!", Colors.green);
      } else {
        _showError(jsonDecode(response.body)['error'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showError("Error sending OTP");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showError("Enter OTP");
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ApiService.verifyOtp(_emailController.text.trim(), _otpController.text.trim());
      if (response.statusCode == 200) {
        setState(() => _isVerified = true);
        _showSnackBar("Email verified!", Colors.green);
      } else {
        _showError(jsonDecode(response.body)['error'] ?? "Invalid OTP");
      }
    } catch (e) {
      _showError("Error verifying OTP");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      _showError("Please fill all required fields in all steps");
      return;
    }
    if (!_isVerified) {
      _showError("Please verify your email first");
      return;
    }

    setState(() => _loading = true);
    List<String> roles = [];
    if (_isGeneralUser) roles.add('user');
    if (_isDonor) roles.add('donor');
    if (_isVolunteer) roles.add('volunteer');

    try {
      final response = await ApiService.registerUser(
        name: _nameController.text.trim(),
        gender: "Other", // Default for now
        dob: _dobController.text.trim(),
        mobile: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        houseNo: _houseNoController.text.trim(),
        roles: roles,
        // Guardian
        guardianName: _guardianNameController.text.trim(),
        guardianRelation: _guardianRelationController.text.trim(),
        guardianMobile: _guardianPhoneController.text.trim(),
        guardianEmail: "N/A",
        guardianAddress: "N/A",
        // Volunteer
        skills: _volunteerSkills.toList(),
        certifications: _certificationsController.text.trim(),
        availability: _availability,
        previousExperience: _previousExperience.toList(),
        // Donor
        itemsOfInterest: _itemsOfInterest.toList(),
        organizationName: _orgNameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        donationType: _donationType,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Registration Successful!", Colors.green);
        Navigator.pop(context);
      } else {
        _showError(jsonDecode(response.body)['error'] ?? "Registration failed");
      }
    } catch (e) {
      _showError("Error connecting to server");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) => _showSnackBar(message, Colors.red);
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.network('https://raw.githubusercontent.com/Antigravity-AI/sahaya-assets/main/logo.png', height: 40, errorBuilder: (c, e, s) => const Text("Sahaya", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text("Unified Registration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _indicatorItem(0, "Basic Info"),
          _indicatorLine(),
          _indicatorItem(1, "Emergency"),
          _indicatorLine(),
          _indicatorItem(2, "Role & Interests"),
        ],
      ),
    );
  }

  Widget _indicatorItem(int index, String label) {
    bool active = _currentStep >= index;
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: active ? _primaryColor : Colors.grey.shade300,
          child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? _primaryColor : Colors.grey)),
      ],
    );
  }

  Widget _indicatorLine() {
    return Expanded(
      child: Container(height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.only(bottom: 15)),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader("Step 1: BASIC INFO"),
          _buildTextField(_nameController, "Full Name (as per Govt ID)"),
          _buildPhoneField(),
          if (_otpSent && !_isVerified) _buildOtpField(),
          _buildTextField(_emailController, "Email Address", suffix: _isVerified ? const Icon(Icons.check_circle, color: Colors.green) : TextButton(onPressed: _sendOtp, child: const Text("Verify Email"))),
          _buildTextField(_dobController, "Date of Birth (DOB)", readOnly: true, onTap: _selectDate, icon: Icons.calendar_today),
          _buildDropdown("Blood Group", _selectedBloodGroup, _bloodGroups, (v) => setState(() => _selectedBloodGroup = v)),
          _buildTextField(_addressController, "Full Address"),
          _buildTextField(_houseNoController, "House No / Flat No"),
          _buildTextField(_pincodeController, "Pincode"),
          const SizedBox(height: 20),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader("Step 2: EMERGENCY"),
          _buildTextField(_guardianNameController, "Guardian Name (Primary Contact)"),
          _buildTextField(_guardianRelationController, "Relationship (e.g., Parent, Spouse)"),
          _buildTextField(_guardianPhoneController, "Guardian Emergency Phone", keyboardType: TextInputType.phone),
          _buildTextField(_altContactController, "Alternative Contact (Optional)"),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBackButton()),
              const SizedBox(width: 16),
              Expanded(child: _buildNextButton(label: "NEXT & CONFIRM DETAILS")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader("STEP 3: ROLE & INTERESTS"),
          _buildCheckbox("GENERAL USER (Get SOS Alerts, News)", _isGeneralUser, (v) => setState(() => _isGeneralUser = v!)),
          _buildCheckbox("DONOR (Funds or Items)", _isDonor, (v) => setState(() => _isDonor = v!)),
          _buildCheckbox("VOLUNTEER (Skills & Field Rescue)", _isVolunteer, (v) => setState(() => _isVolunteer = v!)),

          if (_isVolunteer) ...[
            const SizedBox(height: 20),
            const Text("Since you are joining as a Volunteer...", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            _buildVolunteerSection(),
          ],

          if (_isDonor) ...[
            const SizedBox(height: 20),
            const Text("Since you are joining as a Donor...", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            _buildDonorSection(),
          ],

          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildBackButton()),
              const SizedBox(width: 16),
              Expanded(child: _buildRegisterButton()),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: Text("Sahaya: Empowering Relief", style: TextStyle(color: _primaryColor, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildVolunteerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VOLUNTEER SKILLS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        _buildSkillChip("Medical/First Aid"),
        _buildSkillChip("Search & Rescue"),
        _buildSkillChip("Logistics & Supply Chain"),
        _buildSkillChip("Tech/Admin Support"),
        _buildTextField(_certificationsController, "Additional Skills (Certifications)"),
        const SizedBox(height: 10),
        const Text("VOLUNTEER DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        _buildTextField(_govtIdController, "Full Govt ID (Aadhaar/Driver's License)"),
        _buildDropdown("Availability for deployment", _availability, ["On Call 24/7", "Weekends Only", "Specific Hours"], (v) => setState(() => _availability = v)),
        const SizedBox(height: 10),
        const Text("PREVIOUS EXPERIENCE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          children: [
            _buildExperienceChip("Military/Civil Defence"),
            _buildExperienceChip("NGO"),
          ],
        ),
      ],
    );
  }

  Widget _buildDonorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DONATION PREFERENCES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(child: _donationTypeSelector("CONTRIBUTE FUNDS", Icons.money, _donationType == 'funds' || _donationType == 'both', () => setState(() => _donationType = 'funds'))),
            const SizedBox(width: 10),
            Expanded(child: _donationTypeSelector("CONTRIBUTE GOODS", Icons.inventory, _donationType == 'goods' || _donationType == 'both', () => setState(() => _donationType = 'goods'))),
          ],
        ),
        const SizedBox(height: 10),
        const Text("ITEMS OF INTEREST", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: ["Food", "Clothes", "Medical Supplies", "Blankets"].map((e) => _buildItemChip(e)).toList(),
        ),
        _buildTextField(_orgNameController, "ORGANIZATION DETAILS (Optional)"),
        _buildTextField(_taxIdController, "TAX ID (PAN/GST) for Razorpay receipts"),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 16),
      color: _primaryColor,
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool readOnly = false, VoidCallback? onTap, IconData? icon, TextInputType? keyboardType, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix ?? (icon != null ? Icon(icon, size: 20) : null),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) => v!.isEmpty && !hint.contains("Optional") ? "Required" : null,
      ),
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(_phoneController, "Phone Number", keyboardType: TextInputType.phone);
  }

  Widget _buildOtpField() {
    return Row(
      children: [
        Expanded(child: _buildTextField(_otpController, "Enter OTP", keyboardType: TextInputType.number)),
        const SizedBox(width: 10),
        ElevatedButton(onPressed: _verifyOtp, child: const Text("Verify")),
      ],
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: _primaryColor),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    bool selected = _volunteerSkills.contains(skill);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FilterChip(
        label: Text(skill),
        selected: selected,
        onSelected: (v) => setState(() => v ? _volunteerSkills.add(skill) : _volunteerSkills.remove(skill)),
        selectedColor: _primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildExperienceChip(String exp) {
    bool selected = _previousExperience.contains(exp);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(exp),
        selected: selected,
        onSelected: (v) => setState(() => v ? _previousExperience.add(exp) : _previousExperience.remove(exp)),
      ),
    );
  }

  Widget _buildItemChip(String item) {
    bool selected = _itemsOfInterest.contains(item);
    return FilterChip(
      label: Text(item),
      selected: selected,
      onSelected: (v) => setState(() => v ? _itemsOfInterest.add(item) : _itemsOfInterest.remove(item)),
    );
  }

  Widget _donationTypeSelector(String label, IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? _primaryColor : Colors.white,
          border: Border.all(color: _primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : _primaryColor),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: active ? Colors.white : _primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton({String label = "NEXT"}) {
    return ElevatedButton(
      onPressed: _nextStep,
      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
      child: Text(label),
    );
  }

  Widget _buildBackButton() {
    return OutlinedButton(
      onPressed: _prevStep,
      style: OutlinedButton.styleFrom(foregroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
      child: const Text("BACK"),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
      child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTER & SUBMIT ALL DETAILS"),
    );
  }
}
