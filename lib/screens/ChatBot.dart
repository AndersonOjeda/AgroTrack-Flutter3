import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isTyping = false;
  ChatSession? _chat;
  String? _error;
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
    // Variantes comúnmente disponibles en el nivel gratuito (1.x)
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
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
    var preferredRaw = dotenv.env['GEMINI_MODEL']?.trim();
    if (preferredRaw != null && preferredRaw.toLowerCase().contains('flash-light')) {
      // Normaliza a "flash-lite" (algunas cuentas usan esta denominación)
      preferredRaw = preferredRaw.toLowerCase().replaceAll('flash-light', 'flash-lite');
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

    for (final name in sequence) {
      if (tried.contains(name)) continue;
      tried.add(name);
      try {
        final model = _buildModel(name, apiKey);
        _chat = model.startChat(history: _buildHistoryFromMessages());
        _modelName = name;
        return;
      } catch (e) {
        final m = e.toString();
        final recoverable = m.contains('not found') ||
            m.contains('not supported') ||
            m.contains('Unsupported') ||
            m.contains('404');
        if (!recoverable) {
          _error = 'Error al iniciar el chat: $m';
          return;
        }
      }
    }
    _error = 'Ningún modelo Gemini disponible. Prueba con otra clave o región.';
  }

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _error = 'Falta GEMINI_API_KEY en .env';
      return;
    }

    // Intenta iniciar con cualquier versión disponible
    _initChatWithAnyModel(apiKey);

    _messages.add(
      const _ChatMessage(
        text:
            '¡Hola! Soy tu orientador agrícola. Cuéntame tu consulta '
            'sobre cultivos, suelos, riego, plagas, nutrición o comercialización. '
            'Indica cultivo, etapa, suelo, clima/localidad y síntomas. '
            'Daré recomendaciones generales y prácticas sostenibles; esto no '
            'reemplaza asesoría técnica profesional local.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_chat == null || _error != null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat!.sendMessage(Content.text(text));
      final reply = response.text?.trim() ??
          'No pude elaborar una respuesta en este momento. Intenta reformular '
          'tu consulta con más contexto (cultivo, etapa, suelo, clima/localidad, síntomas) '
          'y evita temas sensibles. Recuerda que esto no reemplaza asesoría técnica agrícola local.';
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
        _scrollToBottom();
      }
    } catch (e) {
      final msg = e.toString();
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
            final reply = response.text?.trim() ??
                'No pude elaborar una respuesta en este momento. Intenta reformular '
                'tu consulta con más contexto (cultivo, etapa, suelo, clima/localidad, síntomas) '
                'y evita temas sensibles. Recuerda que esto no reemplaza asesoría técnica agrícola local.';
            if (mounted) {
              setState(() {
                _messages.add(_ChatMessage(text: reply, isUser: false));
              });
              _scrollToBottom();
            }
            return;
          } catch (_) {
            continue;
          }
        }
      }
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Ocurrió un error: ${e.toString()}',
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
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
                  content: const Text('¿Deseas borrar todo el historial de mensajes?'),
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
      body: SafeArea(
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
                      ? Theme.of(context).primaryColor.withOpacity(0.15)
                      : Colors.grey[100];
                  final borderColor = isUser
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300];

                  final bubble = Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      border: Border.all(color: borderColor ?? Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  );

                  final avatar = CircleAvatar(
                    radius: 14,
                    backgroundColor: isUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400],
                    child: Text(
                      isUser ? 'U' : 'AI',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );

                  final row = Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: isUser
                        ? [bubble, const SizedBox(width: 8), avatar]
                        : [avatar, const SizedBox(width: 8), bubble],
                  );

                  return Dismissible(
                    key: ValueKey('msg-$index-${msg.isUser}-${msg.text.hashCode}'),
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
                              '¿Deseas borrar este mensaje del historial?'),
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
                    child: row,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading && _error == null,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu consulta...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        (_isLoading || _error != null) ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    label: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
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
    _anim1 = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6));
    _anim2 = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8));
    _anim3 = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0));
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
        children: [
          _dot(_anim1),
          _dot(_anim2),
          _dot(_anim3),
        ],
      ),
    );
  }
}
