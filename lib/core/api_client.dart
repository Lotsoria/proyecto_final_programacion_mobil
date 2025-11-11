import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Cliente HTTP centralizado basado en Dio con manejo de cookies de sesión.
///
/// - Base URL: selecciona automáticamente `10.0.2.2` para Android emulador y
///   `127.0.0.1` para otros entornos de desarrollo.
/// - Autenticación: la API establece cookie `sessionid` tras `POST login/`.
///   Este cliente reenvía la cookie automáticamente en las siguientes peticiones.
class ApiClient {
  /// Instancia singleton para uso global.
  static final ApiClient I = ApiClient._();

  /// Cliente Dio configurado con baseUrl, headers y manejo de cookies.
  late final Dio dio;

  /// Almacén de cookies en memoria. Para persistencia, usar `PersistCookieJar`.
  late final CookieJar _cookieJar;

  ApiClient._() {
    final baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:8000/api/'
        : 'http://127.0.0.1:8000/api/';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        // Considerar válidos los estados < 500 para poder mapear errores 400/401.
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    _cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(_cookieJar));
  }

  /// Verifica si existe una cookie `sessionid` cargada (sesión iniciada).
  ///
  /// Nota: algunas implementaciones de `CookieJar` pueden resolver cookies de
  /// forma asíncrona, por lo que este método es `Future<bool>`.
  Future<bool> hasSession() async {
    final uri = Uri.parse(dio.options.baseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    return cookies.any(
      (c) => c.name.toLowerCase() == 'sessionid' && c.value.isNotEmpty,
    );
  }

  /// Realiza POST y devuelve el JSON como `Map<String,dynamic>` o lanza excepción
  /// con el mensaje de error si la API responde `{ "error": "..." }`.
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final res = await dio.post(path, data: data);
    return _unwrap(res);
  }

  /// Realiza GET y devuelve el JSON como `Map<String,dynamic>` o lanza excepción
  /// con el mensaje de error si la API responde `{ "error": "..." }`.
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await dio.get(path, queryParameters: query);
    return _unwrap(res);
  }

  /// Realiza PUT y devuelve el JSON como `Map<String,dynamic>` o lanza excepción
  /// con el mensaje de error si la API responde `{ "error": "..." }`.
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    final res = await dio.put(path, data: data);
    return _unwrap(res);
  }

  /// Extrae el cuerpo válido o lanza excepción con detalle de error.
  Map<String, dynamic> _unwrap(Response res) {
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(res.data);
    }
    if (res.data is Map && (res.data as Map).containsKey('error')) {
      throw Exception((res.data as Map)['error']);
    }
    throw Exception('Error ${res.statusCode}: ${res.statusMessage ?? 'desconocido'}');
  }
}
