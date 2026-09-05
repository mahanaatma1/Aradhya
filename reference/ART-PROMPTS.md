# DivyaVaani — AI Art Prompts (copy-paste ready)

All 55 assets from `assets/manifest.json`. Each prompt below is **complete** — copy the whole block into ChatGPT, Midjourney, Firefly, or Leonardo and generate.

**Rules**
- Generate at **2× size**, then resize to the **Target size** listed.
- Save regenerated images to `reference/generated_review/` first (exact filename, e.g. `krishna.png`) for side-by-side comparison against the current `assets/images/` version.
- Once approved, move the file from `reference/generated_review/` into `assets/images/` or `assets/icon/`, overwriting the old one.
- **Do not** upload Ishvarvaani images as reference (copyright). These prompts describe the style only.
- After generation: human-review, then update `assets/manifest.json` (tool, model, date, prompt, `human_reviewed`).

**Status: all 40 assets actually used by the app (`lib/`) are done. Nothing left to generate.**

**Done (28) — real original art, moved into `assets/images/`, verified byte-distinct from Ishvarvaani, manifest updated:**
- 12 deities (AI-generated): ganesha, shiva, krishna, ram, hanuman, durga, lakshmi, saraswati, kartikeya, ayyappa, dattatreya, meenakshi
- 12 portrait medallions (cropped + circular-masked from the deity images above, no separate generation): pganesha, pshiva, pkrishna, pram, phanuman, pdurga, plakshmi, psaraswati, pkartikeya, payyappa, pdattatreya, pmeenakshi
- 6 emotion banners (hand-authored SVG → PNG): anger, joy, peace, love, faith, fear
- japa_badge, quiz_bg, bhog, ondiya, aartis, bhagavadgita, mahabharata, mantras, ramayana, upanishads

**Removed — confirmed unused anywhere in `lib/`, old Ishvarvaani copies deleted from `assets/images/` and `assets/manifest.json` (not regenerated, since nothing renders them):**
currency, hor, ladoo, offdiya, pan, pladoo, pother, quiz_badge, quote_bg, streak_badge, vitual, logo

**Confirmed original, no action needed (not Ishvarvaani copies, used only via `pubspec.yaml` launcher-icon config, not `lib/`):**
`assets/icon/icon.png`, `assets/icon/icon_foreground.png`, `assets/icon/lotus.png`

---

## 1. ganesha.png -- done

**Target:** 1024×1024 · **Save as:** `assets/images/ganesha.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm cream #FDF8F5, terracotta #A73015, antique gold #C0A062 #D4AF37, rose #E07A98, brown ink #5C3B28. Soft upper-left lighting.

Subject: Lord Ganesha standing upright on a carved sandstone plinth/pedestal, both feet planted, gentle relaxed tribhanga stance. Elephant head, richly shaded warm golden-tan skin with soft dimensional highlights and blush undertones on cheeks/trunk, expressive detailed eyes, four arms — modak sweet, lotus, small trishul, blessing mudra. Terracotta-red upper cloth, golden yellow dhoti, rose-pink sash. Ornate golden crown with jewel, golden prabhavali flame halo behind head, marigold flower dots on plinth edge. Small mouse (mushika vahana) standing beside plinth base. Benevolent calm expression with soft facial shading. Full standing figure, centered composition. Transparent background. 1024x1024 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border, scary, modern clothing.
```

---

## 2. shiva.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/shiva.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm cream #FDF8F5, terracotta #A73015, antique gold #C0A062, ash-grey-blue skin #CFC6B2, saffron dhoti #C97F26, teal accent #2F5D6B, cool blue-green halo #5F9BA8. Soft upper-left lighting.

