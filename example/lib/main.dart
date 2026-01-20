import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera_intrinsics/camera_intrinsics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const CameraIntrinsicsScreen());
  }
}

class CameraIntrinsicsScreen extends StatefulWidget {
  const CameraIntrinsicsScreen({super.key});

  @override
  State<CameraIntrinsicsScreen> createState() => _CameraIntrinsicsScreenState();
}

class _CameraIntrinsicsScreenState extends State<CameraIntrinsicsScreen> {
  bool _isProcessing = false;
  List<double>? _focalLength;
  List<double>? _principalPoint;
  List<int>? _imageDimensions;
  List<double>? _distortion;
  bool _isCachedResponse = false;
  String? _error;

  Future<void> _getIntrinsics() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final response = await CameraIntrinsics.getIntrinsics();

      final result = response.intrinsics;

      setState(() {
        _focalLength = (result['focalLength'] as List?)?.cast<double>();
        _principalPoint = (result['principalPoint'] as List?)?.cast<double>();
        _imageDimensions = (result['imageDimensions'] as List?)?.cast<int>();
        _distortion = (result['distortion'] as List?)?.cast<double>();
        _isCachedResponse = response.isCached;
      });
    } on PlatformException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Intrinsics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('1. Grant camera permission if & when prompted'),
            const Text('2. Point camera in a well-lit direction'),
            const Text('3. Press the button below to fetch intrinsics'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _getIntrinsics,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Camera Intrinsics'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Focal Length: $_focalLength'),
            Text('Principal Point: $_principalPoint'),
            Text('Image Dimensions: $_imageDimensions'),
            Text('Distortion: $_distortion'),
            Text('Cached Response?: $_isCachedResponse'),
          ],
        ),
      ),
    );
  }
}
