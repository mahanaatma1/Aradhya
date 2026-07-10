import 'package:flutter/material.dart';

import 'deity_accent.dart';

/// A search field + horizontal deity-chip row for devotional lists.
/// Emits changes via callbacks; the parent owns the filter state.
class DevotionalFilterBar extends StatelessWidget {
  final List<String> deities; // canonical, without the leading "All"
  final String selected; // 'All' or a deity
  final String query;
  final String searchHint;
  final String allLabel; // localized label shown on the 'All' chip
  final bool hi; // show deity chips in Hindi
  final ValueChanged<String> onDeity;
  final ValueChanged<String> onQuery;

  const DevotionalFilterBar({
    super.key,
    required this.deities,
    required this.selected,
    required this.query,
    required this.searchHint,
    this.allLabel = 'All',
    this.hi = false,
    required this.onDeity,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = ['All', ...deities];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onQuery,
            decoration: InputDecoration(
              isDense: true,
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = chips[i];
              final on = d == selected;
              return ChoiceChip(
                label: Text(d == 'All' ? allLabel : deityLabel(d, hi)),
                selected: on,
                onSelected: (_) => onDeity(d),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: on ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                ),
                selectedColor: scheme.primary,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
