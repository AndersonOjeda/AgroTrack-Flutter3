import 'dart:developer' as developer;

/// Servicio de logging centralizado para reemplazar print() statements
/// Sigue las mejores prácticas de Flutter para logging en producción
class LoggerService {
  static const String _appName = 'AgroTrack';
  
  /// Log de información general
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 800, // INFO level
      time: DateTime.now(),
    );
  }
  
  /// Log de advertencias
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 900, // WARNING level
      time: DateTime.now(),
    );
  }
  
  /// Log de errores
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
  
  /// Log de debug (solo en modo debug)
  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log(
        message,
        name: _appName,
        level: 700, // DEBUG level
        time: DateTime.now(),
      );
      return true;
    }());
  }
  
  /// Log de eventos críticos
  static void severe(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 1200, // SEVERE level
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}