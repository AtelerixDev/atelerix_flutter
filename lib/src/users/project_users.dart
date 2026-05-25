import 'package:atelerix/src/atelerix_backend.dart';
import 'package:atelerix/src/atelerix_keys.dart';
import 'package:atelerix/src/atelerix_package.dart';
import 'package:atelerix/src/utils/enum/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProjectUsers extends ChangeNotifier {
  // Singleton instance
  static final ProjectUsers _instance = ProjectUsers._internal();
  factory ProjectUsers() => _instance;
  ProjectUsers._internal();

  final _storage = const FlutterSecureStorage( aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),);
  final _atelerixPackage = AtelerixPackage();
  final _atelerixKeys = AtelerixKeys();

  final String _userKey = "atelerix_user";
  bool _userRegistered = false;

  /// Returns whether user is registered
  bool get userRegistered => _userRegistered;

  /// Registers a user if not already registered
  Future<bool> registerUser() async {
    final alreadyRegistered = await checkAlreadyUserRegistered();
    if (alreadyRegistered) return true;

    final response = await AtelerixBackend(
      data: {
        "projectApp": _atelerixKeys.projectConfig.id,
        "projectSlug": _atelerixKeys.projectId,
        "version": _atelerixPackage.version,
      },
      route: Routes.registerUser,
    ).post();
    if (response != null && response['user'] != null) {
      final userId = response['user'];
      await _storage.write(key: _userKey, value: userId);
      _atelerixKeys.projectUser = userId;
      _userRegistered = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Checks if user is already registered (from local storage)
  Future<bool> checkAlreadyUserRegistered() async {
    final data = await _storage.read(key: _userKey);
    _userRegistered = true;

    if (data == null) {
      _userRegistered = false;
      return false;
    }

    _atelerixKeys.projectUser = data;
    _userRegistered = true;
    return true;
  }

  /// Deletes the stored user from local storage
  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
    _userRegistered = false;
    notifyListeners();
  }
}