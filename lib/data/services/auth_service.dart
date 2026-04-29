// lib/data/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';
import '../models/user_profile_model.dart';
import '../../core/auth/token_storage.dart';
import '../../core/network/api_client.dart';

class AuthService {
  // URL del servidor de producción
  // Nota: 10.0.2.2 es la IP especial del emulador Android para acceder al localhost del host
  // Para pruebas locales, usar: http://10.0.2.2:8000/api/v1
  final String baseUrlNuevo = 'http://170.231.171.118:9098/api/v1';

  /// Login - Usa el nuevo endpoint OAuth2
  Future<UserModel> login({
    required String ruc,
    required String cusuar,
    required String dclave,
  }) async {
    try {
      // El endpoint usa OAuth2PasswordRequestForm con form-urlencoded
      final response = await http.post(
        Uri.parse('$baseUrlNuevo/auth/login/'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'username': cusuar, // Puede ser nombre de usuario o email
          'password': dclave,
        },
      );

      if (response.statusCode == 200) {
        final tokenModel = authTokenModelFromJson(response.body);

        // Guardar tokens según contrato:
        // - access_token: memoria (y persistimos para auto-login)
        // - refresh_token: secure storage
        await TokenStorage.setAccessToken(tokenModel.accessToken);
        await TokenStorage.setRefreshToken(tokenModel.refreshToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token_type', tokenModel.tokenType);

        // Guardar los roles del usuario si están disponibles
        if (tokenModel.userData?.roles != null) {
          await prefs.setStringList('user_roles', tokenModel.userData!.roles!);
        }
        // Guardar correo del usuario si está disponible
        if (tokenModel.userData?.correo != null &&
            tokenModel.userData!.correo!.isNotEmpty) {
          await prefs.setString('user_email', tokenModel.userData!.correo!);
        }

        // Convertir la respuesta del nuevo endpoint al formato UserModel
        // Si hay datos del usuario en la respuesta, usarlos
        if (tokenModel.userData != null) {
          return UserModel(
            strMensaje: '', // Sin mensaje = éxito
            strDato1:
                tokenModel.userData!.codigoTrabajadorExterno ??
                tokenModel.userData!.nombreUsuario ??
                cusuar,
            strDato2:
                '${tokenModel.userData!.nombre ?? ''} ${tokenModel.userData!.apellido ?? ''}'
                    .trim(),
            strDato3: tokenModel.userData!.usuarioId?.toString() ?? '0',
            intDato4: tokenModel.userData!.usuarioId ?? 0,
          );
        } else {
          // Si no vienen datos del usuario, hacer una llamada a /auth/me/ para obtenerlos
          return await _obtenerDatosUsuario(tokenModel.accessToken);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al autenticar. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener datos del usuario autenticado usando el token
  Future<UserModel> _obtenerDatosUsuario(String accessToken) async {
    try {
      await TokenStorage.setAccessToken(accessToken);
      final response = await ApiClient.get(
        '/auth/me/',
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = UserData.fromJson(json.decode(response.body));

        // Guardar los roles del usuario si están disponibles
        final prefs = await SharedPreferences.getInstance();
        if (userData.roles != null) {
          await prefs.setStringList('user_roles', userData.roles!);
        }
        // Guardar correo del usuario
        if (userData.correo != null && userData.correo!.isNotEmpty) {
          await prefs.setString('user_email', userData.correo!);
        }

        return UserModel(
          strMensaje: '',
          strDato1:
              userData.codigoTrabajadorExterno ?? userData.nombreUsuario ?? '',
          strDato2: '${userData.nombre ?? ''} ${userData.apellido ?? ''}'
              .trim(),
          strDato3: userData.usuarioId?.toString() ?? '0',
          intDato4: userData.usuarioId ?? 0,
        );
      } else {
        throw Exception('Error al obtener datos del usuario');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  /// Obtener el token guardado
  Future<String?> getAccessToken() async {
    return TokenStorage.getAccessToken();
  }

  /// Guardar credenciales para "Recordarme"
  Future<void> saveCredentials({
    required String ruc,
    required String usuario,
    required String clave,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ruc', ruc);
    await prefs.setString('saved_usuario', usuario);
    await prefs.setString('saved_clave', clave);
    await prefs.setBool('remember_me', true);
  }

  /// Obtener credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (!rememberMe) return null;

    final ruc = prefs.getString('saved_ruc');
    final usuario = prefs.getString('saved_usuario');
    final clave = prefs.getString('saved_clave');

    if (ruc != null && usuario != null && clave != null) {
      return {'ruc': ruc, 'usuario': usuario, 'clave': clave};
    }

    return null;
  }

  /// Limpiar credenciales guardadas
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_ruc');
    await prefs.remove('saved_usuario');
    await prefs.remove('saved_clave');
    await prefs.setBool('remember_me', false);
  }

  /// Verificar si hay un token válido y hacer auto-login
  Future<UserModel?> autoLogin() async {
    try {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Verificar/renovar sesión automáticamente usando ApiClient (refresh + retry)
      final response = await ApiClient.get(
        '/auth/me/',
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = UserData.fromJson(json.decode(response.body));

        // Guardar correo del usuario si está disponible
        final prefs = await SharedPreferences.getInstance();
        if (userData.correo != null && userData.correo!.isNotEmpty) {
          await prefs.setString('user_email', userData.correo!);
        }

        return UserModel(
          strMensaje: '',
          strDato1:
              userData.codigoTrabajadorExterno ?? userData.nombreUsuario ?? '',
          strDato2: '${userData.nombre ?? ''} ${userData.apellido ?? ''}'
              .trim(),
          strDato3: userData.usuarioId?.toString() ?? '0',
          intDato4: userData.usuarioId ?? 0,
        );
      } else {
        // Token inválido, limpiar
        await logout();
        return null;
      }
    } catch (e) {
      print('Error en auto-login: $e');
      // Si hay error, limpiar token y credenciales
      await logout();
      return null;
    }
  }

  /// Limpiar el token (logout)
  Future<void> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    try {
      await http.post(
        Uri.parse('$baseUrlNuevo/auth/logout/'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: refreshToken != null && refreshToken.isNotEmpty
            ? jsonEncode({'refresh_token': refreshToken})
            : null,
      );
    } catch (_) {
      // Ignorar errores de red al cerrar sesión; igual limpiamos localmente.
    } finally {
      await TokenStorage.clearAllTokens();
      // NO limpiar credenciales guardadas aquí, solo se limpian si el usuario desmarca "Recordarme"
    }
  }

  /// Verificar si el usuario tiene un rol específico
  static Future<bool> tieneRol(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('user_roles') ?? [];
    return roles.contains(rol);
  }

  /// Obtener perfil completo del usuario autenticado
  Future<UserProfileModel> obtenerPerfilUsuario() async {
    try {
      final response = await ApiClient.get(
        '/auth/me/',
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ?? 'Error al obtener perfil del usuario',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener perfil del usuario: $e');
    }
  }

  /// Cambiar contraseña del usuario
  Future<Map<String, dynamic>> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    try {
      final response = await ApiClient.post(
        '/auth/change-password/',
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contrasena_actual': contrasenaActual,
          'nueva_contrasena': nuevaContrasena,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 400) {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ?? 'La contraseña actual es incorrecta',
        );
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'La nueva contraseña no cumple con los requisitos',
        );
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  /// Validar formato de contraseña
  static String? validarContrasena(String contrasena) {
    if (contrasena.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!contrasena.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!contrasena.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una minúscula';
    }
    if (!contrasena.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  /// Verificar si el usuario es aprobador usando el endpoint específico
  static Future<bool> esAprobador() async {
    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null) {
        print('No hay token de autenticación');
        return false;
      }

      // Usar el endpoint específico para verificar si es aprobador
      final response = await ApiClient.get(
        '/vacaciones/verificar-aprobador',
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final esAprobador = decoded['es_aprobador'] ?? false;
        print('Usuario es aprobador: $esAprobador');
        return esAprobador as bool;
      } else {
        print('Error al verificar aprobador: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al verificar aprobador por endpoint: $e');
      return false;
    }
  }
}
