import 'package:flutter/material.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItemModel> _inventoryItems = [];
  List<InventoryItemModel> _filteredItems = [];
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  bool _showLowStock = false;
  bool _showExpiring = false;

  final InventoryService _inventoryService = InventoryService();

  final List<String> _categories = [
    'Todos',
    'Semillas',
    'Fertilizantes',
    'Pesticidas',
    'Herramientas',
    'Equipos',
    'Materiales',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final items = await _inventoryService.getAllItems();
      
      // Si no hay elementos en la base de datos, cargar datos de ejemplo
      if (items.isEmpty) {
        await _loadSampleData();
        final newItems = await _inventoryService.getAllItems();
        setState(() {
          _inventoryItems = newItems;
        });
      } else {
        setState(() {
          _inventoryItems = items;
        });
      }
      
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar inventario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // no-op
    }
  }

  Future<void> _loadSampleData() async {
    // Datos de ejemplo para demostración
    final sampleItems = [
      InventoryItemModel(
        nombre: 'Semillas de Maíz Híbrido',
        categoria: 'Semillas',
        descripcion: 'Semillas de maíz híbrido de alta productividad',
        cantidad: 50,
        unidadMedida: 'kg',
        precioUnitario: 25000,
        proveedor: 'AgroSemillas S.A.',
        fechaCompra: DateTime.now().subtract(const Duration(days: 30)),
        fechaVencimiento: DateTime.now().add(const Duration(days: 365)),
        ubicacionAlmacen: 'Bodega A - Estante 1',
        lote: 'MS2024001',
        cantidadMinima: 10,
        estado: 'disponible',
      ),
      InventoryItemModel(
        nombre: 'Fertilizante NPK 15-15-15',
        categoria: 'Fertilizantes',
        descripcion: 'Fertilizante completo para cultivos generales',
        cantidad: 5,
        unidadMedida: 'bultos',
        precioUnitario: 85000,
        proveedor: 'Fertilizantes del Valle',
        fechaCompra: DateTime.now().subtract(const Duration(days: 15)),
        ubicacionAlmacen: 'Bodega B - Zona 2',
        lote: 'NPK2024002',
        cantidadMinima: 8,
        estado: 'disponible',
      ),
      InventoryItemModel(
        nombre: 'Herbicida Glifosato',
        categoria: 'Pesticidas',
        descripcion: 'Herbicida sistémico no selectivo',
        cantidad: 12,
        unidadMedida: 'litros',
        precioUnitario: 35000,
        proveedor: 'AgroQuímicos Ltda.',
        fechaCompra: DateTime.now().subtract(const Duration(days: 60)),
        fechaVencimiento: DateTime.now().add(const Duration(days: 25)),
        ubicacionAlmacen: 'Bodega C - Área Restringida',
        lote: 'GLI2024003',
        cantidadMinima: 5,
        estado: 'disponible',
      ),
      InventoryItemModel(
        nombre: 'Azadón de Acero',
        categoria: 'Herramientas',
        descripcion: 'Azadón con mango de madera y hoja de acero',
        cantidad: 3,
        unidadMedida: 'unidades',
        precioUnitario: 45000,
        proveedor: 'Herramientas Agrícolas S.A.',
        fechaCompra: DateTime.now().subtract(const Duration(days: 90)),
        ubicacionAlmacen: 'Taller - Estante Herramientas',
        cantidadMinima: 5,
        estado: 'disponible',
      ),
    ];

    // Insertar datos de ejemplo en la base de datos
    for (final item in sampleItems) {
      await _inventoryService.createItem(item);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _inventoryItems.where((item) {
        // Filtro por categoría
        bool categoryMatch =
            _selectedCategory == 'Todos' || item.categoria == _selectedCategory;

        // Filtro por búsqueda
        bool searchMatch =
            _searchQuery.isEmpty ||
            item.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.descripcion?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);

        // Filtro por stock bajo
        bool lowStockMatch = !_showLowStock || item.isStockBajo;

        // Filtro por próximos a vencer
        bool expiringMatch =
            !_showExpiring || item.isPorVencer || item.isVencido;

        return categoryMatch && searchMatch && lowStockMatch && expiringMatch;
      }).toList();
    });
  }

  Future<void> _showAddItemDialog() async {
    final result = await showDialog<InventoryItemModel>(
      context: context,
      builder: (context) => _AddItemDialog(),
    );

    if (result != null) {
      // Mostrar diálogo de confirmación
      final confirmed = await _showConfirmationDialog(
        title: 'Confirmar Creación',
        content: '¿Está seguro de que desea agregar "${result.nombre}" al inventario?',
        confirmText: 'Agregar',
        cancelText: 'Cancelar',
      );

      if (confirmed) {
        try {
            final id = await _inventoryService.createItem(result);
            if (id != null) {
              await _loadInventoryItems();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto agregado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              throw Exception('No se pudo crear el elemento');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al agregar producto: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            // no-op
          }
      }
    }
  }

  void _showItemDetails(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => _ItemDetailsDialog(
        item: item,
        onEdit: () => _showEditItemDialog(item),
        onDelete: () => _showDeleteConfirmation(item),
      ),
    );
  }

  Future<void> _showEditItemDialog(InventoryItemModel item) async {
    final result = await showDialog<InventoryItemModel>(
      context: context,
      builder: (context) => _EditItemDialog(item: item),
    );

    if (result != null) {
      // Mostrar diálogo de confirmación
      final confirmed = await _showConfirmationDialog(
        title: 'Confirmar Actualización',
        content: '¿Está seguro de que desea actualizar "${result.nombre}"?',
        confirmText: 'Actualizar',
        cancelText: 'Cancelar',
      );

      if (confirmed) {
        try {
          final success = await _inventoryService.updateItem(result);
          if (success) {
            await _loadInventoryItems();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('No se pudo actualizar el elemento');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al actualizar producto: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          // no-op
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(InventoryItemModel item) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Confirmar Eliminación',
      content: '¿Está seguro de que desea eliminar "${item.nombre}" del inventario?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        final success = await _inventoryService.deleteItem(item.id!);
        if (success) {
          await _loadInventoryItems();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto eliminado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('No se pudo eliminar el elemento');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // no-op
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'NotoSans'),
        ),
        content: Text(
          content,
          style: const TextStyle(fontFamily: 'NotoSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(fontFamily: 'NotoSans'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : null,
              foregroundColor: isDestructive ? Colors.white : null,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontFamily: 'NotoSans'),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color _getStatusColor(InventoryItemModel item) {
    if (item.isVencido) return Colors.red;
    if (item.isPorVencer) return Colors.orange;
    if (item.isStockBajo) return Colors.amber;
    return Colors.green;
  }

  String _getStatusText(InventoryItemModel item) {
    if (item.isVencido) return 'Vencido';
    if (item.isPorVencer) return 'Por vencer';
    if (item.isStockBajo) return 'Stock bajo';
    return 'Disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario Agrícola',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'NotoSans'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
            tooltip: 'Agregar producto',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),

                // Filtros
                Row(
                  children: [
                    // Selector de categoría
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _selectedCategory = value!;
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filtros adicionales
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showLowStock,
                              onChanged: (value) {
                                _showLowStock = value!;
                                _applyFilters();
                              },
                            ),
                            const Text(
                              'Stock bajo',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showExpiring,
                              onChanged: (value) {
                                _showExpiring = value!;
                                _applyFilters();
                              },
                            ),
                            const Text(
                              'Por vencer',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resumen estadístico
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  title: 'Total Items',
                  value: '${_inventoryItems.length}',
                  color: Colors.blue,
                  icon: Icons.inventory,
                ),
                _StatCard(
                  title: 'Stock Bajo',
                  value:
                      '${_inventoryItems.where((item) => item.isStockBajo).length}',
                  color: Colors.orange,
                  icon: Icons.warning,
                ),
                _StatCard(
                  title: 'Por Vencer',
                  value:
                      '${_inventoryItems.where((item) => item.isPorVencer || item.isVencido).length}',
                  color: Colors.red,
                  icon: Icons.schedule,
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontFamily: 'NotoSans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega productos a tu inventario',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              item,
                            ).withValues(alpha: 0.1),
                            child: Icon(
                              _getCategoryIcon(item.categoria),
                              color: _getStatusColor(item),
                            ),
                          ),
                          title: Text(
                            item.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.cantidad} ${item.unidadMedida} • ${item.categoria}',
                                style: const TextStyle(fontFamily: 'NotoSans'),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    item,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(item),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(item),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.precioUnitario != null)
                                Text(
                                  '\$${item.valorTotalCalculado.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              Text(
                                item.ubicacionAlmacen ?? 'Sin ubicación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'NotoSans',
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showItemDetails(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria) {
      case 'Semillas':
        return Icons.eco;
      case 'Fertilizantes':
        return Icons.grass;
      case 'Pesticidas':
        return Icons.bug_report;
      case 'Herramientas':
        return Icons.build;
      case 'Equipos':
        return Icons.precision_manufacturing;
      case 'Materiales':
        return Icons.category;
      default:
        return Icons.inventory;
    }
  }
}

class _EditItemDialog extends StatefulWidget {
  final InventoryItemModel item;

  const _EditItemDialog({required this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _precioController;
  late final TextEditingController _proveedorController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _loteController;
  late final TextEditingController _cantidadMinimaController;

  late String _selectedCategory;
  late String _selectedUnidad;
  DateTime? _fechaVencimiento;

  final List<String> _categories = [
    'Semillas',
    'Fertilizantes',
    'Pesticidas',
    'Herramientas',
    'Equipos',
    'Materiales',
    'Otros',
  ];

  final List<String> _unidades = [
    'kg',
    'litros',
    'unidades',
    'bultos',
    'cajas',
    'metros',
    'gramos',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.item.nombre);
    _descripcionController = TextEditingController(text: widget.item.descripcion ?? '');
    _cantidadController = TextEditingController(text: widget.item.cantidad.toString());
    _precioController = TextEditingController(text: widget.item.precioUnitario?.toString() ?? '');
    _proveedorController = TextEditingController(text: widget.item.proveedor ?? '');
    _ubicacionController = TextEditingController(text: widget.item.ubicacionAlmacen ?? '');
    _loteController = TextEditingController(text: widget.item.lote ?? '');
    _cantidadMinimaController = TextEditingController(text: widget.item.cantidadMinima?.toString() ?? '');
    
    _selectedCategory = widget.item.categoria;
    _selectedUnidad = widget.item.unidadMedida;
    _fechaVencimiento = widget.item.fechaVencimiento;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _proveedorController.dispose();
    _ubicacionController.dispose();
    _loteController.dispose();
    _cantidadMinimaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Editar Producto',
        style: TextStyle(fontFamily: 'NotoSans'),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del producto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnidad,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                        ),
                        items: _unidades.map((unidad) {
                          return DropdownMenuItem(
                            value: unidad,
                            child: Text(unidad),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnidad = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proveedorController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación en almacén',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Lote',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cantidadMinimaController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad mínima',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _fechaVencimiento = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fechaVencimiento == null
                              ? 'Fecha de vencimiento (opcional)'
                              : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedItem = widget.item.copyWith(
                nombre: _nombreController.text,
                categoria: _selectedCategory,
                descripcion: _descripcionController.text.isEmpty
                    ? null
                    : _descripcionController.text,
                cantidad: double.parse(_cantidadController.text),
                unidadMedida: _selectedUnidad,
                precioUnitario: _precioController.text.isEmpty
                    ? null
                    : double.parse(_precioController.text),
                proveedor: _proveedorController.text.isEmpty
                    ? null
                    : _proveedorController.text,
                fechaVencimiento: _fechaVencimiento,
                ubicacionAlmacen: _ubicacionController.text.isEmpty
                    ? null
                    : _ubicacionController.text,
                lote: _loteController.text.isEmpty
                    ? null
                    : _loteController.text,
                cantidadMinima: _cantidadMinimaController.text.isEmpty
                    ? null
                    : double.parse(_cantidadMinimaController.text),
                updatedAt: DateTime.now(),
              );

              Navigator.of(context).pop(updatedItem);
            }
          },
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'NotoSans',
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _loteController = TextEditingController();
  final _cantidadMinimaController = TextEditingController();

  String _selectedCategory = 'Semillas';
  String _selectedUnidad = 'kg';
  DateTime? _fechaVencimiento;

  final List<String> _categories = [
    'Semillas',
    'Fertilizantes',
    'Pesticidas',
    'Herramientas',
    'Equipos',
    'Materiales',
    'Otros',
  ];

  final List<String> _unidades = [
    'kg',
    'litros',
    'unidades',
    'bultos',
    'cajas',
    'metros',
    'gramos',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Agregar Producto',
        style: TextStyle(fontFamily: 'NotoSans'),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnidad,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                        ),
                        items: _unidades.map((unidad) {
                          return DropdownMenuItem(
                            value: unidad,
                            child: Text(unidad),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnidad = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio unitario',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _proveedorController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ubicacionController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación almacén',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _loteController,
                        decoration: const InputDecoration(
                          labelText: 'Lote',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cantidadMinimaController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad mínima',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = InventoryItemModel(
                nombre: _nombreController.text,
                categoria: _selectedCategory,
                descripcion: _descripcionController.text.isEmpty
                    ? null
                    : _descripcionController.text,
                cantidad: double.parse(_cantidadController.text),
                unidadMedida: _selectedUnidad,
                precioUnitario: _precioController.text.isEmpty
                    ? null
                    : double.parse(_precioController.text),
                proveedor: _proveedorController.text.isEmpty
                    ? null
                    : _proveedorController.text,
                fechaCompra: DateTime.now(),
                fechaVencimiento: _fechaVencimiento,
                ubicacionAlmacen: _ubicacionController.text.isEmpty
                    ? null
                    : _ubicacionController.text,
                lote: _loteController.text.isEmpty
                    ? null
                    : _loteController.text,
                cantidadMinima: _cantidadMinimaController.text.isEmpty
                    ? null
                    : double.parse(_cantidadMinimaController.text),
                estado: 'disponible',
                createdAt: DateTime.now(),
              );

              Navigator.of(context).pop(item);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _ItemDetailsDialog extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemDetailsDialog({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(item.nombre, style: const TextStyle(fontFamily: 'NotoSans')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Categoría', item.categoria),
              if (item.descripcion != null)
                _DetailRow('Descripción', item.descripcion!),
              _DetailRow('Cantidad', '${item.cantidad} ${item.unidadMedida}'),
              if (item.precioUnitario != null)
                _DetailRow(
                  'Precio unitario',
                  '\$${item.precioUnitario!.toStringAsFixed(0)}',
                ),
              if (item.precioUnitario != null)
                _DetailRow(
                  'Valor total',
                  '\$${item.valorTotalCalculado.toStringAsFixed(0)}',
                ),
              if (item.proveedor != null)
                _DetailRow('Proveedor', item.proveedor!),
              if (item.fechaCompra != null)
                _DetailRow(
                  'Fecha compra',
                  '${item.fechaCompra!.day}/${item.fechaCompra!.month}/${item.fechaCompra!.year}',
                ),
              if (item.fechaVencimiento != null)
                _DetailRow(
                  'Fecha vencimiento',
                  '${item.fechaVencimiento!.day}/${item.fechaVencimiento!.month}/${item.fechaVencimiento!.year}',
                ),
              if (item.ubicacionAlmacen != null)
                _DetailRow('Ubicación', item.ubicacionAlmacen!),
              if (item.lote != null) _DetailRow('Lote', item.lote!),
              if (item.cantidadMinima != null)
                _DetailRow(
                  'Cantidad mínima',
                  '${item.cantidadMinima} ${item.unidadMedida}',
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          child: const Text('Editar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'NotoSans')),
          ),
        ],
      ),
    );
  }
}
