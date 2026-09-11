import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import 'add_maintenance_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _client = SupabaseService.client;
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final res = await _client
          .from('bike_maintenance')
          .select('*, bikes(nickname, brand, model)')
          .order('service_date', ascending: false);
      if (mounted) setState(() { _logs = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addLog() async {
    final messenger = ScaffoldMessenger.of(context);
    // Show bike picker then navigate to add log
    final bikes = await _client.from('bikes').select('id, brand, model, nickname').eq('owner_id', SupabaseService.currentUserId!);
    if (bikes.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Add a bike to your garage first!')));
      return;
    }
    
    if (!mounted) return;
    final selectedBikeId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SELECT BIKE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: bikes.map((b) => ListTile(
            title: Text(b['nickname'] ?? '${b['brand']} ${b['model']}'),
            onTap: () => Navigator.pop(ctx, b['id'].toString()),
          )).toList(),
        ),
      ),
    );

    if (selectedBikeId != null && mounted) {
      final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMaintenancePage(bikeId: selectedBikeId)));
      if (res == true) _fetchLogs();
    }
  }

  void _editLog(Map<String, dynamic> log) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMaintenancePage(bikeId: log['bike_id'], log: log)));
    if (res == true) _fetchLogs();
  }

  void _deleteLog(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text('This will permanently remove this service record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('bike_maintenance').delete().eq('id', id);
      _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('REAL SERVICE LOGS')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLog,
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('LOG SERVICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchLogs,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 80.h),
              itemCount: _logs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_logs.any((l) => l['next_service_at'] != null)) ...[
                        _sectionTitle(theme, 'REMINDERS'),
                        SizedBox(height: 12.h),
                        const _ReminderCard(title: 'Oil Change Due', subtitle: 'At 12,500 KM', icon: Icons.timer_rounded),
                        SizedBox(height: 24.h),
                      ],
                      _sectionTitle(theme, 'SERVICE HISTORY'),
                      SizedBox(height: 12.h),
                      if (_logs.isEmpty)
                        const EmptyState(
                          icon: Icons.build_circle_outlined, 
                          title: 'No Service History', 
                          subtitle: 'Keep your bike in top shape by tracking its service history.',
                        ),
                    ],
                  );
                }
                final log = _logs[index - 1];
                return _MaintenanceTile(
                  log: log,
                  onEdit: () => _editLog(log),
                  onDelete: () => _deleteLog(log['id']),
                );
              },
            ),
          ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(text, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)));
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const Icon(Icons.notifications_active_rounded, color: Colors.orangeAccent),
        ],
      ),
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  const _MaintenanceTile({required this.log, required this.onEdit, required this.onDelete});
  final dynamic log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bike = log['bikes'];
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.asphalt,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(_getIcon(log['service_type']), color: Colors.white, size: 24.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLabel(log['service_type']),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${bike['nickname'] ?? bike['brand']} • ${log['service_date'].toString().split('T')[0]}',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                    if (log['notes'] != null && log['notes'].toString().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(log['notes'], style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${log['cost']}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                  ),
                  if (log['odometer_at'] != null)
                    Text(
                      '${log['odometer_at']} KM',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white38),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Log')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Log', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'oil_change': return Icons.opacity_rounded;
      case 'chain_service': return Icons.link_rounded;
      case 'tyre_replacement': return Icons.tire_repair_rounded;
      default: return Icons.build_rounded;
    }
  }

  String _getLabel(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }
}
