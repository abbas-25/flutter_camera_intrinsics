import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CameraIntrinsics {
  static const MethodChannel _channel = MethodChannel('camera_intrinsics');

  static Map<String, dynamic>? _cachedIntrinsics;

  /// Returns intrinsics map or throws PlatformException
  static Future<CameraIntrinsicsResponse> getIntrinsics() async {
    if (_cachedIntrinsics != null) {
      return CameraIntrinsicsResponse(
        intrinsics: _cachedIntrinsics!,
        isCached: true,
      );
    }

    try {
      final result = await _channel.invokeMethod('getIntrinsics');

      debugPrint("[CAMERA_INTRINSICS PLUGIN OUPUT] ${result.toString()}");

      _cachedIntrinsics = Map<String, dynamic>.from(result);

      return CameraIntrinsicsResponse(
        intrinsics: _cachedIntrinsics!,
        isCached: false,
      );
    } catch (exception) {
      throw PlatformException(
        code: 'getIntrinsics',
        message: exception.toString(),
      );
    }
  }

  /// Clears the cached intrinsics data, forcing a fresh fetch on next call
  static void clearCache() {
    _cachedIntrinsics = null;
  }
}

class CameraIntrinsicsResponse {
  final Map<String, dynamic> intrinsics;
  final bool isCached;

  CameraIntrinsicsResponse({required this.intrinsics, required this.isCached});
}
