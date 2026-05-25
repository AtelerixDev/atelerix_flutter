import 'dart:io';

import 'package:atelerix_flutter/atelerix_platform_interface.dart';
import 'package:atelerix_flutter/src/atelerix_backend.dart';
import 'package:atelerix_flutter/src/atelerix_keys.dart';
import 'package:atelerix_flutter/src/atelerix_native.dart';
import 'package:atelerix_flutter/src/utils/enum/routes.dart';
import 'package:atelerix_flutter/src/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton class for managing push notifications
///
/// This class is NOT initialized by default. You must explicitly call:
/// ```dart
/// await Atelerix.notifications.init();
/// ```
class NotificationsManager extends ChangeNotifier {
  static final NotificationsManager _instance =
      NotificationsManager._internal();
  factory NotificationsManager() => _instance;
  NotificationsManager._internal();

  final AtelerixKeys _atelerixKeys = AtelerixKeys();
  final LoggerMsg _logger = LoggerMsg();
  final AtelerixNative _atelerixNative = AtelerixNative();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  // Storage key for device token
  static const String _deviceTokenKey = 'atelerix_device_token';

  // State management
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _deviceToken;
  Future<String?> get deviceToken async {
    try {
      // Return cached value if available
      if (_deviceToken != null) {
        return _deviceToken;
      }

      // Otherwise read from secure storage
      final cachedTokenNative = await _storage.read(key: _deviceTokenKey);

      // Cache it for future use
      _deviceToken = cachedTokenNative;

      return cachedTokenNative;
    } catch (e) {
      _logger.logError(
          "Failed to get device token: $e", "ERR_GET_DEVICE_TOKEN");
      return null;
    }
  }

  // Callbacks
  void Function(Map<String, dynamic>)? _onNotificationReceived;
  void Function(Map<String, dynamic>)? _onNotificationTapped;

  /// Initialize notifications system
  ///
  /// This MUST be called before using any notification features.
  /// Safe to call multiple times - will only initialize once.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // Initialize Atelerix (WITHOUT notifications)
  ///   Atelerix.init(...);
  ///
  ///   // Initialize notifications when needed
  ///   await Atelerix.notifications.init();
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> init() async {
    if (_isInitialized) {
      _logger.logNormal("✅ Notifications already initialized");
      return;
    }

    try {
      // Step 1: Setup notification listeners
      _setupNotificationListeners();

      // Step 2: Initialize Firebase/FCM in Native (Android only)
      if (Platform.isAndroid) {
          try {
        // Use provided senderId or default
        final fcmSenderId = await getSenderId();

        await AtelerixPlatform.instance.initializeFCM(
          senderId: fcmSenderId!,
        );

        _logger.logNormal("✅ Firebase/FCM initialized");
      } catch (e) {
        // iOS doesn't need this step
        _logger.logWarning("Firebase initialization skipped (iOS): $e");
      }
      }
      _isInitialized = true;
      // Step 3: Register device with Native plugin (Android only)
      try {
          print("Here 3.1");
        final token = await AtelerixPlatform.instance.deviceToken();
        print("Here 3");
        await register(token ?? "");
        print("Here 4");
        _logger.logNormal("✅ Device registered with Native plugin");
      } catch (e) {
        print("Here 3.2");
        print("error: $e");
        _logger.logWarning("Device registration skipped (iOS): $e");
      }

      _logger.logNormal("✅ Notifications system initialized");
    } catch (e) {
      print("Here 9");
      print("error: $e");
      _logger.logError(
          "Failed to initialize notifications: $e", "NOTIF_INIT_ERROR");
      rethrow;
    }
  }