Subject: Lord Shiva in anthropomorphic human-like divine form (NOT a Shivling/lingam — a full figure with head, face, arms, and legs), standing upright on a carved stone plinth/pedestal, both feet planted, one hand resting on trishul planted beside him for a natural standing pose. Matted jata hair with crescent moon, third eye on forehead, richly shaded ash-blue-grey skin with soft dimensional highlights and gentle facial contouring, four arms — damaru drum, trishul, blessing and abhaya mudra. Saffron-orange dhoti, tiger-skin tone sash, rudraksha mala. Cool blue-green prabhavali aureole. Serene meditative expression with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border, scary horror, modern clothing.
```

---

## 3. krishna.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/krishna.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm cream #FDF8F5, antique gold #C0A062 #D4AF37, saffron #FF9F43, golden dhoti #E8B23C, traditional blue-grey divine skin #8CA6C9. Soft upper-left lighting.

Subject: Lord Krishna as Venugopala standing upright on a carved stone plinth/pedestal in classic tribhanga (thrice-bent) pose, one leg gracefully crossed in front of the other, both feet on the plinth. Two arms playing bamboo flute at lips. Peacock feather crest in ornate golden crown. Richly shaded blue-grey divine skin with soft dimensional highlights, warm blush on cheeks, detailed expressive gentle smiling eyes and soft-shaded serene face. Saffron angavastram across shoulder, golden dhoti. Marigold flower garland. Bright golden prabhavali flame halo. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border, western clothing, scary.
```

---

## 4. ram.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/ram.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm cream #FDF8F5, antique gold #C0A062 #D4AF37, forest green #25533F, golden dhoti #E8C15A, terracotta sash #A73015, blue-grey divine skin #8CA6C9. Soft upper-left lighting.

Subject: Lord Rama standing upright on a carved stone plinth/pedestal, both feet planted in a relaxed noble stance. Two arms holding bow and arrow. Richly shaded blue-grey divine skin with soft dimensional highlights and warm facial contouring. Forest green upper garment, golden dhoti, terracotta sash. Ornate golden crown, marigold flower garland. Golden prabhavali flame halo. Noble calm warrior-prince expression with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border, modern clothing.
```

---

## 5. hanuman.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/hanuman.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm cream #FDF8F5, terracotta #A73015, saffron #FF9F43, warm orange skin #E0713F, antique gold #C0A062, saffron halo. Soft upper-left lighting.

Subject: Lord Hanuman standing upright on a carved stone plinth/pedestal, both feet planted, gada mace resting on the ground beside him for a natural standing pose. Vanara monkey-god face with richly shaded warm orange skin, soft dimensional highlights, strong devoted expression with detailed soft-shaded face. Two arms — gada mace in one hand, blessing mudra in other. Saffron dhoti, terracotta sash, golden crown. Long tail curving gracefully in one smooth arc behind left shoulder (not segmented cartoon tail). Saffron-toned prabhavali halo. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border, scary, kinked segmented tail.
```

---

## 6. durga.png -- done

**Target:** 1024×1024 · **Save as:** `assets/images/durga.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm golden skin #F2CFA6, terracotta choli #A73015, deep red lehenga #C4203F, antique gold #C0A062 #D4AF37, marigold garland. Soft upper-left lighting.

Subject: Goddess Durga standing upright on a carved stone plinth/pedestal, both feet planted in a powerful graceful stance. Four arms — lotus flower, trishul, chakra discus, conch shell. Richly shaded warm golden skin with soft dimensional highlights and detailed facial contouring. Terracotta-red choli, deep red skirt, golden sash and border. Ornate golden crown, heavy gold jewellery, marigold garland. Small lion vahana standing beside the plinth. Bright golden prabhavali flame halo. Fierce yet benevolent divine expression with soft-shaded face. Full standing figure, centered. Transparent background. 1024x1024 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border, gore, scary horror.
```

---

## 7. lakshmi.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/lakshmi.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm golden skin #F2CFA6, rose-pink silk #9C2950 #D8456E, antique gold #C0A062 #D4AF37, cream accents #FDF8F5. Soft upper-left lighting.

