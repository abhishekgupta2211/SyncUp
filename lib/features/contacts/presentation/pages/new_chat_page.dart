import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../data/providers/contacts_provider.dart';
import '../../data/repositories/contacts_repository.dart';
import '../widgets/requests_button.dart';
import '../widgets/user_search_view.dart';

/// Full-screen "New Chat" — opened from the center (+) FAB.
class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContactsProvider>(
      create: (_) =>
          ContactsProvider(ContactsRepository(SupabaseService.client)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Chat'),
          actions: const [RequestsButton()],
        ),
        body: const SafeArea(child: UserSearchView(autofocus: true)),
      ),
    );
  }
}
