package com.sumerudigital.divyavaani

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.StatFs
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aradhya/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deviceInfo" -> {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val mi = ActivityManager.MemoryInfo()
                        am.getMemoryInfo(mi)
                        result.success(
                            mapOf(
                                "isLowRamDevice" to am.isLowRamDevice,
                                "totalMemBytes" to mi.totalMem,
                                "sdkInt" to Build.VERSION.SDK_INT,
                                "cores" to Runtime.getRuntime().availableProcessors(),
                            )
                        )
                    }
                    "freeDiskBytes" -> {
                        val path = call.argument<String>("path") ?: filesDir.absolutePath
                        result.success(
                            try {
                                StatFs(path).availableBytes
                            } catch (e: Exception) {
                                -1L
                            }
                        )
                    }
                    "installTtsData" -> result.success(launch(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)))
                    "openTtsSettings" -> result.success(launch(Intent("com.android.settings.TTS_SETTINGS")))
                    else -> result.notImplemented()
                }
            }
    }

    private fun launch(intent: Intent): Boolean = try {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
