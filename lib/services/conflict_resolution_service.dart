import '../models/user_model.dart';

enum ConflictResolutionStrategy {
  lastWriteWins,      // El más reciente gana
  remoteWins,         // Siempre gana el remoto
  localWins,          // Siempre gana el local
  merge,              // Intentar fusionar cambios
  manual,             // Requiere intervención manual
}

class ConflictResolutionService {
  static final ConflictResolutionService _instance = ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  // Estrategia por defecto
  ConflictResolutionStrategy _defaultStrategy = ConflictResolutionStrategy.lastWriteWins;

  void setDefaultStrategy(ConflictResolutionStrategy strategy) {
    _defaultStrategy = strategy;
  }

  // Resolver conflicto entre versiones local y remota
  Future<ConflictResolution> resolveUserConflict(
    UserModel localUser, 
    UserModel remoteUser, 
    {ConflictResolutionStrategy? strategy}
  ) async {
    final resolutionStrategy = strategy ?? _defaultStrategy;
    
    // Detectar si realmente hay conflicto
    if (!_hasConflict(localUser, remoteUser)) {
      return ConflictResolution(
        resolvedUser: remoteUser,
        strategy: resolutionStrategy,
        hasConflict: false,
        conflictFields: [],
      );
    }

    final conflictFields = _detectConflictFields(localUser, remoteUser);
    
    switch (resolutionStrategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveByLastWrite(localUser, remoteUser, conflictFields);
        
      case ConflictResolutionStrategy.remoteWins:
        return _resolveByRemoteWins(localUser, remoteUser, conflictFields);
        
      case ConflictResolutionStrategy.localWins:
        return _resolveByLocalWins(localUser, remoteUser, conflictFields);
        
      case ConflictResolutionStrategy.merge:
        return _resolveByMerge(localUser, remoteUser, conflictFields);
        
      case ConflictResolutionStrategy.manual:
        return _requireManualResolution(localUser, remoteUser, conflictFields);
    }
  }

  // Detectar si hay conflicto real entre dos usuarios
  bool _hasConflict(UserModel local, UserModel remote) {
    // Si ambos tienen timestamps y son diferentes, hay potencial conflicto
    final localUpdated = DateTime.tryParse(local.updatedAt ?? '');
    final remoteUpdated = DateTime.tryParse(remote.updatedAt ?? '');
    
    if (localUpdated != null && remoteUpdated != null) {
      // Si la diferencia es menor a 1 segundo, considerarlo como no conflicto
      final difference = localUpdated.difference(remoteUpdated).abs();
      if (difference.inSeconds < 1) {
        return false;
      }
    }
    
    // Verificar si los datos son diferentes
    return _detectConflictFields(local, remote).isNotEmpty;
  }

  // Detectar campos específicos en conflicto
  List<String> _detectConflictFields(UserModel local, UserModel remote) {
    final conflicts = <String>[];
    
    if (local.nombre != remote.nombre) conflicts.add('nombre');
    if (local.telefono != remote.telefono) conflicts.add('telefono');
    if (local.ubicacion != remote.ubicacion) conflicts.add('ubicacion');
    if (local.fechaNacimiento != remote.fechaNacimiento) conflicts.add('fechaNacimiento');
    if (local.experienciaAgricola != remote.experienciaAgricola) conflicts.add('experienciaAgricola');
    if (local.tamanoFinca != remote.tamanoFinca) conflicts.add('tamanoFinca');
    if (local.tipoAgricultura != remote.tipoAgricultura) conflicts.add('tipoAgricultura');
    if (local.emailConfirmado != remote.emailConfirmado) conflicts.add('emailConfirmado');
    
    return conflicts;
  }

  // Resolución por último en escribir gana
  ConflictResolution _resolveByLastWrite(UserModel local, UserModel remote, List<String> conflicts) {
    final localUpdated = DateTime.tryParse(local.updatedAt ?? '');
    final remoteUpdated = DateTime.tryParse(remote.updatedAt ?? '');
    
    UserModel winner;
    
    if (localUpdated == null && remoteUpdated == null) {
      winner = remote; // Preferir remoto si no hay timestamps
    } else if (localUpdated == null) {
      winner = remote;
    } else if (remoteUpdated == null) {
      winner = local;
    } else {
      winner = remoteUpdated.isAfter(localUpdated) ? remote : local;
    }
    
    return ConflictResolution(
      resolvedUser: winner,
      strategy: ConflictResolutionStrategy.lastWriteWins,
      hasConflict: true,
      conflictFields: conflicts,
      resolution: winner == remote ? 'Remoto ganó por timestamp más reciente' : 'Local ganó por timestamp más reciente',
    );
  }

  // Resolución donde siempre gana el remoto
  ConflictResolution _resolveByRemoteWins(UserModel local, UserModel remote, List<String> conflicts) {
    return ConflictResolution(
      resolvedUser: remote,
      strategy: ConflictResolutionStrategy.remoteWins,
      hasConflict: true,
      conflictFields: conflicts,
      resolution: 'Remoto ganó por estrategia remoteWins',
    );
  }

