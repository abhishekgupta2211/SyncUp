import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';

class AddFuelLogPage extends StatefulWidget {
  const AddFuelLogPage({super.key, required this.bikeId});
  final String bikeId;

  @override
  State<AddFuelLogPage> createState() => _AddFuelLogPageState();
}

class _AddFuelLogPageState extends State<AddFuelLogPage> {
  final _amount = TextEditingController();
  final _liters = TextEditingController();
  final _odo = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    if (_amount.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.client.from('fuel_logs').insert({
        'bike_id': widget.bikeId,
        'amount': double.tryParse(_amount.text) ?? 0.0,
        'liters': double.tryParse(_liters.text),
        'odometer': int.tryParse(_odo.text),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('LOG FUEL')),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
            SizedBox(height: 16.h),
            TextField(controller: _liters, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liters (L)')),
            SizedBox(height: 16.h),
            TextField(controller: _odo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Odometer (KM)')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                child: const Text('SAVE FUEL LOG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
