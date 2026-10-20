package com.anatorius.airapp.v2

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
	private var pendingSmsResult: MethodChannel.Result? = null
	private var pendingSmsNumber: String? = null
	private var pendingSmsMessage: String? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "airtext/screen_privacy")
			.setMethodCallHandler { call, result ->
				if (call.method != "setEnabled") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				if (call.argument<Boolean>("enabled") == true) {
					window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
				} else {
					window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
				}
				result.success(null)
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "airtext/sms")
			.setMethodCallHandler { call, result ->
				if (call.method != "sendSms") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				val number = call.argument<String>("number")?.trim()
				val message = call.argument<String>("message")
				if (number.isNullOrEmpty() || message.isNullOrEmpty()) {
					result.error("invalid_sms", "A phone number and message are required.", null)
					return@setMethodCallHandler
				}
				if (checkSelfPermission(Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
					pendingSmsResult = result
					pendingSmsNumber = number
					pendingSmsMessage = message
					requestPermissions(arrayOf(Manifest.permission.SEND_SMS), SMS_PERMISSION_REQUEST)
					return@setMethodCallHandler
				}
				sendSmsThroughSim(number, message, result)
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "airtext/device_info")
			.setMethodCallHandler { call, result ->
				if (call.method != "getDeviceInfo") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				result.success(
					mapOf(
						"manufacturer" to Build.MANUFACTURER,
						"model" to Build.MODEL,
						"system" to "Android ${Build.VERSION.RELEASE}",
					),
				)
			}
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode != SMS_PERMISSION_REQUEST) return

		val result = pendingSmsResult ?: return
		val number = pendingSmsNumber
		val message = pendingSmsMessage
		pendingSmsResult = null
		pendingSmsNumber = null
		pendingSmsMessage = null
		if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) {
			result.error("permission_denied", "Allow SMS permission to send through this phone SIM.", null)
			return
		}
		if (number.isNullOrEmpty() || message.isNullOrEmpty()) {
			result.error("invalid_sms", "A phone number and message are required.", null)
			return
		}
		sendSmsThroughSim(number, message, result)
	}

	private fun sendSmsThroughSim(number: String, message: String, result: MethodChannel.Result) {
		try {
			val smsManager = getSystemService(SmsManager::class.java)
			val parts = smsManager.divideMessage(message)
			if (parts.size > 1) {
				smsManager.sendMultipartTextMessage(number, null, parts, null, null)
			} else {
				smsManager.sendTextMessage(number, null, message, null, null)
			}
			result.success(true)
		} catch (exception: Exception) {
			result.error("sms_send_failed", exception.localizedMessage, null)
		}
	}

	override fun onCreate(savedInstanceState: android.os.Bundle?) {
		super.onCreate(savedInstanceState)
		createMessageNotificationChannels()
	}

	private fun createMessageNotificationChannels() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

		val notificationManager = getSystemService(NotificationManager::class.java)
		val audioAttributes = AudioAttributes.Builder()
			.setUsage(AudioAttributes.USAGE_NOTIFICATION)
			.build()
		notificationManager.createNotificationChannel(
			NotificationChannel(
				"airtext_calls",
				"AirText calls",
				NotificationManager.IMPORTANCE_HIGH,
			).apply {
				description = "Notifications for incoming AirText calls"
			},
		)
		val channels = listOf(
			Triple("chime", "Chime", R.raw.airtext_chime),
			Triple("modern_ping", "Modern ping", R.raw.airtext_modern_ping),
			Triple("soft_echo", "Soft echo", R.raw.airtext_soft_echo),
		)

		channels.forEach { (tone, label, soundResource) ->
			val soundUri = Uri.parse("android.resource://$packageName/$soundResource")
			val channel = NotificationChannel(
				"airtext_messages_$tone",
				"AirText messages - $label",
				NotificationManager.IMPORTANCE_HIGH,
			).apply {
				description = "Notifications for new AirText messages"
				setSound(soundUri, audioAttributes)
			}
			notificationManager.createNotificationChannel(channel)
		}
	}

	private companion object {
		const val SMS_PERMISSION_REQUEST = 7101
	}
}