Subject: Goddess Lakshmi standing upright on a carved stone plinth/pedestal (or on a full-bloom lotus atop the plinth), both feet planted, graceful elegant stance. Four arms — two lotus flowers, gold coins showering from palm, blessing mudra. Richly shaded warm golden skin with soft dimensional highlights and gentle blush facial contouring. Rose-pink silk sari with golden border, golden sash. Ornate golden crown and jewellery, marigold garland. Gold coins scattered near feet on the plinth. Golden prabhavali flame halo. Graceful serene smile with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border.
```

---

## 8. saraswati.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/saraswati.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm golden skin #F2CFA6, cream-white sari #FFFEFA, soft teal accent #7FD9DC, pale aqua-gold halo #CFE6EA, antique gold #C0A062. Soft upper-left lighting.

Subject: Goddess Saraswati standing upright on a carved stone plinth/pedestal, both feet planted, gently holding and playing the veena in a natural standing pose. Four arms — veena lute, sacred book pothi, mala rosary, blessing mudra. Richly shaded warm golden skin with soft dimensional highlights and detailed facial contouring. Cream-white sari with teal accent. White swan hamsa vahana standing beside the plinth. Pale aqua-gold prabhavali halo. Wise peaceful expression with soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border.
```

---

## 9. kartikeya.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/kartikeya.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: youthful golden skin #F0C9A0, red sacred cloth #C4203F, golden dhoti #E8B23C, green accent #5F8C6E, antique gold #C0A062 #D4AF37. Soft upper-left lighting.

Subject: Lord Kartikeya (Murugan) standing upright on a carved stone plinth/pedestal, both feet planted, vel spear held upright beside him. Youthful richly shaded golden skin with soft dimensional highlights, two arms holding vel leaf-shaped spear. Red upper garment, golden dhoti, green sash. Ornate golden crown. Peacock standing beside the plinth (peacock vahana). Golden prabhavali flame halo. Brave youthful expression with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border.
```

---

## 10. ayyappa.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/ayyappa.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm tan skin #E0B98F, dark blue sacred garment #2E4A7A, saffron accent #FF9F43, antique gold crown #C0A062, saffron halo. Soft upper-left lighting.

Subject: Lord Ayyappa standing upright on a carved stone plinth/pedestal, both feet planted, calm dignified stance. Two arms — bell in one hand, bow in other. Richly shaded warm tan skin with soft dimensional highlights and gentle facial contouring. Unified dark blue dhoti and shawl, saffron yogapatta band across torso. Golden crown. Saffron prabhavali halo. Calm yogi-devotee expression with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border, modern clothing.
```

---

## 11. dattatreya.png -- done

**Target:** 1080×1080 · **Save as:** `assets/images/dattatreya.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: golden skin #EFCBA4, full saffron robes #FF9F43, cream sash #E8DCC8, antique gold #C0A062 #D4AF37. Soft upper-left lighting.

Subject: Lord Dattatreya standing upright on a carved stone plinth/pedestal, both feet planted, serene ascetic stance. Matted jata hair, richly shaded golden skin with soft dimensional highlights, four arms — damaru drum, mala rosary, trishul, kalash sacred pot. Full saffron robes, cream sash. Triple-ring sun symbol behind head. Golden prabhavali flame halo. Serene ascetic sage expression with detailed soft-shaded face. Full standing figure, centered. Transparent background. 1080x1080 square.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, extra arms, distorted face, text, logo, border.
```

---

## 12. meenakshi.png -- done

**Target:** 1080×1381 · **Save as:** `assets/images/meenakshi.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Highly polished traditional Indian devotional idol art — fine painterly detail, realistic carved-gold and gilt-bronze pedestal texture, richly rendered silk/fabric folds with subtle sheen, dimensional shading and soft ambient occlusion, jewel-toned gemstone highlights, premium temple-idol poster quality (murti-photograph level finish, hand-painted not flat). NO cartoon, NO chibi, NO anime, NO 3D render look, NO photorealistic human skin, NO harsh black outlines, NO text, NO watermark.

Colors: warm copper-golden skin #D8A87C, forest green sari #1F6B4F #25533F, antique gold #C0A062 #D4AF37, cream accents. Soft upper-left lighting.

Subject: Goddess Meenakshi standing upright on a carved stone plinth/pedestal, both feet planted, regal graceful stance, taller vertical composition. Two arms — green parrot in one hand, blessing mudra in other. Richly shaded warm copper-golden skin with soft dimensional highlights and detailed facial contouring. Forest green sari with golden border and sash. Ornate golden crown. Twin fish emblems near feet on the plinth (Madurai temple motif). Golden prabhavali flame halo. Regal South Indian devi expression with soft-shaded face. Full standing figure, centered. Transparent background. 1080x1381 portrait aspect.

Avoid: cartoon, chibi, anime, 3D, photorealistic, neon colors, extra fingers, distorted face, text, logo, border.
```

