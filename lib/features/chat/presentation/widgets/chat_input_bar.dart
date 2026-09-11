import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/data/providers/settings_provider.dart';

/// Composer: emoji picker + text + attachment menu (gallery/camera/games/etc) + voice recording.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onTyping,
    this.onPickImage,
    this.onSendVoice,
    this.replyToText,
    this.onCancelReply,
  });

  final ValueChanged<String> onSend;
  final ValueChanged<bool>? onTyping;
  final Function(XFile file, {bool isSnap})? onPickImage;
  final void Function(String path, int durationMs)? onSendVoice;
  final String? replyToText;
  final VoidCallback? onCancelReply;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  bool _hasText = false;
  bool _showEmoji = false;
  bool _vanishMode = false;
  Timer? _typingTimer;
  bool _typingSent = false;

  bool _recording = false;
  String? _recordPath;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    if (has) {
      if (!_typingSent) {
        widget.onTyping?.call(true);
        _typingSent = true;
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
    } else {
      _stopTyping();
    }
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_typingSent) {
      widget.onTyping?.call(false);
      _typingSent = false;
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _stopTyping();
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _showEmoji = true);
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isSnap = false}) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file != null) widget.onPickImage?.call(file, isSnap: isSnap);
    } catch (_) {
      _toast('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _toast('Microphone permission needed');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _recordPath = path;
    _recordElapsed = Duration.zero;
    _stopwatch..reset()..start();
    setState(() => _recording = true);
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordElapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    _stopwatch.stop();
    final path = await _recorder.stop();
    final ms = _stopwatch.elapsedMilliseconds;
    setState(() => _recording = false);
    if (path != null && ms >= 1000) {
      widget.onSendVoice?.call(path, ms);
    } else {
      if (path != null) {
        try { await File(path).delete(); } catch (_) {}
      }
      _toast('Hold longer to record');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    if (_recordPath != null) {
      try { await File(_recordPath!).delete(); } catch (_) {}
    }
    setState(() => _recording = false);
  }

  void _sendAIGame() {
    final games = [
      "🎮 AI Truth: What is your most embarrassing social media moment?",
      "🎮 AI Dare: Send the 5th photo from your gallery right now!",
      "🎮 AI Trivia: Which planet is known as the Red Planet?",
      "🎮 AI Vibe Check: What is the one thing that makes you instantly happy?",
      "🎮 AI Challenge: Can you reply using only emojis for the next 5 minutes?",
      "🎮 Tic-Tac-Toe: Let's play! ❌⭕"
    ];
    final randomGame = games[DateTime.now().millisecond % games.length];
    _controller.text = randomGame;
    _onChanged();
    Navigator.pop(context);
    _toast('AI Arena: Challenge selected! 🎮');
  }

  void _sendIcebreaker() {
    final icebreakers = [
      "If you could travel anywhere right now, where would it be? ✈️",
      "What's the most 'SyncUp' thing that happened to you today? 😂",
      "Pizza with pineapple or without? This is a serious vibe check! 🍕",
      "What's your current favorite song on repeat? 🎵",
      "If you were a superhero, what would your name be? 🦸",
    ];
    final randomIcebreaker = icebreakers[DateTime.now().millisecond % icebreakers.length];
    _controller.text = randomIcebreaker;
    _onChanged();
    Navigator.pop(context);
    _toast('AI Magic: Icebreaker ready! ✨');
  }

  void _showGiftSheet(ThemeData theme) {
    Navigator.pop(context); // Close actions menu first
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a Surprise Gift 🎁', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _giftItem('🌹', '10', theme),
                _giftItem('❤️', '50', theme),
                _giftItem('💎', '200', theme),
                _giftItem('👑', '500', theme),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(String icon, String price, ThemeData theme) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 32.sp)),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.monetization_on, size: 12.r, color: Colors.amber),
            Text(price, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showActionsMenu() {
    final theme = Theme.of(context);
    _focus.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              runSpacing: 20.h,
              spacing: 8.w,
              alignment: WrapAlignment.start,
              children: [
                _actionItem(Icons.photo_library, 'Gallery', Colors.blue, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
                _actionItem(Icons.camera_alt, 'Camera', Colors.teal, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                }),
                _actionItem(Icons.auto_delete, 'Vanish', Colors.orange, () {
                  setState(() => _vanishMode = !_vanishMode);
                  Navigator.pop(ctx);
                  _toast(_vanishMode ? 'Vanish mode ON 🔥' : 'Vanish mode OFF');
                }),
                _actionItem(Icons.sports_esports, 'Games', Colors.green, _sendAIGame),
                _actionItem(Icons.camera, 'Snap', Colors.purple, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, isSnap: true);
                }),
                _actionItem(Icons.auto_fix_high, 'Icebreaker', Colors.amber, _sendIcebreaker),
                _actionItem(Icons.card_giftcard, 'Gift', Colors.pink, () => _showGiftSheet(theme)),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 85.w,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.r),
            ),
          ),
          SizedBox(height: 8.h),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    if (_typingSent) widget.onTyping?.call(false);
    _controller.dispose();
    _focus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyToText != null) _replyPreview(theme),
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h + MediaQuery.of(context).padding.bottom),
          child: _recording ? _recordingBar(theme) : _inputRow(theme),
        ),
        if (_showEmoji)
          SizedBox(
            height: 280.h,
            child: EmojiPicker(
              textEditingController: _controller,
              config: Config(
                height: 280.h,
                emojiViewConfig: EmojiViewConfig(backgroundColor: theme.colorScheme.surface, columns: 8, emojiSizeMax: 28),
                categoryViewConfig: CategoryViewConfig(backgroundColor: theme.colorScheme.surface, indicatorColor: theme.colorScheme.primary, iconColorSelected: theme.colorScheme.primary),
                bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
              ),
            ),
          ),
      ],
    );
  }

  Widget _replyPreview(ThemeData theme) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16.r, color: theme.colorScheme.primary),
          SizedBox(width: 8.w),
          Expanded(child: Text(widget.replyToText!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
          GestureDetector(onTap: widget.onCancelReply, child: Icon(Icons.close, size: 18.r)),
        ],
      ),
    );
  }

  Widget _inputRow(ThemeData theme) {
    final enterToSend = context.watch<SettingsProvider>().enterToSend;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(_showEmoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined,
                      color: theme.colorScheme.primary, size: 24.r),
                  onPressed: _toggleEmoji,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15.sp),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: enterToSend ? TextInputAction.send : TextInputAction.newline,
                    onSubmitted: enterToSend ? (_) => _send() : null,
                    onTap: () { if (_showEmoji) setState(() => _showEmoji = false); },
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 24.r),
                  onPressed: _showActionsMenu,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: _hasText ? _send : _startRecording,
          child: _sendButton(_hasText ? Icons.send_rounded : Icons.mic),
        ),
      ],
    );
  }

  Widget _recordingBar(ThemeData theme) {
    String two(int n) => n.toString().padLeft(2, '0');
    final label = '${two(_recordElapsed.inMinutes)}:${two(_recordElapsed.inSeconds % 60)}';
    return Row(
      children: [
        IconButton(icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 24.r), onPressed: _cancelRecording),
        Expanded(
          child: Row(
            children: [
              Icon(Icons.fiber_manual_record, color: AppColors.danger, size: 14.r),
              SizedBox(width: 8.w),
              Text('Recording  $label', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        GestureDetector(onTap: _stopAndSendRecording, child: _sendButton(Icons.send_rounded)),
      ],
    );
  }

  Widget _sendButton(IconData icon) {
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        gradient: AppColors.gradientFrom(Theme.of(context).colorScheme.primary),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(icon, key: ValueKey(icon), color: Colors.white, size: 22.r),
      ),
    );
  }
}
