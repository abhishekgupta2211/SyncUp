import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../profile/data/models/profile.dart';
import '../repositories/contacts_repository.dart';

/// Search state for the People / New Chat screens (debounced).
class ContactsProvider extends ChangeNotifier {
  ContactsProvider(this._repo);

  final ContactsRepository _repo;
  Timer? _debounce;

  String _query = '';
  List<Profile> _results = [];
  bool _loading = false;
  String? _error;

  String get query => _query;
  List<Profile> get results => _results;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasQuery => _query.trim().isNotEmpty;

  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _results = [];
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<void> _run() async {
    final q = _query;
    try {
      final res = await _repo.search(q);
      if (q != _query) return; // a newer query superseded this one
      _results = res;
      _error = null;
    } catch (_) {
      _error = 'Search failed. Check your connection.';
      _results = [];
    } finally {
      if (q == _query) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<String> relationship(String id) => _repo.relationship(id);
  Future<void> sendRequest(String id) => _repo.sendRequest(id);
  Future<void> acceptRequest(String id) => _repo.acceptRequest(id);
  Future<void> removeFriendship(String id) => _repo.removeFriendship(id);
  Future<void> blockUser(String id) => _repo.blockUser(id);
  Future<void> unblockUser(String id) => _repo.unblockUser(id);
  Future<List<Profile>> incomingRequests() => _repo.incomingRequests();
  Future<List<Profile>> outgoingRequests() => _repo.outgoingRequests();
  Future<List<Profile>> blockedUsers() => _repo.blockedUsers();

  /// Opens (or creates) the 1:1 conversation; returns its id, or null on error.
  Future<String?> startChat(String otherUserId) async {
    try {
      return await _repo.getOrCreateConversation(otherUserId);
    } catch (_) {
      _error = 'Could not start the chat. Try again.';
      notifyListeners();
      return null;
    }
  }

  String? get myId => SupabaseService.currentUserId;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
