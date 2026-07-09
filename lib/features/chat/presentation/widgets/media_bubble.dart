import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/message.dart';
import 'full_screen_image_viewer.dart';

/// Inline image inside a chat bubble (local file while uploading, then network).
class ImageMessageContent extends StatelessWidget {
  const ImageMessageContent({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final hasLocal =
        message.localPath != null && File(message.localPath!).existsSync();
    final width = 224.w;
    final maxHeight = 300.h;

    Widget image;
    if (hasLocal) {
      image = Image.file(File(message.localPath!),
          width: width, fit: BoxFit.cover);
    } else if (message.mediaUrl != null) {
      image = CachedNetworkImage(
        imageUrl: message.mediaUrl!,
        width: width,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: width,
          height: 180.h,
          color: Colors.black12,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, _, _) => Container(
          width: width,
          height: 160.h,
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      image = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => openImageViewer(
        context,
        url: message.mediaUrl,
        localPath: message.localPath,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
          child: Stack(
            children: [
              image,
              if (message.pending)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
