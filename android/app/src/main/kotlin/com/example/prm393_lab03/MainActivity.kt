package com.example.prm393_lab03

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelId = "evia_events_v1"

    private fun ensureChannel(): NotificationManager {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                channelId, "Evia events", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Events and account notifications from Evia" })
        }
        return manager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "evia/notifications")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "ensureChannel" -> { ensureChannel(); result.success(null) }
                        "showNotification" -> {
                            val manager = ensureChannel()
                            if (!manager.areNotificationsEnabled()) { result.success(null); return@setMethodCallHandler }
                            val messageId = call.argument<String>("messageId")
                            val tag = call.argument<String>("tag") ?: messageId ?: "evia"
                            // FlutterFire keeps the received FCM message; reuse its tap handling.
                            val intent = Intent(this, MainActivity::class.java)
                                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                                .putExtra("google.message_id", messageId)
                            val pending = PendingIntent.getActivity(this, tag.hashCode(), intent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                            @Suppress("DEPRECATION")
                            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                Notification.Builder(this, channelId) else Notification.Builder(this)
                            val body = call.argument<String>("body") ?: ""
                            manager.notify(tag, 0, builder
                                .setSmallIcon(R.drawable.ic_notification)
                                .setContentTitle(call.argument<String>("title") ?: "Evia")
                                .setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
                                .setContentIntent(pending).setAutoCancel(true)
                                .setCategory(Notification.CATEGORY_EVENT)
                                .setVisibility(Notification.VISIBILITY_PRIVATE)
                                .setPriority(Notification.PRIORITY_HIGH).build())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("notification_failed", "Could not display notification", null)
                }
            }
    }
}