---

## 13. pganesha.png -- done (crop from ganesha.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pganesha.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Ganesha — head and shoulders only, elephant head, ornate golden crown, modak sweet near hand, warm golden-tan skin. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark pattern behind, thin antique gold ring border. Soft smooth shading, centered face. Designed as circle within 256x256 square.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, extra fingers, distorted face.
```

---

## 14. pshiva.png -- done (crop from shiva.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pshiva.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Shiva — head and shoulders only, matted jata hair, crescent moon, third eye, trishul visible, ash-grey-blue skin #CFC6B2. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. Soft smooth shading, centered face. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 15. pkrishna.png -- done (crop from krishna.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pkrishna.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Krishna — head and shoulders only, blue-grey divine skin #8CA6C9, peacock feather in crown, bamboo flute, saffron cloth hint. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. Gentle smile. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 16. pram.png -- done (crop from ram.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pram.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Rama — head and shoulders only, blue-grey divine skin #8CA6C9, ornate golden crown, bow visible, forest green garment hint, noble calm expression. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 17. phanuman.png -- done (crop from hanuman.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/phanuman.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Hanuman — head and shoulders only, vanara monkey-god face, warm orange skin #E0713F, devoted strong expression, golden crown hint. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 18. pdurga.png -- done (crop from durga.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pdurga.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Goddess Durga — head and shoulders only, warm golden skin #F2CFA6, terracotta-red and deep red garments, ornate golden crown and jewellery, fierce yet benevolent expression. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 19. plakshmi.png -- done (crop from lakshmi.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/plakshmi.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Goddess Lakshmi — head and shoulders only, warm golden skin #F2CFA6, rose-pink sari #9C2950, gold jewellery, lotus flower hint, graceful serene smile. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 20. psaraswati.png -- done (crop from saraswati.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/psaraswati.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Goddess Saraswati — head and shoulders only, warm golden skin #F2CFA6, cream-white sari, soft teal accent #7FD9DC, veena hint, wise peaceful expression. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 21. pkartikeya.png -- done (crop from kartikeya.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pkartikeya.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Kartikeya — head and shoulders only, youthful golden skin #F0C9A0, red sacred cloth, vel spear hint, ornate golden crown, brave youthful face. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 22. payyappa.png -- done (crop from ayyappa.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/payyappa.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Ayyappa — head and shoulders only, warm tan skin #E0B98F, dark blue garment #2E4A7A, serene yogi expression, golden crown hint. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 23. pdattatreya.png -- done (crop from dattatreya.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pdattatreya.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Lord Dattatreya — head and shoulders only, golden skin #EFCBA4, matted jata hair, saffron robes #FF9F43, serene ascetic sage expression. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 24. pmeenakshi.png -- done (crop from meenakshi.png, no separate generation needed)

**Target:** 256×256 · **Save as:** `assets/images/pmeenakshi.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, premium Hindu calendar art quality. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion portrait bust of Goddess Meenakshi — head and shoulders only, warm copper-golden skin #D8A87C, forest green sari #1F6B4F, green parrot hint, ornate golden crown, regal South Indian devi expression. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, distorted face.
```

---

## 25. pother.png -- removed (unused in app code, old copy deleted)

**Target:** 256×256 · **Save as:** `assets/images/pother.png` · **Background:** circular medallion

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading. NO cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.

Circular avatar medallion fallback icon: small Hindu home shrine niche with generic murti silhouette inside arched alcove, warm cream #FDF8F5 and terracotta #A73015 tones, diya lamp glow, no specific deity face visible. Warm burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle golden mandala watermark behind, thin antique gold ring border. 256x256 square designed as circle.

Avoid: cartoon, chibi, anime, 3D, recognizable celebrity face, text, logo, border frame.
```

---

