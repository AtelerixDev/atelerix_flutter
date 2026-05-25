import 'package:atelerix/src/helper.dart';
import 'package:atelerix/src/utils/enum/routes.dart';

import 'atelerix_keys.dart';

/// Backend API wrapper for Atelerix
///
/// This class provides a simple interface for making HTTP requests
/// to the Atelerix backend API with automatic authentication.
class AtelerixBackend {
  final AtelerixHelper _helper = AtelerixHelper();
  final AtelerixKeys _keys = AtelerixKeys();

  AtelerixBackend({
    required this.route,
    this.data,
    this.header,
    this.queryParams,
  });

  final Routes route;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? header;
  final Map<String, dynamic>? queryParams;  
  /// Sends a POST request to the specified route
  ///
  /// Returns the response data as a Map
  Future<Map<String, dynamic>?> post() async {
    return await _helper.post(
      route: route.route,
      queryParams: queryParams,
      data: data ?? {},
      headers: {
        "atelerix-key": _keys.apiKey,
        ...header ?? {}
      },
    );
  }

  /// Sends a GET request to the specified route
  ///
  /// Returns the response data as a Map
  Future<Map<String, dynamic>?> get() async {
    return await _helper.get(
      route: route.route,
      queryParams: queryParams,
      headers: {
        ...header ?? {},
        "atelerix-key": _keys.apiKey,
      },
    );
  }
}