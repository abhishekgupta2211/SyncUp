import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../contacts/data/repositories/contacts_repository.dart';
import '../pages/chat_thread_screen.dart';

class NotesBar extends StatelessWidget {
  const NotesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 100.h,
      child: FutureBuilder(
        future: SupabaseService.client.from('user_notes').select('*, profile:profiles(display_name, avatar_url)'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final notes = snapshot.data as List;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: notes.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _buildAddNote(context, theme);
              final n = notes[i - 1];
              return _buildNoteItem(context, n, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddNote(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: GestureDetector(
        onTap: () => _showNoteDialog(context),
        child: Column(
          children: [
            Stack(
              children: [
                AppAvatar(name: 'Me', radius: 30.r),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.add, size: 16.r, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text('Your note', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, dynamic n, ThemeData theme) {
    final profile = n['profile'];
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: GestureDetector(
        onTap: () async {
          // Open chat with the user
          final userId = n['user_id'];
          if (userId == SupabaseService.currentUserId) {
            _showNoteDialog(context);
            return;
          }
          
          try {
            final repo = ContactsRepository(SupabaseService.client);
            final convId = await repo.getOrCreateConversation(userId);
            
            if (context.mounted) {
              openChat(
                context,
                conversationId: convId,
                peerId: userId,
                peerName: profile['display_name'],
                peerUsername: '', 
                peerAvatarUrl: profile['avatar_url'],
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open chat')),
              );
            }
          }
        },
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                AppAvatar(name: profile['display_name'], avatarUrl: profile['avatar_url'], radius: 30.r),
                Positioned(
                  top: -15.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    constraints: BoxConstraints(maxWidth: 70.w),
                    child: Text(
                      n['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Text(profile['display_name'].split(' ')[0], style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          decoration: const InputDecoration(hintText: "What's on your mind?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await SupabaseService.client.from('user_notes').upsert({
                  'user_id': SupabaseService.currentUserId!,
                  'content': text,
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note updated! ✨')));
                }
              } catch (_) {
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
