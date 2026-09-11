import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';

class PlanRidePage extends StatefulWidget {
  final Map<String, dynamic>? initialRoute;
  const PlanRidePage({super.key, this.initialRoute});

  @override
  State<PlanRidePage> createState() => _PlanRidePageState();
}

class _PlanRidePageState extends State<PlanRidePage> {
  late final _title = TextEditingController(text: widget.initialRoute?['title']);
  late final _start = TextEditingController(text: widget.initialRoute?['start_point']?['name']);
  late final _dest = TextEditingController(text: widget.initialRoute?['end_point']?['name']);
  bool _loading = false;

  Future<void> _submit() async {
    if (_title.text.isEmpty || _start.text.isEmpty || _dest.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client.from('rides').insert({
        'organizer_id': SupabaseService.currentUserId,
        'title': _title.text.trim(),
        'start_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'meeting_point': {'name': _start.text.trim()},
        'destination': {'name': _dest.text.trim()},
        'status': 'upcoming',
      }).select().single();

      if (mounted) {
        Navigator.pop(context, res); // Return the real created ride data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAN YOUR RIDE')),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Ride Title')),
            SizedBox(height: 16.h),
            TextField(controller: _start, decoration: const InputDecoration(labelText: 'Meeting Point')),
            SizedBox(height: 16.h),
            TextField(controller: _dest, decoration: const InputDecoration(labelText: 'Destination')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('CREATE RIDE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
