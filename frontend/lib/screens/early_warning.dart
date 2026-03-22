import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_service.dart';

class EarlyWarningPage extends StatefulWidget {
  const EarlyWarningPage({super.key});

  @override
  State<EarlyWarningPage> createState() => _EarlyWarningPageState();
}

class _EarlyWarningPageState extends State<EarlyWarningPage> {
  bool isLoading = true;
  String? userId;
  List<dynamic> weatherReports = [];
  
  List<String> allLocations = [];
  List<String> subscribedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      
      if (userId != null) {
        // Fetch in parallel
        final results = await Future.wait([
          AlertService.getLocations(),
          AlertService.getMySubscriptions(userId!),
          AlertService.getMyAlerts(userId!),
        ]);
        
        allLocations = results[0] as List<String>;
        subscribedLocations = results[1] as List<String>;
        weatherReports = results[2] as List<dynamic>;
      }
    } catch (e, stacktrace) {
      print("Error loading early warning data: $e\n$stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load alerts: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleSubscription(String location, bool? isSubscribed) async {
    if (userId == null) return;
    
    setState(() {
      if (isSubscribed == true) {
        subscribedLocations.add(location);
      } else {
        subscribedLocations.remove(location);
      }
    });

    final success = await AlertService.subscribeLocations(userId!, subscribedLocations);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscriptions updated", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      // Reload alerts in case new subscription has active alert
      _loadOnlyAlerts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update subscriptions", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      // Revert UI on failure
      setState(() {
        if (isSubscribed == true) {
          subscribedLocations.remove(location);
        } else {
          subscribedLocations.add(location);
        }
      });
    }
  }

  Future<void> _loadOnlyAlerts() async {
    if (userId == null) return;
    final alerts = await AlertService.getMyAlerts(userId!);
    setState(() {
      weatherReports = alerts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disaster Early Warnings"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
        : userId == null 
          ? const Center(child: Text("Please log in to manage alerts"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Subscribed Weather Status",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 10),
                  
                  subscribedLocations.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.blueAccent, size: 30),
                            SizedBox(width: 12),
                            Expanded(child: Text("You are not subscribed to any locations. Please manage your subscriptions below to see live weather warnings.", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      )
                    : weatherReports.isEmpty
                    ? const Center(
                        child: Text(
                          "No weather data available for subscribed locations.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weatherReports.length,
                        itemBuilder: (context, index) {
                          final report = weatherReports[index];
                          final loc = report['location'];
                          final data = report['data'] ?? {};
                          final prediction = report['prediction'] ?? {};
                          
                          final alertLvl = prediction['alert_level'] ?? 0;
                          final isDanger = alertLvl > 0;
                          final color = alertLvl == 2 ? Colors.red : (alertLvl == 1 ? Colors.orange : Colors.green);
                          final icon = alertLvl == 2 ? '🚨' : (alertLvl == 1 ? '⚠️' : '✅');
                          
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 2)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$icon $loc",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                        child: Text(
                                          (prediction['alert_name'] ?? "Safe").replaceAll('🔴', '').replaceAll('🟠', '').replaceAll('🟢', '').trim(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                  const Divider(height: 15),
                                  
                                  // ---------- Weather Data Row ----------
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _weatherStat(Icons.thermostat, "${data['temperature'] ?? '--'}°C"),
                                      _weatherStat(Icons.water_drop, "${data['humidity'] ?? '--'}%"),
                                      _weatherStat(Icons.air, "${data['windspeed'] ?? '--'}m/s"),
                                      _weatherStat(Icons.umbrella, "${data['rainfall'] ?? '--'}mm"),
                                    ],
                                  ),
                                  
                                  if (isDanger) ...[
                                    const Divider(height: 20),
                                    Text("Confidence: ${prediction['confidence'] ?? 0}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (prediction['reasoning'] != null)
                                      ...List.generate((prediction['reasoning'] as List).length, (i) {
                                        return Text("• ${prediction['reasoning'][i]}");
                                      }),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        "Recommendation: ${prediction['recommendation'] ?? 'Stay Alert.'}",
                                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  ] else ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Text(
                                        "Weather is normal. No disaster risk detected.",
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  
                  const Text(
                    "Manage Subscriptions",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 6),
                  const Text("Select locations to receive early warnings.", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 15),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allLocations.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loc = allLocations[index];
                        final isSubbed = subscribedLocations.contains(loc);
                        
                        return CheckboxListTile(
                          title: Text(loc, style: const TextStyle(fontWeight: FontWeight.w500)),
                          activeColor: Colors.blueAccent,
                          value: isSubbed,
                          onChanged: (val) => _toggleSubscription(loc, val),
                          secondary: Icon(
                            isSubbed ? Icons.notifications_active : Icons.notifications_none,
                            color: isSubbed ? Colors.redAccent : Colors.grey,
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
  // Helper for drawing weather stats
  Widget _weatherStat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
