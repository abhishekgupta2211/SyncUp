import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/message.dart';
import '../../data/models/message_enums.dart';
import '../../data/repositories/chat_repository.dart';

class ConversationMediaPage extends StatefulWidget {
  const ConversationMediaPage({
    super.key,
    required this.conversationId,
    required this.peerName,
  });

  final String conversationId;
  final String peerName;

  @override
  State<ConversationMediaPage> createState() => _ConversationMediaPageState();
}

class _ConversationMediaPageState extends State<ConversationMediaPage> {
  final _repo = ChatRepository(SupabaseService.client);
  List<Message>? _media;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.fetchMedia(widget.conversationId);
      if (mounted) setState(() { _media = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Media, Links and Docs'),
            Text(widget.peerName, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _media == null || _media!.isEmpty
              ? const Center(child: Text('No media shared yet'))
              : GridView.builder(
                  padding: EdgeInsets.all(2.r),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2.r,
                    mainAxisSpacing: 2.r,
                  ),
                  itemCount: _media!.length,
                  itemBuilder: (context, index) {
                    final m = _media![index];
                    return _MediaTile(message: m);
                  },
                ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Full screen view logic could go here
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          if (message.messageType == MessageType.video)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
            ),
        ],
      ),
    );
  }
}
