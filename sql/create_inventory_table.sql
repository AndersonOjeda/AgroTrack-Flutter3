-- Crear tabla inventory_items si no existe
CREATE TABLE IF NOT EXISTS inventory_items (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    descripcion TEXT,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
    unidad_medida VARCHAR(50),
    precio_unitario DECIMAL(10,2),
    proveedor VARCHAR(255),
    ubicacion VARCHAR(255),
    numero_lote VARCHAR(100),
    fecha_vencimiento DATE,
    cantidad_minima DECIMAL(10,2) DEFAULT 0,
    estado VARCHAR(50) DEFAULT 'activo',
    notas TEXT,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    needs_sync BOOLEAN DEFAULT FALSE,
    sync_error TEXT
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_inventory_items_user_id ON inventory_items(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_categoria ON inventory_items(categoria);
CREATE INDEX IF NOT EXISTS idx_inventory_items_estado ON inventory_items(estado);
CREATE INDEX IF NOT EXISTS idx_inventory_items_fecha_vencimiento ON inventory_items(fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_inventory_items_needs_sync ON inventory_items(needs_sync);

-- Crear función para actualizar fecha_actualizacion automáticamente
CREATE OR REPLACE FUNCTION update_inventory_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar fecha_actualizacion
DROP TRIGGER IF EXISTS trigger_update_inventory_items_updated_at ON inventory_items;
CREATE TRIGGER trigger_update_inventory_items_updated_at
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_items_updated_at();

-- Habilitar RLS (Row Level Security)
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Crear política para que los usuarios solo puedan ver sus propios items
CREATE POLICY "Users can view their own inventory items" ON inventory_items
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Crear política para que los usuarios solo puedan insertar sus propios items
CREATE POLICY "Users can insert their own inventory items" ON inventory_items
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Crear política para que los usuarios solo puedan actualizar sus propios items
CREATE POLICY "Users can update their own inventory items" ON inventory_items
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Crear política para que los usuarios solo puedan eliminar sus propios items
CREATE POLICY "Users can delete their own inventory items" ON inventory_items
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Crear función para crear la tabla si no existe (para usar desde la app)
CREATE OR REPLACE FUNCTION create_inventory_table_if_not_exists()
RETURNS BOOLEAN AS $$
BEGIN
    -- Esta función ya no es necesaria ya que la tabla se crea arriba
    -- Pero la mantenemos para compatibilidad con el código de la app
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;