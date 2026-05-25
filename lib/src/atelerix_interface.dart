import 'dart:async';

import 'package:atelerix_flutter/atelerix.dart';
import 'package:atelerix_flutter/src/atelerix_inti.dart';
import 'package:atelerix_flutter/src/atelerix_keys.dart';
import 'package:atelerix_flutter/src/atelerix_native.dart';
import 'package:atelerix_flutter/src/atelerix_package.dart';
import 'package:atelerix_flutter/src/errors/errors_handler.dart';
import 'package:atelerix_flutter/src/model/error_model.dart';
import 'package:atelerix_flutter/src/notifications/notifications_handler.dart';
import 'package:atelerix_flutter/src/users/project_users.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Main Atelerix SDK class
///
/// Provides error reporting, user management, and optional notifications.
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize core SDK (errors, analytics)
///   Atelerix.init(
///     url: 'https://api.atelerix.dev',
///     apiKey: 'your-api-key',
///     projectId: 'your-project-id',
///     debugMode: true,
///     builder: () => runApp(MyApp()),
///   );
///   
///   // Optional: Initialize notifications when needed
///   await Atelerix.notifications.init();
/// }
/// ```
class Atelerix {
  // ============================================
  // Internal Dependencies
  // ============================================
  
  static final _native = AtelerixNative();
  static final _package = AtelerixPackage();
  static final _keys = AtelerixKeys();
  static final _errors = ErrorsHandler();
  static final _projectUsers = ProjectUsers();

  // ============================================
  // Public API - Notifications
  // ============================================
  
  /// Access notifications features (requires explicit initialization)
  ///
  /// Must call `await Atelerix.notifications.init()` before using:
  /// - `notifications.register()`
  /// - `notifications.requestPermissions()`
  /// - `notifications.checkPermissionStatus()`
  /// - `notifications.setOnNotificationReceived()`
  /// - `notifications.setOnNotificationTapped()`
  ///
  /// Example:
  /// ```dart
  /// // Initialize notifications
  /// await Atelerix.notifications.init();
  ///
  /// // Then use notification features
  /// await Atelerix.notifications.register();
  /// ```
  static final notifications = NotificationsManager();

  // ============================================
  // Core Initialization
  // ============================================

