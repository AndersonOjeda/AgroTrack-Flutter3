class UserModel {
  final String? id;
  final String nombre;
  final String? apellido;
  final String email;
  final String? telefono;
  final String? ubicacion;
  final String? bio;
  final String? profileImageUrl;
  final DateTime? fechaNacimiento;
  final String? experienciaAgricola;
  final String? tamanoFinca;
  final String? primaryCrops;
  final bool emailConfirmado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncAt;
  final bool needsSync;

  UserModel({
    this.id,
    required this.nombre,
    this.apellido,
    required this.email,
    this.telefono,
    this.ubicacion,
    this.bio,
    this.profileImageUrl,
    this.fechaNacimiento,
    this.experienciaAgricola,
    this.tamanoFinca,
    this.primaryCrops,
    this.emailConfirmado = false,
    this.createdAt,
    this.updatedAt,
    this.lastSyncAt,
    this.needsSync = false,
  });

  // Convertir desde Map (SQLite) usando claves en inglés
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nombre: map['first_name'] ?? map['nombre'] ?? '',
      apellido: map['last_name'] ?? map['apellido'],
      email: map['email'] ?? '',
      telefono: map['phone'] ?? map['telefono'],
      ubicacion: map['location'] ?? map['ubicacion'],
      bio: map['bio'],
      profileImageUrl: map['profile_image_url'],
      fechaNacimiento: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'])
          : (map['fecha_nacimiento'] != null
              ? DateTime.parse(map['fecha_nacimiento'])
              : null),
      experienciaAgricola: map['farming_experience'] ?? map['experiencia_agricola'],
      tamanoFinca: map['farm_size']?.toString() ?? map['tamano_finca'],
      primaryCrops: map['primary_crops'] ?? map['tipo_agricultura'],
      emailConfirmado: map['email_confirmed'] == true || map['email_confirmado'] == true || map['email_confirmado'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.parse(map['last_sync_at'])
          : null,
      needsSync: map['needs_sync'] == true || map['needs_sync'] == 1,
    );
  }

  // Convertir a Map (SQLite) usando claves en inglés
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': nombre,
      'last_name': apellido,
      'email': email,
      'phone': telefono,
      'location': ubicacion,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'birth_date': fechaNacimiento?.toIso8601String(),
      'farming_experience': experienciaAgricola,
      'farm_size': tamanoFinca,
      'primary_crops': primaryCrops,
      'email_confirmed': emailConfirmado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'needs_sync': needsSync,
    };
  }

  // Convertir desde JSON (Supabase) usando claves en inglés
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['first_name'] ?? json['nombre'] ?? '',
      apellido: json['last_name'] ?? json['apellido'],
      email: json['email'] ?? '',
      telefono: json['phone'] ?? json['telefono'],
      ubicacion: json['location'] ?? json['ubicacion'],
      bio: json['bio'],
      profileImageUrl: json['profile_image_url'],
      fechaNacimiento: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : (json['fecha_nacimiento'] != null
              ? DateTime.parse(json['fecha_nacimiento'])
              : null),
      experienciaAgricola: json['farming_experience'] ?? json['experiencia_agricola'],
      tamanoFinca: json['farm_size']?.toString() ?? json['tamano_finca'],
      primaryCrops: json['primary_crops'] ?? json['tipo_agricultura'],
      emailConfirmado: json['email_confirmed'] ?? json['email_confirmado'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convertir a JSON (Supabase) usando claves en inglés
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': nombre,
      'last_name': apellido,
      'email': email,
      'phone': telefono,
      'location': ubicacion,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'birth_date': fechaNacimiento?.toIso8601String(),
      'farming_experience': experienciaAgricola,
      'farm_size': tamanoFinca,
      'primary_crops': primaryCrops,
      'email_confirmed': emailConfirmado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Crear copia con cambios
  UserModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? ubicacion,
    String? bio,
    String? profileImageUrl,
    DateTime? fechaNacimiento,
    String? experienciaAgricola,
    String? tamanoFinca,
    String? primaryCrops,
    bool? emailConfirmado,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    bool? needsSync,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      ubicacion: ubicacion ?? this.ubicacion,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      experienciaAgricola: experienciaAgricola ?? this.experienciaAgricola,
      tamanoFinca: tamanoFinca ?? this.tamanoFinca,
      primaryCrops: primaryCrops ?? this.primaryCrops,
      emailConfirmado: emailConfirmado ?? this.emailConfirmado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombre: $nombre, apellido: $apellido, email: $email, telefono: $telefono, ubicacion: $ubicacion, fechaNacimiento: $fechaNacimiento, experienciaAgricola: $experienciaAgricola, tamanoFinca: $tamanoFinca, primaryCrops: $primaryCrops, emailConfirmado: $emailConfirmado, createdAt: $createdAt, updatedAt: $updatedAt, lastSyncAt: $lastSyncAt, needsSync: $needsSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.id == id &&
      other.nombre == nombre &&
      other.apellido == apellido &&
      other.email == email &&
      other.telefono == telefono &&
      other.ubicacion == ubicacion &&
      other.fechaNacimiento == fechaNacimiento &&
      other.experienciaAgricola == experienciaAgricola &&
      other.tamanoFinca == tamanoFinca &&
    other.primaryCrops == primaryCrops &&
      other.emailConfirmado == emailConfirmado &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.lastSyncAt == lastSyncAt &&
      other.needsSync == needsSync;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      nombre.hashCode ^
      apellido.hashCode ^
      email.hashCode ^
      telefono.hashCode ^
      ubicacion.hashCode ^
      fechaNacimiento.hashCode ^
      experienciaAgricola.hashCode ^
      tamanoFinca.hashCode ^
    (primaryCrops?.hashCode ?? 0) ^
      emailConfirmado.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      lastSyncAt.hashCode ^
      needsSync.hashCode;
  }
}