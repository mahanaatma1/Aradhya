/**
 * The two epics.
 *
 * Kept out of pages/Epic.jsx so that scripts/prerender.mjs — plain Node, no JSX
 * transform — can read the same titles and descriptions the page renders. One
 * definition, so a prerendered <title> cannot disagree with the live one.
 */

export const EPICS = {
  ramayana: {
    title: 'Ramayana',
    titleHi: 'रामायण',
    eyebrow: 'Valmiki Ramayana',
    glyph: 'bow',
    accent: 'epics',
    lead: 'A prince is exiled on the eve of his coronation, his wife is taken, and an army of unlikely allies is raised to bring her home. Read as a sequence of events, each with its cast and its source.',
    description:
      'The Ramayana, book by book — exile, abduction, the search and the return. Every event summarised with its cast and the passage it comes from.',
  },
  mahabharata: {
    title: 'Mahabharata',
    titleHi: 'महाभारत',
    eyebrow: 'Vyasa Mahabharata',
    glyph: 'chakra',
    accent: 'katha',
    lead: 'A quarrel between cousins over a throne, which becomes the tradition’s longest argument about duty — and, in its sixth book, a conversation between two armies.',
    description:
      'The Mahabharata, book by book — the vow, the dice game, the exile, the war and what followed. Every event with its cast and its source.',
  },
};

export default EPICS;
