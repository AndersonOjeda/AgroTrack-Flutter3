class InventoryItemModel {
  final String? id;
  final String nombre;
  final String categoria;
  final String? descripcion;
  final double cantidad;
  final String unidadMedida;
  final double? precioUnitario;
  final double? valorTotal;
  final String? proveedor;
  final DateTime? fechaCompra;
  final DateTime? fechaVencimiento;
  final String? ubicacionAlmacen;
  final String? lote;
  final double? cantidadMinima;
  final String? estado; // 'disponible', 'agotado', 'por_vencer', 'vencido'
  final String? notas;
  final String? imagenUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool needsSync;

  InventoryItemModel({
    this.id,
    required this.nombre,
    required this.categoria,
    this.descripcion,
    required this.cantidad,
    required this.unidadMedida,
    this.precioUnitario,
    this.valorTotal,
    this.proveedor,
    this.fechaCompra,
    this.fechaVencimiento,
    this.ubicacionAlmacen,
    this.lote,
    this.cantidadMinima,
    this.estado,
    this.notas,
    this.imagenUrl,
    this.createdAt,
    this.updatedAt,
    this.needsSync = false,
  });

  // Convertir desde Map (SQLite)
  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      categoria: map['categoria'] ?? '',
      descripcion: map['descripcion'],
      cantidad: (map['cantidad'] ?? 0).toDouble(),
      unidadMedida: map['unidad_medida'] ?? '',
      precioUnitario: map['precio_unitario']?.toDouble(),
      valorTotal: map['valor_total']?.toDouble(),
      proveedor: map['proveedor'],
      fechaCompra: map['fecha_compra'] != null 
          ? DateTime.parse(map['fecha_compra']) 
          : null,
      fechaVencimiento: map['fecha_vencimiento'] != null 
          ? DateTime.parse(map['fecha_vencimiento']) 
          : null,
      ubicacionAlmacen: map['ubicacion_almacen'],
      lote: map['lote'],
      cantidadMinima: map['cantidad_minima']?.toDouble(),
      estado: map['estado'],
      notas: map['notas'],
      imagenUrl: map['imagen_url'],
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
      'nombre': nombre,
      'categoria': categoria,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'precio_unitario': precioUnitario,
      'valor_total': valorTotal,
      'proveedor': proveedor,
      'fecha_compra': fechaCompra?.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'ubicacion_almacen': ubicacionAlmacen,
      'lote': lote,
      'cantidad_minima': cantidadMinima,
      'estado': estado,
      'notas': notas,
      'imagen_url': imagenUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'needs_sync': needsSync,
    };
  }

  // Convertir desde JSON (Supabase)
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      descripcion: json['descripcion'],
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      unidadMedida: json['unidad_medida'] ?? '',
      precioUnitario: json['precio_unitario']?.toDouble(),
      valorTotal: json['valor_total']?.toDouble(),
      proveedor: json['proveedor'],
      fechaCompra: json['fecha_compra'] != null 
          ? DateTime.parse(json['fecha_compra'])
          : null,
      fechaVencimiento: json['fecha_vencimiento'] != null 
          ? DateTime.parse(json['fecha_vencimiento'])
          : null,
      ubicacionAlmacen: json['ubicacion_almacen'],
      lote: json['lote'],
      cantidadMinima: json['cantidad_minima']?.toDouble(),
      estado: json['estado'],
      notas: json['notas'],
      imagenUrl: json['imagen_url'],
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
      'categoria': categoria,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'precio_unitario': precioUnitario,
      'valor_total': valorTotal,
      'proveedor': proveedor,
      'fecha_compra': fechaCompra?.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'ubicacion_almacen': ubicacionAlmacen,
      'lote': lote,
      'cantidad_minima': cantidadMinima,
      'estado': estado,
      'notas': notas,
      'imagen_url': imagenUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Crear copia con cambios
  InventoryItemModel copyWith({
    String? id,
    String? nombre,
    String? categoria,
    String? descripcion,
    double? cantidad,
    String? unidadMedida,
    double? precioUnitario,
    double? valorTotal,
    String? proveedor,
    DateTime? fechaCompra,
    DateTime? fechaVencimiento,
    String? ubicacionAlmacen,
    String? lote,
    double? cantidadMinima,
    String? estado,
    String? notas,
    String? imagenUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
      proveedor: proveedor ?? this.proveedor,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      ubicacionAlmacen: ubicacionAlmacen ?? this.ubicacionAlmacen,
      lote: lote ?? this.lote,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  // Calcular valor total automáticamente
  double get valorTotalCalculado {
    if (precioUnitario != null) {
      return cantidad * precioUnitario!;
    }
    return valorTotal ?? 0.0;
  }

  // Verificar si el item está por vencer (próximos 30 días)
  bool get isPorVencer {
    if (fechaVencimiento == null) return false;
    final now = DateTime.now();
    final diferencia = fechaVencimiento!.difference(now).inDays;
    return diferencia <= 30 && diferencia > 0;
  }

  // Verificar si el item está vencido
  bool get isVencido {
    if (fechaVencimiento == null) return false;
    return fechaVencimiento!.isBefore(DateTime.now());
  }

  // Verificar si el stock está bajo
  bool get isStockBajo {
    if (cantidadMinima == null) return false;
    return cantidad <= cantidadMinima!;
  }

  @override
  String toString() {
    return 'InventoryItemModel(id: $id, nombre: $nombre, categoria: $categoria, cantidad: $cantidad, unidadMedida: $unidadMedida, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InventoryItemModel &&
      other.id == id &&
      other.nombre == nombre &&
      other.categoria == categoria &&
      other.cantidad == cantidad &&
      other.unidadMedida == unidadMedida;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      nombre.hashCode ^
      categoria.hashCode ^
      cantidad.hashCode ^
      unidadMedida.hashCode;
  }
}