## 26. peace.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/peace.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Peace". Soft white calm background #FFFFFF. Bottom-left corner: stylized lotus flower in teal aqua #8FDDDF #B7EBEC. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, decorative devotional atmosphere, serene meditation mood. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary, horror.
```

---

## 27. joy.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/joy.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Joy". Soft warm cream background #FFFDF6. Bottom-left corner: stylized lotus flower in golden yellow #F5C24C #FADFA1. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, uplifting festive calm mood. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary.
```

---

## 28. love.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/love.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Love". Soft blush background #FFFAFB. Bottom-right corner: stylized lotus flower in rose pink #EC9BAF #F6C9D3. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, gentle romantic devotional warmth. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary.
```

---

## 29. faith.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/faith.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Faith". Soft warm cream background #FFFCF5. Bottom-left corner: stylized lotus flower in amber gold #EBA84C #F6D5A3. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, sacred dawn light feeling. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary.
```

---

## 30. anger.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/anger.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Anger". Soft warm white background #FFF8F5. Bottom-right corner: stylized lotus flower in coral orange #DE7452 #EFAE97. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, intense emotional energy but NOT scary or horror. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary horror, fire disaster.
```

---

## 31. fear.png -- done

**Target:** 1920×1080 · **Save as:** `assets/images/fear.png` · **Background:** opaque landscape

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth watercolor-like gradients, premium mobile app quality. NO people, NO faces, NO text, NO watermark, NO cartoon.

Abstract emotion banner for "Fear". Soft pale blue background #F9FAFF. Bottom-left corner: stylized lotus flower in lavender purple #8B93C8 #C0C5E2. From the lotus: 5-7 smooth sweeping gradient light rays fanning diagonally across the frame, watercolor-soft edges, misty uncertain atmosphere but gentle NOT horror. 1920x1080 landscape.

Avoid: people, faces, text, logo, cartoon, harsh rays, neon colors, scary horror, monsters.
```

---

## 32. ramayana.jpg -- done

**Target:** 440×384 · **Save as:** `assets/images/ramayana.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients, storybook scripture cover quality. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Ramayana scripture cover illustration. Dandaka forest scene: Lord Rama with blue-grey skin and bow walking with Sita in rose sari among stylized forest trees, golden magical deer (Maricha) in the distance, warm sunset cream sky #F6EBDC, earthy forest greens and browns #B4855E. Soft narrative illustration, no text, no border. 440x384 landscape card.

Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, neon colors, border frame.
```

---

## 33. bhagavadgita.jpg -- done

**Target:** 399×384 · **Save as:** `assets/images/bhagavadgita.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients, storybook scripture cover quality. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Bhagavad Gita scripture cover. Lord Krishna with blue-grey skin and crown counselled Arjuna on a chariot before the Kurukshetra battle, chariot wheel visible, warm golden dawn sky gradient #FBF0DC to #EFD6AE, peaceful pre-war moment, Krishna gesturing teaching. Soft narrative illustration, no text, no border. 399x384.

Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, gore, battle violence, border frame.
```

---

## 34. mahabharata.jpg -- done

**Target:** 1600×1357 · **Save as:** `assets/images/mahabharata.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients, epic scripture cover quality. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Mahabharata epic cover. Kurukshetra battlefield symbolism — large chariot wheel at center, crossed bow and mace behind it, two army banners on left (terracotta #A73015) and right (sacred green #25533F), distant soft soldier silhouettes on horizon, warm dusty dawn sky #F7E9D2 to #E4C59A, epic scale but soft not gory. No text, no border. 1600x1357.

Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, gore, blood, border frame.
```

---

## 35. upanishads.jpg -- done

**Target:** 435×384 · **Save as:** `assets/images/upanishads.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients, storybook scripture cover quality. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Upanishads scripture cover. Ancient guru seated under large banyan tree teaching two disciples seated on ground, small oil diya lamp glowing warmly, warm cream earth tones #F7EEDD #C9A882, scholarly serene atmosphere. Soft traditional illustration, no text, no border. 435x384.

Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, border frame.
```

---

## 36. aartis.jpg -- done

**Target:** 417×312 · **Save as:** `assets/images/aartis.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Aartis devotional cover illustration. Devotee hands cupping a brass aarti thali plate with three ghee flames burning brightly, ornate temple bells hanging above, warm golden radial glow background #FDF2DE to #E9CFA4, evening ghat devotional mood without photorealism. Soft spiritual light, no text, no border. 417x312.

Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, border frame, full face visible.
```

