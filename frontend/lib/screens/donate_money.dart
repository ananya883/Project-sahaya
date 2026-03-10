import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonateMoneyPage extends StatefulWidget {
  const DonateMoneyPage({super.key});

  @override
  State<DonateMoneyPage> createState() => _DonateMoneyPageState();
}

class _DonateMoneyPageState extends State<DonateMoneyPage> {
  final TextEditingController amountController = TextEditingController();

  Future<void> launchUPI() async {
    final amount = amountController.text.trim();

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter amount")),
      );
      return;
    }

    final uri = Uri.parse(
      "upi://pay?pa=ananyams2015@okhdfcbank&pn=Sahaya&am=$amount&cu=INR",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate Money")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: launchUPI,
              child: const Text("Pay using UPI"),
            ),
            const SizedBox(height: 20),


          ],
        ),
      ),
    );
  }
}
