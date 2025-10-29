import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/logger_service.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final bool _isTyping = false;
  ChatSession? _chat;
  String? _error;
  String? _editingMessageId;
  final Map<String, List<String>> _messageVariants =
      {}; // Para almacenar diferentes respuestas
  final Map<String, List<String>> _questionVersions =
      {}; // Para almacenar versiones de preguntas editadas
  final Map<String, int> _currentQuestionVersionIndex =
      {}; // Índice actual de la versión mostrada
  final Map<String, Map<int, String>> _questionResponseMap =
      {}; // Mapea cada versión de pregunta con su respuesta

  _ChatBotState() {
    LoggerService.info('🏗️ ChatBot widget creado - Constructor llamado');
  }
  static const String _systemPrompt =
      'Eres un orientador agrícola para campesinos. Respondes en español '
      'con empatía, claridad y enfoque práctico. Ofreces información y '
      'recomendaciones generales sobre cultivos, suelos, riego, plagas, '
      'nutrición, cosecha y comercialización, sin reemplazar asesoría '
      'profesional. Pide siempre detalles: cultivo, etapa fenológica, '
      'tipo de suelo, clima/localidad, síntomas o plaga, manejo previo y '
      'recursos disponibles. Indica señales de alarma (plagas agresivas, '
      'deficiencias severas, riesgos de intoxicación) y sugiere acudir a '
      'técnicos locales cuando corresponda. Evita recetas peligrosas y '
      'fomenta prácticas sostenibles.';
  late String _modelName;
  bool _didRetryModel = false;
  final List<String> _modelCandidates = [
    // Modelos gratuitos más recientes y estables
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b-latest',
    'gemini-1.5-flash-8b',
    // Variantes 2.x (nominaciones recientes)
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash-exp',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  GenerativeModel _buildModel(String name, String apiKey) {
    return GenerativeModel(
      model: name,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );
  }

  List<Content> _buildHistoryFromMessages() {
    final history = <Content>[];
    history.add(Content.text(_systemPrompt));
    for (final m in _messages) {
      final prefix = m.isUser ? 'Usuario: ' : 'Asistente: ';
      history.add(Content.text('$prefix${m.text}'));
    }
    return history;
  }

  void _rebuildChatSession() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _error = 'Falta GEMINI_API_KEY en .env';
      return;
    }
    try {
      final model = _buildModel(_modelName, apiKey);
      _chat = model.startChat(history: _buildHistoryFromMessages());
    } catch (e) {
      _error = 'Error al reiniciar el chat: ${e.toString()}';
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _initChatWithAnyModel(String apiKey) {
    LoggerService.info(
      '🔄 Iniciando chat con API key: ${apiKey.substring(0, 10)}...',
    );

    var preferredRaw = dotenv.env['GEMINI_MODEL']?.trim();
    LoggerService.info('📋 Modelo preferido: $preferredRaw');

    if (preferredRaw != null &&
        preferredRaw.toLowerCase().contains('flash-light')) {
      // Normaliza a "flash-lite" (algunas cuentas usan esta denominación)
      preferredRaw = preferredRaw.toLowerCase().replaceAll(
        'flash-light',
        'flash-lite',
      );
    }
    final tried = <String>{};

    List<String> sequence = [];
    if (preferredRaw != null && preferredRaw.isNotEmpty) {
      sequence.add(preferredRaw);
      if (preferredRaw.endsWith('-latest')) {
        final base = preferredRaw.replaceAll(RegExp(r'-latest\s*$'), '');
        if (base.isNotEmpty) sequence.add(base);
      }
    }
    for (final c in _modelCandidates) {
      if (!sequence.contains(c)) sequence.add(c);
    }

    LoggerService.info('🎯 Secuencia de modelos a probar: $sequence');

    for (final name in sequence) {
      if (tried.contains(name)) continue;
      tried.add(name);
      LoggerService.info('🧪 Probando modelo: $name');
      try {
        final model = _buildModel(name, apiKey);
        _chat = model.startChat(history: _buildHistoryFromMessages());
        _modelName = name;
        _error = null; // Limpiar cualquier error previo
        LoggerService.info(
          '✅ Chat inicializado exitosamente con modelo: $name',
        );

        // Actualizar el estado de la UI
        if (mounted) {
          setState(() {
            // Trigger rebuild para mostrar que el chat está listo
          });
        }
        return;
      } catch (e) {
        LoggerService.error('❌ Error con modelo $name: $e');
        final m = e.toString();
        final recoverable =
            m.contains('not found') ||
            m.contains('not supported') ||
            m.contains('Unsupported') ||
            m.contains('404');
        if (!recoverable) {
          _error = 'Error al iniciar el chat: $m';
          LoggerService.error('🚨 Error no recuperable: $m');
          if (mounted) {
            setState(() {
              // Trigger rebuild para mostrar el error
            });
          }
          return;
        }
      }
    }
    _error = 'Ningún modelo Gemini disponible. Prueba con otra clave o región.';
    LoggerService.error('🚨 Ningún modelo disponible');
    if (mounted) {
      setState(() {
        // Trigger rebuild para mostrar el error
      });
    }
  }

  // Método para navegar entre versiones de preguntas
  void _navigateQuestionVersion(String messageId, bool isNext) {
    if (!_questionVersions.containsKey(messageId)) return;

    final versions = _questionVersions[messageId]!;
    final currentIndex = _currentQuestionVersionIndex[messageId] ?? 0;

    int newIndex;
    if (isNext) {
      newIndex = (currentIndex + 1) % versions.length;
    } else {
      newIndex = (currentIndex - 1 + versions.length) % versions.length;
    }

    setState(() {
      _currentQuestionVersionIndex[messageId] = newIndex;

      // Actualizar el texto del mensaje en la lista
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          text: versions[newIndex],
        );

        // Actualizar también la respuesta del bot correspondiente
        if (messageIndex + 1 < _messages.length &&
            !_messages[messageIndex + 1].isUser) {
          final botResponse = _questionResponseMap[messageId]?[newIndex];
          if (botResponse != null) {
            _messages[messageIndex + 1] = _messages[messageIndex + 1].copyWith(
              text: botResponse,
            );
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Agregar mensaje de bienvenida inmediatamente
    _messages.add(
      _ChatMessage.withId(
        text:
            '¡Hola! Soy tu orientador agrícola. Cuéntame tu consulta '
            'sobre cultivos, suelos, riego, plagas, nutrición o comercialización. '
            'Indica cultivo, etapa, suelo, clima/localidad y síntomas. '
            'Daré recomendaciones generales y prácticas sostenibles; esto no '
            'reemplaza asesoría técnica profesional local.',
        isUser: false,
      ),
    );

    // Inicializar el chat de forma asíncrona
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    LoggerService.info('🚀 Iniciando _initializeChat()');

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    LoggerService.info(
      '🔑 API Key encontrada: ${apiKey != null ? "Sí (${apiKey.substring(0, 10)}...)" : "No"}',
    );

    if (apiKey == null || apiKey.isEmpty) {
      LoggerService.error('❌ API Key faltante');
      setState(() {
        _error = 'Falta GEMINI_API_KEY en .env';
      });
      return;
    }

    try {
      LoggerService.info('🔄 Llamando _initChatWithAnyModel...');
      _initChatWithAnyModel(apiKey);

      LoggerService.info('✅ _initChatWithAnyModel completado');
      LoggerService.info(
        '📊 Estado del chat: ${_chat != null ? "Inicializado" : "Null"}',
      );
      LoggerService.info('🚨 Error actual: $_error');

      // Forzar actualización del estado
      if (mounted) {
        setState(() {
          // Trigger rebuild
        });
        LoggerService.info('🔄 setState llamado');
      }
    } catch (e) {
      LoggerService.error('💥 Excepción en _initializeChat: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al inicializar: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    LoggerService.info('📤 _sendMessage iniciado');
    final text = _textController.text.trim();
    LoggerService.info('📝 Texto del mensaje: "$text"');

    if (text.isEmpty) {
      LoggerService.info('❌ Mensaje vacío, cancelando');
      return;
    }

    // Verificar si el chat está inicializado
    if (_chat == null) {
      LoggerService.info(
        '⚠️ Chat no inicializado, intentando reinicializar...',
      );
      // Intentar reinicializar si no está listo
      await _initializeChat();
      if (_chat == null) {
        LoggerService.error('❌ Reinicialización falló');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El chat no está listo. Intenta de nuevo en un momento.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      LoggerService.info('✅ Chat reinicializado exitosamente');
    }

    if (_error != null) {
      LoggerService.error('❌ Error presente: $_error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    LoggerService.info('📨 Agregando mensaje del usuario y iniciando carga...');
    final userMessage = _ChatMessage.withId(text: text, isUser: true);

    // Si estamos editando, agregar la nueva versión a las versiones de pregunta
    if (_editingMessageId != null) {
      if (_questionVersions.containsKey(_editingMessageId)) {
        _questionVersions[_editingMessageId]!.add(text);
        _currentQuestionVersionIndex[_editingMessageId!] =
            _questionVersions[_editingMessageId]!.length - 1;
      }
    }

    setState(() {
      _messages.add(userMessage);
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      LoggerService.info('🚀 Enviando mensaje a Gemini...');
      final response = await _chat!.sendMessage(Content.text(text));
      LoggerService.info('✅ Respuesta recibida de Gemini');

      final reply =
          response.text?.trim() ??
          'No pude elaborar una respuesta en este momento. Intenta reformular '
              'tu consulta con más contexto (cultivo, etapa, suelo, clima/localidad, síntomas) '
              'y evita temas sensibles. Recuerda que esto no reemplaza asesoría técnica agrícola local.';

      LoggerService.info(
        '📝 Respuesta procesada: "${reply.substring(0, reply.length > 50 ? 50 : reply.length)}..."',
      );

      if (mounted) {
        final botMessage = _ChatMessage.withId(text: reply, isUser: false);

        // Si estamos editando un mensaje, guardar la respuesta para esta versión
        if (_editingMessageId != null) {
          // Inicializar el mapa de respuestas si no existe
          if (!_questionResponseMap.containsKey(_editingMessageId)) {
            _questionResponseMap[_editingMessageId!] = {};
          }

          // Guardar la respuesta para la versión actual
          final currentVersionIndex =
              _currentQuestionVersionIndex[_editingMessageId] ?? 0;
          _questionResponseMap[_editingMessageId!]![currentVersionIndex] =
              reply;

          _editingMessageId = null;
        }

        setState(() {
          _messages.add(botMessage);
        });
        _scrollToBottom();
        LoggerService.info('✅ Respuesta agregada a la UI');
      }
    } catch (e) {
      LoggerService.error('❌ Error al enviar mensaje: $e');
      if (!_didRetryModel && _chat != null) {
        _didRetryModel = true;
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        // Construye una secuencia empezando después del modelo actual,
        // incluyendo variantes '-latest' y base.
        final baseSeq = <String>[];
        if (_modelName.endsWith('-latest')) {
          baseSeq.add(_modelName.replaceAll(RegExp(r'-latest\s*$'), ''));
        }
        baseSeq.addAll(_modelCandidates);
        final startIndex = baseSeq.indexOf(_modelName);
        final startAt = startIndex >= 0 ? startIndex + 1 : 0;
        for (var i = startAt; i < baseSeq.length; i++) {
          final candidate = baseSeq[i];
          try {
            final model = _buildModel(candidate, apiKey!);
            _chat = model.startChat(history: _buildHistoryFromMessages());
            _modelName = candidate;
            final response = await _chat!.sendMessage(Content.text(text));
            final reply =
                response.text?.trim() ??
                'No pude elaborar una respuesta en este momento. Intenta reformular '
                    'tu consulta con más contexto (cultivo, etapa, suelo, clima/localidad, síntomas) '
                    'y evita temas sensibles. Recuerda que esto no reemplaza asesoría técnica agrícola local.';
            if (mounted) {
              final botMessage = _ChatMessage.withId(
                text: reply,
                isUser: false,
              );

              // Si estamos editando un mensaje, guardar la respuesta para esta versión
              if (_editingMessageId != null) {
                // Inicializar el mapa de respuestas si no existe
                if (!_questionResponseMap.containsKey(_editingMessageId)) {
                  _questionResponseMap[_editingMessageId!] = {};
                }

                // Guardar la respuesta para la versión actual
                final currentVersionIndex =
                    _currentQuestionVersionIndex[_editingMessageId] ?? 0;
                _questionResponseMap[_editingMessageId!]![currentVersionIndex] =
                    reply;

                _editingMessageId = null;
              }

              setState(() {
                _messages.add(botMessage);
              });
              _scrollToBottom();
            }
            return;
          } catch (_) {
            continue;
          }
        }
      }
      LoggerService.info('🔄 Intentando con modelo de respaldo...');
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage.withId(
              text: 'Ocurrió un error: ${e.toString()}',
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    } finally {
      LoggerService.info(
        '🏁 Finalizando _sendMessage, limpiando estado de carga...',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // Método para editar la última pregunta del usuario
  void _editLastUserMessage() {
    final lastUserMessageIndex = _messages.lastIndexWhere((msg) => msg.isUser);
    if (lastUserMessageIndex == -1) return;

    final lastUserMessage = _messages[lastUserMessageIndex];

    // Guardar la versión original si no existe
    if (!_questionVersions.containsKey(lastUserMessage.id)) {
      _questionVersions[lastUserMessage.id] = [lastUserMessage.text];
      _currentQuestionVersionIndex[lastUserMessage.id] = 0;

      // Inicializar el mapa de respuestas y guardar la respuesta original
      _questionResponseMap[lastUserMessage.id] = {};

      // Buscar la respuesta del bot correspondiente a esta pregunta
      if (lastUserMessageIndex + 1 < _messages.length &&
          !_messages[lastUserMessageIndex + 1].isUser) {
        _questionResponseMap[lastUserMessage.id]![0] =
            _messages[lastUserMessageIndex + 1].text;
      }
    }

    _textController.text = lastUserMessage.text;

    setState(() {
      _editingMessageId = lastUserMessage.id;
      // Remover mensajes desde la última pregunta del usuario
      _messages.removeRange(lastUserMessageIndex, _messages.length);
    });

    _rebuildChatSession();
  }

  // Método para copiar mensaje al portapapeles
  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Método para mostrar diferentes variantes de respuesta
  void _showMessageVariants(String messageId) {
    final variants = _messageVariants[messageId] ?? [];
    if (variants.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Variantes de respuesta'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: variants.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(variants[index]),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Agrícola'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Limpiar chat',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limpiar chat'),
                  content: const Text(
                    '¿Deseas borrar todo el historial de mensajes?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                setState(() {
                  _messages.clear();
                });
                _rebuildChatSession();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    final isTypingRow = _isTyping && index == _messages.length;
                    if (isTypingRow) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: _TypingBubble(),
                      );
                    }
                    final msg = _messages[index];
                    final isUser = msg.isUser;
                    final bubbleColor = isUser
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                        : Colors.grey[100];
                    final borderColor = isUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300];

                    // Verificar si es la última pregunta del usuario
                    final isLastUserMessage =
                        msg.isUser &&
                        index == _messages.lastIndexWhere((m) => m.isUser);

                    final bubble = Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        border: Border.all(color: borderColor ?? Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(msg.text)),
                              // Flechas de navegación para versiones de preguntas editadas
                              if (msg.isUser &&
                                  _questionVersions.containsKey(msg.id) &&
                                  (_questionVersions[msg.id]?.length ?? 0) > 1)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _navigateQuestionVersion(
                                                  msg.id,
                                                  false,
                                                ),
                                            child: const Icon(
                                              Icons.arrow_back_ios,
                                              size: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(_currentQuestionVersionIndex[msg.id] ?? 0) + 1}/${_questionVersions[msg.id]?.length ?? 1}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () =>
                                                _navigateQuestionVersion(
                                                  msg.id,
                                                  true,
                                                ),
                                            child: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (!msg.isUser &&
                              _messageVariants.containsKey(msg.id))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Toca para ver ${_messageVariants[msg.id]!.length} variantes',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          // Menú de 3 puntos para la última pregunta del usuario
                          if (isLastUserMessage)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  tooltip: 'Opciones',
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onSelected: (String value) {
                                    switch (value) {
                                      case 'edit':
                                        _editLastUserMessage();
                                        break;
                                      case 'copy':
                                        _copyMessage(msg.text);
                                        break;
                                      case 'delete':
                                        // Encontrar el índice del mensaje del usuario
                                        final userMessageIndex = index;
                                        final userMessage =
                                            _messages[userMessageIndex];

                                        setState(() {
                                          // Eliminar la pregunta del usuario
                                          _messages.removeAt(userMessageIndex);

                                          // Si hay una respuesta del bot después, también eliminarla
                                          if (userMessageIndex <
                                                  _messages.length &&
                                              !_messages[userMessageIndex]
                                                  .isUser) {
                                            _messages.removeAt(
                                              userMessageIndex,
                                            );
                                          }

                                          // Limpiar los mapas de versiones y respuestas
                                          _questionVersions.remove(
                                            userMessage.id,
                                          );
                                          _currentQuestionVersionIndex.remove(
                                            userMessage.id,
                                          );
                                          _questionResponseMap.remove(
                                            userMessage.id,
                                          );
                                          _messageVariants.remove(
                                            userMessage.id,
                                          );
                                        });
                                        _rebuildChatSession();
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Editar pregunta'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.copy,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Copiar pregunta'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Eliminar pregunta'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );

                    final avatar = CircleAvatar(
                      radius: 14,
                      backgroundColor: isUser
                          ? Colors.blue[100]
                          : Colors.green[100],
                      child: Icon(
                        isUser ? Icons.person : Icons.eco,
                        color: isUser ? Colors.blue[700] : Colors.green[700],
                        size: 20,
                      ),
                    );

                    final row = Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: isUser
                            ? [bubble, const SizedBox(width: 8), avatar]
                            : [avatar, const SizedBox(width: 8), bubble],
                      ),
                    );

                    return Dismissible(
                      key: ValueKey(
                        'msg-$index-${msg.isUser}-${msg.text.hashCode}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.red[300],
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (dir) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar mensaje'),
                            content: const Text(
                              '¿Deseas borrar este mensaje del historial?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Borrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (dir) {
                        setState(() {
                          _messages.removeAt(index);
                        });
                        _rebuildChatSession();
                      },
                      child: GestureDetector(
                        onLongPress: () => _copyMessage(msg.text),
                        onTap:
                            !msg.isUser && _messageVariants.containsKey(msg.id)
                            ? () => _showMessageVariants(msg.id)
                            : null,
                        child: row,
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_messages.isNotEmpty && _messages.any((m) => m.isUser))
                      IconButton(
                        onPressed: _editLastUserMessage,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar última pregunta',
                      ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: _editingMessageId != null
                              ? 'Editando pregunta...'
                              : (_error != null
                                    ? 'Error: $_error'
                                    : (_chat == null
                                          ? 'Inicializando chat...'
                                          : 'Escribe tu consulta...')),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          errorText: _error,
                          suffixIcon: _editingMessageId != null
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _editingMessageId = null;
                                      _textController.clear();
                                    });
                                  },
                                  tooltip: 'Cancelar edición',
                                )
                              : null,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              _editingMessageId != null
                                  ? Icons.edit
                                  : Icons.send,
                            ),
                      label: Text(
                        _editingMessageId != null ? 'Editar' : 'Enviar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    String? id,
    DateTime? timestamp,
  }) : id = id ?? '',
       timestamp = timestamp ?? DateTime.now();

  _ChatMessage.withId({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  _ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? id,
    DateTime? timestamp,
  }) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim1;
  late final Animation<double> _anim2;
  late final Animation<double> _anim3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6),
    );
    _anim2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8),
    );
    _anim3 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(Animation<double> anim) {
    return FadeTransition(
      opacity: anim,
      child: Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_dot(_anim1), _dot(_anim2), _dot(_anim3)],
      ),
    );
  }
}


//comentario para nuevo commit, porque no coge el pull