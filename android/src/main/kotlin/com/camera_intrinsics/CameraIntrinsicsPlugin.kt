package com.camera_intrinsics

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.app.Activity
import android.content.Context
import android.Manifest
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.FrameLayout.LayoutParams
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** CameraIntrinsicsPlugin */
class CameraIntrinsicsPlugin :
    FlutterPlugin,
    MethodCallHandler, ActivityAware {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var arCoreCameraHelper: ArCoreCameraHelper
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var glSurfaceView: GLSurfaceView? = null
    private var containerView: FrameLayout? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "camera_intrinsics")
        channel.setMethodCallHandler(this)
        arCoreCameraHelper = ArCoreCameraHelper()
        applicationContext = flutterPluginBinding.applicationContext
    }

        override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        if (call.method == "getIntrinsics") {
            if (activity == null || applicationContext == null) {
                result.error("NOT_ATTACHED", "Plugin not attached to activity", null)
                return
            }

            // Permission check
            if (ActivityCompat.checkSelfPermission(applicationContext!!, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                println("[CAMERA_INTRINSICS_PLUGIN] Permission Check: Camera permission not granted.")
                ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.CAMERA), 0)
                result.error("CAMERA_PERMISSION_NOT_GRANTED", "Camera permission is required", null)
                return
            }

            setupGlContextAndFetchIntrinsics(result)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun setupGlContextAndFetchIntrinsics(result: MethodChannel.Result) {
        activity?.runOnUiThread {
            containerView =
                FrameLayout(activity!!).apply {
                    layoutParams = LayoutParams(1, 1)
                }

            glSurfaceView =
                GLSurfaceView(activity!!).apply {
                    setEGLContextClientVersion(2)

                    setRenderer(
                        object : GLSurfaceView.Renderer {
                            private var session: Session? = null

                            override fun onSurfaceCreated(
                                gl: GL10?,
                                config: EGLConfig?,
                            ) {
                                println("[CAMERA_INTRINSICS_PLUGIN] GLRenderer: onSurfaceCreated - GL context ready.")

                                try {
                                    // Generate OpenGL texture and set it to ARCore
                                    val textures = IntArray(1)
                                    GLES20.glGenTextures(1, textures, 0)
                                    val textureId = textures[0]

                                    // Start ARCore session
                                    session = Session(activity!!)
                                    session?.setCameraTextureName(textureId)

                                    val arConfig = Config(session)
                                    arConfig.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                                    session?.configure(arConfig)
                                    session?.resume()

                                    println("[CAMERA_INTRINSICS_PLUGIN] ARCore: Session started. Sleeping for 500ms.")
                                    Thread.sleep(500)

                                    // Try fetching camera intrinsics, max 20 attempts
                                    var intrinsicsData: CameraIntrinsicsData? = null
                                    for (i in 1..20) {
                                        val frame = session?.update()
                                        val trackingState = frame?.camera?.trackingState

                                        if (trackingState == TrackingState.TRACKING) {
                                            intrinsicsData = arCoreCameraHelper.getCameraIntrinsics(frame)
                                            break
                                        }
                                        Thread.sleep(100)
                                    }

                                    if (intrinsicsData != null) {
                                        val distortion = arCoreCameraHelper.getBackCameraDistortionCoefficients(activity!!)

                                        val intrinsicsMap: Map<String, Any> =
                                            mapOf(
                                                "focalLength" to intrinsicsData.focalLength.toList(),
                                                "principalPoint" to intrinsicsData.principalPoint.toList(),
                                                "imageDimensions" to intrinsicsData.imageDimensions.toList(),
                                                "distortion" to (distortion?.toList() ?: emptyList()),
                                            )

                                        activity?.runOnUiThread {
                                            result.success(intrinsicsMap)
                                        }
                                    } else {
                                        println("[CAMERA_INTRINSICS_PLUGIN] Tracking failed, intrinsics unavailable.")
                                        activity?.runOnUiThread {
                                            result.error("INTRINSICS_UNAVAILABLE", "Camera intrinsics not available (not tracking).", null)
                                        }
                                    }
                                } catch (e: Exception) {
                                    println("[CAMERA_INTRINSICS_PLUGIN] ERROR: ${e.message}")
                                    activity?.runOnUiThread {
                                        result.error("ARCORE_ERROR", e.message, null)
                                    }
                                } finally {
                                    println("Cleaning up session and surface.")
                                    session?.pause()
                                    session?.close()
                                    removeGlSurfaceView()
                                }
                            }

                            override fun onSurfaceChanged(
                                gl: GL10?,
                                width: Int,
                                height: Int,
                            ) {
                            }

                            override fun onDrawFrame(gl: GL10?) {
                            }
                        },
                    )

                    renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
                }

            containerView?.addView(glSurfaceView)
            activity?.addContentView(containerView, containerView?.layoutParams)

            glSurfaceView?.requestRender()
        }
    }

    private fun removeGlSurfaceView() {
        activity?.runOnUiThread {
            (containerView?.parent as? ViewGroup)?.removeView(containerView)
            glSurfaceView = null
            containerView = null
        }
    }
}
