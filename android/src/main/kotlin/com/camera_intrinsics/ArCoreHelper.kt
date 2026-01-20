package com.camera_intrinsics   

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.util.Log
import com.google.ar.core.Camera
import com.google.ar.core.Frame
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.NotYetAvailableException

data class CameraIntrinsicsData(
    val focalLength: FloatArray,
    val principalPoint: FloatArray,
    val imageDimensions: IntArray,
)

class ArCoreCameraHelper {
    fun getCameraIntrinsics(frame: Frame?): CameraIntrinsicsData? {
        if (frame == null) {
            System.err.println("[CAMERA_INTRINSICS_PLUGIN] Error: ARCore Frame is null.")
            return null
        }

        val camera = frame.camera

        return try {
            val intrinsics = camera.imageIntrinsics

            // Extract focal length (fx, fy) and principal point (px, py).
            val focalLength = intrinsics.focalLength
            val principalPoint = intrinsics.principalPoint

            val fx = focalLength[0]
            val fy = focalLength[1]
            val px = principalPoint[0]
            val py = principalPoint[1]

            CameraIntrinsicsData(
                floatArrayOf(fx, fy),
                floatArrayOf(px, py),
                intArrayOf(intrinsics.imageDimensions[0], intrinsics.imageDimensions[1]),
            )
        } catch (e: NotYetAvailableException) {
            System.err.println("[CAMERA_INTRINSICS_PLUGIN] Camera intrinsics not yet available: ${e.message}")
            // This is common at the start of an ARCore session. You might need to wait for a few frames.
            null
        } catch (e: Exception) {
            System.err.println("[CAMERA_INTRINSICS_PLUGIN] An unexpected error occurred while fetching intrinsics: ${e.message}")
            null
        }
    }

    fun getBackCameraDistortionCoefficients(context: Context): FloatArray? {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)

            if (lensFacing == CameraCharacteristics.LENS_FACING_BACK) {
                val distortion = characteristics.get(CameraCharacteristics.LENS_DISTORTION)
                if (distortion != null) {
                    return distortion
                }
            }
        }

        return null
    }
}