---

## 37. mantras.jpg -- done

**Target:** 448×434 · **Save as:** `assets/images/mantras.jpg` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, gentle watercolor-like gradients. NO text, NO title, NO watermark, NO cartoon, NO 3D.

Mantras meditation cover illustration. Japa mala prayer beads arranged in a circle at center, soft concentric sound ripple rings radiating outward, small lotus at bottom, warm cream radial background #FDF6E8 to #EBD6B4, meditative calm atmosphere. No text, no Om symbol, no border. 448x434 square-ish.

Avoid: text, title, logo, Om symbol, cartoon, chibi, anime, 3D, border frame.
```

---

## 38. bhog.png -- done

**Target:** 1025×1537 · **Save as:** `assets/images/bhog.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, app puja item quality. NO text, NO watermark, NO cartoon, NO 3D.

Puja bhog fruit offering illustration. Ornate brass bowl katora filled with fresh fruits — red apple, green banana, orange — plus one golden modak sweet on top, small green leaf garnish. Soft shadow beneath bowl. Transparent background, centered vertical composition, warm golden lighting. 1025x1537 portrait.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, hands, people, border frame.
```

---

## 39. ladoo.png -- removed (unused in app code, old copy deleted)

**Target:** 1080×1080 · **Save as:** `assets/images/ladoo.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, app puja item quality. NO text, NO watermark, NO cartoon, NO 3D.

Three golden-orange ladoos Indian sweet balls stacked in an ornate brass offering bowl, warm saffron-gold tones #F5B851 #D98A22 with soft highlights, gentle shadow beneath bowl. Transparent background, centered composition. 1080x1080 square.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, people, border frame.
```

---

## 40. pladoo.png -- removed (unused in app code, old copy deleted)

**Target:** 256×256 · **Save as:** `assets/images/pladoo.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading. NO text, NO watermark, NO cartoon.

Single large golden-orange ladoo Indian sweet ball centered, warm saffron-gold #F5B851 #D98A22 with soft highlight, transparent background, simple app icon style. 256x256 square.

Avoid: text, logo, cartoon, chibi, 3D, bowl, people, border frame.
```

---

## 41. ondiya.png -- done

**Target:** 1025×1537 · **Save as:** `assets/images/ondiya.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, app puja item quality. NO text, NO watermark, NO cartoon, NO 3D.

Traditional clay diya oil lamp LIT with bright warm golden flame, terracotta clay body #C98A4A #8A5A2B, brass-gold rim #E0A63C, soft warm glow halo around flame. Transparent background, centered vertical composition. 1025x1537 portrait.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, hands, people, border frame.
```

---

## 42. offdiya.png -- removed (unused in app code, old copy deleted)

**Target:** 1025×1537 · **Save as:** `assets/images/offdiya.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading, app puja item quality. NO text, NO watermark, NO cartoon, NO 3D.

Traditional clay diya oil lamp UNLIT — no flame, cotton wick visible in center, terracotta clay body #C98A4A #8A5A2B, brass-gold rim #E0A63C. Transparent background, centered vertical composition. 1025x1537 portrait.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, flame, hands, people, border frame.
```

---

## 43. vitual.png -- removed (unused in app code, old copy deleted)

**Target:** 256×256 · **Save as:** `assets/images/vitual.png` · **Background:** opaque square tile

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art — smooth blended shading. NO text, NO watermark, NO cartoon, NO 3D.

Virtual puja mini scene for app tile: devotee silhouette with joined hands namaste before small home shrine niche, lit diya on altar shelf, warm cream walls #F6EBDA, terracotta accent #C4553A, soft cozy domestic mandir atmosphere. 256x256 square app tile.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, detailed face, border frame.
```

---

## 44. quiz_badge.png -- removed (unused in app code, old copy deleted)

**Target:** 256×256 · **Save as:** `assets/images/quiz_badge.png` · **Background:** opaque

