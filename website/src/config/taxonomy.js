/**
 * Product-level vocabulary: how the curated content set is presented on the web.
 *
 * The rule this file follows: labels, blurbs and groupings are product copy and
 * live here; anything that asserts a fact about a text, a deity or a place comes
 * from the generated content set (src/data/mockContent.js) and is never written
 * by hand.
 */

/** Search / browse facets, in tab order. `match` runs against a content record. */
export const FACETS = [
  { id: 'all', label: 'All' },
  { id: 'scriptures', label: 'Scriptures' },
  { id: 'stories', label: 'Stories' },
  { id: 'people', label: 'People' },
  { id: 'deities', label: 'Deities' },
  { id: 'places', label: 'Places' },
  { id: 'temples', label: 'Temples' },
  { id: 'festivals', label: 'Festivals' },
  { id: 'practices', label: 'Practices' },
  { id: 'concepts', label: 'Concepts' },
];

export const facetLabel = (id) => FACETS.find((f) => f.id === id)?.label ?? 'Content';

/**
 * Human label for the pipeline's `category` value — what the badge on a card
 * says. Anything missing falls back to a title-cased category.
 */
export const CATEGORY_LABELS = {
  trimurti: 'Trimurti',
  dashavatara: 'Dashavatara',
  avatara: 'Avatara',
  shakta: 'Devi',
  shaiva: 'Shaiva',
  vaishnava: 'Vaishnava',
  ganapatya: 'Ganapatya',
  devi: 'Devi',
  vedic: 'Vedic deity',
  mahabharata: 'Mahabharata',
  ramayana: 'Ramayana',
  pandava: 'Pandava',
  'kaurava-ally': 'Kaurava ally',
  rishi: 'Rishi',
  saptarishi: 'Saptarishi',
  devarishi: 'Devarishi',
  asura: 'Asura',
  exemplar: 'Exemplar',
  vamsha: 'Dynasty',
  vanara: 'Vanara',
  tirtha: 'Tirtha',
  river: 'Sacred river',
  mountain: 'Sacred mountain',
  shastra: 'Shastra',
  purana: 'Purana',
  astra: 'Astra',
  ayudha: 'Divine weapon',
  'sacred-mark': 'Sacred mark',
  vahana: 'Vahana',
  yantra: 'Yantra',
  'ritual-object': 'Ritual object',
  'weapon-symbol': 'Symbol',
  tattva: 'Concept',
};

export const categoryLabel = (category = '') =>
  CATEGORY_LABELS[category] ||
  category.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()) ||
  'Entry';

/** Tirthas are the pilgrimage sites; rivers and mountains stay under Places. */
export const isTirtha = (entity) => entity?.category === 'tirtha';

/**
 * The eight doors on the home page. `glyph` names a motif in components/art/Glyph.
 * `accent` picks a gradient from CATEGORY_GRADIENTS below.
 */
export const EXPLORE_DOORS = [
  {
    id: 'scriptures',
    title: 'Scriptures',
    blurb: 'Read and explore India’s sacred texts.',
    glyph: 'scroll',
    accent: 'scriptures',
    to: '/scriptures',
  },
  {
    id: 'ramayana',
    title: 'Ramayana',
    blurb: 'Walk through the story, one event at a time.',
    glyph: 'bow',
    accent: 'epics',
    to: '/ramayana',
  },
  {
    id: 'mahabharata',
    title: 'Mahabharata',
    blurb: 'Explore the people, events and teachings of the great epic.',
    glyph: 'chakra',
    accent: 'katha',
    to: '/mahabharata',
  },
  {
    id: 'temples',
    title: 'Temples',
    blurb: 'Discover sacred places and their stories.',
    glyph: 'shikhara',
    accent: 'temples',
    to: '/temples',
  },
  {
    id: 'deities',
    title: 'Deities',
    blurb: 'Understand the stories, symbols and traditions.',
    glyph: 'lotus',
    accent: 'mantras',
    to: '/explore?facet=deities',
  },
  {
    id: 'practices',
    title: 'Practices',
    blurb: 'Build a meaningful daily spiritual practice.',
    glyph: 'mala',
    accent: 'sadhana',
    to: '/practices',
  },
  {
    id: 'festivals',
    title: 'Festivals',
    blurb: 'Learn the meaning behind India’s festivals.',
    glyph: 'diya',
    accent: 'panchang',
    to: '/explore?facet=festivals',
  },
  {
    id: 'journeys',
    title: 'Journeys',
    blurb: 'Follow curated paths through spiritual knowledge.',
    glyph: 'compass',
    accent: 'gyan',
    to: '/journeys',
  },
];

/**
 * Category gradients lifted from lib/app/theme/category_colors.dart so a card on
 * the website carries the same colour as the same category inside the app.
 */
export const CATEGORY_GRADIENTS = {
  scriptures: ['#A73015', '#6E1F10'],
  aartis: ['#D4AF37', '#A54325'],
  mantras: ['#C7567F', '#7C1F44'],
  quiz: ['#3E8E6E', '#204B39'],
  astrology: ['#8B6AC7', '#4A2493'],
  panchang: ['#E0762A', '#A7430F'],
  katha: ['#5C6BC0', '#2F3B8E'],
  personality: ['#A85A8C', '#5C2549'],
  temples: ['#9C7A3C', '#5C3B28'],
  gyan: ['#3E7F8E', '#1D4552'],
  srishty: ['#4A3A7A', '#1E1440'],
  epics: ['#8A6A4F', '#4A3220'],
  sadhana: ['#3F7A5E', '#25533F'],
};

export const gradientFor = (accent) =>
  CATEGORY_GRADIENTS[accent] ?? CATEGORY_GRADIENTS.scriptures;