  /// Setup listeners for receiving notifications from Native code
  void _setupNotificationListeners() {
    const notificationChannel = MethodChannel('atelerix/notifications');

    notificationChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationReceived') {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _logger.logNormal(
            "📬 Notification received: ${data['aps']?['alert'] ?? 'No message'}");
        _onNotificationReceived?.call(data);
      } else if (call.method == 'onNotificationTapped') {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _logger.logNormal("👆 Notification tapped");
        _onNotificationTapped?.call(data);
      }
    });
  }

  /// Throws error if notifications not initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      print("Here 7");
      throw StateError(
          'Notifications not initialized. Call await Atelerix.notifications.init() first');
    }
  }

  /// Register device for push notifications
  ///
  /// Returns device token ID if successful, null otherwise
  Future<String?> register(String token) async {
    print("Here 5");
    _ensureInitialized();
    print("Here 6");
    try {
      // Step 1: Get device token from platform
      // _deviceToken = await AtelerixPlatform.instance.deviceToken();
      print("Here 1");
      // Check cached token first
      // final cachedTokenNative = await _storage.read(key: _deviceTokenKey);
      // print("Here 2");
      // if (cachedTokenNative != null) {
      //   return cachedTokenNative;
      // }

      // Store the new token
      _deviceToken = token;
      await _storage.write(key: _deviceTokenKey, value: token);
      _atelerixKeys.deviceToken = token;

      // Step 2: Register with backend
      final response = await AtelerixBackend(
        data: {
          "token": token,
          "userId": _atelerixKeys.projectUser,
          "appId": _atelerixKeys.projectConfig.id,
        },
        route: Routes.registerNotification,
      ).post();

      notifyListeners();

      if (response != null && response['id'] != null) {
        print("response: $response");
        _logger
            .logNormal("✅ Device registered with backend: ${response['id']}");
        return response['id'];
      }

      _logger.logError(
          "Failed to register: ${response?['message'] ?? 'Unknown error'}",
          "ERR_NOTIF_REGISTER");
      return null;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return null;
    } catch (e) {
      print("Here 8");
      print("error: $e");
      _logger.logError("Unexpected error: $e", "ERR_NOTIF_UNKNOWN");
      return null;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    _ensureInitialized();

    try {
      final granted =
          await AtelerixPlatform.instance.requestNotificationPermissions();

      if (granted) {
        _logger.logNormal("✅ Permissions granted");
      } else {
        _logger.logWarning("❌ Permissions denied");
      }

      return granted;
    } catch (e) {
      _logger.logError("Permission request failed: $e", "ERR_PERMISSION");
      return false;
    }
  }

  Future<String?> getSenderId() async {
    try {
      final appId = _atelerixKeys.projectConfig.id;
      final response = await AtelerixBackend(
        route: Routes.getSenderId,
        queryParams: {"appId": appId},
        header: {
          "appID": _atelerixKeys.projectConfig.id,
          "projectID": _atelerixKeys.projectId,
          "platform": _atelerixNative.device?.osName ?? "",
        },
      ).get();

      return response?['senderId'];
    } catch (e) {
      _logger.logError(
          "Failed to get sender id, Check if the app is configured from the dashboard",
          "ERR_GET_SENDER_ID");
      return null;
    }
  }

  /// Check permission status
  Future<String?> checkPermissionStatus() async {
    _ensureInitialized();

    try {
      return await AtelerixPlatform.instance
          .checkNotificationPermissionStatus();
    } catch (e) {
      _logger.logError("Check status failed: $e", "ERR_CHECK_STATUS");
      return null;
    }
  }

  /// Set callback for foreground notifications
  void setOnNotificationReceived(void Function(Map<String, dynamic>) callback) {
    _onNotificationReceived = callback;
  }

  /// Set callback for notification taps
  void setOnNotificationTapped(void Function(Map<String, dynamic>) callback) {
    _onNotificationTapped = callback;
  }

  /// Clear stored token
  Future<void> clearToken() async {
    _deviceToken = null;
    await _storage.delete(key: _deviceTokenKey);
    notifyListeners();
  }

  void _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case "PERMISSION_DENIED":
        _logger.logWarning("User denied permissions");
        break;
      case "TOKEN_PENDING":
        _logger.logWarning("Token pending, try again later");
        break;
      default:
        _logger.logError("Platform error: ${e.message}", e.code);
    }
  }
}
