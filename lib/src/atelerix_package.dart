import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'model/error_model.dart';

/// Singleton class for retrieving application package information
///
/// This class provides access to app metadata such as name, version,
/// package name, and build number.
class AtelerixPackage extends ChangeNotifier {
  static final AtelerixPackage _instance = AtelerixPackage._internal();
  factory AtelerixPackage() => _instance;
  AtelerixPackage._internal();

  late App _app;
  late PackageInfo packageInfo;
  late String _appName;
  late String _packageName;
  late String _version;
  late String _buildNumber;

  App get app => _app;
  String get appName => _appName;
  String get packageName => _packageName;
  String get version => _version;
  String get buildNumber => _buildNumber;

  /// Retrieves package details from the platform
  ///
  /// Returns an [App] object containing:
  /// - Application name
  /// - Package name
  /// - Version
  /// - Build number
  Future<App> getPackageDetails() async {
    packageInfo = await PackageInfo.fromPlatform();
    _appName = packageInfo.appName;
    _packageName = packageInfo.packageName;
    _version = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;
    _app = App.fromJson({
      "name": appName,
      "package": packageName,
      "version": version,
      "buildNo": buildNumber
    });
    notifyListeners();
    return _app;
  }
}
