import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';

class AddBikePage extends StatefulWidget {
  final Map<String, dynamic>? bike;
  const AddBikePage({super.key, this.bike});

  @override
  State<AddBikePage> createState() => _AddBikePageState();
}

class _AddBikePageState extends State<AddBikePage> {
  late final _brand = TextEditingController(text: widget.bike?['brand']);
  late final _model = TextEditingController(text: widget.bike?['model']);
  late final _nickname = TextEditingController(text: widget.bike?['nickname']);
  late final _year = TextEditingController(text: widget.bike?['year']?.toString());
  late final _cc = TextEditingController(text: widget.bike?['engine_cc']?.toString());
  bool _isSaving = false;

  Future<void> _saveBike() async {
    if (_brand.text.isEmpty || _model.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand and Model are required!')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'owner_id': SupabaseService.currentUserId,
        'brand': _brand.text.trim(),
        'model': _model.text.trim(),
        'nickname': _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
        'year': int.tryParse(_year.text) ?? 2024,
        'engine_cc': int.tryParse(_cc.text) ?? 150,
      };

      if (widget.bike != null) {
        await SupabaseService.client.from('bikes').update(data).eq('id', widget.bike!['id']);
      } else {
        await SupabaseService.client.from('bikes').insert(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.bike != null ? 'Bike updated!' : 'Bike added to your garage! 🏍️'),
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
      appBar: AppBar(title: Text(widget.bike != null ? 'EDIT MOTORCYCLE' : 'ADD NEW MOTORCYCLE')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            _field('BRAND (e.g. Royal Enfield)', _brand),
            SizedBox(height: 20.h),
            _field('MODEL (e.g. Himalayan 450)', _model),
            SizedBox(height: 20.h),
            _field('NICKNAME (e.g. Beast, Thunder)', _nickname),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(child: _field('YEAR', _year, isNum: true)),
                SizedBox(width: 16.w),
                Expanded(child: _field('ENGINE CC', _cc, isNum: true)),
              ],
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBike,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(widget.bike != null ? 'UPDATE BIKE' : 'SAVE TO GARAGE', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))),
    );
  }
}
