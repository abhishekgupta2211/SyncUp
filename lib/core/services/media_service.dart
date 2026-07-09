import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_refs.dart';
import '../supabase/supabase_service.dart';

/// Uploads chat media (images, voice notes) to Supabase Storage and returns a
/// long-lived signed URL (private buckets).
class MediaService {
  MediaService._();

  static const _signedTtl = 60 * 60 * 24 * 365; // ~1 year

  static SupabaseClient get _client => SupabaseService.client;

  static Future<String> uploadChatImage({
    required String conversationId,
    required String messageId,
    required XFile file,
  }) async {
    final raw = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
    );
    final path = '$conversationId/$messageId/image.jpg';
    await _client.storage.from(Buckets.chatMedia).uploadBinary(
          path,
          compressed,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(Buckets.chatMedia).createSignedUrl(path, _signedTtl);
  }

  static Future<String> uploadVoiceNote({
    required String conversationId,
    required String messageId,
    required String filePath,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final path = '$conversationId/$messageId/voice.m4a';
    await _client.storage.from(Buckets.voiceNotes).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/mp4',
            upsert: true,
          ),
        );
    return _client.storage.from(Buckets.voiceNotes).createSignedUrl(path, _signedTtl);
  }

  /// Uploads a user avatar to the public `avatars` bucket; returns a public URL.
  static Future<String> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    final raw = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      quality: 75,
      minWidth: 512,
      minHeight: 512,
    );
    final path = '$userId/avatar.jpg';
    await _client.storage.from(Buckets.avatars).uploadBinary(
          path,
          compressed,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    // bust the CDN cache with a timestamp-free unique query isn't possible without
    // a clock; callers can append their own cache-buster if needed.
    return _client.storage.from(Buckets.avatars).getPublicUrl(path);
  }
}
