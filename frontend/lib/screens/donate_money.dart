import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class DonateMoneyPage extends StatefulWidget {
  final String? campId;
  const DonateMoneyPage({super.key, this.campId});

  @override
  State<DonateMoneyPage> createState() => _DonateMoneyPageState();
}

class _DonateMoneyPageState extends State<DonateMoneyPage> {
  final TextEditingController amountController = TextEditingController();
  late Razorpay _razorpay;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    amountController.dispose();
    super.dispose();
  }

  Future<void> openRazorpay() async {
    final amount = amountController.text.trim();

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter amount")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // 1. Create order on the backend to get Order ID
      final response = await ApiService.createRazorpayOrder(amount);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode != 200 || jsonResponse['id'] == null) {
        throw Exception(jsonResponse['error'] ?? "Failed to create order");
      }

      final String orderId = jsonResponse['id'];
      
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? "Donor";
      final userPhone = prefs.getString('userPhone') ?? "9999999999";
      final userEmail = prefs.getString('userEmail') ?? "donor@sahaya.com";

      // 2. Setup Razorpay Options
      var options = {
        'key': 'rzp_test_S3iNfkYOx5zNOb', // Using actual test API key
        'amount': (double.parse(amount) * 100).toInt(), // amount in paise
        'name': 'Sahaya Foundation',
        'description': widget.campId != null ? 'Donation for Camp ${widget.campId}' : 'General Donation',
        'order_id': orderId,
        'timeout': 120, // in seconds
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
        },
      };

      // Since we can't easily fetch the key from the frontend without another endpoint, 
      // we need to set the key directly from the environment or user input.
      // We will ask the user to configure it via an endpoint, OR we can fetch it.
      // For now, Razorpay Flutter requires the key in the options.
      
      // Temporary solution for options key until user provides it via instructions:
      options['key'] = 'rzp_test_S3iNfkYOx5zNOb';

      // 3. Open Razorpay Checkout
      _razorpay.open(options);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _generateAndSaveReceipt({
    required String paymentId,
    required String orderId,
    required String amount,
    required String donorName,
    required String donorEmail,
    required String date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Sahaya Foundation', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Donation Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Receipt No: RCPT-${paymentId.substring(4)}', style: pw.TextStyle(fontSize: 14)),
                pw.Text('Date: $date', style: pw.TextStyle(fontSize: 14)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                pw.Text('Donor Information:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Name: $donorName', style: pw.TextStyle(fontSize: 14)),
                pw.Text('Email: $donorEmail', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text('Payment Details:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Description', 'Amount'],
                    <String>[widget.campId != null ? 'Donation to Camp ${widget.campId}' : 'General Donation', 'Rs. $amount'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total: Rs. $amount', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your generous donation to Sahaya Foundation!',
                    style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated receipt and does not require a signature.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Sahaya_Receipt_$paymentId.pdf");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Receipt saved to ${file.path}"),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not save receipt: $e")),
        );
      }
    }
  }

  void _showSuccessDialog(String paymentId, String amount, String orderId) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text("Payment Successful!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Thank you for your generous donation of Rs. $amount."),
              const SizedBox(height: 10),
              Text("Payment ID: $paymentId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text("Done"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text("Download Receipt"),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final donorName = prefs.getString('userName') ?? "Anonymous Donor";
                final donorEmail = prefs.getString('userEmail') ?? "donor@example.com";
                final date = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());

                await _generateAndSaveReceipt(
                  paymentId: paymentId,
                  orderId: orderId,
                  amount: amount,
                  donorName: donorName,
                  donorEmail: donorEmail,
                  date: date,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[900],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donorId = prefs.getString('userId') ?? "Anonymous";
      final amount = amountController.text.trim();

      // 4. Verify payment on backend
      final verifyResponse = await ApiService.verifyRazorpayPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        donorId: donorId,
        campId: widget.campId ?? "General",
        amount: amount,
      );

      if (verifyResponse.statusCode == 200) {
        if (mounted) {
          // Show success dialog with receipt download option instead of just popping
          _showSuccessDialog(response.paymentId!, amount, response.orderId!);
        }
      } else {
        throw Exception("Verification failed on server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Verification Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed: ${response.message}")),
      );
      setState(() => isProcessing = false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
      );
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate Money")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.campId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Donating to Camp ID: ${widget.campId}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: openRazorpay,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text("Pay with Razorpay", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
            const SizedBox(height: 20),
            const Text(
              "Note: This will use the Razorpay gateway to process your payment securely.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
