import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atelerix/atelerix_platform_interface.dart';
import 'package:atelerix/src/atelerix_backend.dart';
import 'package:atelerix/src/atelerix_keys.dart';
import 'package:atelerix/src/atelerix_native.dart';
import 'package:atelerix/src/atelerix_package.dart';
import 'package:atelerix/src/model/ping_model.dart';
import 'package:atelerix/src/users/project_users.dart';
import 'package:atelerix/src/utils/enum/routes.dart';
import 'package:atelerix/src/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AtelerixInit extends ChangeNotifier {
  // Singleton
  static final AtelerixInit _instance = AtelerixInit._internal();
  factory AtelerixInit() => _instance;
  AtelerixInit._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
  final _atelerixNative = AtelerixNative();
  final _atelerixPackage = AtelerixPackage();
  final _atelerixKeys = AtelerixKeys();
  final _projectUsers = ProjectUsers();

  final String _configKey = "atelerix_config";
  bool _configured = false;

  /// Returns whether the app is configured
  bool get configured => _configured;

  /// Performs ping/init request to verify app is connected to Atelerix backend
  Future<void> ping() async {
    // await _storage.deleteAll();
    final alreadyConfigured = await _checkAlreadyConfigured();
    LoggerMsg().logNormal("alreadyConfigured: $alreadyConfigured");
    if (!alreadyConfigured) {
      final os = await getOs();
      final response = await AtelerixBackend(
        header: {
          "appID": _atelerixPackage.packageName,
          "projectID": _atelerixKeys.projectId,
          "platform": _atelerixNative.device?.osName ?? "",
          "os": os,
        },
        route: Routes.initApp,
      ).get();

      if (response != null && response['data'] != null) {
        LoggerMsg().logNormal("App configured via ping");
        final pingData = response['data'];
        await _storage.write(key: _configKey, value: jsonEncode(pingData));

        final model = PingModel.fromJson(pingData);
        _atelerixKeys.projectConfig = model;
        _configured = true;

        LoggerMsg().logNormal("App configured via ping");
        notifyListeners();
      }
    }
    // Register user if app is configured
    if (_configured) {
      await _projectUsers.registerUser();
    }
    // await AtelerixPlatform.instance.clearBadge();
  }

  /// Checks if the app has already been configured (locally stored)
  Future<bool> _checkAlreadyConfigured() async {
    final data = await _storage.read(key: _configKey);
    if (data == null) return false;
    final jsonData = jsonDecode(data);
    final json = PingModel.fromJson(jsonData);
    final device = await _atelerixNative.getMobileDetails();
    final package = await _atelerixPackage.getPackageDetails();

    final isValid =
        (device.osName?.toLowerCase() ?? "").contains(json.platform ?? "") &&
            package.package == json.appId &&
            _atelerixKeys.projectId == json.projectSlug;
    if (isValid) {
      _atelerixKeys.projectConfig = json;
      _configured = true;
      LoggerMsg().logNormal("App already configured locally");
      notifyListeners();
      return true;
    }

    return false;
  }

  FutureOr<String> getOs() async {
    if (Platform.isIOS) return "ios";
    if (Platform.isAndroid) {
      final isAvailable =
          await AtelerixPlatform.instance.isGoogleServicesAvailable();
      if (isAvailable) return "android";
      return "harmony";
    }
    return "unknown";
  }
}
