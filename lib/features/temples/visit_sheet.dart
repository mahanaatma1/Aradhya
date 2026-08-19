import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'passport_providers.dart';

const _gold = Color(0xFFC08A2E);

/// Record what a visit was like: when, a note, and how it felt.
///
/// Opened from the temple page after a visit is marked. Everything is optional
/// — a visit with no note is still a visit, and the sheet should never feel
/// like a form that has to be completed before the record counts.
Future<void> showVisitSheet(
    BuildContext context, WidgetRef ref, int templeId, bool hindi) async {
  final existing =
      (await ref.read(visitRecordsProvider.future))[templeId];
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _VisitSheet(
        templeId: templeId,
        hindi: hindi,
        initialNote: existing?.note,
        initialRating: existing?.rating,
        initialDate: existing?.visitedAt,
      ),
    ),
  );
}

class _VisitSheet extends ConsumerStatefulWidget {
  final int templeId;
  final bool hindi;
  final String? initialNote;
  final int? initialRating;
  final DateTime? initialDate;

  const _VisitSheet({
    required this.templeId,
    required this.hindi,
    this.initialNote,
    this.initialRating,
    this.initialDate,
  });

  @override
  ConsumerState<_VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends ConsumerState<_VisitSheet> {
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote ?? '');
  late int? _rating = widget.initialRating;
  late DateTime _date = widget.initialDate ?? DateTime.now();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  static const _mon = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final hi = widget.hindi;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'यात्रा का विवरण' : 'About this visit',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          // When
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 18, color: _gold),
                  const SizedBox(width: 10),
                  Text(
                    '${_date.day} ${_mon[_date.month - 1]} ${_date.year}',
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(hi ? 'बदलें' : 'Change',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const Divider(height: 20),

          Text(hi ? 'यह यात्रा कैसी रही?' : 'How was it?',
              style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(
                      () => _rating = _rating == i ? null : i),
                  icon: Icon(
                    (_rating ?? 0) >= i
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _gold,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _note,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hi
                  ? 'क्या याद रहा? (वैकल्पिक)'
                  : 'What do you want to remember? (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hi
                ? 'यह केवल आपके उपकरण पर रहेगा।'
                : 'This stays on your device.',
            style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await ref
                      .read(passportControllerProvider)
                      .remove(widget.templeId);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(hi ? 'यात्रा हटाएँ' : 'Remove visit',
                    style: TextStyle(color: scheme.error)),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(passportControllerProvider).save(
                        widget.templeId,
                        visitedAt: _date,
                        note: _note.text.trim().isEmpty
                            ? null
                            : _note.text.trim(),
                        rating: _rating,
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(hi ? 'सहेजें' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
