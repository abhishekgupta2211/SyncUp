import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_service.dart';

class AIMessage {
  final String id;
  final String role; 
  final String message;
  final String? imageUrl; // Support for images
  final DateTime createdAt;

  AIMessage({
    required this.id,
    required this.role,
    required this.message,
    this.imageUrl,
    required this.createdAt,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'],
      role: json['role'],
      message: json['message'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AIProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  List<AIMessage> _messages = [];
  bool _loading = false;
  bool _isTyping = false;
  String? _conversationId;
  String _personality = 'Friendly'; // NEW

  List<AIMessage> get messages => _messages;
  bool get loading => _loading;
  bool get isTyping => _isTyping;
  String get personality => _personality;

  void setPersonality(String p) {
    _personality = p;
    notifyListeners();
  }

  Future<String> generateBio(String name, List<String> interests) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate AI
    final interestList = interests.isNotEmpty ? interests.join(', ') : 'meeting new people';
    return "Hi, I'm $name! I'm passionate about $interestList. Let's connect and share some good vibes on SyncUp! ✨🚀";
  }

  Future<void> init() async {
    if (_conversationId != null) return;
    _loading = true;
    notifyListeners();
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;
      final data = await _client.from('ai_conversations').select().eq('user_id', userId).maybeSingle();
      if (data == null) {
        final newConv = await _client.from('ai_conversations').insert({'user_id': userId, 'title': 'SyncUp AI'}).select().single();
        _conversationId = newConv['id'];
      } else {
        _conversationId = data['id'];
        await _loadMessages();
      }
    } catch (e) { debugPrint('AI Init Error: $e'); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final data = await _client.from('ai_messages').select().eq('conversation_id', _conversationId!).order('created_at', ascending: true);
    _messages = (data as List).map((m) => AIMessage.fromJson(m)).toList();
    notifyListeners();
  }

  Future<void> sendImage(XFile file) async {
    // 1. Show user image optimistically
    final id = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(AIMessage(id: id, role: 'user', message: 'Analyzing image...', imageUrl: file.path, createdAt: DateTime.now()));
    _isTyping = true;
    notifyListeners();

    // 2. In real app, upload to Supabase Storage and call Gemini/GPT-4V Edge Function
    await Future.delayed(const Duration(seconds: 2));
    
    final botMsg = AIMessage(
      id: 'bot_$id',
      role: 'assistant',
      message: "That's a beautiful image! I can see some interesting details there. How can I help you with this? 📸✨",
      createdAt: DateTime.now()
    );
    _messages.add(botMsg);
    _isTyping = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_conversationId == null || text.trim().isEmpty) return;
    final userMsg = AIMessage(id: 'temp_${DateTime.now().millisecondsSinceEpoch}', role: 'user', message: text, createdAt: DateTime.now());
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    try {
      await _client.from('ai_messages').insert({'conversation_id': _conversationId, 'role': 'user', 'message': text});
      await Future.delayed(const Duration(seconds: 1));
      
      final botResponse = _getAdvancedResponse(text);
      final assistantMsgData = await _client.from('ai_messages').insert({
        'conversation_id': _conversationId, 'role': 'assistant', 'message': botResponse,
      }).select().single();
      _messages.add(AIMessage.fromJson(assistantMsgData));
    } catch (e) { debugPrint('AI Send Error: $e'); }
    finally { _isTyping = false; notifyListeners(); }
  }

  String _getAdvancedResponse(String query) {
    query = query.toLowerCase();
    
    String prefix = "";
    if (_personality == 'Flirty') prefix = "Hey gorgeous! 😉 ";
    if (_personality == 'Funny') prefix = "Lol! Listen to this... 😂 ";
    if (_personality == 'Professional') prefix = "Greetings. I have analyzed your request. 🧐 ";

    if (query.startsWith('/draw')) {
      return "$prefix🎨 AI Art Studio: Generating your masterpiece... [Simulation: Imagine a beautiful image based on '${query.replaceFirst('/draw', '').trim()}'] ✨. In the pro version, I'll use DALL-E to show you the result here!";
    }

    if (query.contains('?') || query.length > 20) {
      return "$prefix That's a great question! As an advanced AI, I've analyzed your query. It seems you're looking for deep insights. I'm connected to the SyncUp Knowledge Cloud to provide you the best answers! 🌐🧠";
    }
    if (query.contains('hi') || query.contains('hello')) return "$prefix Hey there! SyncUp AI is online. Ready to help you with anything! ⚡";
    return "$prefix Understood. I'm processing that. SyncUp AI is here to make your experience seamless. Any specific details you want me to look into? 🧐";
  }
}
