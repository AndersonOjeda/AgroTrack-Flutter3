## Objetivo
- Resolver el “Right overflowed by 260 pixels” originado por desbordes verticales cuando aparece el teclado.

## Causa
- Se está aplicando doble ajuste de `viewInsets.bottom`: `Scaffold(resizeToAvoidBottomInset: true)` ya reduce el cuerpo, y además se usa `AnimatedPadding` con `MediaQuery.of(context).viewInsets.bottom`, duplicando el espacio.

## Cambios propuestos
1. Remover `AnimatedPadding` en la zona del input inferior y usar solo `Padding` estático.
   - Ubicación: `lib/screens/chat_bot.dart` (bloque debajo del `Divider` donde está el `Row` con `TextField` y botón).
   - Sustituir:
     """
     AnimatedPadding(
       duration: const Duration(milliseconds: 180),
       padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         child: Row(...)
     """
     Por:
     """
     Padding(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       child: Row(...)
     """
2. Mantener `Scaffold(resizeToAvoidBottomInset: true)` para que el cuerpo se redimensione automáticamente con el teclado.
3. Verificar que el `ListView.builder` esté dentro de `Expanded` (ya lo está) y que las burbujas sigan usando ancho dinámico y `Flexible` para evitar desbordes horizontales.

## Validación
- Probar en un móvil con teclado abierto:
  - Escribir en el `TextField` y confirmar que no aparece el banner de overflow.
  - Verificar que el `ListView` se recorta correctamente y el input queda visible.

## Compatibilidad
- No afecta la lógica del chat ni el filtrado de temas agrícolas.
- La UI se mantiene más estable y sin efectos secundarios.

## Confirmación
¿Apruebas que proceda a eliminar `AnimatedPadding` y dejar solo `Padding`, confiando en `resizeToAvoidBottomInset: true` para resolver el overflow?