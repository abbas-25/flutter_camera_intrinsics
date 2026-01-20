import 'package:flutter_test/flutter_test.dart';
import 'package:camera_intrinsics/camera_intrinsics.dart';
import 'package:camera_intrinsics/camera_intrinsics_platform_interface.dart';
import 'package:camera_intrinsics/camera_intrinsics_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCameraIntrinsicsPlatform
    with MockPlatformInterfaceMixin
    implements CameraIntrinsicsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CameraIntrinsicsPlatform initialPlatform =
      CameraIntrinsicsPlatform.instance;

  test('$MethodChannelCameraIntrinsics is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCameraIntrinsics>());
  });

  test('getPlatformVersion', () async {
    MockCameraIntrinsicsPlatform fakePlatform = MockCameraIntrinsicsPlatform();
    CameraIntrinsicsPlatform.instance = fakePlatform;

    expect(await CameraIntrinsics.getIntrinsics(), '42');
  });
}
