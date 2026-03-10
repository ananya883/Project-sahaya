import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'admin_register_disaster.dart';
import '../services/api_config.dart';

class AdminDisastersList extends StatefulWidget {
  const AdminDisastersList({super.key});

  @override
  State<AdminDisastersList> createState() => _AdminDisastersListState();
}

class _AdminDisastersListState extends State<AdminDisastersList> {
  List<Map<String, dynamic>> disasters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisasters();
  }

  Future<void> _loadDisasters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminDisasters),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          disasters = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load disasters');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading disasters: $e')),
        );
      }
    }
  }

  Future<void> _deleteDisaster(String disasterId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Disaster'),
        content: const Text('Are you sure you want to delete this disaster record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.adminDisaster(disasterId)),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disaster deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDisasters(); // Refresh list
      } else {
        throw Exception('Failed to delete disaster');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateDisasterStatus(String disasterId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.adminDisaster(disasterId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDisasters(); // Refresh list
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDisasterDetails(Map<String, dynamic> disaster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _getSeverityColor(disaster['severity'])),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                disaster['disasterName'] ?? 'Disaster Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Disaster ID', disaster['disasterId']),
              _buildDetailRow('Type', disaster['disasterType']),
              _buildDetailRow('Location', disaster['location']),
              _buildDetailRow(
                'Date Occurred',
                DateFormat('dd MMM yyyy').format(DateTime.parse(disaster['dateOccurred'])),
              ),
              _buildDetailRow('Severity', disaster['severity'],
                  color: _getSeverityColor(disaster['severity'])),
              _buildDetailRow('Status', disaster['status'],
                  color: _getStatusColor(disaster['status'])),
              if (disaster['affectedPopulation'] != null && disaster['affectedPopulation'] > 0)
                _buildDetailRow('Affected Population',
                    disaster['affectedPopulation'].toString()),
              if (disaster['description'] != null && disaster['description'].isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(disaster['description']),
              ],
              const Divider(height: 24),
              const Text(
                'Update Status:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Active', 'Monitoring', 'Resolved'].map((status) {
                  final isCurrentStatus = disaster['status'] == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isCurrentStatus,
                    selectedColor: _getStatusColor(status).withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected && !isCurrentStatus) {
                        Navigator.pop(context);
                        _updateDisasterStatus(disaster['disasterId'], status);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDisaster(disaster['disasterId']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.deepOrange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.red;
      case 'Monitoring':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Disasters'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDisasters,
        child: disasters.isEmpty
            ? const Center(
          child: Text('No disasters registered yet'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disasters.length,
          itemBuilder: (context, index) {
            final disaster = disasters[index];
            final dateOccurred = DateTime.parse(disaster['dateOccurred']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                onTap: () => _showDisasterDetails(disaster),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(disaster['severity'])
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getSeverityColor(disaster['severity']),
                              ),
                            ),
                            child: Text(
                              disaster['severity'],
                              style: TextStyle(
                                color: _getSeverityColor(disaster['severity']),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(disaster['status'])
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              disaster['status'],
                              style: TextStyle(
                                color: _getStatusColor(disaster['status']),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            disaster['disasterId'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        disaster['disasterName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            disaster['disasterType'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              disaster['location'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(dateOccurred),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (disaster['affectedPopulation'] != null &&
                          disaster['affectedPopulation'] > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${disaster['affectedPopulation']} people affected',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRegisterDisaster()),
          );
          if (result == true) {
            _loadDisasters(); // Refresh list after adding new disaster
          }
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Register Disaster'),
      ),
    );
  }
}
