import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'app_config.dart';

class ConnectionService {
  static const String _systemUsername = 'admin';
  static const String _systemPassword = 'password123';

  static const Duration _timeout = Duration(seconds: 20);

  http.Client _createHttpClient() {
    final io = HttpClient()
      ..idleTimeout = const Duration(seconds: 10)
      ..connectionTimeout = _timeout;
    return IOClient(io);
  }

  Future<String> obtenerBaseUrl(String ruc) async {
    final jwt = await _loginSistema();
    return _buscarConexion(ruc: ruc, jwt: jwt);
  }

  Future<String> _loginSistema() async {
    final client = _createHttpClient();
    try {
      final response = await _postFormWithRedirects(
        client,
        Uri.parse('${AppConfig.urlCentral}/auth/login/'),
        body: const <String, String>{
          'username': _systemUsername,
          'password': _systemPassword,
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        final msg =
            _tryReadDetail(response.body) ??
            'No se pudo autenticar con el servidor central. Código: ${response.statusCode}';
        throw Exception(msg);
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida del servidor central.');
      }

      final accessToken = decoded['access_token']?.toString() ?? '';
      if (accessToken.isEmpty) {
        throw Exception('No se recibió token del servidor central.');
      }
      return accessToken;
    } on http.ClientException catch (e) {
      if (e.message.toLowerCase().contains('connection closed')) {
        throw Exception(
          'No se pudo conectar al servidor central (conexión cerrada durante la respuesta). '
          'Esto suele indicar un problema de TLS/SSL del servidor (renegociación).',
        );
      }
      throw Exception('No se pudo verificar el cliente: $e');
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado al conectar con el servidor central. Verifique su conexión a internet.',
      );
    } catch (e) {
      throw Exception('No se pudo verificar el cliente: $e');
    } finally {
      client.close();
    }
  }

  Future<String> _buscarConexion({
    required String ruc,
    required String jwt,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '${AppConfig.urlCentral}/conexion/buscar',
      ).replace(queryParameters: <String, String>{'ruc': ruc, 'app': 'mobile'});

      final response = await _getWithRedirects(
        client,
        uri,
        headers: <String, String>{'Authorization': 'Bearer $jwt'},
      ).timeout(_timeout);

      if (response.statusCode == 404) {
        throw Exception('No se encontró configuración para el RUC ingresado.');
      }
      if (response.statusCode == 403) {
        throw Exception(
          'Acceso denegado al consultar la conexión del cliente.',
        );
      }
      if (response.statusCode == 401) {
        throw Exception(
          'Sesión inválida al consultar la conexión del cliente.',
        );
      }
      if (response.statusCode != 200) {
        final msg =
            _tryReadDetail(response.body) ??
            'Error al consultar la conexión. Código: ${response.statusCode}';
        throw Exception(msg);
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida al consultar conexión.');
      }

      final conexiones = decoded['conexiones'];
      if (conexiones is! List || conexiones.isEmpty) {
        throw Exception('No hay conexiones disponibles para el cliente.');
      }

      Map<String, dynamic>? principal;
      for (final item in conexiones) {
        if (item is Map<String, dynamic> && item['es_principal'] == true) {
          principal = item;
          break;
        }
      }
      principal ??= conexiones.first is Map<String, dynamic>
          ? conexiones.first as Map<String, dynamic>
          : null;

      final baseUrl = principal?['base_url']?.toString() ?? '';
      if (baseUrl.isEmpty) {
        throw Exception('La conexión del cliente no contiene base_url.');
      }
      return baseUrl;
    } catch (e) {
      throw Exception('No se pudo verificar el cliente: $e');
    } finally {
      client.close();
    }
  }

  Future<http.Response> _getWithRedirects(
    http.Client client,
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    Uri current = uri;
    for (int i = 0; i < 5; i++) {
      final request = http.Request('GET', current)
        ..followRedirects = false
        ..headers.addAll(headers);

      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 303 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) return response;
        current = current.resolve(location);
        continue;
      }

      return response;
    }

    throw Exception('Demasiados redirects al consultar la conexión.');
  }

  Future<http.Response> _postFormWithRedirects(
    http.Client client,
    Uri uri, {
    required Map<String, String> body,
  }) async {
    final request = http.Request('POST', uri)
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..headers['Connection'] = 'close'
      ..bodyFields = body;

    final streamed = await client.send(request);
    return http.Response.fromStream(streamed);
  }

  String? _tryReadDetail(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail']?.toString();
        if (detail != null && detail.trim().isNotEmpty) return detail;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
