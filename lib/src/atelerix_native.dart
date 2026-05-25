import 'package:atelerix/src/utils/logger.dart';
import 'package:flutter/material.dart';

import '../atelerix_platform_interface.dart';
import 'model/error_model.dart';

/// A singleton class that provides device and platform information
///
/// This class interfaces with the native platform to retrieve
/// device details such as name, architecture, OS version, etc.
class AtelerixNative extends ChangeNotifier {
  static final AtelerixNative _instance = AtelerixNative._internal();
  factory AtelerixNative() => _instance;
  AtelerixNative._internal();

  final AtelerixPlatform data = AtelerixPlatform.instance;

  Device? _device;
  String? _deviceName;
  String? _arc;
  String? _countryCode;
  String? _osName;
  String? _osVersion;
  String? _timeZone;

  Device? get device => _device;
  String? get deviceName => _deviceName;
  String? get arc => _arc;
  String? get countryCode => _countryCode;
  String? get osName => _osName;
  String? get osVersion => _osVersion;
  String? get timeZone => _timeZone;

  /// Retrieves device and platform details from the native side
  ///
  /// Returns a [Device] object containing:
  /// - Device name
  /// - Architecture
  /// - Operating system name and version
  /// - Timezone
  /// - Country code
  Future<Device> getMobileDetails() async {
    _deviceName = await data.getDeviceName() ?? "Unknown";
    _arc = await data.getArch() ?? "Unknown";
    _countryCode = await data.getCountryCode() ?? "Unknown";
    _osName = await data.getPlatformName() ?? "Unknown";
    _osVersion = await data.getPlatformVersion() ?? "Unknown";
    _timeZone = await data.getTimeZone() ?? "Unknown";
    _device = Device.fromJson({
      "deviceName": deviceName,
      "arc": arc,
      "osName": osName,
      "osVersion": osVersion,
      "timeZone": timeZone,
      "countryCode": countryCode
    });
    LoggerMsg().logNormal("device details: ${_device?.toJson()}");
    notifyListeners();
    return _device ?? Device();
  }
}
