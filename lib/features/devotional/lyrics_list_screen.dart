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

/// A filterable list of aartis or chalisas — search + deity chips + a lyrics
/// preview. Our own typographic card style.
class LyricsListScreen extends ConsumerStatefulWidget {
  final LyricsKind kind;
  const LyricsListScreen({super.key, required this.kind});

  @override
  ConsumerState<LyricsListScreen> createState() => _LyricsListScreenState();
}

class _LyricsListScreenState extends ConsumerState<LyricsListScreen> {
  String _query = '';
  String _deity = 'All';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final value = widget.kind == LyricsKind.aartis
        ? ref.watch(aartisProvider)
        : ref.watch(chalisasProvider);
    final title = widget.kind == LyricsKind.aartis
        ? t.catAartis
        : (hi ? 'चालीसा' : 'Chalisa');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: value,
        emptyMessage: t.comingSoon,
        isEmpty: (l) => l.isEmpty,
        builder: (items) {
          final deities = <String>{
            for (final it in items) canonicalDeity(it.deity),
          }.toList()
            ..sort();
          final filtered = items.where((it) {
            final matchDeity =
                _deity == 'All' || canonicalDeity(it.deity) == _deity;
            final q = _query.trim().toLowerCase();
            final matchQuery = q.isEmpty ||
                it.titleEn.toLowerCase().contains(q) ||
                (it.titleHi ?? '').contains(q) ||
                (it.deity ?? '').toLowerCase().contains(q);
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
                        itemBuilder: (context, i) => _LyricsCard(
                          item: filtered[i],
                          hindi: hi,
                          onTap: () => context.push('/read-lyrics',
                              extra: (filtered[i], widget.kind)),
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

class _LyricsCard extends StatelessWidget {
  final DevotionalItem item;
  final bool hindi;
  final VoidCallback onTap;
  const _LyricsCard({required this.item, required this.hindi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = DeityAccent.of(item.deity);
    final preview = _preview(item.lyrics(hindi));
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
                      item.title(hindi),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    if (item.deity != null && item.deity!.isNotEmpty)
                      Text(deityLabel(canonicalDeity(item.deity), hindi),
                          style: TextStyle(fontSize: 13, color: accent.color)),
                    if (preview != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily:
                              hindi ? AppFonts.devanagari : AppFonts.accent,
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
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

  String? _preview(String? lyrics) {
    if (lyrics == null || lyrics.trim().isEmpty) return null;
    return lyrics.replaceAll('\n', ' · ').trim();
  }
}
