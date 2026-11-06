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
    private val saveReportRequest = 49303
    private var reportResult: MethodChannel.Result? = null
    private var reportBytes: ByteArray? = null

    @Deprecated("Activity result bridge for the Flutter report service")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveReportRequest) return
        val result = reportResult ?: return
        val bytes = reportBytes
        val uri = data?.data
        reportResult = null
        reportBytes = null
        if (resultCode != RESULT_OK) { result.success(false); return }
        if (uri == null || bytes == null) {
            result.error("report_failed", "No output document", null)
            return
        }
        Thread {
            try {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw java.io.IOException("No output stream")
                output.use { it.write(bytes) }
                runOnUiThread { result.success(true) }
            } catch (_: Exception) {
                runOnUiThread { result.error("report_failed", "Could not save report", null) }
            }
        }.start()
    }

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "evia/reports")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveCsv") { result.notImplemented(); return@setMethodCallHandler }
                if (reportResult != null) { result.error("report_busy", "A save is in progress", null); return@setMethodCallHandler }
                val bytes = call.arguments as? ByteArray
                if (bytes == null || bytes.size > 5 * 1024 * 1024) {
                    result.error("report_failed", "Invalid report size", null)
                    return@setMethodCallHandler
                }
                reportResult = result
                reportBytes = bytes
                try {
                    @Suppress("DEPRECATION")
                    startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "text/csv"
                        putExtra(Intent.EXTRA_TITLE, "evia-coin-history.csv")
                    }, saveReportRequest)
                } catch (_: Exception) {
                    reportResult = null
                    reportBytes = null
                    result.error("report_failed", "Could not open save dialog", null)
                }
            }
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
