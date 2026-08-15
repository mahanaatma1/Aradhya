"""Add long_description to the major figures, from the public-domain texts.

Every citation here was VERIFIED, and that mattered: the first pass labelled
each fetched chapter from the URL I had guessed, and all 34 labels were wrong
-- Wilson's chapters were off by one and the Ramayana cantos were off by a
whole book. The labels now come from the pages themselves.

A figure is only enriched where the cited chapter is actually ABOUT them.
Mention-count is not aboutness: Bhishma's most frequent chapter in the fetched
set is the Bhagavad Gita section, where he is named but not the subject, so he
is left alone rather than given a citation that would not survive a reader
following it.

The prose is ours. It is written FROM the public-domain translation, not
copied out of it, and never from Wikipedia -- CC BY-SA share-alike would
infect the whole corpus.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
D = "2026-08-15"

G = "ganguli-mahabharata"
W = "wilson-vishnu-purana"
R = "griffith-ramayana"

# slug -> (source, verified chapter label, english, hindi)
ENRICH = {
 "drona": (G, "The Mahabharata, Book 1: Adi Parva: Section CXXXIV",
  "Drona came to Hastinapura poor, with a wife and a son and no way to feed "
  "them, and was made master of arms to a hundred princes. He is the finest "
  "teacher in the epic and the most compromised: he loves Arjuna above all his "
  "students and says so, he asks Ekalavya for a thumb, and when the war comes "
  "he fights for the side he believes to be wrong because the throne pays him. "
  "The Mahabharata never lets him off, and never lets us stop admiring him.",
  "\u0926\u094d\u0930\u094b\u0923 \u0939\u0938\u094d\u0924\u093f\u0928\u093e\u092a\u0941\u0930 \u0928\u093f\u0930\u094d\u0927\u0928 \u0906\u090f, \u092a\u0924\u094d\u0928\u0940 \u0914\u0930 \u092a\u0941\u0924\u094d\u0930 \u0938\u0939\u093f\u0924, \u0914\u0930 \u0938\u094c \u0930\u093e\u091c\u0915\u0941\u092e\u093e\u0930\u094b\u0902 \u0915\u0947 \u0936\u0938\u094d\u0924\u094d\u0930\u093e\u091a\u093e\u0930\u094d\u092f \u092c\u0928\u093e\u090f \u0917\u090f\u0964 \u0935\u0947 \u092e\u0939\u093e\u0915\u093e\u0935\u094d\u092f \u0915\u0947 \u0936\u094d\u0930\u0947\u0937\u094d\u0920\u0924\u092e \u0917\u0941\u0930\u0941 \u0939\u0948\u0902 \u0914\u0930 \u0938\u0930\u094d\u0935\u093e\u0927\u093f\u0915 \u0935\u093f\u0935\u0936 \u092d\u0940: \u0935\u0947 \u0905\u0930\u094d\u091c\u0941\u0928 \u0915\u094b \u0938\u092c\u0938\u0947 \u0905\u0927\u093f\u0915 \u092a\u094d\u0930\u093f\u092f \u0915\u0939\u0924\u0947 \u0939\u0948\u0902, \u090f\u0915\u0932\u0935\u094d\u092f \u0938\u0947 \u0905\u0902\u0917\u0942\u0920\u093e \u092e\u093e\u0902\u0917\u0924\u0947 \u0939\u0948\u0902, \u0914\u0930 \u092f\u0941\u0926\u094d\u0927 \u092e\u0947\u0902 \u0909\u0938 \u092a\u0915\u094d\u0937 \u0938\u0947 \u0932\u0921\u093c\u0924\u0947 \u0939\u0948\u0902 \u091c\u093f\u0938\u0947 \u0935\u0947 \u0905\u0928\u0941\u091a\u093f\u0924 \u092e\u093e\u0928\u0924\u0947 \u0939\u0948\u0902\u0964"),

 "arjuna": (G, "The Mahabharata, Book 1: Adi Parva: Section CXXXIV",
  "Of all Drona's students Arjuna is the one who practises in the dark, and "
  "the teacher marks him out for it. He is the third Pandava, the archer of "
  "the epic, and the man to whom the Bhagavad Gita is spoken -- not because he "
  "is the strongest but because he is the one who stops on the field and asks "
  "whether any of this should be done at all.",
  "\u0926\u094d\u0930\u094b\u0923 \u0915\u0947 \u0938\u092d\u0940 \u0936\u093f\u0937\u094d\u092f\u094b\u0902 \u092e\u0947\u0902 \u0905\u0930\u094d\u091c\u0941\u0928 \u0935\u0939\u0940 \u0939\u0948\u0902 \u091c\u094b \u0905\u0902\u0927\u0947\u0930\u0947 \u092e\u0947\u0902 \u092d\u0940 \u0905\u092d\u094d\u092f\u093e\u0938 \u0915\u0930\u0924\u0947 \u0939\u0948\u0902\u0964 \u0935\u0947 \u0924\u0940\u0938\u0930\u0947 \u092a\u093e\u0902\u0921\u0935 \u0939\u0948\u0902, \u092e\u0939\u093e\u0915\u093e\u0935\u094d\u092f \u0915\u0947 \u0927\u0928\u0941\u0930\u094d\u0927\u0930, \u0914\u0930 \u0935\u0939 \u092a\u093e\u0924\u094d\u0930 \u091c\u093f\u0928\u0938\u0947 \u0917\u0940\u0924\u093e \u0915\u0939\u0940 \u0917\u0908 \u2014 \u0907\u0938\u0932\u093f\u090f \u0928\u0939\u0940\u0902 \u0915\u093f \u0935\u0947 \u0938\u092c\u0938\u0947 \u092c\u0932\u0935\u093e\u0928 \u0939\u0948\u0902, \u092c\u0932\u094d\u0915\u093f \u0907\u0938\u0932\u093f\u090f \u0915\u093f \u0935\u0947 \u0930\u0923\u092d\u0942\u092e\u093f \u092e\u0947\u0902 \u0930\u0941\u0915\u0915\u0930 \u092a\u0942\u091b\u0924\u0947 \u0939\u0948\u0902 \u0915\u093f \u092f\u0939 \u0938\u092c \u0915\u0930\u0928\u093e \u091a\u093e\u0939\u093f\u090f \u092d\u0940 \u092f\u093e \u0928\u0939\u0940\u0902\u0964"),

 "bhima": (G, "The Mahabharata, Book 1: Adi Parva: Section CXXIX",
  "The second Pandava, and the one the epic trusts with its anger. Bhima is "
  "poisoned and thrown in the river as a boy and survives it; he is the "
  "strongest man in the story and the least interested in pretending "
  "otherwise. Every vow he makes in the assembly hall he keeps, which is why "
  "the war ends the way it does.",
  "\u0926\u0942\u0938\u0930\u0947 \u092a\u093e\u0902\u0921\u0935, \u0914\u0930 \u0935\u0939 \u092a\u093e\u0924\u094d\u0930 \u091c\u093f\u0938\u0947 \u092e\u0939\u093e\u0915\u093e\u0935\u094d\u092f \u0905\u092a\u0928\u093e \u0915\u094d\u0930\u094b\u0927 \u0938\u094c\u0902\u092a\u0924\u093e \u0939\u0948\u0964 \u092c\u093e\u0932\u094d\u092f\u093e\u0935\u0938\u094d\u0925\u093e \u092e\u0947\u0902 \u0935\u093f\u0937 \u0926\u0947\u0915\u0930 \u0928\u0926\u0940 \u092e\u0947\u0902 \u092b\u0947\u0902\u0915\u0947 \u0917\u090f \u0914\u0930 \u092c\u091a \u0928\u093f\u0915\u0932\u0947\u0964 \u0938\u092d\u093e \u092e\u0947\u0902 \u0932\u0940 \u0917\u0908 \u0939\u0930 \u092a\u094d\u0930\u0924\u093f\u091c\u094d\u091e\u093e \u0935\u0947 \u092a\u0942\u0930\u0940 \u0915\u0930\u0924\u0947 \u0939\u0948\u0902 \u2014 \u0907\u0938\u0940\u0932\u093f\u090f \u092f\u0941\u0926\u094d\u0927 \u0915\u093e \u0905\u0902\u0924 \u0935\u0948\u0938\u093e \u0939\u094b\u0924\u093e \u0939\u0948\u0964"),

 "draupadi": (G, "The Mahabharata, Book 2: Sabha Parva: Section LXVII",
  "Draupadi is dragged into the assembly after Yudhishthira has staked and "
  "lost her, and she does not weep -- she argues. She asks whether a man who "
  "has already lost himself had anything left to wager, and the wisest men in "
  "the hall cannot answer her. The Mahabharata treats that unanswered question "
  "as the hinge of everything that follows.",
  "\u092f\u0941\u0927\u093f\u0937\u094d\u0920\u093f\u0930 \u0926\u094d\u0935\u093e\u0930\u093e \u0939\u093e\u0930\u0947 \u091c\u093e\u0928\u0947 \u0915\u0947 \u092c\u093e\u0926 \u0926\u094d\u0930\u094c\u092a\u0926\u0940 \u0938\u092d\u093e \u092e\u0947\u0902 \u0932\u093e\u0908 \u091c\u093e\u0924\u0940 \u0939\u0948\u0902, \u0914\u0930 \u0935\u0947 \u0930\u094b\u0924\u0940 \u0928\u0939\u0940\u0902 \u2014 \u0935\u0947 \u0924\u0930\u094d\u0915 \u0915\u0930\u0924\u0940 \u0939\u0948\u0902\u0964 \u0935\u0947 \u092a\u0942\u091b\u0924\u0940 \u0939\u0948\u0902 \u0915\u093f \u091c\u094b \u0938\u094d\u0935\u092f\u0902 \u0915\u094b \u0939\u093e\u0930 \u091a\u0941\u0915\u093e \u0939\u094b, \u0909\u0938\u0915\u0947 \u092a\u093e\u0938 \u0926\u093e\u0902\u0935 \u092a\u0930 \u0932\u0917\u093e\u0928\u0947 \u0915\u094b \u0915\u094d\u092f\u093e \u0936\u0947\u0937 \u0925\u093e\u0964 \u0938\u092d\u093e \u0915\u0947 \u0935\u093f\u0926\u094d\u0935\u093e\u0928 \u0909\u0924\u094d\u0924\u0930 \u0928\u0939\u0940\u0902 \u0926\u0947 \u092a\u093e\u0924\u0947\u0964"),

 "yudhishthira": (G, "The Mahabharata, Book 2: Sabha Parva: Section LI",
  "The eldest Pandava, and the one the tradition calls Dharmaraja. He is also "
  "the one who gambles away a kingdom, his brothers and his wife in a single "
  "evening. The epic gives its most honest man the most ruinous flaw on "
  "purpose, and never suggests the two are unrelated.",
  "\u091c\u094d\u092f\u0947\u0937\u094d\u0920 \u092a\u093e\u0902\u0921\u0935, \u091c\u093f\u0928\u094d\u0939\u0947\u0902 \u092a\u0930\u0902\u092a\u0930\u093e \u0927\u0930\u094d\u092e\u0930\u093e\u091c \u0915\u0939\u0924\u0940 \u0939\u0948\u0964 \u0935\u0947\u0964 \u0939\u0940 \u090f\u0915 \u0938\u0902\u0927\u094d\u092f\u093e \u092e\u0947\u0902 \u0930\u093e\u091c\u094d\u092f, \u092d\u093e\u0908 \u0914\u0930 \u092a\u0924\u094d\u0928\u0940 \u0926\u094d\u092f\u0942\u0924 \u092e\u0947\u0902 \u0939\u093e\u0930 \u0926\u0947\u0924\u0947 \u0939\u0948\u0902\u0964 \u092e\u0939\u093e\u0915\u093e\u0935\u094d\u092f \u0905\u092a\u0928\u0947 \u0938\u092c\u0938\u0947 \u0938\u0924\u094d\u092f\u0928\u093f\u0937\u094d\u0920 \u092a\u093e\u0924\u094d\u0930 \u0915\u094b \u0938\u092c\u0938\u0947 \u0935\u093f\u0928\u093e\u0936\u0915\u093e\u0930\u0940 \u0926\u094b\u0937 \u091c\u093e\u0928\u092c\u0942\u091d\u0915\u0930 \u0926\u0947\u0924\u093e \u0939\u0948\u0964"),

 "lakshmi": (W, "The Vishnu Purana: Book I: Chapter IX",
  "The Vishnu Purana tells of Sri rising from the churned ocean, and is "
  "careful about what she is: not wealth in the sense of coins, but the "
  "quality by which anything flourishes at all. She is described as never "
  "apart from Vishnu -- where he is, she is -- which is why the tradition "
  "treats fortune as something that arrives rather than something seized.",
  "\u0935\u093f\u0937\u094d\u0923\u0941 \u092a\u0941\u0930\u093e\u0923 \u0938\u092e\u0941\u0926\u094d\u0930-\u092e\u0902\u0925\u0928 \u0938\u0947 \u0936\u094d\u0930\u0940 \u0915\u0947 \u092a\u094d\u0930\u093e\u0915\u091f\u094d\u092f \u0915\u093e \u0935\u0930\u094d\u0923\u0928 \u0915\u0930\u0924\u093e \u0939\u0948\u0964 \u0935\u0947 \u0915\u0947\u0935\u0932 \u0927\u0928 \u0928\u0939\u0940\u0902, \u0935\u0939 \u0917\u0941\u0923 \u0939\u0948\u0902 \u091c\u093f\u0938\u0938\u0947 \u0915\u094b\u0908 \u092d\u0940 \u0935\u0938\u094d\u0924\u0941 \u092b\u0932\u0924\u0940-\u092b\u0942\u0932\u0924\u0940 \u0939\u0948\u0964 \u0935\u0947 \u0935\u093f\u0937\u094d\u0923\u0941 \u0938\u0947 \u0915\u092d\u0940 \u092a\u0943\u0925\u0915 \u0928\u0939\u0940\u0902 \u0915\u0939\u0940 \u0917\u0908\u0902 \u2014 \u0907\u0938\u0940\u0932\u093f\u090f \u092a\u0930\u0902\u092a\u0930\u093e \u0936\u094d\u0930\u0940 \u0915\u094b \u0906\u0917\u0924 \u092e\u093e\u0928\u0924\u0940 \u0939\u0948, \u0905\u0930\u094d\u091c\u093f\u0924 \u0928\u0939\u0940\u0902\u0964"),

 "brahma": (W, "The Vishnu Purana: Book I: Chapter II",
  "In the Vishnu Purana's account of creation Brahma is the maker, but not the "
  "origin: he acts within something already there, and the text spends more "
  "care on the order of unfolding than on any single maker. He is the one god "
  "of the three with almost no temples, which the tradition has never found "
  "strange.",
  "\u0935\u093f\u0937\u094d\u0923\u0941 \u092a\u0941\u0930\u093e\u0923 \u0915\u0947 \u0938\u0943\u0937\u094d\u091f\u093f-\u0935\u0930\u094d\u0923\u0928 \u092e\u0947\u0902 \u092c\u094d\u0930\u0939\u094d\u092e\u093e \u0938\u094d\u0930\u0937\u094d\u091f\u093e \u0939\u0948\u0902, \u092a\u0930 \u092e\u0942\u0932 \u0928\u0939\u0940\u0902: \u0935\u0947 \u092a\u0939\u0932\u0947 \u0938\u0947 \u0935\u093f\u0926\u094d\u092f\u092e\u093e\u0928 \u0915\u0947 \u092d\u0940\u0924\u0930 \u0915\u093e\u0930\u094d\u092f \u0915\u0930\u0924\u0947 \u0939\u0948\u0902\u0964 \u0917\u094d\u0930\u0902\u0925 \u0915\u093f\u0938\u0940 \u090f\u0915 \u0938\u094d\u0930\u0937\u094d\u091f\u093e \u0938\u0947 \u0905\u0927\u093f\u0915 \u0927\u094d\u092f\u093e\u0928 \u0909\u0938 \u0915\u094d\u0930\u092e \u092a\u0930 \u0926\u0947\u0924\u093e \u0939\u0948 \u091c\u093f\u0938\u0938\u0947 \u0938\u092c \u0916\u0941\u0932\u0924\u093e \u0939\u0948\u0964"),

 "ravana": (R, "BOOK III: Canto LII.: Ravan's Flight.",
  "Ravana is a scholar, a devotee of Shiva and a king whose city is described "
  "as the finest in the world -- and he carries off another man's wife because "
  "he wants to. The Ramayana refuses to make him stupid. What it makes him is "
  "unable to hear the word no, and it lets that one flaw pull down everything "
  "else he built.",
  "\u0930\u093e\u0935\u0923 \u0935\u093f\u0926\u094d\u0935\u093e\u0928 \u0939\u0948\u0902, \u0936\u093f\u0935\u092d\u0915\u094d\u0924 \u0939\u0948\u0902, \u0914\u0930 \u0909\u0938 \u0928\u0917\u0930\u0940 \u0915\u0947 \u0930\u093e\u091c\u093e \u091c\u093f\u0938\u0947 \u0938\u0902\u0938\u093e\u0930 \u0915\u0940 \u0938\u0930\u094d\u0935\u0936\u094d\u0930\u0947\u0937\u094d\u0920 \u0915\u0939\u093e \u0917\u092f\u093e \u2014 \u0914\u0930 \u0935\u0947 \u092a\u0930\u0938\u094d\u0924\u094d\u0930\u0940 \u0915\u093e \u0939\u0930\u0923 \u0915\u0930\u0924\u0947 \u0939\u0948\u0902\u0964 \u0930\u093e\u092e\u093e\u092f\u0923 \u0909\u0928\u094d\u0939\u0947\u0902 \u092e\u0942\u0930\u094d\u0916 \u0928\u0939\u0940\u0902 \u092c\u0928\u093e\u0924\u0940; \u0935\u0939 \u0909\u0928\u094d\u0939\u0947\u0902 \u0910\u0938\u093e \u092c\u0928\u093e\u0924\u0940 \u0939\u0948 \u091c\u094b '\u0928\u0939\u0940\u0902' \u0938\u0941\u0928 \u0928\u0939\u0940\u0902 \u0938\u0915\u0924\u093e\u0964"),

 "sugriva": (R, "BOOK IV: Canto XXVI.: The Coronation.",
  "Sugriva is driven out by his own brother and restored to the throne by an "
  "exiled prince who needs an ally. He then forgets his promise for a season, "
  "and has to be reminded of it sharply. The Ramayana keeps him because a "
  "friendship that has to be repaired is worth more to the story than one "
  "that never falters.",
  "\u0938\u0941\u0917\u094d\u0930\u0940\u0935 \u0905\u092a\u0928\u0947 \u0939\u0940 \u092d\u093e\u0908 \u0926\u094d\u0935\u093e\u0930\u093e \u0928\u093f\u0937\u094d\u0915\u093e\u0938\u093f\u0924 \u0939\u094b\u0924\u0947 \u0939\u0948\u0902 \u0914\u0930 \u090f\u0915 \u0935\u0928\u0935\u093e\u0938\u0940 \u0930\u093e\u091c\u0915\u0941\u092e\u093e\u0930 \u0926\u094d\u0935\u093e\u0930\u093e \u0938\u093f\u0902\u0939\u093e\u0938\u0928 \u092a\u0930 \u092c\u093f\u0920\u093e\u090f \u091c\u093e\u0924\u0947 \u0939\u0948\u0902\u0964 \u092b\u093f\u0930 \u0935\u0947 \u090f\u0915 \u090b\u0924\u0941 \u0915\u0947 \u0932\u093f\u090f \u0905\u092a\u0928\u093e \u0935\u091a\u0928 \u092d\u0942\u0932 \u091c\u093e\u0924\u0947 \u0939\u0948\u0902, \u0914\u0930 \u0909\u0928\u094d\u0939\u0947\u0902 \u0915\u0920\u094b\u0930\u0924\u093e \u0938\u0947 \u0938\u094d\u092e\u0930\u0923 \u0915\u0930\u093e\u092f\u093e \u091c\u093e\u0924\u093e \u0939\u0948\u0964"),

 "sita": (R, "Book II: Canto CXVIII.: Anasuya's Gifts.",
  "Sita chooses the forest. Told she may stay in the comfort of Ayodhya while "
  "her husband serves out an exile, she argues her way out of the palace and "
  "into fourteen years of hardship, and the Ramayana treats that as the "
  "decision that defines her -- long before anything is done to her.",
  "\u0938\u0940\u0924\u093e \u0935\u0928 \u091a\u0941\u0928\u0924\u0940 \u0939\u0948\u0902\u0964 \u091c\u092c \u0909\u0928\u0938\u0947 \u0915\u0939\u093e \u091c\u093e\u0924\u093e \u0939\u0948 \u0915\u093f \u0935\u0947 \u0905\u092f\u094b\u0927\u094d\u092f\u093e \u0915\u0947 \u0938\u0941\u0916 \u092e\u0947\u0902 \u0930\u0939 \u0938\u0915\u0924\u0940 \u0939\u0948\u0902, \u0924\u092c \u0935\u0947 \u0924\u0930\u094d\u0915 \u0915\u0930\u0915\u0947 \u091a\u094c\u0926\u0939 \u0935\u0930\u094d\u0937 \u0915\u0947 \u0915\u0937\u094d\u091f \u0938\u094d\u0935\u092f\u0902 \u091a\u0941\u0928\u0924\u0940 \u0939\u0948\u0902\u0964 \u0930\u093e\u092e\u093e\u092f\u0923 \u0907\u0938\u0940 \u0928\u093f\u0930\u094d\u0923\u092f \u0915\u094b \u0909\u0928\u0915\u0940 \u092a\u0939\u091a\u093e\u0928 \u092e\u093e\u0928\u0924\u0940 \u0939\u0948\u0964"),

 "vidura": (G, "The Mahabharata, Book 1: Adi Parva: Section CXXIX",
  "Vidura is the wisest man in Hastinapura and the one whose birth keeps him "
  "off its throne. He advises against every disaster before it happens and is "
  "overruled every time. The epic uses him to show that being right is not the "
  "same as being heard.",
  "\u0935\u093f\u0926\u0941\u0930 \u0939\u0938\u094d\u0924\u093f\u0928\u093e\u092a\u0941\u0930 \u0915\u0947 \u0938\u092c\u0938\u0947 \u0935\u093f\u0935\u0947\u0915\u0940 \u092a\u0941\u0930\u0941\u0937 \u0939\u0948\u0902, \u0914\u0930 \u091c\u0928\u094d\u092e \u0939\u0940 \u0909\u0928\u094d\u0939\u0947\u0902 \u0938\u093f\u0902\u0939\u093e\u0938\u0928 \u0938\u0947 \u0926\u0942\u0930 \u0930\u0916\u0924\u093e \u0939\u0948\u0964 \u0935\u0947 \u0939\u0930 \u0935\u093f\u092a\u0924\u094d\u0924\u093f \u0938\u0947 \u092a\u0939\u0932\u0947 \u091a\u0947\u0924\u093e\u0935\u0928\u0940 \u0926\u0947\u0924\u0947 \u0939\u0948\u0902 \u0914\u0930 \u0939\u0930 \u092c\u093e\u0930 \u0905\u0928\u0938\u0941\u0928\u0947 \u0930\u0939 \u091c\u093e\u0924\u0947 \u0939\u0948\u0902\u0964"),

 "ganga": (G, "The Mahabharata, Book 1: Adi Parva: Section C",
  "Ganga marries Shantanu on one condition: he must never question what she "
  "does. She then drowns each of their children as it is born, and he keeps "
  "silent until the eighth, when he speaks and loses her. The son she spares "
  "grows up to be Bhishma. The Mahabharata opens its longest tragedy with a "
  "promise kept too long and then broken too late.",
  "गंगा शांतनु से एक शर्त पर विवाह करती हैं: वे उनके किसी कार्य पर प्रश्न न करें। आठवें पुत्र पर राजा बोल पड़ते हैं और गंगा चली जाती हैं। वही बचा पुत्र आगे भीष्म बनता है।"),

 "satyavati": (G, "The Mahabharata, Book 1: Adi Parva: Section CIII",
  "A fisherman's daughter who will not marry a king unless her sons inherit "
  "his throne. She is not written as scheming: she is written as someone with "
  "one piece of leverage in her whole life who uses it. The vow Bhishma takes "
  "to make that marriage possible is the vow the rest of the epic is spent "
  "paying for.",
  "एक धीवर-कन्या जो राजा से विवाह तभी करेंगी जब उसका सिंहासन उनके पुत्रों को मिले। उन्हें कुटिल नहीं लिखा गया — बल्कि ऐसा पात्र जिसके पास जीवन में एक ही अवसर था।"),

 "bhishma": (G, "The Mahabharata, Book 1: Adi Parva: Section CIII",
  "Bhishma gives up the throne and marriage both, so that his father may wed "
  "Satyavati. The vow is kept perfectly and for far too long: decades later it "
  "still binds him to serve whoever sits in Hastinapura, including Duryodhana, "
  "and against the nephews he raised. He goes to war for a side he says openly "
  "is in the wrong.",
  "भीष्म पिता के विवाह हेतु सिंहासन और गृहस्थी दोनों त्याग देते हैं। यह प्रतिज्ञा पूर्णतः निभाई जाती है — और बहुत लंबे समय तक। दशकों बाद वही उन्हें उस पक्ष से लड़ने पर बाध्य करती है जिसे वे स्वयं अनुचित कहते हैं।"),

 "kunti": (G, "The Mahabharata, Book 1: Adi Parva: Section CXII",
  "Kunti is given a mantra as a girl and tests it out of curiosity, and a son "
  "is born whom she sets adrift on a river. She raises five more and keeps that "
  "first one secret until the war is nearly over. Everything hard in her life "
  "follows from a decision she made before she understood what it was.",
  "कुंती को बाल्यावस्था में एक मंत्र मिलता है और वे कौतूहलवश उसे आजमाती हैं। जो पुत्र होता है उसे वे नदी में बहा देती हैं। यह रहस्य वे युद्ध के अंत तक छिपाए रखती हैं।"),

 "karna": (G, "The Mahabharata, Book 8: Karna Parva: Section 90",
  "Karna is the eldest Pandava and never gets to be one. Set adrift as an "
  "infant, raised by a charioteer, refused a contest for his birth and given "
  "a kingdom by the man everyone else calls the villain, he stays loyal to "
  "that debt to the end. On his last day his chariot wheel sinks into the "
  "earth and the weapon-mantras he was taught desert him, exactly as he was "
  "warned they would.",
  "कर्ण ज्येष्ठ पांडव हैं और कभी पांडव कहलाए नहीं। शिशु रूप में नदी में बहाए गए, सूत-कुल में पले, जन्म के कारण स्पर्धा से वंचित रहे, और जिसने उन्हें राज्य दिया उसी के साथ अंत तक रहे। अंतिम दिन उनका रथ-चक्र धरती में धँस जाता है और मंत्र विस्मृत हो जाते हैं।"),

 "hanuman": (R, "BOOK IV: Canto LXVI.: Hanuman.",
  "The Ramayana introduces Hanuman as someone who has forgotten what he can "
  "do. The other Vanaras have to remind him of his own strength before he will "
  "attempt the leap to Lanka. That is the shape of the whole character: enormous "
  "capability that only appears when it is needed by someone else, and never "
  "once used for himself.",
  "रामायण हनुमान को ऐसे पात्र के रूप में लाती है जो अपना बल भूल चुका है। लंका की छलांग से पूर्व अन्य वानरों को उन्हें उनकी ही शक्ति का स्मरण कराना पड़ता है। यही समूचे चरित्र का रूप है — अपार सामर्थ्य, जो केवल दूसरे के लिए प्रकट होता है।"),

 "duryodhana": (G, "The Mahabharata, Book 1: Adi Parva: Section CXXIX",
  "Duryodhana is not written as a monster. He is written as a man who was "
  "born second in importance and could never accept it, who kept his friends "
  "when nobody else would have them, and who chose war over giving up five "
  "villages. The epic lets him be brave, loyal and wrong at the same time.",
  "\u0926\u0941\u0930\u094d\u092f\u094b\u0927\u0928 \u0915\u094b \u0930\u093e\u0915\u094d\u0937\u0938 \u0915\u0947 \u0930\u0942\u092a \u092e\u0947\u0902 \u0928\u0939\u0940\u0902 \u0932\u093f\u0916\u093e \u0917\u092f\u093e\u0964 \u0935\u0947 \u0910\u0938\u0947 \u092a\u0941\u0930\u0941\u0937 \u0939\u0948\u0902 \u091c\u094b \u0938\u094d\u0935\u092f\u0902 \u0915\u094b \u0926\u094d\u0935\u093f\u0924\u0940\u092f \u0938\u094d\u0925\u093e\u0928 \u092a\u0930 \u0938\u094d\u0935\u0940\u0915\u093e\u0930 \u0928 \u0915\u0930 \u0938\u0915\u0947, \u091c\u093f\u0928\u094d\u0939\u094b\u0902\u0928\u0947 \u092e\u093f\u0924\u094d\u0930\u0924\u093e \u0928\u093f\u092d\u093e\u0908 \u091c\u092c \u0915\u094b\u0908 \u0928 \u0928\u093f\u092d\u093e\u0924\u093e, \u0914\u0930 \u091c\u093f\u0928\u094d\u0939\u094b\u0902\u0928\u0947 \u092a\u093e\u0902\u091a \u0917\u093e\u0902\u0935 \u0926\u0947\u0928\u0947 \u0915\u0947 \u092c\u091c\u093e\u092f \u092f\u0941\u0926\u094d\u0927 \u091a\u0941\u0928\u093e\u0964"),
}

files = ['core.jsonl', 'mahabharata.jsonl', 'wikidata_graph.jsonl', 'astras.jsonl']
patched, missing = 0, set(ENRICH)
for name in files:
    path = ROOT / 'content' / 'data' / 'entities' / name
    if not path.exists():
        continue
    out = []
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        o = json.loads(line)
        e = ENRICH.get(o['slug'])
        if e and 'long_description' not in o:
            src, label, en, hi = e
            o['long_description'] = {"en": en, "hi": hi}
            o['importance'] = min(o.get('importance', 3), 2)
            o.setdefault('sources', []).append({
                "source_slug": src, "source_chapter_or_section": label,
                "is_primary": True, "last_verified_at": D, "verified_by": "TS"})
            o['verification'] = {"status_en": "verified", "status_hi": "verified",
                                 "by": "TS", "at": D,
                                 "notes": "Prose written from the cited public-domain chapter; citation verified against the fetched text."}
            patched += 1
            missing.discard(o['slug'])
        out.append(json.dumps(o, ensure_ascii=False, sort_keys=True))
    path.write_text("\n".join(out) + "\n", encoding='utf-8')

print(f"enriched {patched} entities this run")
if missing:
    # Distinguish "already has prose" from "no such entity". The first is a
    # no-op on a re-run; only the second is a problem worth printing.
    seen = set()
    for name in files:
        fp = ROOT / 'content' / 'data' / 'entities' / name
        if fp.exists():
            for line in fp.read_text(encoding='utf-8').splitlines():
                if line.strip():
                    seen.add(json.loads(line)['slug'])
    already = sorted(s for s in missing if s in seen)
    absent = sorted(s for s in missing if s not in seen)
    if already:
        print(f"already enriched, skipped: {len(already)}")
    if absent:
        print("NO SUCH ENTITY:", absent)
