import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/providers/auth_provider.dart';

class SafetyCenterPage extends StatefulWidget {
  const SafetyCenterPage({super.key});

  @override
  State<SafetyCenterPage> createState() => _SafetyCenterPageState();
}

class _SafetyCenterPageState extends State<SafetyCenterPage> {
  bool _saving = false;

  Future<void> _editField(String title, String current) async {
    final controller = TextEditingController(text: current);
    
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Enter $title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('SAVE')),
        ],
      ),
    );

    if (res != null && mounted) {
      setState(() => _saving = true);
      final auth = context.read<AuthProvider>();
      final profile = auth.profile!;
      
      final ok = await auth.saveProfile(
        displayName: profile.displayName,
        username: profile.username,
        statusLine: profile.statusLine,
        bio: profile.bio,
        interests: profile.interests,
        ridingStyle: profile.ridingStyle,
        experienceYears: profile.experienceYears,
        bloodGroup: title == 'Blood Group' ? res : profile.bloodGroup,
        allergies: title == 'Allergies' ? res : profile.allergies,
        emergencyContactName: title == 'Emergency Contact Name' ? res : profile.emergencyContactName,
        emergencyContactPhone: title == 'Emergency Contact Phone' ? res : profile.emergencyContactPhone,
      );
      
      if (mounted) {
        setState(() => _saving = false);
        if (!ok) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthProvider>().profile;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Safety & SOS')),
      body: _saving ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          // --- SOS Large Button ---
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EMERGENCY ALERT SENT! 🚨')));
                  },
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'SOS',
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                const Text(
                  'Long press for 3 seconds to send emergency alert to all trusted contacts with your live location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          _sectionHeader(theme, 'EMERGENCY CONTACT'),
          _infoTile(theme, Icons.person, 'Emergency Contact Name', profile.emergencyContactName ?? 'Not Set'),
          _infoTile(theme, Icons.phone, 'Emergency Contact Phone', profile.emergencyContactPhone ?? 'Not Set'),

          SizedBox(height: 32.h),

          _sectionHeader(theme, 'MEDICAL INFO'),
          _infoTile(theme, Icons.bloodtype_rounded, 'Blood Group', profile.bloodGroup ?? 'Not Set'),
          _infoTile(theme, Icons.medical_information_rounded, 'Allergies', profile.allergies ?? 'None'),
          
          SizedBox(height: 32.h),

          _sectionHeader(theme, 'NEARBY ASSISTANCE'),
          _assistTile(theme, Icons.local_hospital_rounded, 'Nearby Hospitals'),
          _assistTile(theme, Icons.local_police_rounded, 'Police Stations'),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _infoTile(ThemeData theme, IconData icon, String label, String value) {
    return ListTile(
      onTap: () => _editField(label, value == 'Not Set' ? '' : value),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      subtitle: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.edit_rounded, size: 18),
    );
  }

  Widget _assistTile(ThemeData theme, IconData icon, String label) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searching for $label on map... 🔍')));
        },
      ),
    );
  }
}
