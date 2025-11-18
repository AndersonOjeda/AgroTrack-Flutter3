## Objetivo UX
- Eliminar por completo la necesidad de deslizar horizontalmente para leer mensajes del chat en móviles.
- Mantener lectura vertical con ajuste automático del texto, incluso para palabras largas sin espacios (URLs, hashes).

## Cambios de Código
- En `lib/screens/chat_bot.dart`:
  - Reducir umbral de detección de tokens largos en `_hasLongUnbreakableToken`:
    - Cambiar límite de 16 a 12 caracteres para considerar un token como no quebrable.
    - Ubicación: ~`lib/screens/chat_bot.dart:75–80`.
  - Endurecer los cortes invisibles en `_insertSoftBreaks`:
    - Cambiar `step` de 6 a 4 para insertar `\u200B` cada 4 caracteres.
    - Cambiar condición de `p.length < 16` a `p.length < 12` para aplicar el corte en más casos.
    - Ubicación: ~`lib/screens/chat_bot.dart:83–99`.
  - Confirmar visualización sin scroll horizontal en `_buildMessageText`:
    - Mantener `softWrap: true`, `overflow: TextOverflow.clip`, `maxLines: null`.
    - Ya presente en ~`lib/screens/chat_bot.dart:105–112`.
  - Mantener estructura de burbuja sin forzar ancho:
    - Burbuja usa `Column` para texto + controles (flechas) en vertical.
    - La fila de mensaje alrededor del avatar mantiene `Flexible(child: bubble)` para evitar desbordes.
    - Referencias: `lib/screens/chat_bot.dart:904–970` y `lib/screens/chat_bot.dart:1039`, `lib/screens/chat_bot.dart:1046`.
  - Conservar ancho máximo de burbuja calculado en función del viewport:
    - `_bubbleMaxWidth(context)` ya considera padding/márgenes/avatares.
    - Referencia: `lib/screens/chat_bot.dart:63–70`.

## Pruebas
- Mensajes:
  - URL muy larga sin espacios, hash continuo de 120+ caracteres, y texto normal multirenglón.
- Dispositivos/Orientación:
  - Teléfonos pequeños (HDPI) y grandes, vertical/horizontal.
- Gestos/Acciones:
  - Confirmar que “deslizar a la izquierda” elimina el mensaje (`Dismissible endToStart`).
  - Con teclado abierto, comprobar que el input permanece visible y el contenido se ajusta.

## Compatibilidad y Efectos Colaterales
- Los `\u200B` solo se insertan para renderizado; el texto original de los mensajes se mantiene sin modificar para copia/edición.
- No se introduce scroll horizontal en burbujas; la lectura es siempre vertical.

## Resultado Esperado
- Lectura fluida sin gestos horizontales.
- Sin desbordes a la derecha en ningún caso práctico.
- Eliminación por deslizamiento a la izquierda conservada y sin interferencias.

¿Confirmas que proceda con estos cambios y ejecute las pruebas descritas?