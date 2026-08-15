import 'package:flutter/material.dart';

import '../../app/theme/category_colors.dart';

/// The single declaration of every Gyan module.
///
/// Without this, the same 17 modules would have to be listed in four places —
/// the Gyan hub tile grid, the search filter chips, `build.py --modules`, and
/// the coming-soon gating — and those four lists would drift.
///
/// Deliberately **not** a plugin system. Dynamic module loading buys nothing
/// here: `go_router` needs its routes registered at compile time for deep links
/// and tree-shaking, Flutter has no runtime code loading, and the content is a
/// single bundled file. A `const` registry gets the maintainability win without
/// an abstraction layer that would only ever have one implementation.
///
/// Routes stay declared explicitly in `app/router/app_router.dart`;
/// `test/gyan_modules_test.dart` asserts every [route] here resolves there, and
/// exports `content/tools/modules.json` so the Python pipeline and this list
/// cannot disagree about which modules exist.
@immutable
class GyanModule {
  /// Stable id. Matches `search_docs.kind` and `build.py --modules`.
  final String id;

  /// Must resolve against the app router.
  final String route;

  final String titleEn;
  final String titleHi;
  final String blurbEn;
  final String blurbHi;
  final IconData icon;

  /// Which gyan.sqlite table backs it — used by the content health report to
  /// spot a module whose screen exists but whose table is empty.
  final String backingTable;

  /// False renders the hub tile in its coming-soon state instead of navigating.
  /// Flip to true in the same commit that lands the screen.
  final bool shipped;

  /// Section of the reference spec this implements, for traceability.
  final String spec;

  const GyanModule({
    required this.id,
    required this.route,
    required this.titleEn,
    required this.titleHi,
    required this.blurbEn,
    required this.blurbHi,
    required this.icon,
    required this.backingTable,
    required this.spec,
    this.shipped = false,
  });

  String title(bool hi) => hi ? titleHi : titleEn;
  String blurb(bool hi) => hi ? blurbHi : blurbEn;

  /// Tile gradient. Resolved from the theme rather than stored, so a palette
  /// change lands everywhere at once.
  CategoryStyle style(CategoryColors c) => switch (id) {
        'srishty' || 'yuga' => c.srishty,
        'ramayana' || 'mahabharata' => c.epics,
        'dharma' => c.personality,
        'festivals' => c.panchang,
        'journey' => c.scriptures,
        _ => c.gyan,
      };
}

