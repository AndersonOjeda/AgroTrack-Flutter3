class FarmLocationModel {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool needsSync;

  FarmLocationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.needsSync = false,
  });

  // Convertir desde Map (SQLite)
  factory FarmLocationModel.fromMap(Map<String, dynamic> map) {
    return FarmLocationModel(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: map['description'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      needsSync: map['needs_sync'] == true || map['needs_sync'] == 1,
    );
  }

  // Convertir a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'needs_sync': needsSync,
    };
  }

  // Convertir a JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convertir desde JSON (Supabase)
  factory FarmLocationModel.fromJson(Map<String, dynamic> json) {
    return FarmLocationModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      needsSync: false,
    );
  }

  FarmLocationModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return FarmLocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}