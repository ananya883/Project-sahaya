import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/camp_session.dart';
import '../../services/api_config.dart';

class CampInventoryScreen extends StatefulWidget {
  const CampInventoryScreen({super.key});

  @override
  State<CampInventoryScreen> createState() => _CampInventoryScreenState();
}

class _CampInventoryScreenState extends State<CampInventoryScreen> {
  // Use centralized API configuration
  final String _baseUrl = ApiConfig.inventory;
  String? _campId; // Load from session

  List<dynamic> inventory = [];
  bool isLoading = true;

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
          const SnackBar(content: Text("Error: Camp ID not found. Please login again.")),
        );
      }
      return;
    }

    setState(() {
      _campId = campId;
    });

    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    if (_campId == null) return;

    try {
      final response = await http.get(Uri.parse("$_baseUrl/$_campId"));
      if (response.statusCode == 200) {
        setState(() {
          inventory = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load inventory");
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

  Future<void> _updateInventory(String itemName, String quantity) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "campId": _campId,
          "itemName": itemName,
          "quantity": int.tryParse(quantity) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        _fetchInventory(); // Refresh
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventory updated successfully")),
          );
        }
      } else {
        throw Exception("Failed to update");
      }
    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camp Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_campId != null) {
                setState(() => isLoading = true);
                _fetchInventory();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventory.isEmpty
          ? const Center(child: Text("No inventory items found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item["itemName"] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditDialog(item["itemName"], (item["currentStock"] ?? 0).toString());
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("Requested", "${item["requested"] ?? 0}"),
                      _buildStat("Received", "${item["received"] ?? 0}"),
                      _buildStat("Stock", "${item["currentStock"] ?? 0}", color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Donors:", style: TextStyle(fontWeight: FontWeight.bold)),
                  if ((item["donors"] as List<dynamic>?)?.isEmpty ?? true)
                    const Text("No donations yet.", style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: (item["donors"] as List<dynamic>).map<Widget>((donor) {
                        return Chip(
                          label: Text(
                            "${donor['name']} (${donor['quantity']}${donor['unit'] ?? ''})",
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.shade50,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color color = Colors.black}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  void _showEditDialog(String itemName, String currentQty) {
    final TextEditingController qtyController = TextEditingController(text: currentQty);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update $itemName"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "New Quantity",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (qtyController.text.isNotEmpty) {
                _updateInventory(itemName, qtyController.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