  /// Initialize the Atelerix SDK
  ///
  /// Sets up error monitoring and reporting. Does NOT initialize notifications.
  /// Call `Atelerix.notifications.init()` separately if you need push notifications.
  ///
  /// Parameters:
  /// - [url] - Your project URL (e.g., 'https://api.atelerix.dev')
  /// - [apiKey] - Your project API key from dashboard
  /// - [projectId] - Your project ID from dashboard
  /// - [builder] - Function containing `runApp(MyApp())`
  /// - [debugMode] - Enable debug logging (default: false)
  /// - [onError] - Optional custom error handler
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   Atelerix.init(
  ///     url: 'https://api.atelerix.dev',
  ///     apiKey: 'your-api-key',
  ///     projectId: 'your-project-id',
  ///     debugMode: true,
  ///     builder: () => runApp(MyApp()),
  ///     onError: (error) {
  ///       print('Custom error handler: ${error.message}');
  ///     },
  ///   );
  /// }
  /// ```
  static void init({
    required String url,
    required String apiKey,
    required String projectId,
    required void Function() builder,
    bool? debugMode,
    Function(ErrorModel details)? onError,
  }) {
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        // Step 1: Store configuration
        _keys.debug = debugMode ?? false;
        _keys.apiKey = apiKey;
        _keys.url = url;
        _keys.projectId = projectId;

        // Step 2: Retrieve app and device information
        await _package.getPackageDetails();
        await _native.getMobileDetails();

        // Step 3: Ping backend to register SDK
        await AtelerixInit().ping();

        // Step 4: Setup Flutter UI error handler
        FlutterError.onError = (FlutterErrorDetails details) {
          _errors.analyze(
            exception: details.exception.toString(),
            stack: details.stack ?? StackTrace.current,
          );
          if (onError != null && _errors.errorDetails != null) {
            onError(_errors.errorDetails!);
          }
        };

        // Step 5: Setup Dart platform error handler
        PlatformDispatcher.instance.onError = (error, stack) {
          if (_keys.debug) {
            debugPrint('[Atelerix] Platform error: $error\n$stack');
          }

          _errors.analyze(
            exception: error.toString(),
            stack: stack,
          );

          if (onError != null && _errors.errorDetails != null) {
            onError(_errors.errorDetails!);
          }

          return true; // Prevents app crash
        };

        // Step 6: Launch the app
        builder.call();
      } catch (e, stack) {
        if (_keys.debug) {
          debugPrint('[Atelerix] Initialization error: $e\n$stack');
        }
        // Still run the app even if init fails
        builder.call();
      }
    }, (Object error, StackTrace stack) {
      // Handle uncaught zone errors
      if (_keys.debug) {
        debugPrint('[Atelerix] Uncaught zone error: $error\n$stack');
      }

      _errors.analyze(
        exception: error.toString(),
        stack: stack,
      );

      if (onError != null && _errors.errorDetails != null) {
        onError(_errors.errorDetails!);
      }
    });
  }

  // ============================================
  // Error Reporting
  // ============================================

  /// Manually report an error to Atelerix
  ///
  /// Use this to send custom errors or exceptions to your dashboard.
  ///
  /// Parameters:
  /// - [error] - Error object or message
  /// - [stack] - Stack trace associated with the error
  /// - [bugType] - Optional bug classification
  /// - [bugSeverity] - Optional severity level
  /// - [metaData] - Optional additional context
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stack) {
  ///   await Atelerix.throwError(
  ///     e,
  ///     stack,
  ///     bugSeverity: BugSeverity.high,
  ///     metaData: {
  ///       'userId': '123',
  ///       'action': 'payment',
  ///       'amount': 100.0,
  ///     },
  ///   );
  /// }
  /// ```
  static Future<void> throwError(
    Object error,
    StackTrace stack, {
    BugType? bugType,
    BugSeverity? bugSeverity,
    Map<String, dynamic>? metaData,
  }) async {
    await ErrorsHandler().throwError(
      error,
      stack,
      bugType: bugType,
      bugSeverity: bugSeverity,
      metaData: metaData,
    );
  }

  // ============================================
  // User Management
  // ============================================

  /// Ensure user is registered with Atelerix
  ///
  /// Checks if user is already registered, if not, registers automatically.
  ///
  /// Returns `true` if user is registered or registration succeeds,
  /// `false` if registration fails.
  ///
  /// Example:
  /// ```dart
  /// void initializeApp() async {
  ///   bool registered = await Atelerix.ensureUserRegistered();
  ///   
  ///   if (registered) {
  ///     print('User registered: ${Atelerix.getUserId()}');
  ///   } else {
  ///     print('User registration failed');
  ///   }
  /// }
  /// ```
  static Future<bool> ensureUserRegistered() async {
    final isRegistered = await _projectUsers.checkAlreadyUserRegistered();
    
    if (isRegistered) {
      if (_keys.debug) {
        debugPrint('[Atelerix] User already registered: ${_keys.projectUser}');
      }
      return true;
    }
    
    if (_keys.debug) {
      debugPrint('[Atelerix] Registering user...');
    }
    
    final success = await _projectUsers.registerUser();
    
    if (_keys.debug) {
      if (success) {
        debugPrint('[Atelerix] User registered: ${_keys.projectUser}');
      } else {
        debugPrint('[Atelerix] User registration failed');
      }
    }
    
    return success;
  }

  /// Get current user ID
  ///
  /// Returns the user ID if registered, otherwise returns `null`.
  ///
  /// Example:
  /// ```dart
  /// String? userId = Atelerix.getUserId();
  /// if (userId != null) {
  ///   print('Current user: $userId');
  /// }
  /// ```
  static String? getUserId() {
    return _keys.projectUser;
  }

  /// Check if user is currently registered
  ///
  /// Returns `true` if user is registered, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (!Atelerix.isUserRegistered()) {
  ///   await Atelerix.ensureUserRegistered();
  /// }
  /// ```
  static bool isUserRegistered() {
    return _projectUsers.userRegistered;
  }
}