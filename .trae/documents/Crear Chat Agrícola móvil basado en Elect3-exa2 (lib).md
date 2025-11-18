## Objetivo
Construir una pantalla de chat agrícola para móviles, basada en el estilo de `MedicalChatScreen` del repositorio Elect3-exa2 (lib), integrada con Gemini y con UX optimizada: sin desbordes, lectura vertical, gestos de eliminación, y buen comportamiento con teclado.

## Arquitectura de Pantalla
- Crear `AgroChatScreen` (StatefulWidget) con:
  - Estado: `_messages`, `_controller`, `_scrollController`, `_isLoading`, `_isTyping`, `_chat`, `_error`.
  - Inicialización de Gemini desde `.env` (corrigiendo `GEMINI_MODEL` si viene mal escrito): fallback con lista de modelos.
  - Métodos: `_buildModel`, `_buildHistoryFromMessages`, `_initChatWithAnyModel`, `_rebuildChatSession`, `_sendMessage`, `_scrollToBottom`.

## UI Responsiva y Sin Desbordes
- Lista de mensajes:
  - `ListView.builder` con `padding` móvil y `keyboardDismissBehavior: onDrag`.
  - Ítems envueltos en `Dismissible` con `DismissDirection.endToStart` y confirmación de borrado.
- Burbujas de mensaje:
  - `Container` con `constraints` calculadas por viewport (máx. ancho: min(600, ancho disponible)).
  - Estructura interna en `Column`: texto arriba y controles (p.ej. flechas/menú) debajo para evitar `Row` que fuerza ancho.
  - En el `Row` que contiene avatar + burbuja usar `Flexible(child: bubble)` para impedir overflow.
- Texto del mensaje:
  - `Text` con `softWrap: true`, `overflow: TextOverflow.clip`, `maxLines: null`.
  - Algoritmo de corte con `\u200B` en tokens largos: detectar palabras >12 caracteres e insertar quiebres cada 4 caracteres para garantizar envoltura vertical.
- Teclado e input:
  - `Scaffold(resizeToAvoidBottomInset: true)`.
  - `AnimatedPadding` en la barra de entrada con `viewInsets.bottom`.
  - `TextField` con `minLines: 1`, `maxLines: 5`, tipografía móvil (15), `contentPadding` compacto.

## Integración Gemini
- Leer `GEMINI_API_KEY` y `GEMINI_MODEL` desde `.env`.
- Fallback de modelos (1.5 flash, 2.x flash/lite/exp, 2.5) con manejo de errores recuperables.
- Construcción de historial `Usuario:/Asistente:` + prompt agrícola.
- Envío/recepción con feedback de carga (spinner y `_isTyping`).

## Funcionalidad y Accesibilidad
- Gestos: eliminar por deslizamiento a la izquierda con confirmación.
- Copiar texto por `onLongPress`.
- Estados de error: banner en rojo y `hintText` adaptado.
- Avatares simples (U/AI) y colores legibles.

## Pruebas
- Contenido: textos normales, URLs largas, hashes (>120), multirenglón.
- Dispositivos: teléfonos pequeños y grandes; orientación vertical/horizontal.
- Teclado: apertura/cierre, envío por Enter, input visible.
- Rendimiento: lista con muchos mensajes.

## Entregables
- Archivo `AgroChatScreen` con la estructura y mejoras descritas.
- Código listo para móvil Android (emulador/dispositivo) sin desbordes y con UX consistente.

¿Confirmas que proceda con estos cambios e implemente la pantalla siguiendo esta arquitectura y pruebas?