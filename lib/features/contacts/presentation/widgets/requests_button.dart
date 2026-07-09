import 'package:flutter/material.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/contacts_repository.dart';
import '../pages/requests_page.dart';

/// App-bar action that opens the friend-requests inbox, with a pending-count
/// badge. Self-contained (own repository) so it works from any screen.
class RequestsButton extends StatefulWidget {
  const RequestsButton({super.key});

  @override
  State<RequestsButton> createState() => _RequestsButtonState();
}

class _RequestsButtonState extends State<RequestsButton> {
  final _repo = ContactsRepository(SupabaseService.client);
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final incoming = await _repo.incomingRequests();
      if (mounted) setState(() => _count = incoming.length);
    } catch (_) {}
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RequestsPage()),
    );
    if (mounted) _refresh(); // counts may change after accept/reject
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: 'Friend requests',
      onPressed: _open,
      icon: Badge(
        isLabelVisible: _count > 0,
        label: Text('$_count'),
        child:
            Icon(Icons.group_add_outlined, color: theme.colorScheme.primary),
      ),
    );
  }
}
