import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/camp_session.dart';
import '../../services/api_config.dart';

class InmatesScreen extends StatefulWidget {
  const InmatesScreen({super.key});

  @override
  State<InmatesScreen> createState() => _InmatesScreenState();
}

class _InmatesScreenState extends State<InmatesScreen> {
  final String _baseUrl = ApiConfig.inmates;
  String? _campId;

  List<dynamic> inmates = [];
  List<dynamic> filteredInmates = [];
  Map<String, dynamic>? stats;

  bool isLoading = true;
  String searchQuery = "";
  String? filterGender;
  String? filterStatus;

  @override
  void initState() {
    super.initState();
    _loadCampIdAndFetch();
  }

  Future<void> _loadCampIdAndFetch() async {
    final campId = await CampSession.getCampId();
    if (campId == null || campId.isEmpty) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Camp ID not found")),
        );
      }
      return;
    }

    setState(() => _campId = campId);
    _fetchInmates();
    _fetchStats();
  }

  Future<void> _fetchInmates() async {
    if (_campId == null) return;

    try {
      final response = await http.get(Uri.parse("$_baseUrl/$_campId"));
      if (response.statusCode == 200) {
        setState(() {
          inmates = jsonDecode(response.body);
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _fetchStats() async {
    if (_campId == null) return;

    try {
      final response = await http.get(Uri.parse("$_baseUrl/$_campId/stats"));
      if (response.statusCode == 200) {
        setState(() {
          stats = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Stats error: $e");
    }
  }

  void _applyFilters() {
    filteredInmates = inmates.where((inmate) {
      bool matchesSearch = inmate['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      bool matchesGender = filterGender == null || inmate['gender'] == filterGender;
      bool matchesStatus = filterStatus == null || inmate['status'] == filterStatus;
      return matchesSearch && matchesGender && matchesStatus;
    }).toList();
  }

  Future<void> _deleteInmate(String inmateId) async {
    try {
      final response = await http.delete(Uri.parse("$_baseUrl/$inmateId"));
      if (response.statusCode == 200) {
        _fetchInmates();
        _fetchStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inmate deleted successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showAddInmateDialog([Map<String, dynamic>? inmate]) {
    showDialog(
      context: context,
      builder: (context) => AddInmateDialog(
        campId: _campId!,
        inmate: inmate,
        onSuccess: () {
          _fetchInmates();
          _fetchStats();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inmates Registration"),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Statistics Card
          if (stats != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "📊 Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("Total", stats!['total'].toString()),
                      _statItem("Male", stats!['byGender']['male'].toString()),
                      _statItem("Female", stats!['byGender']['female'].toString()),
                    ],
                  ),
                ],
              ),
            ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search by name...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() {
                      if (value.startsWith("gender:")) {
                        filterGender = value.split(":")[1];
                      } else if (value.startsWith("status:")) {
                        filterStatus = value.split(":")[1];
                      } else if (value == "clear") {
                        filterGender = null;
                        filterStatus = null;
                      }
                      _applyFilters();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "gender:Male", child: Text("Male")),
                    const PopupMenuItem(value: "gender:Female", child: Text("Female")),
                    const PopupMenuItem(value: "status:Active", child: Text("Active")),
                    const PopupMenuItem(value: "status:Relocated", child: Text("Relocated")),
                    const PopupMenuItem(value: "status:Left", child: Text("Left")),
                    const PopupMenuItem(value: "clear", child: Text("Clear Filters")),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inmates List
          Expanded(
            child: filteredInmates.isEmpty
                ? const Center(child: Text("No inmates registered"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredInmates.length,
              itemBuilder: (context, index) {
                final inmate = filteredInmates[index];
                return _inmateCard(inmate);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInmateDialog(),
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _inmateCard(Map<String, dynamic> inmate) {
    final statusColor = inmate['status'] == 'Active'
        ? Colors.green
        : inmate['status'] == 'Relocated'
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    inmate['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inmate['status'],
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Age: ${inmate['age']} | Gender: ${inmate['gender']}"),
            Text("Family Members: ${inmate['familyMembers']}"),
            if (inmate['contactNumber'] != null && inmate['contactNumber'].isNotEmpty)
              Text("Contact: ${inmate['contactNumber']}"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddInmateDialog(inmate),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Inmate"),
                        content: const Text("Are you sure you want to delete this inmate?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteInmate(inmate['_id']);
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add Inmate Dialog
class AddInmateDialog extends StatefulWidget {
  final String campId;
  final Map<String, dynamic>? inmate;
  final VoidCallback onSuccess;

  const AddInmateDialog({
    super.key,
    required this.campId,
    this.inmate,
    required this.onSuccess,
  });

  @override
  State<AddInmateDialog> createState() => _AddInmateDialogState();
}

class _AddInmateDialogState extends State<AddInmateDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final contactController = TextEditingController();
  final aadharController = TextEditingController();
  final addressController = TextEditingController();
  final familyController = TextEditingController();
  final medicalController = TextEditingController();

  String gender = "Male";
  String status = "Active";
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.inmate != null) {
      nameController.text = widget.inmate!['name'];
      ageController.text = widget.inmate!['age'].toString();
      gender = widget.inmate!['gender'];
      contactController.text = widget.inmate!['contactNumber'] ?? '';
      aadharController.text = widget.inmate!['aadharNumber'] ?? '';
      addressController.text = widget.inmate!['address'] ?? '';
      familyController.text = widget.inmate!['familyMembers'].toString();
      medicalController.text = widget.inmate!['medicalConditions'] ?? '';
      status = widget.inmate!['status'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final data = {
      "campId": widget.campId,
      "name": nameController.text.trim(),
      "age": int.parse(ageController.text),
      "gender": gender,
      "contactNumber": contactController.text.trim(),
      "aadharNumber": aadharController.text.trim(),
      "address": addressController.text.trim(),
      "familyMembers": int.tryParse(familyController.text) ?? 1,
      "medicalConditions": medicalController.text.trim(),
      "status": status,
    };

    try {
      final url = widget.inmate == null
          ? "${ApiConfig.inmates}/register"
          : ApiConfig.inmateById(widget.inmate!['_id']);

      final response = widget.inmate == null
          ? await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      )
          : await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        widget.onSuccess();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.inmate == null ? "Inmate registered!" : "Inmate updated!")),
          );
        }
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inmate == null ? "Register Inmate" : "Edit Inmate"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name *"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age *"),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(labelText: "Gender"),
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => gender = v!),
              ),
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact Number"),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: aadharController,
                decoration: const InputDecoration(labelText: "Aadhar Number"),
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                maxLines: 2,
              ),
              TextFormField(
                controller: familyController,
                decoration: const InputDecoration(labelText: "Family Members"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: medicalController,
                decoration: const InputDecoration(labelText: "Medical Conditions"),
                maxLines: 2,
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Status"),
                items: ["Active", "Relocated", "Left"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => status = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(widget.inmate == null ? "Register" : "Update"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    contactController.dispose();
    aadharController.dispose();
    addressController.dispose();
    familyController.dispose();
    medicalController.dispose();
    super.dispose();
  }
}
