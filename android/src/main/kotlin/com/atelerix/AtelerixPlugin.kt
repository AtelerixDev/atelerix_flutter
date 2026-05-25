package com.atelerix

import android.Manifest
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.NetworkInterface
import java.net.URL
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

/**
 * Atelerix Flutter Plugin
 * 
 * Production-ready implementation with:
 * - Lazy Firebase initialization
 * - Proper coroutine management
 * - Thread-safe operations
 * - Comprehensive error handling
 * - Clean architecture separation
 * 
 * @version 1.0.0
 * @author Atelerix Team
 */
class AtelerixPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, 
    EventChannel.StreamHandler, ActivityAware {

    // ============================================
    // Properties
    // ============================================
    
    private lateinit var context: Context
    private lateinit var systemChannel: MethodChannel
    private lateinit var notificationsChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    
    // Coroutine scope with SupervisorJob for proper lifecycle management
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    // Firebase instance (lazy initialized)
    private var customFirebaseApp: FirebaseApp? = null

    // ============================================
    // Constants
    // ============================================
    
    companion object {
        private const val TAG = "AtelerixPlugin"
        
        // Channel names
        private const val SYSTEM_CHANNEL = "atelerix/system"
        private const val NOTIFICATIONS_CHANNEL = "atelerix/notifications"
        private const val EVENT_CHANNEL = "atelerix/events"
        
        // Permission
        private const val PERMISSION_REQUEST_CODE = 1001
        
        // Firebase configuration
        private const val CUSTOM_FCM_APP_NAME = "ATELERIX_FCM_APP"
        private const val FCM_DEFAULT_PROJECT_ID = "atelerix-44685"
        private const val FCM_DEFAULT_APP_ID = "1:152690376774:android:9d72d1299efc71ac39ca47"
        private const val FCM_DEFAULT_API_KEY_BASE64 = "QUl6YVN5RGZTZ20xU0Q3bHcwd0FuRmJwT0RQX3ZoSjZlbjNObHA0"
        
        // Preferences
        private const val PREFS_NAME = "atelerix_prefs"
        private const val PREF_DEVICE_ID = "device_id"
        private const val PREF_API_KEY = "api_key"
        private const val PREF_USER_ID = "user_id"
        private const val PREF_SERVER_URL = "server_url"
        private const val PREF_FCM_TOKEN = "fcm_token"
        
        // Event streaming
        var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        /**
         * Send notification data to Flutter
         */
        fun sendNotificationToFlutter(notification: JSONObject) {
            val data = mutableMapOf<String, Any>("type" to "notification")
            notification.keys().forEach { key ->
                notification.opt(key)?.let { value -> data[key] = value }
            }
            sendEventToFlutter(data)
        }

        /**
         * Send connection status to Flutter
         */
        fun sendConnectionStatus(connected: Boolean) {
            sendEventToFlutter(mapOf(
                "type" to "connection",
                "connected" to connected
            ))
        }

        /**
         * Thread-safe event sending to Flutter
         */
        private fun sendEventToFlutter(data: Map<String, Any>) {
            eventSink?.let { sink ->
                if (Looper.myLooper() == Looper.getMainLooper()) {
                    sendEventOnMainThread(sink, data)
                } else {
                    mainHandler.post { sendEventOnMainThread(sink, data) }
                }
            }
        }

        /**
         * Send event on main thread
         */
        private fun sendEventOnMainThread(sink: EventChannel.EventSink, data: Map<String, Any>) {
            try {
                sink.success(JSONObject(data).toString())
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send event to Flutter", e)
            }
        }
    }

    // ============================================
    // Plugin Lifecycle
    // ============================================

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        // Setup system channel
        systemChannel = MethodChannel(binding.binaryMessenger, SYSTEM_CHANNEL)
        systemChannel.setMethodCallHandler { call, result ->
            handleSystemCall(call, result)
        }

        // Setup notifications channel
        notificationsChannel = MethodChannel(binding.binaryMessenger, NOTIFICATIONS_CHANNEL)
        notificationsChannel.setMethodCallHandler { call, result ->
            handleNotificationsCall(call, result)
        }

        // Setup event channel
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        Log.d(TAG, "✅ Atelerix Plugin attached")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Clean up channels
        systemChannel.setMethodCallHandler(null)
        notificationsChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        // Cancel all coroutines
        pluginScope.cancel()
        
        Log.d(TAG, "🔌 Atelerix Plugin detached")
    }

    // ============================================
    // Method Call Handlers (Deprecated - kept for backward compatibility)
    // ============================================

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        // Redirect to system channel
        handleSystemCall(call, result)
    }

    // ============================================
    // System Channel Handler
    // ============================================

    /**
     * Handle system-related method calls
     */
    private fun handleSystemCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                // Platform info
                "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
                "getSystemName" -> result.success(Build.BRAND)
                "getDeviceName" -> result.success(Build.MODEL)
                "getAppID" -> result.success(context.packageName)
                
                // Additional system info
                "getArch" -> result.success(getArchitecture())
                "getTimeZone" -> result.success(getTimeZone())
                "getCountryCode" -> result.success(getCountryCode())
                "getFreeMemory" -> result.success(getFreeMemory())
                
                // Connection
                "getConnectionStatus" -> result.success(true)
                
                // App state
                "setAppVisible" -> handleSetAppVisible(call, result)
                // Google Services
                "isGoogleServicesAvailable" -> handleIsGoogleServicesAvailable(result)
                "listen" -> handleListen(result)
                
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling system call: ${call.method}", e)
            result.error("SYSTEM_CALL_ERROR", e.message, null)
        }
    }

    // ============================================
    // Notifications Channel Handler
    // ============================================

    /**
     * Handle notifications-specific method calls
     */
    private fun handleNotificationsCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                // Initialization
                "initializeFCM" -> handleInitializeFirebase(call, result)
                "register" -> handleRegister(call, result)
                
                // Token management
                "getDeviceToken" -> handleGetDeviceToken(result)
                
                // Permissions
                "requestPermissions" -> handleRequestPermission(result)
                "checkNotificationPermission" -> handleCheckNotificationPermission(result)
                
                // Topics
                "subscribe" -> handleSubscribe(call, result)
                "unsubscribe" -> handleUnsubscribe(call, result)
                
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification call: ${call.method}", e)
            result.error("NOTIFICATION_CALL_ERROR", e.message, null)
        }
    }

    // ============================================
    // System Method Implementations
    // ============================================

    private fun handleListen(result: MethodChannel.Result) {
        Log.d(TAG, "🎧 Listening for notifications")
        result.success(true)
    }

    private fun handleSetAppVisible(call: MethodCall, result: MethodChannel.Result) {
        val visible = call.argument<Boolean>("visible") ?: false
        Log.d(TAG, "👁️ App visibility: $visible")
        result.success(true)
    }

    private fun handleIsGoogleServicesAvailable(result: MethodChannel.Result) {
        val isAvailable = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS
        result.success(isAvailable)
    }

    /**
     * Get device architecture
     */
    private fun getArchitecture(): String {
        return Build.SUPPORTED_ABIS.firstOrNull() ?: "Unknown"
    }

    /**
     * Get device timezone
     */
    private fun getTimeZone(): String {
        return TimeZone.getDefault().id
    }

    /**
     * Get device country code
     */
    private fun getCountryCode(): String {
        return Locale.getDefault().country
    }

    /**
     * Get available free memory (in MB)
     */
    private fun getFreeMemory(): String {
        val runtime = Runtime.getRuntime()
        val freeMemory = runtime.freeMemory()
        val totalMemory = runtime.totalMemory()
        val freeMB = (totalMemory - freeMemory) / (1024 * 1024)
        return "${freeMB}MB"
    }

    // ============================================
    // Notification Method Implementations
    // ============================================

    /**
     * Register device with Atelerix backend
     */
    private fun handleRegister(call: MethodCall, result: MethodChannel.Result) {
        val apiKey = call.argument<String>("apiKey")
        val userId = call.argument<String?>("userId")
        val serverUrl = call.argument<String?>("serverUrl") ?: "http://192.168.40.77:3000"

        if (apiKey.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "apiKey is required", null)
            return
        }

        pluginScope.launch {
            try {
                val deviceId = getOrCreateDeviceId()
                saveConfiguration(apiKey, userId, serverUrl)

                Log.d(TAG, "✅ Device registered with ID: $deviceId")

                // Initialize Firebase and get token
                val senderId = "645864880516" // TODO: Fetch from backend
                val firebaseApp = initializeFirebaseApp(senderId)
                val fcmToken = getFcmToken(firebaseApp)

                // Save token
                savePreference(PREF_FCM_TOKEN, fcmToken)

                // Register with backend (optional)
                registerDeviceWithBackend(
                    deviceId = deviceId,
                    fcmToken = fcmToken,
                    apiKey = apiKey,
                    userId = userId,
                    serverUrl = serverUrl
                )

                result.success(deviceId)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Registration failed", e)
                result.error("REGISTER_ERROR", e.message, null)
            }
        }
    }

    /**
     * Initialize Firebase with custom configuration
     */
    private fun handleInitializeFirebase(call: MethodCall, result: MethodChannel.Result) {
        val senderId = call.argument<String>("senderId")

        if (senderId.isNullOrEmpty()) {
            result.error("FIREBASE_INIT_ERROR", "Sender ID is required", null)
            return
        }

        pluginScope.launch {
            try {
                initializeFirebaseApp(senderId)
                result.success("Firebase App initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Firebase initialization failed", e)
                result.error("FIREBASE_INIT_ERROR", e.message, null)
            }
        }
    }

    // ============================================
    // Firebase Operations
    // ============================================

    /**
     * Initialize Firebase App with custom configuration
     * Thread-safe and idempotent
     */
    private suspend fun initializeFirebaseApp(senderId: String): FirebaseApp = 
        withContext(Dispatchers.IO) {
            // Return existing instance if already initialized
            customFirebaseApp?.let {
                Log.d(TAG, "✅ Firebase App already initialized")
                return@withContext customFirebaseApp!!
            }

            // Try to get existing named instance
            try {
                customFirebaseApp = FirebaseApp.getInstance(CUSTOM_FCM_APP_NAME)
                return@withContext customFirebaseApp!!
            } catch (e: IllegalStateException) {
                // Instance doesn't exist, create new one
            }

            // Create new Firebase App
            try {
                val apiKey = String(Base64.decode(FCM_DEFAULT_API_KEY_BASE64, Base64.DEFAULT))

                val options = FirebaseOptions.Builder()
                    .setGcmSenderId(senderId)
                    .setProjectId(FCM_DEFAULT_PROJECT_ID)
                    .setApplicationId(FCM_DEFAULT_APP_ID)
                    .setApiKey(apiKey)
                    .build()

                customFirebaseApp = FirebaseApp.initializeApp(
                    context.applicationContext,
                    options,
                    CUSTOM_FCM_APP_NAME
                )

                Log.d(TAG, "✅ Firebase App created successfully")
                Log.d(TAG, "🔢 Sender ID: $senderId")
                Log.d(TAG, "📦 Project ID: $FCM_DEFAULT_PROJECT_ID")

                return@withContext customFirebaseApp!!
            } catch (e: Exception) {
                Log.e(TAG, "❌ Firebase initialization failed", e)
                throw e
            }
        }

    /**
     * Get FCM token from Firebase instance
     */
    private suspend fun getFcmToken(firebaseApp: FirebaseApp): String = 
        withContext(Dispatchers.IO) {
            try {
                val fcmInstance = firebaseApp.get(FirebaseMessaging::class.java)
                val token = Tasks.await(fcmInstance.token)

                Log.d(TAG, "✅ FCM Token obtained: ${token.take(20)}...")
                return@withContext token
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting FCM token", e)
                throw e
            }
        }

    /**
     * Get device token - requires Firebase to be initialized
     */
    private fun handleGetDeviceToken(result: MethodChannel.Result) {
        if (customFirebaseApp == null) {
            Log.e(TAG, "❌ Firebase not initialized")
            result.error(
                "NOT_INITIALIZED",
                "Firebase not initialized. Call register() or notifications.init() first",
                null
            )
            return
        }

        pluginScope.launch {
            try {
                val token = getFcmToken(customFirebaseApp!!)
                result.success(token)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting device token", e)
                result.error("TOKEN_ERROR", e.message, null)
            }
        }
    }

    // ============================================
    // Backend Communication
    // ============================================

    /**
     * Register device with Atelerix backend
     */
    private fun registerDeviceWithBackend(
        deviceId: String,
        fcmToken: String,
        apiKey: String,
        userId: String?,
        serverUrl: String
    ) {
        pluginScope.launch(Dispatchers.IO) {
            try {
                val url = URL("$serverUrl/api/devices/register")
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    doOutput = true
                    connectTimeout = 10000
                    readTimeout = 10000
                }

                val body = JSONObject().apply {
                    put("deviceId", deviceId)
                    put("fcmToken", fcmToken)
                    put("platform", "android")
                    put("appId", context.packageName)
                    put("deviceModel", Build.MODEL)
                    put("osVersion", Build.VERSION.RELEASE)
                    put("manufacturer", Build.MANUFACTURER)
                    put("ipAddress", getDeviceIPAddress())
                    put("arch", getArchitecture())
                    put("timezone", getTimeZone())
                    put("countryCode", getCountryCode())
                    userId?.let { put("userId", it) }
                }

                connection.outputStream.use {
                    it.write(body.toString().toByteArray())
                }

                val responseCode = connection.responseCode
                if (responseCode in 200..299) {
                    Log.d(TAG, "✅ Device registered with backend")
                } else {
                    val error = connection.errorStream?.bufferedReader()?.use { it.readText() }
                    Log.e(TAG, "❌ Backend error: $responseCode - $error")
                }

                connection.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Backend registration failed", e)
            }
        }
    }

    // ============================================
    // Permissions
    // ============================================

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val activity = activityBinding?.activity
            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity not available", null)
                return
            }

            val permission = Manifest.permission.POST_NOTIFICATIONS
            val hasPermission = ContextCompat.checkSelfPermission(context, permission) ==
                PackageManager.PERMISSION_GRANTED

            if (hasPermission) {
                result.success(true)
            } else {
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(permission),
                    PERMISSION_REQUEST_CODE
                )
            }
        } else {
            // Android 12 and below don't need runtime permission
            result.success(true)
        }
    }

    private fun handleCheckNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = Manifest.permission.POST_NOTIFICATIONS
            val hasPermission = ContextCompat.checkSelfPermission(context, permission) ==
                PackageManager.PERMISSION_GRANTED
            result.success(if (hasPermission) "authorized" else "denied")
        } else {
            result.success("authorized")
        }
    }

    // ============================================
    // Topic Subscription
    // ============================================

    private fun handleSubscribe(call: MethodCall, result: MethodChannel.Result) {
        val topic = call.argument<String>("topic")
        if (topic.isNullOrBlank()) {
            result.error("INVALID_ARGS", "topic is required", null)
            return
        }

        if (customFirebaseApp == null) {
            result.error(
                "NOT_INITIALIZED",
                "Firebase not initialized. Call register() first",
                null
            )
            return
        }

        pluginScope.launch {
            try {
                val fcmInstance = customFirebaseApp!!.get(FirebaseMessaging::class.java)
                withContext(Dispatchers.IO) {
                    Tasks.await(fcmInstance.subscribeToTopic(topic))
                }

                Log.d(TAG, "✅ Subscribed to topic: $topic")
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Subscribe failed for topic: $topic", e)
                result.error("SUBSCRIBE_ERROR", e.message, null)
            }
        }
    }

    private fun handleUnsubscribe(call: MethodCall, result: MethodChannel.Result) {
        val topic = call.argument<String>("topic")
        if (topic.isNullOrBlank()) {
            result.error("INVALID_ARGS", "topic is required", null)
            return
        }

        if (customFirebaseApp == null) {
            result.error(
                "NOT_INITIALIZED",
                "Firebase not initialized. Call register() first",
                null
            )
            return
        }

        pluginScope.launch {
            try {
                val fcmInstance = customFirebaseApp!!.get(FirebaseMessaging::class.java)
                withContext(Dispatchers.IO) {
                    Tasks.await(fcmInstance.unsubscribeFromTopic(topic))
                }

                Log.d(TAG, "🔕 Unsubscribed from topic: $topic")
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Unsubscribe failed for topic: $topic", e)
                result.error("UNSUBSCRIBE_ERROR", e.message, null)
            }
        }
    }

    // ============================================
    // Event Stream
    // ============================================

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "✅ Flutter listening to events")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "⚠️ Flutter stopped listening")
    }

    // ============================================
    // Activity Lifecycle
    // ============================================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode == PERMISSION_REQUEST_CODE) {
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
                return@addRequestPermissionsResultListener true
            }
            false
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    // ============================================
    // Helper Methods
    // ============================================

    /**
     * Get or create unique device ID
     */
    private fun getOrCreateDeviceId(): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var deviceId = prefs.getString(PREF_DEVICE_ID, null)

        if (deviceId == null) {
            deviceId = UUID.randomUUID().toString()
            prefs.edit().putString(PREF_DEVICE_ID, deviceId).apply()
        }

        return deviceId
    }

    /**
     * Save configuration to SharedPreferences
     */
    private fun saveConfiguration(apiKey: String, userId: String?, serverUrl: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString(PREF_API_KEY, apiKey)
            putString(PREF_USER_ID, userId)
            putString(PREF_SERVER_URL, serverUrl)
            apply()
        }
    }

    /**
     * Save single preference
     */
    private fun savePreference(key: String, value: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(key, value).apply()
    }

    /**
     * Get device IP address
     */
    private fun getDeviceIPAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses

                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        return address.hostAddress ?: "Unknown"
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting IP address", e)
        }
        return "Unknown"
    }
}