package com.atelerix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject

/**
 * ✅ Firebase Messaging Service لمعالجة الإشعارات الواردة
 */
class AtelerixMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "AtelerixMessaging"
        private const val CHANNEL_ID = "atelerix_notifications"
        private const val CHANNEL_NAME = "Atelerix Notifications"
    }

    /**
     * ✅ يتم استدعاؤها عند وصول إشعار جديد
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d(TAG, "📥 Message received from: ${remoteMessage.from}")

        try {
            // 1. معالجة Data Payload
            if (remoteMessage.data.isNotEmpty()) {
                Log.d(TAG, "📦 Data payload: ${remoteMessage.data}")
                handleDataPayload(remoteMessage.data)
            }

            // 2. معالجة Notification Payload
            remoteMessage.notification?.let { notification ->
                Log.d(TAG, "🔔 Notification: ${notification.title}")
                sendNotification(
                    title = notification.title ?: "New Message",
                    body = notification.body ?: "",
                    data = remoteMessage.data
                )
            }

            // 3. إرسال للـ Flutter
            sendToFlutter(remoteMessage)

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling message: ${e.message}", e)
        }
    }

    /**
     * ✅ يتم استدعاؤها عند تحديث FCM Token
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)

        Log.d(TAG, "🔄 New FCM Token: ${token.take(20)}...")

        // حفظ التوكن الجديد
        val prefs = getSharedPreferences("atelerix_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()

        // TODO: إرسال التوكن الجديد للـ Backend
        sendTokenToBackend(token)
    }

    /**
     * ✅ معالجة Data Payload
     */
    private fun handleDataPayload(data: Map<String, String>) {
        try {
            val title = data["title"] ?: "New Message"
            val body = data["body"] ?: data["message"] ?: ""
            val type = data["type"] ?: "default"

            Log.d(TAG, "📨 Type: $type, Title: $title")

            // عرض الإشعار
            sendNotification(title, body, data)

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling data: ${e.message}", e)
        }
    }

    /**
     * ✅ إرسال الإشعار إلى Flutter
     */
    private fun sendToFlutter(remoteMessage: RemoteMessage) {
        try {
            val notificationData = JSONObject().apply {
                // Notification payload
                remoteMessage.notification?.let {
                    put("title", it.title ?: "")
                    put("body", it.body ?: "")
                    put("imageUrl", it.imageUrl?.toString() ?: "")
                }

                // Data payload
                remoteMessage.data.forEach { (key, value) ->
                    put(key, value)
                }

                // Metadata
                put("from", remoteMessage.from ?: "")
                put("messageId", remoteMessage.messageId ?: "")
                put("sentTime", remoteMessage.sentTime)
            }

            // إرسال عبر Event Channel
            AtelerixPlugin.sendNotificationToFlutter(notificationData)

            Log.d(TAG, "✅ Notification sent to Flutter")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending to Flutter: ${e.message}", e)
        }
    }

    /**
     * ✅ عرض Notification في الـ System Tray
     */
    private fun sendNotification(
        title: String,
        body: String,
        data: Map<String, String> = emptyMap()
    ) {
        try {
            // إنشاء Notification Channel (Android 8.0+)
            createNotificationChannel()

            // Intent للفتح عند الضغط
            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                // إضافة البيانات
                data.forEach { (key, value) ->
                    putExtra(key, value)
                }
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                System.currentTimeMillis().toInt(),
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            // صوت الإشعار
            val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            // بناء الإشعار
            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(getNotificationIcon())
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))

            // عرض الإشعار
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(
                System.currentTimeMillis().toInt(),
                notificationBuilder.build()
            )

            Log.d(TAG, "✅ Notification displayed: $title")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing notification: ${e.message}", e)
        }
    }

    /**
     * ✅ إنشاء Notification Channel (Android 8.0+)
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Atelerix push notifications"
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    /**
     * ✅ الحصول على أيقونة الإشعار
     */
    private fun getNotificationIcon(): Int {
        // محاولة إيجاد الأيقونة
        val iconId = resources.getIdentifier(
            "ic_notification",
            "drawable",
            packageName
        )

        // إذا لم توجد، استخدم أيقونة التطبيق
        return if (iconId != 0) {
            iconId
        } else {
            applicationInfo.icon
        }
    }

    /**
     * ✅ إرسال التوكن الجديد للـ Backend
     */
    private fun sendTokenToBackend(token: String) {
        Thread {
            try {
                val prefs = getSharedPreferences("atelerix_prefs", Context.MODE_PRIVATE)
                val apiKey = prefs.getString("api_key", null)
                val deviceId = prefs.getString("device_id", null)
                val serverUrl = prefs.getString("server_url", null)

                if (apiKey == null || deviceId == null || serverUrl == null) {
                    Log.w(TAG, "⚠️ Cannot update token: missing config")
                    return@Thread
                }

                val url = java.net.URL("$serverUrl/api/devices/$deviceId/token")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "PUT"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Bearer $apiKey")
                connection.doOutput = true

                val body = JSONObject().apply {
                    put("fcmToken", token)
                }

                connection.outputStream.use {
                    it.write(body.toString().toByteArray())
                }

                val responseCode = connection.responseCode
                if (responseCode in 200..299) {
                    Log.d(TAG, "✅ Token updated on backend")
                } else {
                    Log.e(TAG, "❌ Backend error: $responseCode")
                }

                connection.disconnect()

            } catch (e: Exception) {
                Log.e(TAG, "❌ Error updating token: ${e.message}", e)
            }
        }.start()
    }
}
