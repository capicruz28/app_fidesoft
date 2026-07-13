class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // URL fija del servidor central (NUNCA cambia)
  static const String urlCentral = 'https://fidesoft.stnsoluciones.pe/api/v1';

  // URL dinámica obtenida según el RUC del cliente (cambia por cliente)
  String? _baseUrl;

  String get baseUrl {
    if (_baseUrl == null) throw Exception('AppConfig no inicializado');
    return _baseUrl!;
  }

  void setBaseUrl(String url) => _baseUrl = url;
  bool get isInitialized => _baseUrl != null;
}

