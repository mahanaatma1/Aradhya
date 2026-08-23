import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
// The reader is addressed by book + verse index, not section id. This resolver
// already exists for "Ask the Scriptures"; reusing it keeps one entry point into
// the reader rather than a second query that could disagree with the first.
import '../ask/ask_providers.dart';
import '../gyan/entity_providers.dart';
import '../related/related_rail.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';
import 'story_structure.dart';

const _accent = Color(0xFF8A6A4F);
const _deep = Color(0xFF4A3220);
const _onDeep = Color(0xFFFFF8EF);

/// Devanagari needs more room between lines than Latin at the same size.
double _lh(bool hindi, double base) => hindi ? base * 1.18 : base;

Color _panel(ColorScheme scheme, double alpha) =>
    scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest.withValues(alpha: alpha)
        : AppColors.kraft.withValues(alpha: alpha);

Color _goldInk(ColorScheme scheme) => scheme.brightness == Brightness.dark
    ? AppColors.goldBright
    : const Color(0xFF8A6A2E);

/// One event of an epic, shared by both (SC-10).
///
/// The order of this page is fixed, and deliberately so: illustration, title
/// with its section and arc, quick summary, story, key moments, reflection,
/// people, place, themes, the original text, related, then where to go next.
/// A reader who has seen one event knows where to look on every other one.
///
/// Every block below is conditional on its content existing. Most of the Story
/// Cards prose is still to be written, and a page of empty labelled panels would
/// promise what is not there — so a section with nothing in it does not appear
/// at all, and the older `long_description` / `lesson` columns stand in through
/// the model's fallbacks until the prose lands.
class SceneScreen extends ConsumerStatefulWidget {
  final int sceneId;
  const SceneScreen({super.key, required this.sceneId});

  @override
  ConsumerState<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends ConsumerState<SceneScreen> {
  @override
  void initState() {
    super.initState();
    // Opening a scene marks it read. Anything stricter would be guessing at
    // whether someone finished reading, and this is a story, not a course.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(epicProgressProvider.notifier).markRead(widget.sceneId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final value = ref.watch(sceneByIdProvider(widget.sceneId));

    return Scaffold(
      body: AsyncView(
        value: value,
        isEmpty: (s) => s == null,
        emptyMessage: hi ? 'यह दृश्य नहीं मिला' : 'Scene not found',
        builder: (scene) => _Body(scene: scene!, hindi: hi),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  const _Body({required this.scene, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cast = ref.watch(sceneCastProvider(scene.id)).valueOrNull ?? const [];

    final quick = scene.quickSummary(hindi);
    final story = scene.story(hindi);
    final moments = scene.keyMoments(hindi);
    final reflection = scene.reflection(hindi);
    final themes = scene.themes;

    return CustomScrollView(
      slivers: [
        // 1 & 2 — the illustration, carrying the section, the arc and the title.
        _SceneHeader(scene: scene, hindi: hindi),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 — Quick summary. The blurb stands in until one is written,
                // without the label: `short_description` is a card fragment, and
                // calling a fragment a summary would overstate it.
                if (quick != null && quick.isNotEmpty)
                  _Eyebrow(hindi ? 'संक्षेप में' : 'IN SHORT'),
                if (quick != null && quick.isNotEmpty) const SizedBox(height: 7),
                Text(
                  quick?.isNotEmpty == true ? quick! : scene.desc(hindi),
                  style: TextStyle(fontSize: 16.5, height: _lh(hindi, 1.58)),
                ),

                // 4 — The story.
                if (story != null && story.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _Eyebrow(hindi ? 'कथा' : 'THE STORY'),
                  const SizedBox(height: 8),
                  Text(
                    story,
                    style: TextStyle(
                      fontSize: 15,
                      height: _lh(hindi, 1.62),
                      color: scheme.onSurface.withValues(alpha: 0.86),
                    ),
                  ),
                ],

                // 5 — Key moments.
                if (moments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Eyebrow(hindi ? 'मुख्य क्षण' : 'KEY MOMENTS'),
                  const SizedBox(height: 10),
                  _KeyMoments(moments: moments, hindi: hindi),
                ],

                // 6 — Reflection: a question, and somewhere to answer it.
                if (reflection != null && reflection.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _ReflectionPanel(text: reflection, hindi: hindi),
                ],

                // 7 — People.
                if (cast.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _Eyebrow(hindi ? 'पात्र' : 'WHO IS HERE'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in cast) _CastChip(member: c, hindi: hindi),
                    ],
                  ),
                ],

                // 8 — Place.
                if (scene.placeEntityId != null) ...[
                  const SizedBox(height: 24),
                  _PlaceBlock(entityId: scene.placeEntityId!, hindi: hindi),
                ],

                // 9 — Themes.
                if (themes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Eyebrow(hindi ? 'विषय' : 'THEMES'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in themes) _ThemeChip(slug: t, hindi: hindi),
                    ],
                  ),
                ],

                // 10 — The original text: who is telling this, and where to read
                // it in their own words.
                const SizedBox(height: 26),
                _OriginalText(scene: scene, hindi: hindi),
              ],
            ),
          ),
        ),

