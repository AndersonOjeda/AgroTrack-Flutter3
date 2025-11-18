## Objetivo
- Resolver el “Right overflowed by N pixels” en mensajes (incluyendo el saludo inicial y todos los posteriores).
- Hacer la UI más amigable eliminando desbordes internos de las burbujas y manteniendo el menú de 3 puntos.

## Causas probables
- La fila interna dentro de la burbuja (`Row`) combina `Expanded(Text)` + controles (flechas y menú), que no puede envolver contenido en pantallas estrechas.
- El ancho máximo fijo o insuficiente de la burbuja puede, junto con avatar y espaciados, forzar overflow.

## Cambios propuestos
1. Refactor del contenido de la burbuja
   - Sustituir la `Row` interna por una `Column` que contenga:
     - `Text(msg.text, softWrap: true, overflow: TextOverflow.clip)`.
     - Una barra de acciones inferior con `Wrap` (flechas de versión y menú de 3 puntos), permitiendo salto de línea cuando falte ancho.
   - Ubicación: reemplazar el bloque `Row` dentro de la `Column` de la burbuja alrededor de `lib/screens/chat_bot.dart:816-875` por `Column + Wrap`.

2. Ancho máximo robusto de la burbuja
   - Mantener `Flexible(child: bubble)` en el `Row` externo (entre avatar y burbuja).
   - Calcular `maxBubbleWidth = min(MediaQuery.of(context).size.width * 0.72, 600)` (ya en uso). Validar que se aplica a todas las ramas.

3. Ajustes de texto y estilo
   - `Text` con `softWrap: true` y `overflow: TextOverflow.clip` para evitar stripes.
   - Evitar largas filas con muchos controles al lado del texto; los controles pasan a una línea aparte (via `Wrap`).

4. Confirmación en Eliminar (ya añadida)
   - Mantener el `AlertDialog` antes de borrar.

## Ejemplo de estructura nueva en la burbuja
- Column(
  - Text(...)
  - SizedBox(height: 8)
  - Wrap(children: [version navigator, PopupMenuButton])
)

## Pruebas
- Dispositivo móvil de ancho <= 360dp con texto largo (saludo inicial y respuestas extensas) para comprobar que no aparece el banner de overflow.
- Tablet para validar que la UI conserva el estilo.

## Compatibilidad
- No cambia la lógica del chat ni el filtrado agrícola.
- Menú de 3 puntos se mantiene funcional.

## Confirmación
¿Apruebas este refactor (Column + Wrap en la burbuja y ajustes de texto) para eliminar definitivamente el overflow en móviles y hacer la UI más amigable?