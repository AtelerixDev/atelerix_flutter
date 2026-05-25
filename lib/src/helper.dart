import 'dart:io';

import 'package:atelerix_flutter/src/atelerix_keys.dart';
import 'package:atelerix_flutter/src/utils/logger.dart';
import 'package:dio/dio.dart';

class AtelerixHelper {
  late final Dio _dio;
  final AtelerixKeys _keys = AtelerixKeys();
  final LoggerMsg _logger = LoggerMsg();

  AtelerixHelper() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _keys.url,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.addAll([
        _LoggingInterceptor(_logger),
        _ErrorInterceptor(_logger),
      ]);
  }

  /// Sends a POST request to the Atelerix backend.
  ///
  /// [data] is the request body.
  /// [headers] are additional headers (e.g., authentication).
  /// [route] is the endpoint path, e.g., `projects/init`.
  Future<Map<String, dynamic>?> post({
    required Map<String, dynamic> data,
    Map<String, String>? headers,
    required String route,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        route,
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Sends a GET request to the Atelerix backend.
  ///
  /// [queryParams] are optional query parameters.
  /// [headers] are additional headers (e.g., authentication).
  /// [route] is the endpoint path, e.g., `projects/info`.
  Future<Map<String, dynamic>?> get({
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    required String route,
    CancelToken? cancelToken,
  }) async {

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        route,
        queryParameters: queryParams,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Sends a PUT request to the Atelerix backend.
  Future<Map<String, dynamic>?> put({
    required Map<String, dynamic> data,
    Map<String, String>? headers,
    required String route,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        route,
        data: data,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Sends a PATCH request to the Atelerix backend.
  Future<Map<String, dynamic>?> patch({
    required Map<String, dynamic> data,
    Map<String, String>? headers,
    required String route,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        route,
        data: data,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Sends a DELETE request to the Atelerix backend.
  Future<Map<String, dynamic>?> delete({
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    required String route,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        route,
        data: data,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Uploads a file with multipart/form-data
  Future<Map<String, dynamic>?> upload({
    required String route,
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        route,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Downloads a file
  Future<bool> download({
    required String route,
    required String savePath,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        route,
        savePath,
        queryParameters: queryParams,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      _logger.logNormal('File downloaded successfully');
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  /// Handles successful responses
  Map<String, dynamic>? _handleResponse(Response<Map<String, dynamic>> response) {
    final data = response.data;
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      _logger.logNormal(data?['message'] ?? 'Success');
      return data;
    } else {
      _logger.logError(
        data?['message'].toString() ?? 'Unknown error',
        data?['errCode']?.toString() ?? statusCode.toString(),
      );
      return data;
    }
  }

  /// Handles Dio errors
  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _logger.logError('Connection timeout', 'TIMEOUT');
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        _logger.logError(
          data is Map ? (data['message'] ?? 'Bad response') : 'Bad response',
          error.response?.statusCode.toString() ?? 'UNKNOWN',
        );
        break;
      case DioExceptionType.cancel:
        _logger.logNormal('Request cancelled');
        break;
      case DioExceptionType.connectionError:
        _logger.logError('Connection error', 'NO_INTERNET');
        break;
      case DioExceptionType.badCertificate:
        _logger.logError('Certificate error', 'CERT_ERROR');
        break;
      case DioExceptionType.unknown:
        _logger.logError('Unknown error', error.message ?? 'UNKNOWN');
        break;
    }
  }

  /// Closes the Dio instance
  void dispose() {
    _dio.close();
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  final LoggerMsg _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.logNormal('→ ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.logNormal('← ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.logError(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}',
      err.response?.statusCode.toString() ?? 'ERROR',
    );
    super.onError(err, handler);
  }
}

/// Error interceptor for retry logic
class _ErrorInterceptor extends Interceptor {
  final LoggerMsg _logger;
  static const maxRetries = 3;

  _ErrorInterceptor(this._logger);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retries = err.requestOptions.extra['retries'] as int? ?? 0;

      if (retries < maxRetries) {
        _logger.logNormal('Retrying request (${retries + 1}/$maxRetries)');
        err.requestOptions.extra['retries'] = retries + 1;

        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return super.onError(err, handler);
        }
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}