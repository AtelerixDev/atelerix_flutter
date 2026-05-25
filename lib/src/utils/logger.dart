import 'dart:developer';

import 'package:atelerix_flutter/src/atelerix_keys.dart';

/// Logger utility for Atelerix plugin
/// Provides debug logging functionality that respects the debug flag
class LoggerMsg {
  final AtelerixKeys _keys = AtelerixKeys();

  /// Logs a normal informational message
  /// Only logs when debug mode is enabled
  void logNormal(String message) {
    if (_keys.debug) {
      log(
        '[$message]',
        name: 'Atelerix 🦔',
        level: 800, // INFO level
      );
    }
  }

  /// Logs an error message with an error code
  /// Only logs when debug mode is enabled
  /// [message] - The error message to log
  /// [code] - The error code for reference
  void logError(String message, String code) {
    if (_keys.debug) {
      log(
        'ERROR: $message (Code: $code)\n'
        'Read more: https://atelerix.dev/docs/errors/#$code',
        name: 'Atelerix 🦔',
        level: 1000, // SEVERE level
      );
    }
  }

  /// Logs a warning message
  /// Only logs when debug mode is enabled
  void logWarning(String message) {
    if (_keys.debug) {
      log(
        'WARNING: $message',
        name: 'Atelerix 🦔',
        level: 900, // WARNING level
      );
    }
  }
}