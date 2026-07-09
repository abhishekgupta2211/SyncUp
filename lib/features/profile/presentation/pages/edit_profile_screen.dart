import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/media_service.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../ai/data/providers/ai_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/models/profile.dart';

/// Edit display name, @username, status line, and profile photo (DP).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _picker = ImagePicker();
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.displayName);
  late final TextEditingController _username =
      TextEditingController(text: widget.profile.username);
  late final TextEditingController _status =
      TextEditingController(text: widget.profile.statusLine);
  late final TextEditingController _bio =
      TextEditingController(text: widget.profile.bio);
  late final TextEditingController _interests =
      TextEditingController(text: widget.profile.interests.join(', '));

  XFile? _picked;
  bool _saving = false;
  bool _generatingBio = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _status.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1024);
      if (file != null) setState(() => _picked = file);
    } catch (_) {
      _toast('Could not open the picker');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final handle = _username.text.trim();
    if (name.isEmpty) {
      _toast('Name cannot be empty');
      return;
    }
    if (handle.length < 3 || handle.length > 30) {
      _toast('Username must be 3–30 characters');
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    String? avatarUrl;
    try {
      if (_picked != null) {
        final uid = SupabaseService.currentUserId!;
        final url =
            await MediaService.uploadAvatar(userId: uid, file: _picked!);
        // bust the CDN cache (stable storage path → same base URL)
        avatarUrl = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      _toast('Photo upload failed. Try again.');
      return;
    }

    final ok = await auth.saveProfile(
      displayName: name,
      username: handle,
      statusLine: _status.text.trim(),
      bio: _bio.text.trim(),
      interests: _interests.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      avatarUrl: avatarUrl,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      _toast(auth.error ?? 'Could not save your profile');
    }
  }

  Future<void> _generateBio() async {
    final name = _name.text.trim();
    final interests = _interests.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (name.isEmpty) {
      _toast('Please enter your name first');
      return;
    }
    setState(() => _generatingBio = true);
    try {
      final bio = await context.read<AIProvider>().generateBio(name, interests);
      setState(() => _bio.text = bio);
      _toast('AI Bio Generated! ✨');
    } catch (_) {
      _toast('Failed to generate bio');
    } finally {
      setState(() => _generatingBio = false);
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        children: [
          SizedBox(height: 8.h),
          Center(
            child: GestureDetector(
              onTap: _saving ? null : _pickPhoto,
              child: Stack(
                children: [
                  _avatarPreview(),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientFrom(
                            Theme.of(context).colorScheme.primary),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 16.r, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _pickPhoto,
              child: const Text('Change photo'),
            ),
          ),
          SizedBox(height: 12.h),
          _label('Name'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          SizedBox(height: 18.h),
          _label('Username'),
          TextField(
            controller: _username,
            autocorrect: false,
            decoration: const InputDecoration(
              prefixText: '@',
              hintText: 'username',
            ),
          ),
          SizedBox(height: 18.h),
          _label('Status'),
          TextField(
            controller: _status,
            maxLines: 2,
            maxLength: 140,
            decoration: const InputDecoration(hintText: 'Tell people about you'),
          ),
          SizedBox(height: 18.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Bio (About Me)'),
              TextButton.icon(
                onPressed: _generatingBio ? null : _generateBio,
                icon: _generatingBio 
                  ? SizedBox(width: 14.r, height: 14.r, child: const CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI Magic', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Share more about yourself...'),
          ),
          SizedBox(height: 18.h),
          _label('Interests (comma separated)'),
          TextField(
            controller: _interests,
            decoration: const InputDecoration(hintText: 'Travel, Music, Coding...'),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 52.h,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPreview() {
    final radius = 54.r;
    if (_picked != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(_picked!.path)),
      );
    }
    return AppAvatar(
      name: _name.text.isEmpty ? widget.profile.displayName : _name.text,
      avatarUrl: widget.profile.avatarUrl,
      radius: radius,
    );
  }

  Widget _label(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
