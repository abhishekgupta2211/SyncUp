import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/chat_wallpaper.dart';
import '../../data/providers/settings_provider.dart';

/// Chat wallpaper picker — built-in presets + a custom image from the gallery.
class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  bool _busy = false;

  Future<void> _pickImage() async {
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null) {
        final dir = await getApplicationDocumentsDirectory();
        final dest =
            '${dir.path}/chat_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(picked.path).copy(dest);
        if (mounted) {
          await context.read<SettingsProvider>().setWallpaperImage(dest);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not set that image')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<SettingsProvider>();
    final customPath = s.wallpaperPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallpaper'),
        actions: [
          if (s.wallpaperId != 'default')
            TextButton(
              onPressed: () =>
                  context.read<SettingsProvider>().setWallpaperPreset('default'),
              child: const Text('Reset'),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          _customCard(context, customPath, s),
          SizedBox(height: 16.h),
          Text('Presets',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 10.h),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.62,
            children: [
              for (final w in kChatWallpapers)
                _swatch(context, w, selected: s.wallpaperId == w.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customCard(
      BuildContext context, String? customPath, SettingsProvider s) {
    final theme = Theme.of(context);
    final isCustom = s.wallpaperId == 'custom' && customPath != null;
    return InkWell(
      onTap: _busy ? null : _pickImage,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCustom
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isCustom ? 2 : 1,
          ),
          image: isCustom
              ? DecorationImage(
                  image: FileImage(File(customPath)), fit: BoxFit.cover)
              : null,
        ),
        child: Center(
          child: _busy
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 28.r,
                        color: isCustom ? Colors.white : theme.colorScheme.primary),
                    SizedBox(height: 6.h),
                    Text(
                      isCustom ? 'Change my photo' : 'Choose from gallery',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isCustom ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _swatch(BuildContext context, ChatWallpaper w,
      {required bool selected}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.read<SettingsProvider>().setWallpaperPreset(w.id),
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: w.isDefault
                  ? BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: theme.colorScheme.outline),
                    )
                  : (w.preview as BoxDecoration).copyWith(
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
              child: selected
                  ? Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 22.r)
                  : (w.isDefault
                      ? Icon(Icons.block,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          size: 20.r)
                      : null),
            ),
          ),
          SizedBox(height: 5.h),
          Text(w.label,
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
