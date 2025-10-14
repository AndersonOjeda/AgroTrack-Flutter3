class UserModel {
  final String? id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? ubicacion;
  final DateTime? fechaNacimiento;
  final String? experienciaAgricola;
  final String? tamanoFinca;
  final String? tipoAgricultura;
  final bool emailConfirmado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncAt;
  final bool needsSync;

  UserModel({
    this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.ubicacion,
    this.fechaNacimiento,
    this.experienciaAgricola,
    this.tamanoFinca,
    this.tipoAgricultura,
    this.emailConfirmado = false,
    this.createdAt,
    this.updatedAt,
    this.lastSyncAt,
    this.needsSync = false,
  });

  // Convertir desde Map (SQLite)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'],
      ubicacion: map['ubicacion'],
      fechaNacimiento: map['fecha_nacimiento'] != null 
          ? DateTime.parse(map['fecha_nacimiento'])
          : null,
      experienciaAgricola: map['experiencia_agricola'],
      tamanoFinca: map['tamano_finca'],
      tipoAgricultura: map['tipo_agricultura'],
      emailConfirmado: map['email_confirmado'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : null,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'])
          : null,
      needsSync: map['needs_sync'] == 1,
    );
  }

  // Convertir a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'ubicacion': ubicacion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'experiencia_agricola': experienciaAgricola,
      'tamano_finca': tamanoFinca,
      'tipo_agricultura': tipoAgricultura,
      'email_confirmado': emailConfirmado ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  // Convertir desde JSON (Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'],
      ubicacion: json['ubicacion'],
      fechaNacimiento: json['fecha_nacimiento'] != null 
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      experienciaAgricola: json['experiencia_agricola'],
      tamanoFinca: json['tamano_finca'],
      tipoAgricultura: json['tipo_agricultura'],
      emailConfirmado: json['email_confirmado'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convertir a JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'ubicacion': ubicacion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'experiencia_agricola': experienciaAgricola,
      'tamano_finca': tamanoFinca,
      'tipo_agricultura': tipoAgricultura,
      'email_confirmado': emailConfirmado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Crear copia con cambios
  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? ubicacion,
    DateTime? fechaNacimiento,
    String? experienciaAgricola,
    String? tamanoFinca,
    String? tipoAgricultura,
    bool? emailConfirmado,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    bool? needsSync,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      ubicacion: ubicacion ?? this.ubicacion,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      experienciaAgricola: experienciaAgricola ?? this.experienciaAgricola,
      tamanoFinca: tamanoFinca ?? this.tamanoFinca,
      tipoAgricultura: tipoAgricultura ?? this.tipoAgricultura,
      emailConfirmado: emailConfirmado ?? this.emailConfirmado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombre: $nombre, email: $email, needsSync: $needsSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.nombre == nombre;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ nombre.hashCode;
}