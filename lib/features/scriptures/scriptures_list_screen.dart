import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/async_view.dart';
import 'scripture_providers.dart';

class ScripturesListScreen extends ConsumerWidget {
  const ScripturesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final scriptures = ref.watch(scripturesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.catScriptures),
        actions: [
          // 27,890 verses are unbrowsable by scrolling; search is the only
          // realistic way in.
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AsyncView(
        value: scriptures,
        emptyMessage: t.comingSoon,
        isEmpty: (list) => list.isEmpty,
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = list[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.menu_book_rounded, color: scheme.primary),
                ),
                title: Text(
                  s.name(hi),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                subtitle: hi ? null : (s.nameHi != null ? Text(s.nameHi!) : null),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/scriptures/${s.id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
