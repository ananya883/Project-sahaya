import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/api_config.dart';

class DonateInventoryPage extends StatefulWidget {
  const DonateInventoryPage({super.key});

  @override
  State<DonateInventoryPage> createState() => _DonateInventoryPageState();
}

class _DonateInventoryPageState extends State<DonateInventoryPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCampId;
  String? selectedUnit = "kg";
  String? selectedCategory = "Food";

  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();

  List<Map<String, dynamic>> camps = [];
  bool isLoading = true;
  bool isSubmitting = false;

  final List<String> units = ["kg", "liters", "packs", "units", "boxes"];
  final List<String> categories = [
    "Food",
    "Water",
    "Medical",
    "Clothing",
    "Shelter",
    "Hygiene",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    fetchCamps();
  }

  Future<void> fetchCamps() async {
    try {
      final data = await ApiService.getCamps();
      setState(() {
        camps = data.map((c) => {
          "campId": c["campId"],
          "campName": c["campName"] ?? "Unknown",
          "location": c["location"] ?? "",
        }).toList().cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching camps: $e")),
        );
      }
    }
  }

  Future<void> submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCampId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a camp")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.donorDonateDirect),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "campId": selectedCampId,
          "itemName": itemNameController.text.trim(),
          "quantity": int.parse(quantityController.text),
          "unit": selectedUnit,
          "category": selectedCategory,
        }),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Donation submitted successfully!")),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Failed to submit donation");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donate Inventory"),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Donate Items Directly",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Help camps by donating items directly, even without a specific request.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Camp Selection
              const Text(
                "Select Camp",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCampId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: "Choose a camp",
                ),
                items: camps.map((camp) {
                  return DropdownMenuItem<String>(
                    value: camp["campId"],
                    child: Text(
                      "${camp["campName"]} - ${camp["location"]}",
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCampId = value);
                },
                validator: (value) {
                  if (value == null) return "Please select a camp";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Item Name
              const Text(
                "Item Name",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: itemNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: "e.g., Rice, Water, Blankets",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter item name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity and Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quantity",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: "100",
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Required";
                            }
                            if (int.tryParse(value) == null) {
                              return "Invalid number";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Unit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedUnit = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category
              const Text(
                "Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value);
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Submit Donation",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}
