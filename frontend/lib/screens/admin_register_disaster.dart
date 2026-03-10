import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/location_picker.dart';
import '../../services/api_config.dart';

class AdminRegisterDisaster extends StatefulWidget {
  const AdminRegisterDisaster({super.key});

  @override
  State<AdminRegisterDisaster> createState() => _AdminRegisterDisasterState();
}

class _AdminRegisterDisasterState extends State<AdminRegisterDisaster> {
  final _formKey = GlobalKey<FormState>();
  final _disasterNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _affectedPopulationController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedDisasterType = 'Flood';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;

  // Location data
  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  final List<String> _disasterTypes = [
    'Flood',
    'Earthquake',
    'Fire',
    'Cyclone',
    'Landslide',
    'Tsunami',
    'Other'
  ];

  final List<String> _severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _disasterNameController.dispose();
    _descriptionController.dispose();
    _affectedPopulationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitDisaster() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select disaster date')),
      );
      return;
    }

    if (_latitude == null || _longitude == null || _locationAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select disaster location')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.adminRegisterDisaster),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'disasterName': _disasterNameController.text.trim(),
          'location': _locationAddress!,
          'latitude': _latitude,
          'longitude': _longitude,
          'dateOccurred': _selectedDate!.toIso8601String(),
          'disasterType': _selectedDisasterType,
          'severity': _selectedSeverity,
          'description': _descriptionController.text.trim(),
          'affectedPopulation': _affectedPopulationController.text.isEmpty
              ? 0
              : int.parse(_affectedPopulationController.text),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Disaster registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to register disaster');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Disaster'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disaster Name
              TextFormField(
                controller: _disasterNameController,
                decoration: const InputDecoration(
                  labelText: 'Disaster Name *',
                  hintText: 'e.g., Kerala Floods 2024',
                  prefixIcon: Icon(Icons.warning_amber, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter disaster name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Picker
              const Text(
                'Location *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              LocationPicker(
                onLocationSelected: (locationData) {
                  setState(() {
                    _latitude = locationData.latitude;
                    _longitude = locationData.longitude;
                    _locationAddress = locationData.address;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date Occurred
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date Occurred *',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Disaster Type
              DropdownButtonFormField<String>(
                value: _selectedDisasterType,
                decoration: const InputDecoration(
                  labelText: 'Disaster Type *',
                  prefixIcon: Icon(Icons.category, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                items: _disasterTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDisasterType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Severity Level
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severity Level *',
                  prefixIcon: Icon(Icons.priority_high, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                items: _severityLevels.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(severity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(severity),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSeverity = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Affected Population
              TextFormField(
                controller: _affectedPopulationController,
                decoration: const InputDecoration(
                  labelText: 'Affected Population (Optional)',
                  hintText: 'Estimated number of people affected',
                  prefixIcon: Icon(Icons.people, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional details about the disaster',
                  prefixIcon: Icon(Icons.description, color: Colors.red),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDisaster,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Register Disaster',
                    style: TextStyle(
                      fontSize: 16,
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
}
