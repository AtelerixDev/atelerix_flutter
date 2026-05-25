import 'dart:convert';

import 'package:atelerix/atelerix.dart';
import 'package:atelerix/src/atelerix_backend.dart';
import 'package:atelerix/src/atelerix_keys.dart';
import 'package:atelerix/src/atelerix_native.dart';
import 'package:atelerix/src/atelerix_package.dart';
import 'package:atelerix/src/model/error_model.dart';
import 'package:atelerix/src/users/project_users.dart';
import 'package:atelerix/src/utils/enum/routes.dart';
import 'package:atelerix/src/utils/logger.dart';
import 'package:atelerix/src/utils/utils.dart';
import 'package:flutter/material.dart';

/// Singleton class responsible for capturing and reporting errors
///
/// This class handles both automatic error analysis and manual error reporting.
/// It integrates with the Atelerix backend to send error reports.
class ErrorsHandler extends ChangeNotifier {
  static final ErrorsHandler _instance = ErrorsHandler._internal();
  factory ErrorsHandler() => _instance;
  ErrorsHandler._internal();

  final AtelerixNative _atelerixNative = AtelerixNative();
  final AtelerixPackage _atelerixPackage = AtelerixPackage();
  final ProjectUsers _users = ProjectUsers();
  final AtelerixKeys _atelerixKeys = AtelerixKeys();
  final LoggerMsg _logger = LoggerMsg();

  ErrorModel? _errorDetails;
  ErrorModel? get errorDetails => _errorDetails;
  // Error code constants
  static const int _errorCodeUserNotRegistered = 5006;
  static const int _maxRetryAttempts = 3;

  /// Analyzes an error and creates an error model
  ///
  /// This method is called automatically when errors are caught by
  /// the error handlers set up in Atelerix.init()
  ///
  /// Parameters:
  /// - [stack] - The stack trace of the error
  /// - [exception] - The exception message
  void analyze({required StackTrace stack, required String exception}) {
    try {
      final List<String> stackTraceElements = getStackTraceElements(stack);
      _errorDetails = ErrorModel.fromJson({
        "issue": exception,
        "stack": stackTraceElements,
        "device": _atelerixNative.device?.toJson(),
        "app": _atelerixPackage.app.toJson(),
      });
      notifyListeners();
    } catch (e) {
      _logger.logError('Failed to analyze error', 'ERR_ANALYZE');
    }
  }

  /// Manually reports an error to the Atelerix backend
  ///
  /// This method sends error details to the backend and handles user
  /// re-registration if needed.
  ///
  /// Parameters:
  /// - [error] - The error object or message
  /// - [stack] - The stack trace
  /// - [bugType] - Optional bug classification
  /// - [bugSeverity] - Optional severity level
  /// - [metaData] - Optional additional metadata
  /// - [_retryCount] - Internal retry counter (don't use externally)
  Future<void> throwError(
    Object error,
    StackTrace stack, {
    BugType? bugType,
    BugSeverity? bugSeverity,
    Map<String, dynamic>? metaData,
    int retryCount = 0,
  }) async {
    try {
      final List<String> stackTraceElements = getStackTraceElements(stack);

      // Create error model for local storage/notification
      _errorDetails = ErrorModel.fromJson({
        "issue": error.toString(),
        "stack": stackTraceElements,
        "device": _atelerixNative.device?.toJson(),
        "app": _atelerixPackage.app.toJson(),
        if (metaData != null && metaData.isNotEmpty) "metadata": metaData,
        if (bugType != null) "type": bugType,
        if (bugSeverity != null) "severity": bugSeverity,
      });
      notifyListeners();

      // Send error to backend
      final data = await AtelerixBackend(
        data: {
          "issue": error.toString(),
          "stack": stackTraceElements,
          "device": jsonEncode(_atelerixNative.device?.toJson()),
          "app": jsonEncode(_atelerixPackage.app.toJson()),
          if (metaData != null && metaData.isNotEmpty) "metaData": metaData,
          if (bugType != null) "type": bugType.type,
          if (bugSeverity != null) "severity": bugSeverity.type,
        },
        header: {"app-user": _atelerixKeys.projectUser},
        route: Routes.sendBug,
      ).post();

      _logger.logNormal("Error sent to backend: ${data?['message'] ?? 'Success'}");

      // Handle user not registered error (5006)
      if (data != null &&
          data['errCode'] != null &&
          data["errCode"] == _errorCodeUserNotRegistered.toString()) {

        if (retryCount >= _maxRetryAttempts) {
          _logger.logError(
            'Max retry attempts reached for user registration',
            'ERR_MAX_RETRY',
          );
          return;
        }

        _logger.logNormal(
          "User ID not registered in project. Generating new user ID (attempt ${retryCount + 1}/$_maxRetryAttempts)",
        );

        await _users.deleteUser();
        await _users.registerUser();

        // Retry sending the error with incremented retry count
        await throwError(
          error,
          stack,
          bugType: bugType,
          bugSeverity: bugSeverity,
          metaData: metaData,
          retryCount: retryCount + 1,
        );
      }
    } catch (e) {
      _logger.logError(
        'Failed to send error to backend: $e',
        'ERR_SEND_FAILED',
      );
    }
  }
}
