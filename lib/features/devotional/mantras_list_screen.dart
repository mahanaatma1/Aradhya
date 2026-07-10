import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/async_view.dart';
import 'deity_accent.dart';
import 'devotional_filter.dart';
import 'devotional_models.dart';
import 'devotional_providers.dart';

class MantrasListScreen extends ConsumerStatefulWidget {
  const MantrasListScreen({super.key});

  @override
  ConsumerState<MantrasListScreen> createState() => _MantrasListScreenState();
}

class _MantrasListScreenState extends ConsumerState<MantrasListScreen> {
  String _query = '';
  String _deity = 'All';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final value = ref.watch(mantrasProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.catMantras)),
      body: AsyncView(
        value: value,
        emptyMessage: t.comingSoon,
        isEmpty: (l) => l.isEmpty,
        builder: (items) {
          final deities = <String>{
            for (final m in items) canonicalDeity(m.deity),
          }.toList()
            ..sort();
          final filtered = items.where((m) {
            final matchDeity =
                _deity == 'All' || canonicalDeity(m.deity) == _deity;
            final q = _query.trim().toLowerCase();
            final matchQuery = q.isEmpty ||
                m.titleEn.toLowerCase().contains(q) ||
                (m.titleHi ?? '').contains(q) ||
                (m.deity ?? '').toLowerCase().contains(q);
            return matchDeity && matchQuery;
          }).toList();

          return Column(
            children: [
              DevotionalFilterBar(
                deities: deities,
                selected: _deity,
                query: _query,
                allLabel: hi ? 'सभी' : 'All',
                hi: hi,
                searchHint: hi ? 'शीर्षक या देवता से खोजें…' : 'Search title or deity…',
                onDeity: (d) => setState(() => _deity = d),
                onQuery: (q) => setState(() => _query = q),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(t.comingSoon))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _MantraCard(
                          mantra: filtered[i],
                          hindi: hi,
                          onTap: () =>
                              context.push('/read-mantra', extra: filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MantraCard extends StatelessWidget {
  final Mantra mantra;
  final bool hindi;
  final VoidCallback onTap;
  const _MantraCard({required this.mantra, required this.hindi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = DeityAccent.of(mantra.deity);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(accent.icon, color: accent.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mantra.title(hindi),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (mantra.typeEn != null && mantra.typeEn!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(mantraTypeLabel(mantra.typeEn, hindi),
                                style: TextStyle(
                                    fontSize: 11, color: accent.color)),
                          ),
                        if (mantra.deity != null)
                          Text(deityLabel(canonicalDeity(mantra.deity), hindi),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                    if (mantra.translation(hindi) != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        mantra.translation(hindi)!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: hindi ? AppFonts.devanagari : AppFonts.body,
                          fontSize: 13,
                          height: 1.4,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