/// Every module, in hub display order.
const List<GyanModule> gyanModules = <GyanModule>[
  GyanModule(
    id: 'journey',
    route: '/journey',
    titleEn: 'Knowledge Journeys',
    titleHi: 'ज्ञान यात्रा',
    blurbEn: 'Guided paths — start here if you are new',
    blurbHi: 'निर्देशित मार्ग — नए हैं तो यहीं से शुरू करें',
    icon: Icons.route_rounded,
    backingTable: 'learning_paths',
    spec: '4.21',
    shipped: true,
  ),
  GyanModule(
    id: 'graph',
    route: '/gyan/graph',
    titleEn: 'Knowledge Graph',
    titleHi: 'ज्ञान संजाल',
    blurbEn: 'Gods, sages, places and texts, and how they connect',
    blurbHi: 'देव, ऋषि, स्थान और ग्रंथ — और उनके संबंध',
    icon: Icons.hub_rounded,
    backingTable: 'entities',
    spec: '4.1',
    shipped: true,
  ),
  GyanModule(
    id: 'lineage',
    route: '/gyan/lineage',
    titleEn: 'Family Tree',
    titleHi: 'वंशावली',
    blurbEn: 'Lineages of gods, dynasties and sages',
    blurbHi: 'देवताओं, वंशों और ऋषियों की वंशावली',
    icon: Icons.account_tree_rounded,
    backingTable: 'relations',
    spec: '4.2',
    shipped: true,
  ),
  GyanModule(
    id: 'rishis',
    route: '/gyan/rishis',
    titleEn: 'Rishis',
    titleHi: 'ऋषि',
    blurbEn: 'Sages, their hymns, students and ashrams',
    blurbHi: 'ऋषि, उनके सूक्त, शिष्य और आश्रम',
    icon: Icons.self_improvement_rounded,
    backingTable: 'entities',
    spec: '4.13',
    shipped: true,
  ),
  GyanModule(
    id: 'astras',
    route: '/gyan/astras',
    titleEn: 'Ancient Astras',
    titleHi: 'प्राचीन अस्त्र',
    blurbEn: 'Divine weapons, their wielders and their limits',
    blurbHi: 'दिव्य अस्त्र, उनके धारक और उनकी सीमाएँ',
    icon: Icons.bolt_rounded,
    backingTable: 'entities',
    spec: '4.12',
    shipped: true,
  ),
  GyanModule(
    id: 'symbols',
    route: '/gyan/symbols',
    titleEn: 'Symbols',
    titleHi: 'प्रतीक',
    blurbEn: 'Sacred marks and what they mean, tradition by tradition',
    blurbHi: 'पवित्र चिह्न और परंपरा अनुसार उनके अर्थ',
    icon: Icons.auto_awesome_rounded,
    backingTable: 'entities',
    spec: '4.10',
    shipped: true,
  ),
  GyanModule(
    id: 'srishty',
    route: '/gyan/srishty',
    titleEn: 'Srishty Universe',
    titleHi: 'सृष्टि',
    blurbEn: 'Creation, the lokas and the shape of the cosmos',
    blurbHi: 'सृष्टि, लोक और ब्रह्मांड का स्वरूप',
    icon: Icons.blur_circular_rounded,
    backingTable: 'cosmology_nodes',
    spec: '4.6',
    shipped: true,
  ),
  GyanModule(
    id: 'yuga',
    route: '/gyan/yuga',
    titleEn: 'Yuga Explorer',
    titleHi: 'युग',
    blurbEn: 'The four ages and the cycles of time',
    blurbHi: 'चार युग और काल चक्र',
    icon: Icons.hourglass_bottom_rounded,
    backingTable: 'cosmology_nodes',
    spec: '4.14',
    shipped: true,
  ),
  GyanModule(
    id: 'ramayana',
    route: '/gyan/ramayana',
    titleEn: 'Ramayana Journey',
    titleHi: 'रामायण यात्रा',
    blurbEn: 'The epic as a guided path, scene by scene',
    blurbHi: 'दृश्य दर दृश्य, एक निर्देशित यात्रा',
    icon: Icons.park_rounded,
    backingTable: 'narrative_nodes',
    spec: '4.7',
    shipped: true,
  ),
  GyanModule(
    id: 'mahabharata',
    route: '/gyan/mahabharata',
    titleEn: 'Mahabharata Timeline',
    titleHi: 'महाभारत कालक्रम',
    blurbEn: 'The epic in narrative order, arc by arc',
    blurbHi: 'कथाक्रम में महाभारत, खंड दर खंड',
    icon: Icons.timeline_rounded,
    backingTable: 'narrative_nodes',
    spec: '4.8',
    shipped: true,
  ),
  GyanModule(
    id: 'vidya',
    route: '/gyan/vidya',
    titleEn: 'Vedic Science',
    titleHi: 'वैदिक विद्या',
    blurbEn: 'Traditional knowledge, stated carefully',
    blurbHi: 'पारंपरिक ज्ञान, सावधानी के साथ',
    icon: Icons.science_rounded,
    backingTable: 'vidya_topics',
    spec: '4.15',
    shipped: true,
  ),
  GyanModule(
    id: 'dharma',
    route: '/dharma',
    titleEn: 'Dharma Decisions',
    titleHi: 'धर्म संकट',
    blurbEn: 'Moral dilemmas from the epics — reflection, not verdicts',
    blurbHi: 'महाकाव्यों के धर्मसंकट — चिंतन, निर्णय नहीं',
    icon: Icons.balance_rounded,
    backingTable: 'dharma_scenarios',
    spec: '4.11',
    shipped: true,
  ),
  GyanModule(
    id: 'festivals',
    route: '/festivals',
    titleEn: 'Festivals',
    titleHi: 'पर्व',
    blurbEn: 'Vrats and festivals, with dates for your region',
    blurbHi: 'व्रत और त्योहार, आपके क्षेत्र की तिथियों सहित',
    icon: Icons.celebration_rounded,
    backingTable: 'festivals',
    spec: '4.18',
    shipped: true,
  ),
  GyanModule(
    id: 'ask',
    route: '/ask',
    titleEn: 'Ask the Scriptures',
    titleHi: 'शास्त्र से पूछें',
    blurbEn: 'Answers are passages, selected — never generated',
    blurbHi: 'उत्तर शास्त्र के अंश हैं — रचे नहीं गए',
    icon: Icons.help_center_rounded,
    backingTable: 'qa_pairs',
    spec: '4.19',
  ),
];

/// Lookup by stable id.
GyanModule? gyanModuleById(String id) {
  for (final m in gyanModules) {
    if (m.id == id) return m;
  }
  return null;
}