```
DivyaVaani app illustration. Soft devotional app badge icon — smooth shading, slightly flat but polished. NO text, NO watermark, NO cartoon chibi.

Quiz badge icon: rounded square shape filled pink #F7BCD4 with deep terracotta border #7B2A4E, open book with small sacred flame above, decorative dashed cream stitch outline border motif, subtle golden petal ring behind book. 256x256 square.

Avoid: text, question mark letter, logo, cartoon chibi, 3D, photorealistic.
```

---

## 45. japa_badge.png -- done

**Target:** 256×256 · **Save as:** `assets/images/japa_badge.png` · **Background:** opaque

```
DivyaVaani app illustration. Soft devotional app badge icon — smooth shading, slightly flat but polished. NO text, NO watermark, NO cartoon chibi.

Japa badge icon: rounded square shape filled warm gold #FBE3B0 with brown border #8A5A2B, japa mala prayer beads in circle at center, small lotus flower below, decorative dashed cream stitch outline border motif. 256x256 square.

Avoid: text, logo, cartoon chibi, 3D, photorealistic.
```

---

## 46. streak_badge.png -- removed (unused in app code, old copy deleted)

**Target:** 256×256 · **Save as:** `assets/images/streak_badge.png` · **Background:** opaque

```
DivyaVaani app illustration. Soft devotional app badge icon — smooth shading, slightly flat but polished. NO text, NO watermark, NO cartoon chibi.

Streak badge icon: rounded square shape filled peach #F8C9A8 with deep terracotta border #8E2E14, sacred flame at top center, four small day-streak tick boxes below (three filled terracotta, one pale), decorative dashed cream stitch outline border motif. 256x256 square.

Avoid: text, numbers, logo, cartoon chibi, 3D, photorealistic.
```

---

## 47. quiz_bg.jpg -- done

**Target:** 1125×1350 · **Save as:** `assets/images/quiz_bg.jpg` · **Background:** opaque vertical wallpaper

```
DivyaVaani app illustration. Soft traditional Indian decorative background — very low contrast, premium mobile wallpaper. NO text, NO watermark, NO people.

Quiz screen background: warm cream gradient #FDF8F5 to #F1D9B9 top to bottom, large faint golden mandala watermark upper center at 8% opacity, subtle lotus motifs in bottom corners at low opacity, decorative dashed gold stitch line curves, calm devotional atmosphere. Vertical phone wallpaper. 1125x1350.

Avoid: text, logo, people, faces, cartoon, high contrast, busy details.
```

---

## 48. quote_bg.png -- removed (unused in app code, old copy deleted)

**Target:** 480×270 · **Save as:** `assets/images/quote_bg.png` · **Background:** opaque

```
DivyaVaani app illustration. Soft traditional Indian decorative paper texture. NO text, NO watermark, NO people.

Daily quote card background: warm parchment paper #F6E8CC, soft cream blob washes #F3E3C6 #F6E9D2, tiny gold petal accent motifs in corners, subtle linen paper texture feel, very soft and readable under text overlay. 480x270 landscape.

Avoid: text, quote text, logo, people, faces, cartoon, high contrast, border frame.
```

---

## 49. pan.png -- removed (unused in app code, old copy deleted)

**Target:** 128×128 · **Save as:** `assets/images/pan.png` · **Background:** opaque tiny tile

```
DivyaVaani app illustration. Soft devotional app tile — readable at small size. NO text, NO watermark.

Panchang calendar tiny app tile: cream rounded square #F6E4C4, small golden sun with petal rays at top #E8B33C, mini calendar grid of warm pastel colored cells below, simple clean composition readable at 128px. 128x128 square.

Avoid: text, numbers, dates, logo, cartoon, fine details, border frame.
```

---

## 50. logo.png -- removed (unused in app code, old copy deleted)

**Target:** 2048×2048 · **Save as:** `assets/images/logo.png` · **Background:** cream or transparent

```
DivyaVaani app illustration. Original brand logo mark — NOT copying any existing app logo. NO text letters, NO watermark.

DivyaVaani sacred logo mark: abstract combined flame-and-lotus-petal shape in terracotta #A73015 with soft cream shadow, decorative dashed cream stitch line running through the form as signature motif, small gold bindu dot above, clean centered composition on warm cream background #FBEFDD or transparent. Smooth blended shading, premium spiritual app branding. 2048x2048 square.

Avoid: text, letters, IV logo, existing brand logos, cartoon, 3D, photorealistic, watermark.
```

