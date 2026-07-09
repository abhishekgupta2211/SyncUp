import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen image with pinch-to-zoom.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({super.key, this.url, this.localPath});

  final String? url;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && File(localPath!).existsSync();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: hasLocal
              ? Image.file(File(localPath!))
              : (url != null
                  ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.contain)
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

void openImageViewer(BuildContext context, {String? url, String? localPath}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FullScreenImageViewer(url: url, localPath: localPath),
    ),
  );
}