        // 11 — Related.
        SliverToBoxAdapter(
          child: RelatedRail(src: 'gyan', table: 'narrative_nodes', id: scene.id),
        ),

        // 12 — Where this sits in the telling.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
            child: _PrevNext(scene: scene, hindi: hindi),
          ),
        ),
      ],
    );
  }
}

/// The illustration, with the section, the arc and the title over it.
///
/// No artwork exists for any event yet. Rather than a grey box or a stand-in
/// picture of some other scene, the header falls back to the brand gradient —
/// a coloured field claims nothing.
class _SceneHeader extends StatelessWidget {
  final NarrativeNode scene;
  final bool hindi;
  const _SceneHeader({required this.scene, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final art = scene.illustrationAsset ?? scene.imageAsset;
    final arc = scene.arcTitle(hindi);

    // The canonical roster, not `book_label_*`: the shipped labels disagree with
    // themselves across authoring batches (see story_structure.dart), and the
    // section shown here has to match the one shown on the epic screen.
    final section = sectionsFor(scene.epic)
            .where((s) => s.no == scene.bookNo)
            .map((s) => s.title(hindi))
            .firstOrNull ??
        scene.bookLabel(hindi);

    final crumbs = [
      if (section != null && section.isNotEmpty) section,
      if (arc != null && arc.isNotEmpty) arc,
    ].join('  ·  ');

    return SliverAppBar(
      pinned: true,
      expandedHeight: art == null ? 158 : 240,
      backgroundColor: _deep,
      foregroundColor: _onDeep,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _deep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (art != null)
              Image.asset(
                art,
                fit: BoxFit.cover,
                // A missing asset must not take the page down, and must not
                // leave a broken-image glyph where art was promised.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            // Legibility over any artwork, and depth over the gradient.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC2A1B10)],
                  stops: [0.42, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (crumbs.isNotEmpty)
                    Text(
                      crumbs,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.4,
                        height: _lh(hindi, 1.3),
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldBright.withValues(alpha: 0.95),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    scene.title(hindi),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 25,
                      height: _lh(hindi, 1.14),
                      color: _onDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one section-label style on this page, so the order is legible at a glance.
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.3,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

/// The beats of the event, numbered.
class _KeyMoments extends StatelessWidget {
  final List<String> moments;
  final bool hindi;
  const _KeyMoments({required this.moments, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < moments.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == moments.length - 1 ? 0 : 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _panel(scheme, 0.9),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _goldInk(scheme),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      moments[i],
                      style: TextStyle(
                        fontSize: 14.5,
                        height: _lh(hindi, 1.5),
                        color: scheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The reflection — a question, and a way into the Journal to answer it.
///
/// Kept visually distinct for the same reason the entity screen separates
/// symbolism from description: a reader should be able to tell what the text
/// says from what it is being taken to mean. Older events carry a one-line
/// moral in `lesson_*` instead of a question; the model falls back to it, and
/// the invitation reads the same either way.
class _ReflectionPanel extends StatelessWidget {
  final String text;
  final bool hindi;
  const _ReflectionPanel({required this.text, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
      decoration: BoxDecoration(
        color: _panel(scheme, 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hindi ? 'विचार के लिए' : 'TO REFLECT ON',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: _goldInk(scheme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.accent,
              fontSize: 16.5,
              height: _lh(hindi, 1.5),
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              // Carried as a query parameter so the entry keeps the question it
              // was written against, the way a prompted entry does.
              onPressed: () => context.push(
                  '/journal/new?prompt=${Uri.encodeQueryComponent(text)}'),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(hindi ? 'इस पर विचार करें' : 'Think about it'),
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CastChip extends StatelessWidget {
  final CastMember member;
  final bool hindi;
  const _CastChip({required this.member, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLead = member.role == 'protagonist';

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/gyan/entity/${member.entityId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isLead ? _accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLead
                ? _accent.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          member.title(hindi),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isLead ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Where the event happens, resolved to its entity so the place is a place and
/// not a word.
class _PlaceBlock extends ConsumerWidget {
  final int entityId;
  final bool hindi;
  const _PlaceBlock({required this.entityId, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(entityByIdProvider(entityId)).valueOrNull;
    // Nothing is claimed while the lookup is in flight, and nothing is claimed
    // if the id points at a row that is not there.
    if (place == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(hindi ? 'स्थान' : 'WHERE'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/gyan/entity/${place.id}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: scheme.outline.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 18, color: _accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title(hindi),
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: _lh(hindi, 1.2),
                        ),
                      ),
                      if (place.desc(hindi).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.desc(hindi),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: _lh(hindi, 1.38),
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: scheme.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A theme, taken into search rather than into a filter that does not exist yet.
class _ThemeChip extends StatelessWidget {
  final String slug;
  final bool hindi;
  const _ThemeChip({required this.slug, required this.hindi});

  /// Slugs are English and lower-case in the data. Only the ones actually in use
  /// are translated; anything new reads as its own words rather than as a slug.
  static const _hi = <String, String>{
    'dharma': 'धर्म',
    'duty': 'कर्तव्य',
    'sacrifice': 'त्याग',
    'devotion': 'भक्ति',
    'governance': 'राजनीति',
    'teaching': 'उपदेश',
    'loyalty': 'निष्ठा',
    'exile': 'वनवास',
    'war': 'युद्ध',
    'friendship': 'मैत्री',
    'grief': 'शोक',
    'anger': 'क्रोध',
    'truth': 'सत्य',
    'fate': 'नियति',
  };

  String get _label {
    if (hindi) {
      final t = _hi[slug];
      if (t != null) return t;
    }
    return slug
        .split(RegExp(r'[-_]'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/search?q=${Uri.encodeQueryComponent(slug)}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// Who is telling this, and where to read it in their own words (SC-11).
///
/// The source citation always shows. The button only appears when the event
/// actually carries a section id that resolves to a place in the reader — no
/// event does yet, and a button that lands on a search box would be a promise
/// the page cannot keep.
class _OriginalText extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  const _OriginalText({required this.scene, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionId = scene.scriptureSectionId;
    final loc = sectionId == null
        ? null
        : ref.watch(verseLocationProvider(sectionId)).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(hindi ? 'मूल पाठ' : 'THE ORIGINAL TEXT'),
        const SizedBox(height: 10),
        SourceChip(
          hindi: hindi,
          sourceName: scene.sourceName,
          sourceRef: scene.sourceRef,
          sourceUrl: scene.sourceUrl,
          lastVerifiedAt: scene.lastVerifiedAt,
        ),
        if (loc != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/scriptures/book/${loc.bookId}?v=${loc.index}'),
            icon: const Icon(Icons.menu_book_rounded, size: 17),
            label: Text(hindi ? 'यह अंश पढ़ें' : 'Read this passage'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Previous and next, each with a line of what it is.
///
/// The neighbours come from `prev_node_id` / `next_node_id`, denormalised at
/// build time (SC-16), so paging does not depend on the whole epic being loaded
/// and does not skip the war days the epic list leaves out.
class _PrevNext extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  const _PrevNext({required this.scene, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prev = scene.prevNodeId == null
        ? null
        : ref.watch(sceneByIdProvider(scene.prevNodeId!)).valueOrNull;
    final next = scene.nextNodeId == null
        ? null
        : ref.watch(sceneByIdProvider(scene.nextNodeId!)).valueOrNull;

    if (prev == null && next == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prev != null)
          _NavCard(
            scene: prev,
            hindi: hindi,
            label: hindi ? 'पिछला' : 'PREVIOUS',
            forward: false,
          ),
        if (prev != null && next != null) const SizedBox(height: 10),
        if (next != null)
          _NavCard(
            scene: next,
            hindi: hindi,
            label: hindi ? 'आगे' : 'NEXT',
            forward: true,
          ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final NarrativeNode scene;
  final bool hindi;
  final String label;

  /// Forward is the one a reader is most likely to want, so it carries the
  /// weight: a filled arrow and a warmer border.
  final bool forward;

  const _NavCard({
    required this.scene,
    required this.hindi,
    required this.label,
    required this.forward,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = scene.quickSummary(hindi) ?? scene.desc(hindi);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      // `pushReplacement` so walking an epic does not build a stack thirty
      // scenes deep that Back has to unwind one at a time.
      onTap: () => context.pushReplacement('/gyan/scene/${scene.id}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 11, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: forward ? _accent.withValues(alpha: 0.06) : null,
          border: Border.all(
            color: forward
                ? _accent.withValues(alpha: 0.38)
                : scheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            if (!forward)
              Padding(
                padding: const EdgeInsets.only(right: 9),
                child: Icon(Icons.arrow_back_rounded,
                    size: 17, color: scheme.onSurface.withValues(alpha: 0.4)),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: forward
                          ? _accent
                          : scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    scene.title(hindi),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: _lh(hindi, 1.2),
                    ),
                  ),
                  // The one line of what is coming — the whole point of showing
                  // a card here rather than a bare arrow.
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: _lh(hindi, 1.38),
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (forward)
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: _accent),
              ),
          ],
        ),
      ),
    );
  }
}
