import 'package:atelerix/src/model/ping_model.dart';
import 'package:flutter/material.dart';

class AtelerixKeys extends ChangeNotifier {
  // Singleton instance
  static final AtelerixKeys _instance = AtelerixKeys._internal();

  /// Factory constructor to return the singleton instance.
  factory AtelerixKeys() {
    return _instance;
  }

  /// Private internal constructor for singleton pattern.
  AtelerixKeys._internal();
  late String _url;
  late bool _debug;
  late String _apiKey;
  late String _projectId;
  late PingModel _projectConfig;
  String? _deviceToken;
  String? get deviceToken => _deviceToken;
   String? _projectUser;
  String get url => _url;
  bool get debug => _debug;

  String get apiKey => _apiKey;

  String get projectId => _projectId;
  PingModel get projectConfig => _projectConfig;
  String? get projectUser => _projectUser;
  

  set deviceToken(String? deviceToken) {
    _deviceToken = deviceToken;
    notifyListeners();
  }

  set apiKey(String apiKey) {
    _apiKey = apiKey;
    notifyListeners();
  }

  set url(String url) {
    _url = url;
    notifyListeners();
  }

  set projectId(String projectId) {
    _projectId = projectId;
    notifyListeners();
  }

  set projectConfig(PingModel data) {
    _projectConfig = data;
    notifyListeners();
  }

    set projectUser(String? data) {
    _projectUser = data;
    notifyListeners();
  }

  /// Set the debug mode
  set debug(bool value) {
    _debug = value;
    notifyListeners();
  }
}
