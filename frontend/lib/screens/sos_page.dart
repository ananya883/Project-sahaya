import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// Web-only import
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final List<String> emergencyTypes = ['Medical', 'Fire', 'Rescue', 'Other'];
  final List<String> disasterTypes = ['Flood', 'Earthquake', 'Landslide', 'Cyclone', ];

  String? selectedEmergency;
  String? selectedDisaster;

  // Mobile
  XFile? pickedFile;

  // Web
  Uint8List? webImageData;
  // html.VideoElement? _webVideo;
  // html.CanvasElement? _webCanvas;

  Position? currentPosition;
  bool locating = false;
  bool sending = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // if (kIsWeb) _initWebCamera();
  }

  // ---------------- Web Camera Preview ----------------
  // void _initWebCamera() {
  //   _webVideo = html.VideoElement()
  //     ..autoplay = true
  //     ..width = 300
  //     ..height = 200;

  //   html.window.navigator.mediaDevices?.getUserMedia({'video': true}).then((stream) {
  //     _webVideo!.srcObject = stream;
  //   });

  //   setState(() {});
  // }

  // void _captureWebImage() {
  //   if (_webVideo == null) return;

  //   _webCanvas ??= html.CanvasElement(
  //     width: _webVideo!.videoWidth,
  //     height: _webVideo!.videoHeight,
  //   );

  //   final ctx = _webCanvas!.context2D;
  //   ctx.drawImage(_webVideo!, 0, 0);

  //   final dataUrl = _webCanvas!.toDataUrl('image/png');
  //   final bytes = base64Decode(dataUrl.split(',')[1]);

  //   setState(() {
  //     webImageData = bytes;
  //   });
  // }

  // ---------------- Web File Upload ----------------
  // void _pickWebImageFile() {
  //   final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  //   uploadInput.click();

  //   uploadInput.onChange.listen((event) {
  //     final files = uploadInput.files;
  //     if (files != null && files.isNotEmpty) {
  //       final reader = html.FileReader();
  //       reader.readAsArrayBuffer(files[0]);
  //       reader.onLoadEnd.listen((event) {
  //         setState(() {
  //           webImageData = Uint8List.fromList(reader.result as List<int>);
  //         });
  //       });
  //     }
  //   });
  // }

  // ---------------- Pick Image (Mobile) ----------------
  Future<void> _pickImage({required bool fromCamera}) async {
    if (kIsWeb) return;
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 70);
    if (file != null) setState(() => pickedFile = file);
  }

  // ---------------- Location ----------------
  Future<void> _determinePosition() async {
    setState(() => locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() => currentPosition = pos);
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      setState(() => locating = false);
    }
  }

  // ---------------- Send SOS ----------------
  Future<void> _sendSos() async {
    if (selectedEmergency == null) return;

    setState(() => sending = true);
    try {
      final response = await ApiService.sendSos(
        emergencyType: selectedEmergency!,
        disasterType: selectedDisaster == null || selectedDisaster == 'None' ? '' : selectedDisaster!,
        latitude: currentPosition?.latitude.toString(),
        longitude: currentPosition?.longitude.toString(),
        imageFile: pickedFile,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _resetForm();
        _showSnackBar('SOS Sent Successfully', success: true);
      } else {
        _showSnackBar('Failed to send SOS (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Network error: $e');
    } finally {
      setState(() => sending = false);
    }
  }

  void _resetForm() {
    setState(() {
      selectedEmergency = null;
      selectedDisaster = null;
      pickedFile = null;
      webImageData = null;
    });
  }

  void _showSnackBar(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY REPORT'),
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black87),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedEmergency,
              hint: const Text('Select emergency type'),
              isExpanded: true,
              items: emergencyTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedEmergency = v),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedDisaster,
              hint: const Text('Select related disaster (optional)'),
              isExpanded: true,
              items: ['None', ...disasterTypes].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedDisaster = v),
            ),
            const SizedBox(height: 16),

            // ---------------- Image selection ----------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                      onPressed: () => _pickImage(fromCamera: true),
                      child: const Text('Open Camera')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () => _pickImage(fromCamera: false),
                      child: const Text('Gallery')),
                ),
              ],
            ),

            const SizedBox(height: 12),
            if (pickedFile != null)
              Image.file(File(pickedFile!.path), height: 100, width: 100, fit: BoxFit.cover),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sending ? null : _sendSos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('TRIGGER SOS'),
            ),
          ],
        ),
      ),
    );
  }
}