---

## 51. currency.png -- removed (unused in app code, old copy deleted)

**Target:** 257×171 · **Save as:** `assets/images/currency.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art. NO text, NO watermark, NO cartoon.

App reward token "Kamal" icon: pink lotus flower #E0708F #D8567A with small gold center #D4AF37, two antique gold coins stacked behind, warm devotional colors, transparent background, horizontal composition. 257x171.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, border frame.
```

---

## 52. hor.png -- removed (unused in app code, old copy deleted)

**Target:** 128×128 · **Save as:** `assets/images/hor.png` · **Background:** opaque tiny icon

```
DivyaVaani app illustration. Soft devotional icon — readable at small size. NO text, NO watermark.

Hindu zodiac rashi chakra wheel tiny icon: 12 houses in alternating deep indigo blue #4A5A8C and terracotta red #B8452E, gold center dot #D4AF37, cream outer ring #F3E4C6, flat but smoothly shaded, clean and readable at 128px. 128x128 square.

Avoid: text, zodiac English letters, logo, cartoon, fine details, border frame.
```

---

## 53. icon.png -- not required

**Target:** 1024×1024 · **Save as:** `assets/icon/icon.png` · **Background:** opaque app icon

```
DivyaVaani app illustration. Mobile app launcher icon. NO text, NO watermark.

Mobile app icon: warm cream background #FBEFDD, centered terracotta-gold sacred flame-lotus mark #A73015 (same as DivyaVaani logo), faint golden petal ring behind at low opacity, soft subtle shadow, clean professional app store icon. 1024x1024 square.

Avoid: text, letters, logo text, cartoon, 3D glossy, photorealistic, watermark, border.
```

---

## 54. icon_foreground.png -- not required

**Target:** 1024×1024 · **Save as:** `assets/icon/icon_foreground.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Adaptive icon foreground layer only. NO text, NO watermark.

Adaptive Android icon foreground: same terracotta-gold sacred flame-lotus mark as DivyaVaani logo but scaled smaller and centered in middle 66% safe zone, transparent background everywhere outside the mark, no background fill. 1024x1024 square.

Avoid: text, letters, background fill, cartoon, 3D, watermark, border.
```

---

## 55. lotus.png -- not required

**Target:** 1024×1024 · **Save as:** `assets/icon/lotus.png` · **Background:** transparent PNG

```
DivyaVaani app illustration. Soft traditional Indian devotional digital art. NO text, NO watermark, NO cartoon.

Standalone pink lotus flower symbol: rose pink petals #D8567A #E0708F, bright gold center #D4AF37, gentle green stem curve #5F8C6E, soft smooth shading, transparent background, centered devotional symbol. 1024x1024 square.

Avoid: text, logo, cartoon, chibi, 3D, photorealistic, border frame, multiple flowers.
```

---

## Quick checklist after each image

- [ ] Resized to exact target dimensions
- [ ] Saved to correct path and filename
- [ ] Iconography looks correct (hands, arms, attributes)
- [ ] Colors match warm cream / terracotta / gold palette
- [ ] No text or watermark in image
- [ ] Updated `assets/manifest.json` with provenance

**Note:** All 55 assets already exist in `assets/images/` and `assets/icon/` from a prior generation pass. Items #50 logo.png, #51 currency.png, #53 icon.png, #54 icon_foreground.png, #55 lotus.png already use our own approved brand assets — **do not regenerate these**.

**Regeneration scope (standing-pose update):** Only the 12 main deity portraits (#1–12: ganesha, shiva, krishna, ram, hanuman, durga, lakshmi, saraswati, kartikeya, ayyappa, dattatreya, meenakshi) were updated to a standing pose with enhanced skin/face shading. Regenerate only these, then decide separately whether the matching portrait medallions (#13–24, `p*.png`) should be re-cropped from the new standing images or left as-is.

**Suggested order:** `krishna.png` (test style) → remaining 11 standing deities.
