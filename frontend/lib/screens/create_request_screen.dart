import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/camp_session.dart';
import '../../services/api_config.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  String _selectedCategory = "Food";
  String _selectedPriority = "Medium";

  final List<String> _categories = ["Food", "Water", "Medicine", "Clothes", "Other"];
  final List<String> _priorities = ["High", "Medium", "Low"];

  bool _isLoading = false;

  Future<void> _submitRequest() async {
    final String itemName = _itemController.text.trim();
    final String qtyStr = _qtyController.text.trim();
    final String unit = _unitController.text.trim();

    if (itemName.isEmpty || qtyStr.isEmpty || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Get camp info from session
    final campId = await CampSession.getCampId();
    final campName = await CampSession.getCampName();

    if (campId == null || campName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(ApiConfig.campRequest);

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "campId": campId,
          "campName": campName,
          "itemName": itemName,
          "requiredQty": int.parse(qtyStr),
          "remainingQty": int.parse(qtyStr),
          "status": "Pending",
          "unit": unit,
          "category": _selectedCategory,
          "priority": _selectedPriority,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        _itemController.clear();
        _qtyController.clear();
        _unitController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
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
    _itemController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Resource Request"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildInput(
              controller: _itemController,
              icon: Icons.inventory_2,
              label: "Item Name",
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: buildInput(
                    controller: _qtyController,
                    icon: Icons.confirmation_number,
                    label: "Quantity",
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: buildInput(
                    controller: _unitController,
                    icon: Icons.scale,
                    label: "Unit (kg, L)",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),

            const SizedBox(height: 15),

            // Priority Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: "Priority",
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => _selectedPriority = val!),
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Submit Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
      ),
    );
  }
}
