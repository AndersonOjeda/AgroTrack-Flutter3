-- =====================================================
-- SCRIPT DE CORRECCIÓN PARA TABLA DE INVENTARIO
-- =====================================================
-- Este script corrige los problemas identificados en el inventario
-- Ejecutar en el editor SQL de Supabase

-- 1. Crear la tabla inventory_items si no existe
CREATE TABLE IF NOT EXISTS public.inventory_items (
  id VARCHAR(255) PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  nombre VARCHAR(255) NOT NULL,
  categoria VARCHAR(100) NOT NULL,
  descripcion TEXT,
  cantidad NUMERIC NOT NULL DEFAULT 0,
  unidad_medida VARCHAR(50) NOT NULL,
  precio_unitario NUMERIC,
  valor_total NUMERIC,
  proveedor VARCHAR(255),
  fecha_compra TIMESTAMP WITH TIME ZONE,
  fecha_vencimiento TIMESTAMP WITH TIME ZONE,
  ubicacion_almacen VARCHAR(255),
  lote VARCHAR(100),
  cantidad_minima NUMERIC,
  estado VARCHAR(50) DEFAULT 'disponible',
  notas TEXT,
  imagen_url TEXT,
  needs_sync BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON public.inventory_items(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_categoria ON public.inventory_items(categoria);
CREATE INDEX IF NOT EXISTS idx_inventory_estado ON public.inventory_items(estado);
CREATE INDEX IF NOT EXISTS idx_inventory_needs_sync ON public.inventory_items(needs_sync);
CREATE INDEX IF NOT EXISTS idx_inventory_fecha_vencimiento ON public.inventory_items(fecha_vencimiento);

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

-- 4. Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Inventory items viewable by owner" ON public.inventory_items;
DROP POLICY IF EXISTS "Inventory items insertable by owner" ON public.inventory_items;
DROP POLICY IF EXISTS "Inventory items updatable by owner" ON public.inventory_items;
DROP POLICY IF EXISTS "Inventory items deletable by owner" ON public.inventory_items;

-- 5. Crear políticas de seguridad
CREATE POLICY "Inventory items viewable by owner" ON public.inventory_items
  FOR SELECT USING (
    user_id IN (
      SELECT id FROM public.usuarios 
      WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Inventory items insertable by owner" ON public.inventory_items
  FOR INSERT WITH CHECK (
    user_id IN (
      SELECT id FROM public.usuarios 
      WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Inventory items updatable by owner" ON public.inventory_items
  FOR UPDATE USING (
    user_id IN (
      SELECT id FROM public.usuarios 
      WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Inventory items deletable by owner" ON public.inventory_items
  FOR DELETE USING (
    user_id IN (
      SELECT id FROM public.usuarios 
      WHERE auth_user_id = auth.uid()
    )
  );

-- 6. Crear función para crear tabla desde la aplicación
CREATE OR REPLACE FUNCTION public.create_inventory_table_if_not_exists()
RETURNS BOOLEAN AS $$
BEGIN
  -- La tabla ya debería existir después de ejecutar este script
  -- Esta función es para compatibilidad con el código de la app
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Crear función para obtener estadísticas del inventario
CREATE OR REPLACE FUNCTION public.get_inventory_stats(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_items', COUNT(*),
    'total_value', COALESCE(SUM(valor_total), 0),
    'low_stock_items', COUNT(*) FILTER (WHERE cantidad <= cantidad_minima),
    'expiring_soon', COUNT(*) FILTER (WHERE fecha_vencimiento <= NOW() + INTERVAL '30 days'),
    'categories', json_agg(DISTINCT categoria)
  )
  INTO result
  FROM public.inventory_items
  WHERE user_id = p_user_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.update_inventory_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_inventory_updated_at_trigger ON public.inventory_items;
CREATE TRIGGER update_inventory_updated_at_trigger
  BEFORE UPDATE ON public.inventory_items
  FOR EACH ROW
  EXECUTE FUNCTION public.update_inventory_updated_at();

-- 9. Insertar datos de ejemplo para pruebas (opcional)
-- Descomenta las siguientes líneas si quieres datos de ejemplo

/*
INSERT INTO public.inventory_items (
  id, user_id, nombre, categoria, descripcion, cantidad, unidad_medida,
  precio_unitario, valor_total, estado, created_at, updated_at
) VALUES (
  'test-item-1',
  (SELECT id FROM public.usuarios LIMIT 1),
  'Semillas de Maíz (Ejemplo)',
  'Semillas',
  'Semillas de maíz híbrido para pruebas',
  100,
  'kg',
  25000,
  2500000,
  'disponible',
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;
*/

-- Mensaje de confirmación
DO $$
BEGIN
  RAISE NOTICE 'Tabla de inventario configurada correctamente';
END $$;