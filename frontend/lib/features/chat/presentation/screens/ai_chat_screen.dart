import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! 👋 I\'m the PharmaTwin AI Assistant.\n\nI can help you with drug information, predict stability, find alternatives, and answer questions about formulation.\n\nWhat would you like to know?',
      'source': 'PharmaTwin AI',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/chat/ask', data: {
        'message': text,
        'history': [],
      });

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': response.data['reply'] ?? 'No response',
            'source': response.data['source'],
            'data': response.data['data'],
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sorry, I encountered an error: $e',
            'source': 'System Error',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const Icon(Icons.auto_awesome, color: AppTheme.neonCyan, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    message['source'] ?? 'AI',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                ],
                if (isUser) ...[
                  const Text(
                    'YOU',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: AppTheme.neonPurple,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.person, color: AppTheme.neonPurple, size: 14),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.neonPurple.withOpacity(0.15) 
                    : AppTheme.bgCard.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                  bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(12),
                ),
                border: Border.all(
                  color: isUser 
                      ? AppTheme.neonPurple.withOpacity(0.3) 
                      : AppTheme.borderSubtle,
                ),
              ),
              child: Text(
                message['content'],
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            if (message['data'] != null && !isUser) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                ),
                child: const Text(
                  '✓ Simulation Data Attached',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.neonGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: const Text(
          'AI ASSISTANT',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppTheme.neonCyan,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.neonCyan.withOpacity(0.3),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ParticleBackground(),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI is thinking...',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1.seconds),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  border: const Border(
                    top: BorderSide(color: AppTheme.borderGlass, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white, fontFamily: 'SpaceMono', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask about stability, formulations...',
                            hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                            filled: true,
                            fillColor: AppTheme.bgDeep,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: AppTheme.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppTheme.neonCyan),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isLoading ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
