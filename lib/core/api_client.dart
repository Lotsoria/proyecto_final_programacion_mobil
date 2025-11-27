import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiClient {
  /// Instancia singleton de uso global.
  static final ApiClient I = ApiClient._();

  /// Cliente Dio configurado con baseUrl, headers y manejo de cookies.
  late final Dio dio;

  /// Almacen de cookies en memoria; para persistir usar `PersistCookieJar`.
  late final CookieJar _cookieJar;

  ApiClient._() {
    final baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:8000/api/'
        : 'http://127.0.0.1:8000/api/';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    _cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(_cookieJar));
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Retorna true si hay una cookie de sesion cargada.
  Future<bool> hasSession() async {
    final uri = Uri.parse(dio.options.baseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    return cookies.any(
      (c) => c.name.toLowerCase() == 'sessionid' && c.value.isNotEmpty,
    );
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final res = await dio.post(path, data: data);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await dio.get(path, queryParameters: query);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) async {
    final res = await dio.patch(path, data: data);
    return _unwrap(res);
  }

  /// DELETE acepta 200/204, el resto lanza una excepcion con el detalle.
  Future<void> delete(String path) async {
    final res = await dio.delete(path);
    if (res.statusCode == 200 || res.statusCode == 204) return;

    if (res.data is Map && (res.data as Map).containsKey('error')) {
      final msg = (res.data as Map)['error'];
      throw Exception('[DELETE] ${res.requestOptions.uri} -> ${res.statusCode}: $msg');
    }

    throw Exception(
      '[DELETE] ${res.requestOptions.uri} -> ${res.statusCode}: ${res.statusMessage ?? 'desconocido'}',
    );
  }

  /// Extrae el cuerpo de respuesta valido o lanza una excepcion describiendo el error.
  Map<String, dynamic> _unwrap(Response res) {
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(res.data);
    }

    if (res.data is Map && (res.data as Map).containsKey('error')) {
      final msg = (res.data as Map)['error'];
      throw Exception('[${res.requestOptions.method}] ${res.requestOptions.uri} -> ${res.statusCode}: $msg');
    }

    throw Exception(
      '[${res.requestOptions.method}] ${res.requestOptions.uri} -> ${res.statusCode}: ${res.statusMessage ?? 'desconocido'}',
    );
  }
}
