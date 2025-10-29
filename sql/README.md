# Scripts SQL para AgroTrack

## Configuración de la Base de Datos

### 1. Crear tabla inventory_items

Para crear la tabla de inventario en Supabase:

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a la sección "SQL Editor"
3. Copia y pega el contenido del archivo `create_inventory_table.sql`
4. Ejecuta el script

### Características de la tabla inventory_items:

- **Seguridad**: Implementa Row Level Security (RLS) para que cada usuario solo pueda acceder a sus propios items
- **Auditoría**: Incluye campos de fecha de creación y actualización automáticas
- **Sincronización**: Campos `needs_sync` y `sync_error` para manejo de sincronización offline
- **Índices**: Optimizada para consultas frecuentes por usuario, categoría, estado y fecha de vencimiento
- **Relaciones**: Conectada con la tabla `usuarios` mediante foreign key

### Campos principales:

- `id`: Identificador único
- `user_id`: Referencia al usuario propietario
- `nombre`: Nombre del item
- `categoria`: Categoría del producto
- `descripcion`: Descripción detallada
- `cantidad`: Cantidad disponible
- `unidad_medida`: Unidad de medida (kg, litros, unidades, etc.)
- `precio_unitario`: Precio por unidad
- `proveedor`: Proveedor del producto
- `ubicacion`: Ubicación física del item
- `numero_lote`: Número de lote para trazabilidad
- `fecha_vencimiento`: Fecha de vencimiento
- `cantidad_minima`: Cantidad mínima para alertas
- `estado`: Estado del item (activo, inactivo, vencido, etc.)
- `notas`: Notas adicionales

### Políticas de Seguridad:

El script incluye políticas RLS que garantizan que:
- Los usuarios solo pueden ver sus propios items
- Los usuarios solo pueden crear items asociados a su cuenta
- Los usuarios solo pueden modificar sus propios items
- Los usuarios solo pueden eliminar sus propios items

### Próximos pasos:

1. Ejecutar el script SQL
2. Probar la funcionalidad de diagnóstico en la app
3. Verificar que las operaciones CRUD funcionen correctamente