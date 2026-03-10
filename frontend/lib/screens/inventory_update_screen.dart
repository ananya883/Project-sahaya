import 'package:flutter/material.dart';

class InventoryUpdateScreen extends StatefulWidget {
  const InventoryUpdateScreen({super.key});

  @override
  State<InventoryUpdateScreen> createState() => _InventoryUpdateScreenState();
}

class _InventoryUpdateScreenState extends State<InventoryUpdateScreen> {
  // TEMP UI STATE (will be backend data later)
  final Map<String, String> inventory = {
    "Rice": "120 kg",
    "Water Bottles": "300",
    "Medicines": "50 units",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camp Inventory"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: inventory.entries.map((entry) {
          return inventoryItem(
            context,
            itemName: entry.key,
            availableQty: entry.value,
          );
        }).toList(),
      ),
    );
  }

  Widget inventoryItem(
      BuildContext context, {
        required String itemName,
        required String availableQty,
      }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.inventory, color: Colors.green),
        title: Text(
          itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Available: $availableQty"),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            showEditDialog(context, itemName);
          },
        ),
      ),
    );
  }

  void showEditDialog(BuildContext context, String itemName) {
    final TextEditingController qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update $itemName"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter New Quantity",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                inventory[itemName] = qtyController.text;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Inventory updated successfully"),
                ),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
