import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/camp_session.dart';
import '../../services/api_config.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  // Use centralized API configuration
  final String _baseUrl = "${ApiConfig.campRequest}/donations";
  String? _campId; // Load from session

  List<dynamic> donations = [];
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

    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    if (_campId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camp ID not found. Please log in again.")),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$_baseUrl/$_campId"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          donations = data.map((d) => d as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load donations");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _markAsReceived(String donationId) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/$donationId/receive"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _fetchDonations(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Donation marked as received!")),
          );
        }
      } else {
        throw Exception("Failed to mark as received");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _markAsNotReceived(String donationId) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.donationNotReceive(donationId)),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _fetchDonations(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Donation marked as not received")),
          );
        }
      } else {
        throw Exception("Failed to mark as not received");
      }
    } catch (e) {
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
        title: const Text("Donations Received"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_campId != null) {
                setState(() => isLoading = true);
                _fetchDonations();
              }
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : donations.isEmpty
          ? const Center(child: Text("No donations received yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final d = donations[index];
          return donationCard(
            context,
            donationId: d["_id"] ?? "",
            donor: d["donorName"] ?? "Anonymous",
            item: d["itemName"] ?? "Unknown",
            promisedQty: "${d["quantity"]} ${d["unit"] ?? ""}",
            status: d["status"] ?? "Pending",
          );
        },
      ),
    );
  }

  Widget donationCard(
      BuildContext context, {
        required String donationId,
        required String donor,
        required String item,
        required String promisedQty,
        required String status,
      }) {
    final isPending = status == "Pending";
    final isReceived = status == "Received";
    final isNotReceived = status == "Not Received";

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              donor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("Item: $item"),
            Text("Quantity: $promisedQty"),
            const SizedBox(height: 12),

            // Status chip
            if (!isPending)
              Chip(
                label: Text(status),
                backgroundColor: isReceived
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                labelStyle: TextStyle(
                  color: isReceived ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // Action buttons for pending donations
            if (isPending) ...[
              const Text(
                "Mark donation status:",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsReceived(donationId),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text("Received"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsNotReceived(donationId),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text("Not Received"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
