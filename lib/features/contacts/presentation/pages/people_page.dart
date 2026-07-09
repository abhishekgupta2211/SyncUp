import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../data/providers/contacts_provider.dart';
import '../../data/repositories/contacts_repository.dart';
import '../widgets/requests_button.dart';
import '../widgets/user_search_view.dart';

/// People tab — searchable directory + a friend-requests inbox.
class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider<ContactsProvider>(
      create: (_) =>
          ContactsProvider(ContactsRepository(SupabaseService.client)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 4.h),
              child: Row(
                children: [
                  Text(
                    'People',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const RequestsButton(),
                ],
              ),
            ),
            const Expanded(child: UserSearchView()),
          ],
        ),
      ),
    );
  }
}
