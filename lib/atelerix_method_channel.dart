import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'atelerix_platform_interface.dart';

/// An implementation of [AtelerixPlatform] that uses method channels.
class MethodChannelAtelerix extends AtelerixPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('atelerix/system');
  final notificationsChannel = const MethodChannel('atelerix/notifications');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> getPlatformName() async {
    final version = await methodChannel.invokeMethod<String>('getSystemName');
    return version;
  }

  @override
  Future<String?> getMemorySize() async {
    final version = await methodChannel.invokeMethod<String>('getFreeMemory');
    return version;
  }

  @override
  Future<String?> getDeviceName() async {
    final version = await methodChannel.invokeMethod<String>('getDeviceName');
    return version;
  }

  @override
  Future<String?> getCountryCode() async {
    final version = await methodChannel.invokeMethod<String>('getCountryCode');
    return version;
  }

  @override
  Future<String?> getTimeZone() async {
    final version = await methodChannel.invokeMethod<String>('getTimeZone');
    return version;
  }

  @override
  Future<String?> getArch() async {
    return null;
  
    // final version = await methodChannel.invokeMethod<String>('getArch');
    // return version;
  }

  @override
  Future<String?> deviceToken() async {
    final version =
        await notificationsChannel.invokeMethod<String>('getDeviceToken');
    return version;
  }

  @override
  Future<void> registerDevice({
    required String apiKey,
    String? userId,
    String? serverUrl,
  }) async {
    await methodChannel.invokeMethod('register', {
      'apiKey': apiKey,
      'userId': userId,
      'serverUrl': serverUrl,
    });
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    try {
      final result =
          await notificationsChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> checkNotificationPermissionStatus() async {
    final status = await notificationsChannel
        .invokeMethod<String>('checkNotificationPermission');
    return status;
  }

  @override
  Future<void> clearBadge() async {
    await notificationsChannel.invokeMethod<void>('clearBadge');
  }

  @override
  Future<void> initializeFCM({required String senderId}) async {
    await notificationsChannel
        .invokeMethod('initializeFCM', {'senderId': senderId});
  }

  @override
  Future<bool> isGoogleServicesAvailable() async {
    if (Platform.isAndroid) {
      final result =
          await methodChannel.invokeMethod<bool>('isGoogleServicesAvailable');
      return result ?? false;
    }else{
      return false;
    }
  }
}
