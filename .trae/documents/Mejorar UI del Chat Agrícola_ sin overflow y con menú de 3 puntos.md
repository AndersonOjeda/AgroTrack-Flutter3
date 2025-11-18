## Objetivo
- Eliminar definitivamente el error "Right overflowed by N pixels".
- Sustituir el borrado por deslizamiento (swipe) por un menú de 3 puntos por mensaje con las acciones Editar, Copiar y Eliminar.

## Cambios clave
1. Limitar el ancho de las burbujas de chat con un valor dinámico:
   - Usar `maxBubbleWidth = min(MediaQuery.of(context).size.width * 0.72, 600)` para móviles y tablets.
   - Envolver las burbujas en `Flexible` dentro del `Row` para evitar desbordes junto al avatar.
2. Asegurar el ajuste del texto:
   - `Text(msg.text, softWrap: true)` y evitar estilos que fuercen anchuras.
3. Reemplazar `Dismissible` por `PopupMenuButton`:
   - Menú de 3 puntos en la esquina superior de cada burbuja con: Editar (solo última pregunta del usuario), Copiar, Eliminar.
   - En Eliminar, mostrar `AlertDialog` de confirmación antes de borrar.
4. Mantener consistencia visual:
   - Espaciado con `SizedBox(width: 8)` entre avatar y burbuja.
   - Colores actuales y sombras sin cambios para no romper el estilo.

## Implementación técnica
- En `lib/screens/chat_bot.dart`:
  - Calcular y aplicar `maxBubbleWidth` al `Container` de la burbuja (actualmente cerca de `795`).
  - Envolver la burbuja con `Flexible` en el `Row` (referencia actual `1026-1036`).
  - Reemplazar el bloque `Dismissible` por un `GestureDetector` + `PopupMenuButton` incrustado en la cabecera de la burbuja.
  - Añadir confirmación de eliminación con `showDialog<bool>` y solo proceder si es `true`.

## Pruebas y validación
- Móvil pequeño (≤360dp), textos largos: verificar que no aparece el banner de overflow.
- Tablet: verificar que el límite `min(600, width*0.72)` mantiene estética sin desbordes.
- Acciones del menú:
  - Copiar: muestra snackbar de confirmación.
  - Editar: disponible solo en la última pregunta del usuario.
  - Eliminar: solicita confirmación; borra pregunta y respuesta del bot si están acopladas.

## Impacto y compatibilidad
- No afecta la lógica del chatbot ni el filtrado de temas agrícolas ya implementado.
- Navegación y estado permanecen iguales.
- UI se vuelve más amigable y estándar.

## Confirmación
¿Confirmas que proceda con estos cambios en la pantalla `ChatBot` para aplicar el ancho dinámico, `Flexible` y el menú de 3 puntos con confirmación de borrado, sustituyendo por completo el swipe?