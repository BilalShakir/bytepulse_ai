import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';

class GeminiAgentScreen extends ConsumerStatefulWidget {
  const GeminiAgentScreen({super.key});

  @override
  ConsumerState<GeminiAgentScreen> createState() => _GeminiAgentScreenState();
}

class _GeminiAgentScreenState extends ConsumerState<GeminiAgentScreen> {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isRecording = false;

  final List<String> promptChips = [
    'Why does this matter?',
    'Show code example',
    'What are the risks?',
    'Synthesize architectural impact',
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groundedContext = ref.watch(groundedContextProvider);
    final groundedCard = ref.watch(groundedCardProvider);
    final messages = ref.watch(chatMessagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);

    _scrollToBottom();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
            children: [
              const SizedBox(height: 12),

              // Grounded Context Badge (Only show when explicitly attached)
              if (groundedCard != null || (groundedContext != null && groundedContext.isNotEmpty)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AIGlowColors.electricCyan.withOpacity(0.1),
                        AIGlowColors.hyperViolet.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AIGlowColors.electricCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 16, color: AIGlowColors.electricCyan),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                groundedCard != null
                                    ? 'Grounded in: ${groundedCard.headline}'
                                    : 'Grounded in: $groundedContext',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AIGlowColors.electricCyan,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(groundedContextProvider.notifier).state = null;
                          ref.read(groundedCardProvider.notifier).state = null;
                        },
                        child: const Text(
                          'Detach Context',
                          style: TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Prompt Chips
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: promptChips.length,
                  itemBuilder: (context, index) {
                    final p = promptChips[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          ref.read(chatMessagesProvider.notifier).sendUserQuery(p);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AIGlowColors.softBorder),
                          ),
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AIGlowColors.mediumSlate),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Voice Microphone Recording Overlay
              if (isRecording) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AIGlowColors.roseCritical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AIGlowColors.roseCritical),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mic, color: AIGlowColors.roseCritical, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Listening to voice prompt... "Analyze memory bandwidth..."',
                            style: TextStyle(fontSize: 12, color: AIGlowColors.roseCritical),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isRecording = false),
                        child: const Text(
                          'Stop',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AIGlowColors.roseCritical,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Chat Messages Window
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length + (isStreaming ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && isStreaming) {
                      return _buildStreamingIndicator();
                    }
                    final msg = messages[index];
                    return _buildChatBubble(msg);
                  },
                ),
              ),
              const SizedBox(height: 4),

              // AI Guardrails Disclaimer Banner
              const Text(
                'AI-generated analysis may contain errors. Verify critical technical decisions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AIGlowColors.softBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(139, 92, 246, 0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          hintText: 'Ask Live Gemini anything...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            ref.read(chatMessagesProvider.notifier).sendUserQuery(val.trim());
                            textController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isRecording ? Icons.mic_off : Icons.mic,
                        color: isRecording ? AIGlowColors.roseCritical : AIGlowColors.mediumSlate,
                      ),
                      onPressed: () {
                        setState(() {
                          isRecording = !isRecording;
                        });
                        if (isRecording) {
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted && isRecording) {
                              setState(() => isRecording = false);
                              ref.read(chatMessagesProvider.notifier).sendUserQuery(
                                  'Analyze memory bandwidth & tensor parallel speedup for 64-node clusters');
                            }
                          });
                        }
                      },
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: AIGlowColors.iridescentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        onPressed: () {
                          if (textController.text.trim().isNotEmpty) {
                            ref.read(chatMessagesProvider.notifier).sendUserQuery(textController.text.trim());
                            textController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildStreamingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AIGlowColors.softBorder),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AIGlowColors.electricCyan),
          ),
          SizedBox(width: 8),
          Text(
            'Gemini Streaming Response...',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AIGlowColors.electricCyan),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AIGlowColors.iridescentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(6, 182, 212, 0.3),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AIGlowColors.softBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(139, 92, 246, 0.06),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AIGlowColors.electricCyan),
                    SizedBox(width: 6),
                    Text(
                      'Gemini 3.6 Flash API',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AIGlowColors.electricCyan,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AIGlowColors.emeraldMint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Confidence: ${msg.confidence}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AIGlowColors.emeraldMint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFormattedMarkdownText(context, msg.text),
            if (msg.codeSnippet != null && msg.codeSnippet!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildCodeConsoleWidget(context, 'PYTHON 3.11', msg.codeSnippet!),
            ],
            if (msg.suggestedTopic != null && msg.suggestedTopic!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  final newTopic = CustomTopic(
                    id: 'topic-${DateTime.now().millisecondsSinceEpoch}',
                    name: msg.suggestedTopic!,
                    keywords: [msg.suggestedTopic!.toLowerCase()],
                    addedAt: 'Just now from Gemini Chat',
                  );
                  ref.read(customTopicsProvider.notifier).addTopic(newTopic);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('➕ Added "${msg.suggestedTopic}" to your Custom Feeds & Firestore!'),
                      backgroundColor: AIGlowColors.electricCyan,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AIGlowColors.electricCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AIGlowColors.electricCyan),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 14, color: AIGlowColors.electricCyan),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '➕ Add "${msg.suggestedTopic}" to My Feeds',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AIGlowColors.electricCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Sources: ', style: TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate)),
                  ...msg.citations.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(c, style: const TextStyle(fontSize: 9, color: AIGlowColors.electricCyan)),
                          backgroundColor: AIGlowColors.iceWhite,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                ref.read(chatMessagesProvider.notifier).toggleSave(msg.id);
                ref.read(savedLibraryProvider.notifier).addItem(
                      SavedItem(
                        id: 'lib-${DateTime.now().millisecondsSinceEpoch}',
                        type: 'gemini_answer',
                        title: 'Gemini Answer: ${msg.text.substring(0, msg.text.length > 30 ? 30 : msg.text.length)}...',
                        snippet: msg.text,
                        codeSnippet: msg.codeSnippet,
                        savedAt: 'Just now',
                        source: 'Live Gemini Session',
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved answer to your offline library!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AIGlowColors.electricCyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AIGlowColors.electricCyan),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(msg.saved ? Icons.check : Icons.bookmark_add_outlined,
                        size: 12, color: AIGlowColors.electricCyan),
                    const SizedBox(width: 4),
                    Text(
                      msg.saved ? 'Saved to Library' : 'Save Answer',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AIGlowColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedMarkdownText(BuildContext context, String rawText) {
    return MarkdownBody(
      data: rawText,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 13, color: AIGlowColors.inkSlate, height: 1.45),
        h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
        h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
        h4: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
        strong: const TextStyle(fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
        em: const TextStyle(fontStyle: FontStyle.italic, color: AIGlowColors.mediumSlate),
        listBullet: const TextStyle(color: AIGlowColors.electricCyan, fontWeight: FontWeight.bold),
        code: TextStyle(
          backgroundColor: AIGlowColors.iceWhite,
          color: AIGlowColors.electricCyan,
          fontSize: 12,
          fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AIGlowColors.softBorder),
        ),
        codeblockPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildCodeConsoleWidget(BuildContext context, String lang, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, size: 14, color: AIGlowColors.electricCyan),
                    const SizedBox(width: 6),
                    Text(
                      lang,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        backgroundColor: AIGlowColors.electricCyan,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 12, color: AIGlowColors.electricCyan),
                      SizedBox(width: 4),
                      Text(
                        'Copy Code',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AIGlowColors.electricCyan),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF38BDF8),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
