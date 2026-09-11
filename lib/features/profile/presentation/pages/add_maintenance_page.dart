import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';

class AddMaintenancePage extends StatefulWidget {
  const AddMaintenancePage({super.key, required this.bikeId, this.log});
  final String bikeId;
  final Map<String, dynamic>? log;

  @override
  State<AddMaintenancePage> createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends State<AddMaintenancePage> {
  late final _cost = TextEditingController(text: widget.log?['cost']?.toString());
  late final _notes = TextEditingController(text: widget.log?['notes']);
  late final _odo = TextEditingController(text: widget.log?['odometer_at']?.toString());
  late String _type = widget.log?['service_type'] ?? 'oil_change';
  bool _isSaving = false;

  final List<String> _types = ['oil_change', 'chain_service', 'tyre_replacement', 'general_service'];

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'bike_id': widget.bikeId,
        'service_type': _type,
        'cost': double.tryParse(_cost.text) ?? 0.0,
        'notes': _notes.text.trim(),
        'odometer_at': int.tryParse(_odo.text) ?? 0,
        'service_date': widget.log?['service_date'] ?? DateTime.now().toIso8601String(),
      };

      if (widget.log != null) {
        await SupabaseService.client.from('bike_maintenance').update(data).eq('id', widget.log!['id']);
      } else {
        await SupabaseService.client.from('bike_maintenance').insert(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.log != null ? 'Service log updated!' : 'Service log saved! 🛠️'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.log != null ? 'EDIT SERVICE LOG' : 'LOG REAL SERVICE')),
      body: _isSaving ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'SERVICE TYPE'),
            ),
            SizedBox(height: 20.h),
            _field('COST (₹)', _cost, isNum: true),
            SizedBox(height: 20.h),
            _field('ODOMETER AT SERVICE', _odo, isNum: true),
            SizedBox(height: 20.h),
            _field('NOTES / PARTS CHANGED', _notes, maxLines: 3),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                child: Text(widget.log != null ? 'UPDATE LOG' : 'SAVE LOG', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNum = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))),
    );
  }
}
