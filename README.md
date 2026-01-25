# camera_intrinsics

A Flutter plugin to retrieve camera intrinsics from ARCore (Android) and ARKit (iOS) for camera calibration and image geometry calculations.

## Platform Support

| Android | iOS |
|:-------:|:---:|
|    ✅    |  ✅  |

## Requirements

### Android
- **minSdkVersion**: 24 or higher
- **ARCore**: Device must support ARCore (Google Play Services for AR)
- **Camera Permission**: Required at runtime

### iOS
- **iOS**: 13.0 or higher
- **ARKit**: Device must support ARKit (iPhone 6s or later)
- **Camera Permission**: Required (add to Info.plist)

## Limits
- **iOS**: Distortion coefficients unavailable

## Setup

### Android

Add the following to your app's `AndroidManifest.xml` inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.ar.core"
    android:value="required" />
```

### iOS

Add camera permission to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to get camera intrinsics</string>
```

## Usage

```dart
import 'package:camera_intrinsics/camera_intrinsics.dart';

// Get camera intrinsics
try {
  final response = await CameraIntrinsics.getIntrinsics();

  final intrinsics = response.intrinsics;
  print('Focal Length: ${intrinsics['focalLength']}');
  print('Principal Point: ${intrinsics['principalPoint']}');
  print('Image Dimensions: ${intrinsics['imageDimensions']}');
  print('Distortion: ${intrinsics['distortion']}');
  print('Was cached: ${response.isCached}');
} on PlatformException catch (e) {
  print('Error: ${e.message}');
}

// Clear cache if you need fresh data
CameraIntrinsics.clearCache();
```

## Response Data

| Field | Type | Description |
|-------|------|-------------|
| `focalLength` | `List<double>` | Focal length in pixels [fx, fy] |
| `principalPoint` | `List<double>` | Principal point [cx, cy] |
| `imageDimensions` | `List<int>` | Image size [width, height] |
| `distortion` | `List<double>` | Distortion coefficients (Android only, empty on iOS) |

## Error Codes

### Android
| Code | Description |
|------|-------------|
| `CAMERA_PERMISSION_NOT_GRANTED` | Camera permission was denied |
| `NOT_ATTACHED` | Plugin not attached to activity |
| `INTRINSICS_UNAVAILABLE` | Could not get intrinsics (tracking failed) |
| `ARCORE_ERROR` | ARCore session error |

### iOS
| Code | Description |
|------|-------------|
| `ARKIT_NOT_SUPPORTED` | ARKit is not supported on this device |
| `INTRINSICS_UNAVAILABLE` | No AR frame available |

## Contributing

Contributions are welcome! Fork the repo, make your changes, and submit a pull request.

### Project Structure

```
camera_intrinsics/
├── lib/                          # Dart plugin interface
├── android/src/main/kotlin/      # Android (Kotlin) implementation
├── ios/Classes/                  # iOS (Swift) implementation
└── example/                      # Example Flutter app
```

### Guidelines

- Test on both Android and iOS if possible
- Keep PRs focused on a single feature or fix
- Update CHANGELOG.md for user-facing changes
- Follow platform-specific code conventions ([Dart](https://dart.dev/guides/language/effective-dart/style), [Kotlin](https://kotlinlang.org/docs/coding-conventions.html), [Swift](https://swift.org/documentation/api-design-guidelines/))

### Reporting Issues

Please include: device model, OS version, Flutter version, steps to reproduce, and any error logs.
