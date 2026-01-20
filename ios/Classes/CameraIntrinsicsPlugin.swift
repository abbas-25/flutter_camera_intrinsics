import Flutter
import UIKit
import ARKit

public class CameraIntrinsicsPlugin: NSObject, FlutterPlugin {
    private var arSession: ARSession?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "camera_intrinsics", binaryMessenger: registrar.messenger())
        let instance = CameraIntrinsicsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsics":
            getIntrinsics(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getIntrinsics(result: @escaping FlutterResult) {
        if let cached = cachedIntrinsics {
            result(cached)
            return
        }

        guard ARWorldTrackingConfiguration.isSupported else {
            result(FlutterError(code: "ARKIT_NOT_SUPPORTED", message: "ARKit is not supported on this device", details: nil))
            return
        }

        arSession = ARSession()
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        arSession?.run(config)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchIntrinsics(result: result, attempt: 0)
        }
    }

    private func fetchIntrinsics(result: @escaping FlutterResult, attempt: Int) {
        guard let currentFrame = arSession?.currentFrame else {
            if attempt < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.fetchIntrinsics(result: result, attempt: attempt + 1)
                }
            } else {
                cleanup()
                result(FlutterError(code: "INTRINSICS_UNAVAILABLE", message: "No AR frame available", details: nil))
            }
            return
        }

        let intrinsics = currentFrame.camera.intrinsics
        let resolution = currentFrame.camera.imageResolution

        let fx = intrinsics.columns.0.x
        let fy = intrinsics.columns.1.y
        let cx = intrinsics.columns.2.x
        let cy = intrinsics.columns.2.y

        let intrinsicsMap: [String: Any] = [
            "focalLength": [Double(fx), Double(fy)],
            "principalPoint": [Double(cx), Double(cy)],
            "imageDimensions": [Int(resolution.width), Int(resolution.height)],
            "distortion": [] as [Double]
        ]

        cachedIntrinsics = intrinsicsMap
        cleanup()
        result(intrinsicsMap)
    }

    private func cleanup() {
        arSession?.pause()
        arSession = nil
    }
}
