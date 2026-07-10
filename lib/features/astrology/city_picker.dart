import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/skeleton.dart';
import 'astrology_providers.dart';

/// Shared birth-city search sheet (over the bundled city table).
Future<City?> pickBirthCity(BuildContext context) => showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CityPickerSheet(),
    );

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet();
  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _query.trim().length >= 2
        ? ref.watch(citySearchProvider(_query.trim()))
        : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Place of birth',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: scheme.primary)),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search city…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: results == null
                ? Center(
                    child: Text('Type at least 2 letters',
                        style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.5))))
                : results.when(
                    loading: () => const SkeletonList(count: 6),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (cities) => ListView(
                      children: [
                        for (final c in cities)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(c.name),
                            subtitle: Text(c.state),
                            onTap: () => Navigator.pop(context, c),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
