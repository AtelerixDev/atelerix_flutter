import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'atelerix_method_channel.dart';

abstract class AtelerixPlatform extends PlatformInterface {
  /// Constructs a AtelerixPlatform.
  AtelerixPlatform() : super(token: _token);

  static final Object _token = Object();

  static AtelerixPlatform _instance = MethodChannelAtelerix();

  /// The default instance of [AtelerixPlatform] to use.
  ///
  /// Defaults to [MethodChannelAtelerix].
  static AtelerixPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AtelerixPlatform] when
  /// they register themselves.
  static set instance(AtelerixPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
  Future<String?> getPlatformName() {
    throw UnimplementedError('getPlatformName() has not been implemented.');
  }
  Future<String?> getDeviceName() {
    throw UnimplementedError('getDeviceName() has not been implemented.');
  }

  Future<String?> getMemorySize() {
    throw UnimplementedError('getMemorySize() has not been implemented.');
  }

  Future<String?> getCountryCode() {
    throw UnimplementedError('getCountryCode() has not been implemented.');
  }

  Future<String?> getTimeZone() {
    throw UnimplementedError('getTimeZone() has not been implemented.');
  }
  Future<String?> getArch() {
    throw UnimplementedError('getArch() has not been implemented.');
  }

  Future<String?> deviceToken() {
    throw UnimplementedError('getDeviceToken() has not been implemented.');
  }

  Future<void> registerDevice({
    required String apiKey,
    String? userId,
    String? serverUrl,
  }) {
    throw UnimplementedError('registerDevice() has not been implemented.');
  }

  Future<bool> requestNotificationPermissions() {
    throw UnimplementedError('requestNotificationPermissions() has not been implemented.');
  }

  Future<String?> checkNotificationPermissionStatus() {
    throw UnimplementedError('checkNotificationPermissionStatus() has not been implemented.');
  }
  Future<void> clearBadge() {
    throw UnimplementedError('clearBadge() has not been implemented.');
  }
  Future<void> initializeFCM({
    required String senderId,
  }) {
    throw UnimplementedError('initializeFCM() has not been implemented.');
  }

  Future<bool> isGoogleServicesAvailable() {
    throw UnimplementedError('isGoogleServicesAvailable() has not been implemented.');
  }
}
