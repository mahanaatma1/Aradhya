import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// A citation line: `📜 Vishnu Purana 1.3.12 ›`
///
/// Renders **only when a source is actually present**, so legacy content shows
/// nothing rather than an empty "no source" state. That is what makes it safe
/// to drop onto every screen while provenance coverage is still partial.
class SourceChip extends StatelessWidget {
  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? licenseNote;
  final String? lastVerifiedAt;
  final bool hindi;

  /// Extra citations beyond the primary — shown in the sheet, not the chip.
  final List<String> otherUrls;

  const SourceChip({
    super.key,
    required this.hindi,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.licenseNote,
    this.lastVerifiedAt,
    this.otherUrls = const [],
  });

  bool get _hasSource =>
      (sourceName?.trim().isNotEmpty ?? false) ||
      (sourceUrl?.trim().isNotEmpty ?? false) ||
      otherUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasSource) return const SizedBox.shrink();

    final label = [
      if (sourceName != null && sourceName!.isNotEmpty) sourceName,
      if (sourceRef != null && sourceRef!.isNotEmpty) sourceRef,
    ].whereType<String>().join(' · ');

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            color: AppColors.gold.withValues(alpha: 0.07),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 13, color: AppColors.gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.isEmpty ? (hindi ? 'स्रोत' : 'Source') : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  size: 14, color: AppColors.gold.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _SourceSheet(
        hindi: hindi,
        sourceName: sourceName,
        sourceRef: sourceRef,
        sourceUrl: sourceUrl,
        licenseNote: licenseNote,
        lastVerifiedAt: lastVerifiedAt,
        otherUrls: otherUrls,
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  final bool hindi;
  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? licenseNote;
  final String? lastVerifiedAt;
  final List<String> otherUrls;

  const _SourceSheet({
    required this.hindi,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.licenseNote,
    this.lastVerifiedAt,
    this.otherUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hindi ? 'स्रोत' : 'Source',
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            const SizedBox(height: 12),
            if (sourceName != null && sourceName!.isNotEmpty)
              Text(sourceName!,
                  style: const TextStyle(fontSize: 15, height: 1.4)),
            if (sourceRef != null && sourceRef!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(sourceRef!,
                  style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7))),
            ],
            if (lastVerifiedAt != null && lastVerifiedAt!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                hindi
                    ? 'अंतिम जाँच: $lastVerifiedAt'
                    : 'Last verified: $lastVerifiedAt',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.55)),
              ),
            ],
            if (licenseNote != null && licenseNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(licenseNote!,
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.7))),
              ),
            ],
            if (sourceUrl != null && sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _LinkButton(url: sourceUrl!, hindi: hindi, primary: true),
            ],
            if (otherUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(hindi ? 'अन्य संदर्भ' : 'Other references',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: otherUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) =>
                      _LinkButton(url: otherUrls[i], hindi: hindi),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              // Offline is the norm for this app, so say plainly that only the
              // link needs a connection — the citation itself is stored locally.
              hindi
                  ? 'लिंक खोलने के लिए इंटरनेट चाहिए।'
                  : 'Opening a link needs an internet connection.',
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String url;
  final bool hindi;
  final bool primary;
  const _LinkButton(
      {required this.url, required this.hindi, this.primary = false});

  String get _host {
    final u = Uri.tryParse(url);
    return u?.host.replaceFirst('www.', '') ?? url;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(hindi ? 'लिंक नहीं खुल सका' : 'Could not open link'),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: primary
                  ? scheme.primary.withValues(alpha: 0.4)
                  : scheme.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.open_in_new_rounded,
                size: 15,
                color: primary
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
                      color: primary ? scheme.primary : scheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber "unverified" marker.
///
/// Shown only in dev builds — `build.py --strict` refuses to ship unverified
/// content at all, so if this ever appears in a release something is wrong with
/// the build, not the data. Its job is to make content debt visible in the
/// product instead of only in a spreadsheet.
class VerificationChip extends StatelessWidget {
  final String status;
  final bool hindi;
  const VerificationChip({super.key, required this.status, required this.hindi});

  @override
  Widget build(BuildContext context) {
    if (status == 'verified') return const SizedBox.shrink();

    final disputed = status == 'disputed';
    final color = disputed ? const Color(0xFFC0392B) : const Color(0xFFFF9F43);
    final label = disputed
        ? (hindi ? 'विवादित' : 'Disputed')
        : (hindi ? 'असत्यापित' : 'Unverified');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
