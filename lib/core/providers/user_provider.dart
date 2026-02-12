// lib/core/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String _currentRUC = ''; // Almacenará el RUC de la empresa
  String _userEmail = ''; // Correo del usuario
  List<String> _roles = [];

  UserModel? get currentUser => _currentUser;
  String get currentRUC => _currentRUC;
  String get userEmail => _userEmail;
  List<String> get roles => _roles;
  
  // Getter para el nombre del usuario (usado en el Drawer)
  String get userName => _currentUser?.strDato2 ?? 'Usuario General'; 
  
  // Getter para el correo del usuario (usado en el Drawer)
  String get email => _userEmail.isNotEmpty ? _userEmail : 'usuario@fidesoft.com';
  
  // Verificar si el usuario es aprobador
  Future<bool> esAprobador() async {
    return await AuthService.esAprobador();
  }
  
  // Verificar si el usuario tiene un rol específico
  Future<bool> tieneRol(String rol) async {
    return await AuthService.tieneRol(rol);
  }

  // Método para establecer el usuario y el RUC al iniciar sesión
  void setUser(UserModel user, String ruc, {String? email}) async {
    _currentUser = user;
    _currentRUC = ruc;
    if (email != null) {
      _userEmail = email;
    }
    
    // Cargar roles desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _roles = prefs.getStringList('user_roles') ?? [];
    
    // Si no hay email guardado, intentar obtenerlo de SharedPreferences
    if (_userEmail.isEmpty) {
      _userEmail = prefs.getString('user_email') ?? '';
    }
    
    notifyListeners();
  }

  // Método para actualizar el correo del usuario
  Future<void> setUserEmail(String email) async {
    _userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentRUC = '';
    _userEmail = '';
    _roles = [];
    notifyListeners();
  }
}