/** Gradient chosen for an entity from its facet — keeps cards colour-coded. */
export const FACET_ACCENT = {
  deities: 'mantras',
  people: 'epics',
  places: 'temples',
  temples: 'temples',
  scriptures: 'scriptures',
  objects: 'aartis',
  concepts: 'gyan',
  festivals: 'panchang',
  stories: 'katha',
  practices: 'sadhana',
  journeys: 'gyan',
};

/**
 * Scripture collections. Each one points at a real entity page where the
 * content set has one; `entitySlug: null` means the collection exists in the app
 * but has no standalone web entry yet, so the card links to the section instead.
 */
export const SCRIPTURE_COLLECTIONS = [
  {
    id: 'bhagavad-gita',
    title: 'Bhagavad Gita',
    titleHi: 'भगवद्गीता',
    blurb: 'Eighteen chapters of dialogue, read chapter by chapter or verse by verse.',
    entitySlug: 'bhagavad-gita',
    accent: 'scriptures',
    glyph: 'chakra',
  },
  {
    id: 'upanishads',
    title: 'Upanishads',
    titleHi: 'उपनिषद्',
    blurb: 'The reflective end of the Veda — inquiry into self and reality.',
    entitySlug: 'upanishads-text',
    accent: 'gyan',
    glyph: 'flame',
  },
  {
    id: 'vedas',
    title: 'Vedas',
    titleHi: 'वेद',
    blurb: 'The oldest layer of the tradition, beginning with the Rigveda.',
    entitySlug: 'rigveda',
    accent: 'aartis',
    glyph: 'scroll',
  },
  {
    id: 'puranas',
    title: 'Puranas',
    titleHi: 'पुराण',
    blurb: 'Cosmology, dynasties and the deeds of the deities, told as story.',
    entitySlug: 'bhagavata-purana',
    accent: 'srishty',
    glyph: 'lotus',
  },
  {
    id: 'stotras',
    title: 'Stotras',
    titleHi: 'स्तोत्र',
    blurb: 'Praise hymns and chalisas, with transliteration alongside the text.',
    entitySlug: null,
    accent: 'mantras',
    glyph: 'conch',
  },
  {
    id: 'mantras',
    title: 'Mantras',
    titleHi: 'मंत्र',
    blurb: 'Short invocations, with meaning and the occasion each belongs to.',
    entitySlug: 'om',
    accent: 'personality',
    glyph: 'om',
  },
];

/** The five practice tools the app ships. Anchors match /practices#id. */
export const PRACTICES = [
  {
    id: 'dhyana',
    title: 'Meditation',
    titleHi: 'ध्यान',
    blurb: 'Timed sitting with a gentle bell, and a record of the days you kept.',
    glyph: 'flame',
    accent: 'sadhana',
  },
  {
    id: 'japa',
    title: 'Japa',
    titleHi: 'जप',
    blurb: 'A counter that behaves like a mala — 108 at a time, streaks remembered.',
    glyph: 'mala',
    accent: 'mantras',
  },
  {
    id: 'pranayama',
    title: 'Breathing',
    titleHi: 'प्राणायाम',
    blurb: 'Guided inhale, hold and exhale cycles you can follow with your eyes closed.',
    glyph: 'breath',
    accent: 'gyan',
  },
  {
    id: 'puja',
    title: 'Puja',
    titleHi: 'पूजा',
    blurb: 'Step-by-step vidhi for the rites people actually perform at home.',
    glyph: 'diya',
    accent: 'panchang',
  },
  {
    id: 'journal',
    title: 'Reflection',
    titleHi: 'चिंतन',
    blurb: 'A private journal for what a reading left you with. Stays on your device.',
    glyph: 'book',
    accent: 'personality',
  },
];

/** Human label for a relation type coming out of the knowledge graph. */
export const RELATION_LABELS = {
  child_of: 'child of',
  father_of: 'father of',
  mother_of: 'mother of',
  sibling_of: 'sibling of',
  spouse_of: 'spouse of',
  wielded_by: 'wielded by',
  student_of: 'student of',
  teacher_of: 'teacher of',
  devotee_of: 'devotee of',
  incarnation_of: 'incarnation of',
  ally_of: 'ally of',
  enemy_of: 'opposed to',
  ruled: 'ruled',
  located_in: 'located in',
  appears_in: 'appears in',
  kept_for: 'festival',
};

/**
 * Relations are stored one way and browsed both ways, so the reverse direction
 * needs its own wording. Getting this wrong would state something false — "Arjuna
 * · father of · Krishna" — so the inverse is spelled out rather than inferred.
 */
export const INVERSE_RELATION_LABELS = {
  child_of: 'parent of',
  father_of: 'child of',
  mother_of: 'child of',
  sibling_of: 'sibling of',
  spouse_of: 'spouse of',
  wielded_by: 'wields',
  student_of: 'teacher of',
  teacher_of: 'student of',
  devotee_of: 'venerated by',
  incarnation_of: 'incarnates as',
  ally_of: 'ally of',
  enemy_of: 'opposed to',
  ruled: 'ruled by',
  located_in: 'contains',
  appears_in: 'appears in',
  kept_for: 'festival',
};

export const relationLabel = (type = '', inverse = false) => {
  const table = inverse ? INVERSE_RELATION_LABELS : RELATION_LABELS;
  return table[type] || RELATION_LABELS[type] || type.replace(/_/g, ' ');
};

/** Epic display names. */
export const EPIC_LABELS = {
  ramayana: 'Ramayana',
  mahabharata: 'Mahabharata',
};

export const LEVEL_LABELS = {
  beginner: 'Beginner',
  core: 'Core',
  deeper: 'Deeper',
};
