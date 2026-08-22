package com.rise.mahjong

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Drives the vibration motor directly. Avoids Android's touch-haptic path,
/// which many OEMs mute even when the game asks for feedback.
class HapticsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "vibrate") {
            result.notImplemented()
            return
        }
        val duration = intArg(call, "duration", 80).toLong().coerceIn(40L, 400L)
        val amplitude = intArg(call, "amplitude", 255).coerceIn(1, 255)
        vibrate(duration, amplitude)
        result.success(null)
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        val vibrator = vibrator() ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val effect = VibrationEffect.createOneShot(durationMs, amplitude)
                val attrs =
                    VibrationAttributes.Builder()
                        .setUsage(VibrationAttributes.USAGE_HARDWARE_FEEDBACK)
                        .build()
                vibrator.vibrate(effect, attrs)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createOneShot(
                    durationMs,
                    VibrationEffect.DEFAULT_AMPLITUDE,
                )
                val attrs =
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                @Suppress("DEPRECATION")
                vibrator.vibrate(effect, attrs)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs)
            }
        } catch (_: Exception) {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs)
            } catch (_: Exception) {
                // No vibrator / restricted by the OS.
            }
        }
    }

    private fun vibrator(): Vibrator? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val managed =
                appContext.getSystemService(VibratorManager::class.java)?.defaultVibrator
            if (managed != null) return managed
        }
        return appContext.getSystemService(Vibrator::class.java)
            ?: @Suppress("DEPRECATION")
            (appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator)
    }

    private fun intArg(call: MethodCall, key: String, fallback: Int): Int {
        return when (val raw = call.argument<Any>(key)) {
            is Int -> raw
            is Long -> raw.toInt()
            is Double -> raw.toInt()
            is Float -> raw.toInt()
            else -> fallback
        }
    }

    companion object {
        const val CHANNEL = "com.rise.mahjong/haptics"
    }
}
