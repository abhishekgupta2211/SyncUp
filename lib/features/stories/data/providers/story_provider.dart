import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/story.dart';
import '../repositories/story_repository.dart';

/// App-lifetime story state: my + friends' active stories, and my seen set.
/// Resets on account switch so one user never sees another's stories.
class StoryProvider extends ChangeNotifier {
  StoryProvider() {
    _authSub = SupabaseService.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedOut:
          _clear();
        case AuthChangeEvent.signedIn:
          load();
        case AuthChangeEvent.initialSession:
          // A restored session emits this (not signedIn) on cold start.
          if (s.session != null) load();
        default:
          break;
      }
    });
    load();
  }

  final StoryRepository repo = StoryRepository();
  late final StreamSubscription<AuthState> _authSub;
  List<UserStories> _groups = [];
  Set<String> _seen = {};
  bool _loading = true;
  bool _posting = false;
  String? error;

  bool get loading => _loading;
  bool get posting => _posting;
  String? get myId => SupabaseService.currentUserId;

  UserStories? get myStories {
    for (final g in _groups) {
      if (g.userId == myId) return g;
    }
    return null;
  }

  List<UserStories> get friendStories =>
      _groups.where((g) => g.userId != myId).toList();

  bool hasUnseen(UserStories g) =>
      g.stories.any((s) => !_seen.contains(s.id));

  bool isSeen(String storyId) => _seen.contains(storyId);

  Future<void> load() async {
    _loading = true;
    error = null;
    notifyListeners();
    try {
      _groups = await repo.fetchActiveStories();
      _seen = await repo.fetchMySeen();
    } catch (e, st) {
      error = e.toString();
      debugPrint('[stories.load] FAILED: $e\n$st');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> postStories(List<XFile> files) async {
    if (files.isEmpty) return;
    _posting = true;
    error = null;
    notifyListeners();
    try {
      for (final f in files) {
        await repo.postStory(f);
      }
      await load();
    } catch (e) {
      error = e.toString();
    } finally {
      _posting = false;
      notifyListeners();
    }
  }

  Future<void> deleteStory(String storyId) async {
    await repo.deleteStory(storyId);
    await load();
  }

  Future<void> markViewed(String storyId) async {
    if (_seen.contains(storyId)) return;
    _seen.add(storyId);
    notifyListeners();
    try {
      await repo.recordView(storyId);
    } catch (_) {}
  }

  void _clear() {
    _groups = [];
    _seen = {};
    _loading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
