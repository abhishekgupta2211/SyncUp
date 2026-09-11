import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/providers/ai_provider.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIProvider>().init();
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<AIProvider>().sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    if (!mounted) return;
    context.read<AIProvider>().sendImage(file);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 20.r, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SyncUp AI', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(ai.isTyping ? 'Thinking...' : 'Personality: ${ai.personality}', 
                  style: theme.textTheme.labelSmall?.copyWith(color: ai.isTyping ? theme.colorScheme.primary : Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_suggest_outlined),
            onSelected: ai.setPersonality,
            itemBuilder: (ctx) => [
              'Friendly', 'Professional', 'Funny', 'Flirty'
            ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ai.loading && ai.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                    itemCount: ai.messages.length + (ai.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == ai.messages.length && ai.isTyping) {
                        return _TypingIndicator();
                      }
                      return _AIBubble(message: ai.messages[index]);
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image_outlined, color: theme.colorScheme.primary),
            onPressed: _pickImage,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIBubble extends StatelessWidget {
  const _AIBubble({required this.message});
  final AIMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 0.78.sw),
        decoration: BoxDecoration(
          gradient: isUser ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]) : null,
          color: isUser ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
            bottomRight: Radius.circular(isUser ? 4.r : 20.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: message.imageUrl!.startsWith('temp') 
                  ? Image.file(File(message.imageUrl!), height: 200.h, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(message.imageUrl!, height: 200.h, width: double.infinity, fit: BoxFit.cover),
              ),
              SizedBox(height: 8.h),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    message.message,
                    style: TextStyle(color: isUser ? Colors.white : theme.colorScheme.onSurface, fontSize: 14.5.sp, height: 1.4),
                  ),
                ),
                if (!isUser) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI is reading the message... 🎙️'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Icon(Icons.volume_up_rounded, size: 16.r, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Container(
            width: 6.r,
            height: 6.r,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.5), shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).scale(duration: 600.ms, delay: (i * 200).ms, begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2))),
        ),
      ),
    );
  }
}
