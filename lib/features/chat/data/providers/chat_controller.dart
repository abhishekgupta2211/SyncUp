import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/message.dart';
import '../models/message_enums.dart';
import '../models/reaction.dart';
import '../repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required ChatRepository repository,
    required this.conversationId,
    required this.peerId,
    required this.myId,
  }) : _repo = repository {
    _init();
  }

  final ChatRepository _repo;
  final String conversationId;
  final String peerId;
  final String myId;
  static const _uuid = Uuid();

  final List<Message> _messages = []; // ascending (oldest → newest)
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  RealtimeChannel? _channel;

  RealtimeChannel? _typingChannel;
  bool _peerTyping = false;
  Timer? _peerTypingTimer;

  RealtimeChannel? _reactionChannel;
  final Map<String, List<Reaction>> _reactions = {};
  Message? _replyTo;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get peerTyping => _peerTyping;
  Message? get replyTo => _replyTo;
  List<Reaction> reactionsFor(String messageId) =>
      _reactions[messageId] ?? const [];

  Future<void> _init() async {
    try {
      final page = await _repo.fetchMessages(conversationId);
      _messages
        ..clear()
        ..addAll(page.reversed); // store ascending
      _hasMore = page.length >= ChatRepository.pageSize;
    } catch (_) {
      _error = 'Could not load messages';
    } finally {
      _loading = false;
      notifyListeners();
    }
    _channel = _repo.subscribe(
      conversationId,
      onInsert: _applyInsert,
      onUpdate: _applyUpdate,
    );
    _initTyping();
    _reactionChannel =
        _repo.subscribeReactions(conversationId, onChange: _loadReactions);
    unawaited(_loadReactions());
    // Catch anything that landed between the initial fetch and subscribe().
    unawaited(_reconcile());
    // Mark the peer's messages read as soon as the thread opens.
    unawaited(_repo.markRead(conversationId));
  }

  Future<void> _reconcile() async {
    try {
      final fresh = await _repo.fetchMessages(conversationId);
      var changed = false;
      for (final m in fresh) {
        if (!_contains(m.messageId)) {
          _messages.add(m);
          changed = true;
        }
      }
      if (changed) {
        _sort();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadReactions() async {
    final ids = _messages.map((m) => m.messageId).toList();
    try {
      final list = await _repo.fetchReactions(ids);
      _reactions.clear();
      for (final r in list) {
        (_reactions[r.messageId] ??= []).add(r);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final existing = _reactions[messageId] ?? const <Reaction>[];
    final hadSame = existing.any((r) => r.userId == myId && r.emoji == emoji);
    _reactions[messageId] = [
      ...existing.where((r) => r.userId != myId),
      if (!hadSame) Reaction(messageId: messageId, userId: myId, emoji: emoji),
    ];
    notifyListeners();
    try {
      if (hadSame) {
        await _repo.clearReaction(messageId);
      } else {
        await _repo.setReaction(messageId, emoji);
      }
    } catch (_) {
      unawaited(_loadReactions());
    }
  }

  void setReply(Message m) {
    _replyTo = m;
    notifyListeners();
  }

  void clearReply() {
    _replyTo = null;
    notifyListeners();
  }

  Future<void> deleteForEveryone(Message m) async {
    final idx = _indexOf(m.messageId);
    final original = idx >= 0 ? _messages[idx] : null;
    if (idx >= 0) {
      _messages[idx] = m.copyWith(deletedForEveryone: true);
      notifyListeners();
    }
    try {
      await _repo.deleteForEveryone(m.messageId);
    } catch (e) {
      // Persist failed — restore the message so the UI stays truthful.
      debugPrint('[chat.deleteForEveryone] FAILED: $e');
      if (idx >= 0 && original != null) {
        _messages[idx] = original;
        notifyListeners();
      }
    }
  }

  Future<void> deleteForMe(Message m) async {
    _messages.removeWhere((x) => x.messageId == m.messageId);
    notifyListeners();
    try {
      await _repo.deleteForMe(m.messageId);
    } catch (_) {}
  }

  void _initTyping() {
    final channel = SupabaseService.client.channel('typing:$conversationId');
    channel
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          if (payload['user_id'] != peerId) return;
          _peerTyping = payload['typing'] == true;
          notifyListeners();
          _peerTypingTimer?.cancel();
          if (_peerTyping) {
            _peerTypingTimer = Timer(const Duration(seconds: 5), () {
              _peerTyping = false;
              notifyListeners();
            });
          }
        },
      )
      ..subscribe();
    _typingChannel = channel;
  }

  void setTyping(bool typing) {
    _typingChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': myId, 'typing': typing},
    );
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final older =
          await _repo.fetchMessages(conversationId, before: _messages.first.createdAt);
      _hasMore = older.length >= ChatRepository.pageSize;
      // older comes newest→oldest; prepend as ascending
      final ascending = older.reversed.toList();
      _messages.insertAll(0, ascending.where((m) => !_contains(m.messageId)));
      unawaited(_loadReactions());
    } catch (_) {
      // keep silent; user can retry by scrolling
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    final id = _uuid.v4();
    final now = DateTime.now();
    final replyId = _replyTo?.messageId;
    final optimistic = Message(
      messageId: id,
      conversationId: conversationId,
      senderId: myId,
      receiverId: peerId,
      messageType: MessageType.text,
      message: text,
      replyMessageId: replyId,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    _messages.add(optimistic);
    _replyTo = null;
    notifyListeners();

    try {
      final saved = await _repo.sendText(
        messageId: id,
        conversationId: conversationId,
        receiverId: peerId,
        text: text,
        replyMessageId: replyId,
      );
      _replace(id, saved);
    } catch (_) {
      _replace(id, optimistic.copyWith(pending: false, failed: true));
    }
  }

  Future<void> sendImage(XFile file, {bool isSnap = false}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final optimistic = Message(
      messageId: id,
      conversationId: conversationId,
      senderId: myId,
      receiverId: peerId,
      messageType: MessageType.image,
      message: '',
      localPath: file.path,
      isSnap: isSnap,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    _messages.add(optimistic);
    notifyListeners();
    try {
      final url = await MediaService.uploadChatImage(
        conversationId: conversationId,
        messageId: id,
        file: file,
      );
      final saved = await _repo.sendMedia(
        messageId: id,
        conversationId: conversationId,
        receiverId: peerId,
        messageType: 'image',
        mediaUrl: url,
        isSnap: isSnap,
      );
      // keep the local path so the sender sees the image instantly
      _replace(id, saved.copyWith(localPath: file.path));
    } catch (_) {
      _replace(id, optimistic.copyWith(pending: false, failed: true));
    }
  }

  Future<void> sendVoice(String filePath, int durationMs) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final optimistic = Message(
      messageId: id,
      conversationId: conversationId,
      senderId: myId,
      receiverId: peerId,
      messageType: MessageType.voice,
      message: '$durationMs',
      localPath: filePath,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    _messages.add(optimistic);
    notifyListeners();
    try {
      final url = await MediaService.uploadVoiceNote(
        conversationId: conversationId,
        messageId: id,
        filePath: filePath,
      );
      final saved = await _repo.sendMedia(
        messageId: id,
        conversationId: conversationId,
        receiverId: peerId,
        messageType: 'voice',
        mediaUrl: url,
        caption: '$durationMs',
      );
      _replace(id, saved.copyWith(localPath: filePath));
    } catch (_) {
      _replace(id, optimistic.copyWith(pending: false, failed: true));
    }
  }

  Future<void> retry(Message failed) async {
    final path = failed.localPath;
    if (failed.messageType == MessageType.image) {
      if (path == null) return; // local file gone — can't re-upload
      _messages.removeWhere((m) => m.messageId == failed.messageId);
      notifyListeners();
      await sendImage(XFile(path));
    } else if (failed.messageType == MessageType.voice) {
      if (path == null) return;
      _messages.removeWhere((m) => m.messageId == failed.messageId);
      notifyListeners();
      await sendVoice(path, int.tryParse(failed.message) ?? 0);
    } else {
      _messages.removeWhere((m) => m.messageId == failed.messageId);
      notifyListeners();
      await sendText(failed.message);
    }
  }

  // ---- realtime handlers ----
  void _applyInsert(Message m) {
    final idx = _indexOf(m.messageId);
    if (idx >= 0) {
      _messages[idx] = m; // confirm an optimistic/own message
    } else {
      _messages.add(m);
      _sort();
      if (m.senderId == peerId) {
        unawaited(_repo.markRead(conversationId)); // incoming while open
      }
    }
    notifyListeners();
  }

  void _applyUpdate(Message m) {
    final idx = _indexOf(m.messageId);
    if (idx >= 0) {
      _messages[idx] = m;
      notifyListeners();
    }
  }

  int _indexOf(String id) => _messages.indexWhere((m) => m.messageId == id);
  bool _contains(String id) => _indexOf(id) >= 0;

  void _replace(String id, Message m) {
    final idx = _indexOf(id);
    if (idx >= 0) {
      _messages[idx] = m;
      notifyListeners();
    }
  }

  void _sort() =>
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  void dispose() {
    _peerTypingTimer?.cancel();
    final ch = _channel;
    if (ch != null) _repo.removeChannel(ch);
    final tc = _typingChannel;
    if (tc != null) _repo.removeChannel(tc);
    final rc = _reactionChannel;
    if (rc != null) _repo.removeChannel(rc);
    super.dispose();
  }
}