  // Resolución donde siempre gana el local
  ConflictResolution _resolveByLocalWins(UserModel local, UserModel remote, List<String> conflicts) {
    return ConflictResolution(
      resolvedUser: local,
      strategy: ConflictResolutionStrategy.localWins,
      hasConflict: true,
      conflictFields: conflicts,
      resolution: 'Local ganó por estrategia localWins',
    );
  }

  // Resolución por fusión inteligente
  ConflictResolution _resolveByMerge(UserModel local, UserModel remote, List<String> conflicts) {
    // Crear usuario fusionado tomando el mejor valor de cada campo
    final merged = UserModel(
      id: remote.id ?? local.id,
      nombre: _chooseBestValue(local.nombre, remote.nombre),
      email: remote.email, // Email no debe cambiar
      telefono: _chooseBestValue(local.telefono, remote.telefono),
      ubicacion: _chooseBestValue(local.ubicacion, remote.ubicacion),
      fechaNacimiento: _chooseBestValue(local.fechaNacimiento, remote.fechaNacimiento),
      experienciaAgricola: _chooseBestValue(local.experienciaAgricola, remote.experienciaAgricola),
      tamanoFinca: _chooseBestValue(local.tamanoFinca, remote.tamanoFinca),
      tipoAgricultura: _chooseBestValue(local.tipoAgricultura, remote.tipoAgricultura),
      emailConfirmado: remote.emailConfirmado || local.emailConfirmado, // Mantener confirmación
      createdAt: local.createdAt ?? remote.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      lastSyncAt: DateTime.now().toIso8601String(),
      needsSync: false,
    );
    
    return ConflictResolution(
      resolvedUser: merged,
      strategy: ConflictResolutionStrategy.merge,
      hasConflict: true,
      conflictFields: conflicts,
      resolution: 'Datos fusionados inteligentemente',
    );
  }

  // Elegir el mejor valor entre dos opciones
  String? _chooseBestValue(String? local, String? remote) {
    // Si uno es null y el otro no, elegir el no-null
    if (local == null && remote != null) return remote;
    if (remote == null && local != null) return local;
    if (local == null && remote == null) return null;
    
    // Si ambos tienen valor, elegir el más largo (asumiendo más información)
    if (remote!.length > local!.length) return remote;
    return local;
  }

  // Requerir resolución manual
  ConflictResolution _requireManualResolution(UserModel local, UserModel remote, List<String> conflicts) {
    return ConflictResolution(
      resolvedUser: null, // No se resuelve automáticamente
      strategy: ConflictResolutionStrategy.manual,
      hasConflict: true,
      conflictFields: conflicts,
      resolution: 'Requiere resolución manual',
      requiresManualIntervention: true,
      localVersion: local,
      remoteVersion: remote,
    );
  }

  // Crear resolución manual con usuario elegido
  ConflictResolution createManualResolution(
    UserModel chosenUser,
    UserModel localUser,
    UserModel remoteUser,
    List<String> conflictFields,
  ) {
    return ConflictResolution(
      resolvedUser: chosenUser.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
        lastSyncAt: DateTime.now().toIso8601String(),
        needsSync: false,
      ),
      strategy: ConflictResolutionStrategy.manual,
      hasConflict: true,
      conflictFields: conflictFields,
      resolution: 'Resuelto manualmente por el usuario',
      requiresManualIntervention: false,
    );
  }

  // Obtener estadísticas de conflictos
  ConflictStats getConflictStats(List<ConflictResolution> resolutions) {
    final totalConflicts = resolutions.where((r) => r.hasConflict).length;
    final autoResolved = resolutions.where((r) => r.hasConflict && !r.requiresManualIntervention).length;
    final manualResolved = resolutions.where((r) => r.requiresManualIntervention).length;
    
    final strategyCount = <ConflictResolutionStrategy, int>{};
    for (final resolution in resolutions) {
      strategyCount[resolution.strategy] = (strategyCount[resolution.strategy] ?? 0) + 1;
    }
    
    return ConflictStats(
      totalConflicts: totalConflicts,
      autoResolved: autoResolved,
      manualResolved: manualResolved,
      strategyUsage: strategyCount,
    );
  }
}

// Clase para el resultado de resolución de conflictos
class ConflictResolution {
  final UserModel? resolvedUser;
  final ConflictResolutionStrategy strategy;
  final bool hasConflict;
  final List<String> conflictFields;
  final String? resolution;
  final bool requiresManualIntervention;
  final UserModel? localVersion;
  final UserModel? remoteVersion;
  
  ConflictResolution({
    this.resolvedUser,
    required this.strategy,
    required this.hasConflict,
    required this.conflictFields,
    this.resolution,
    this.requiresManualIntervention = false,
    this.localVersion,
    this.remoteVersion,
  });
}

// Estadísticas de conflictos
class ConflictStats {
  final int totalConflicts;
  final int autoResolved;
  final int manualResolved;
  final Map<ConflictResolutionStrategy, int> strategyUsage;
  
  ConflictStats({
    required this.totalConflicts,
    required this.autoResolved,
    required this.manualResolved,
    required this.strategyUsage,
  });
  
  double get autoResolutionRate => 
      totalConflicts > 0 ? autoResolved / totalConflicts : 0.0;
}