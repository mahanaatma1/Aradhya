#!/usr/bin/env python3
"""Generate DivyaVaani art assets via OpenAI gpt-image-1, reading the key from .env.

Usage:
    python content/tools/gen_deity_image.py pkrishna
    python content/tools/gen_deity_image.py pkrishna bhog ladoo
    python content/tools/gen_deity_image.py --all

Reads OPENAI_API_KEY from .env in the repo root (never pass it on the CLI).
Saves output to reference/generated_review/<name>.<ext> for review before
moving into assets/images/.
"""
import base64
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = ROOT / ".env"
OUT_DIR = ROOT / "reference" / "generated_review"

# name -> (prompt, size, ext, quality)
ITEMS = {
    "pganesha": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Ganesha — head and "
        "shoulders only, elephant head, ornate golden crown, modak sweet near "
        "hand, warm golden-tan skin. Warm burgundy-to-gold radial circle "
        "background #C89A5A to #5B1B22, subtle golden mandala watermark pattern "
        "behind, thin antique gold ring border. Soft smooth shading, centered "
        "face. Designed as circle within 256x256 square.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "extra fingers, distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pshiva": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Shiva — head and "
        "shoulders only, matted jata hair, crescent moon, third eye, trishul "
        "visible, ash-grey-blue skin #CFC6B2. Warm burgundy-to-gold radial circle "
        "background #C89A5A to #5B1B22, subtle golden mandala watermark behind, "
        "thin antique gold ring border. Soft smooth shading, centered face. "
        "256x256 square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pkrishna": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. Flat "
        "hand-painted illustration style like a calendar print, NOT a "
        "photograph. NO cartoon, NO chibi, NO anime, NO 3D, NO photorealism, NO "
        "photographic skin texture or pores, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Krishna — head and "
        "shoulders only, blue-grey divine skin #8CA6C9 (flat painted skin tone, "
        "not realistic human skin), peacock feather in crown, bamboo flute, "
        "saffron cloth hint. Warm burgundy-to-gold radial circle background "
        "#C89A5A to #5B1B22, subtle golden mandala watermark behind, thin "
        "antique gold ring border. Gentle smile. 256x256 square designed as "
        "circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, photorealistic, realistic human face, "
        "photographic skin, full body, text, logo, border frame, distorted "
        "face.",
        "1024x1024", "png", "high",
    ),
    "pram": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Rama — head and "
        "shoulders only, blue-grey divine skin #8CA6C9, ornate golden crown, bow "
        "visible, forest green garment hint, noble calm expression. Warm "
        "burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle "
        "golden mandala watermark behind, thin antique gold ring border. 256x256 "
        "square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "phanuman": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Hanuman — head and "
        "shoulders only, vanara monkey-god face, warm orange skin #E0713F, "
        "devoted strong expression, golden crown hint. Warm burgundy-to-gold "
        "radial circle background #C89A5A to #5B1B22, subtle golden mandala "
        "watermark behind, thin antique gold ring border. 256x256 square "
        "designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pdurga": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Goddess Durga — head and "
        "shoulders only, warm golden skin #F2CFA6, terracotta-red and deep red "
        "garments, ornate golden crown and jewellery, fierce yet benevolent "
        "expression. Warm burgundy-to-gold radial circle background #C89A5A to "
        "#5B1B22, subtle golden mandala watermark behind, thin antique gold ring "
        "border. 256x256 square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "plakshmi": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Goddess Lakshmi — head and "
        "shoulders only, warm golden skin #F2CFA6, rose-pink sari #9C2950, gold "
        "jewellery, lotus flower hint, graceful serene smile. Warm "
        "burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle "
        "golden mandala watermark behind, thin antique gold ring border. 256x256 "
        "square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "psaraswati": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Goddess Saraswati — head and "
        "shoulders only, warm golden skin #F2CFA6, cream-white sari, soft teal "
        "accent #7FD9DC, veena hint, wise peaceful expression. Warm "
        "burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle "
        "golden mandala watermark behind, thin antique gold ring border. 256x256 "
        "square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pkartikeya": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Kartikeya — head and "
        "shoulders only, youthful golden skin #F0C9A0, red sacred cloth, vel "
        "spear hint, ornate golden crown, brave youthful face. Warm "
        "burgundy-to-gold radial circle background #C89A5A to #5B1B22, subtle "
        "golden mandala watermark behind, thin antique gold ring border. 256x256 "
        "square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "payyappa": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Ayyappa — head and "
        "shoulders only, warm tan skin #E0B98F, dark blue garment #2E4A7A, "
        "serene yogi expression, golden crown hint. Warm burgundy-to-gold radial "
        "circle background #C89A5A to #5B1B22, subtle golden mandala watermark "
        "behind, thin antique gold ring border. 256x256 square designed as "
        "circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pdattatreya": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Lord Dattatreya — head and "
        "shoulders only, golden skin #EFCBA4, matted jata hair, saffron robes "
        "#FF9F43, serene ascetic sage expression. Warm burgundy-to-gold radial "
        "circle background #C89A5A to #5B1B22, subtle golden mandala watermark "
        "behind, thin antique gold ring border. 256x256 square designed as "
        "circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pmeenakshi": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, premium Hindu calendar art quality. NO "
        "cartoon, NO chibi, NO anime, NO 3D, NO text, NO watermark.\n\n"
        "Circular avatar medallion portrait bust of Goddess Meenakshi — head and "
        "shoulders only, warm copper-golden skin #D8A87C, forest green sari "
        "#1F6B4F, green parrot hint, ornate golden crown, regal South Indian "
        "devi expression. Warm burgundy-to-gold radial circle background "
        "#C89A5A to #5B1B22, subtle golden mandala watermark behind, thin "
        "antique gold ring border. 256x256 square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, full body, text, logo, border frame, "
        "distorted face.",
        "1024x1024", "png", "medium",
    ),
    "pother": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading. NO cartoon, NO chibi, NO anime, NO 3D, NO "
        "text, NO watermark.\n\n"
        "Circular avatar medallion fallback icon: small Hindu home shrine niche "
        "with generic murti silhouette inside arched alcove, warm cream #FDF8F5 "
        "and terracotta #A73015 tones, diya lamp glow, no specific deity face "
        "visible. Warm burgundy-to-gold radial circle background #C89A5A to "
        "#5B1B22, subtle golden mandala watermark behind, thin antique gold ring "
        "border. 256x256 square designed as circle.\n\n"
        "Avoid: cartoon, chibi, anime, 3D, recognizable celebrity face, text, "
        "logo, border frame.",
        "1024x1024", "png", "medium",
    ),
    "aartis": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, gentle watercolor-like gradients. NO "
        "text, NO title, NO watermark, NO cartoon, NO 3D.\n\n"
        "Aartis devotional cover illustration. Devotee hands cupping a brass "
        "aarti thali plate with three ghee flames burning brightly, ornate "
        "temple bells hanging above, warm golden radial glow background #FDF2DE "
        "to #E9CFA4, evening ghat devotional mood without photorealism. Soft "
        "spiritual light, no text, no border. 417x312.\n\n"
        "Avoid: text, title, logo, cartoon, chibi, anime, 3D, photorealistic, "
        "border frame, full face visible.",
        "1024x1024", "jpg", "medium",
    ),
    "mantras": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, gentle watercolor-like gradients. NO "
        "text, NO title, NO watermark, NO cartoon, NO 3D.\n\n"
        "Mantras meditation cover illustration. Japa mala prayer beads arranged "
        "in a circle at center, soft concentric sound ripple rings radiating "
        "outward, small lotus at bottom, warm cream radial background #FDF6E8 "
        "to #EBD6B4, meditative calm atmosphere. No text, no Om symbol, no "
        "border. 448x434 square-ish.\n\n"
        "Avoid: text, title, logo, Om symbol, cartoon, chibi, anime, 3D, border "
        "frame.",
        "1024x1024", "jpg", "medium",
    ),
    "bhog": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, app puja item quality. NO text, NO "
        "watermark, NO cartoon, NO 3D.\n\n"
        "Puja bhog fruit offering illustration. Ornate brass bowl katora filled "
        "with fresh fruits — red apple, green banana, orange — plus one golden "
        "modak sweet on top, small green leaf garnish. Soft shadow beneath bowl. "
        "Transparent background, centered vertical composition, warm golden "
        "lighting. 1025x1537 portrait.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, hands, people, "
        "border frame.",
        "1024x1536", "png", "medium",
    ),
    "ladoo": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, app puja item quality. NO text, NO "
        "watermark, NO cartoon, NO 3D.\n\n"
        "Three golden-orange ladoos Indian sweet balls stacked in an ornate "
        "brass offering bowl, warm saffron-gold tones #F5B851 #D98A22 with soft "
        "highlights, gentle shadow beneath bowl. Transparent background, "
        "centered composition. 1080x1080 square.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, people, border "
        "frame.",
        "1024x1024", "png", "medium",
    ),
    "pladoo": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading. NO text, NO watermark, NO cartoon.\n\n"
        "Single large golden-orange ladoo Indian sweet ball centered, warm "
        "saffron-gold #F5B851 #D98A22 with soft highlight, transparent "
        "background, simple app icon style. 256x256 square.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, bowl, people, border frame.",
        "1024x1024", "png", "medium",
    ),
    "ondiya": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, app puja item quality. NO text, NO "
        "watermark, NO cartoon, NO 3D.\n\n"
        "Traditional clay diya oil lamp LIT with bright warm golden flame, "
        "terracotta clay body #C98A4A #8A5A2B, brass-gold rim #E0A63C, soft warm "
        "glow halo around flame. Transparent background, centered vertical "
        "composition. 1025x1537 portrait.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, hands, people, "
        "border frame.",
        "1024x1536", "png", "medium",
    ),
    "offdiya": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading, app puja item quality. NO text, NO "
        "watermark, NO cartoon, NO 3D.\n\n"
        "Traditional clay diya oil lamp UNLIT — no flame, cotton wick visible in "
        "center, terracotta clay body #C98A4A #8A5A2B, brass-gold rim #E0A63C. "
        "Transparent background, centered vertical composition. 1025x1537 "
        "portrait.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, flame, hands, "
        "people, border frame.",
        "1024x1536", "png", "medium",
    ),
    "vitual": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art — smooth blended shading. NO text, NO watermark, NO cartoon, NO "
        "3D.\n\n"
        "Virtual puja mini scene for app tile: devotee silhouette with joined "
        "hands namaste before small home shrine niche, lit diya on altar shelf, "
        "warm cream walls #F6EBDA, terracotta accent #C4553A, soft cozy domestic "
        "mandir atmosphere. 256x256 square app tile.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, detailed face, "
        "border frame.",
        "1024x1024", "png", "medium",
    ),
    "quiz_badge": (
        "DivyaVaani app illustration. Soft devotional app badge icon — smooth "
        "shading, slightly flat but polished. NO text, NO watermark, NO cartoon "
        "chibi.\n\n"
        "Quiz badge icon: rounded square shape filled pink #F7BCD4 with deep "
        "terracotta border #7B2A4E, open book with small sacred flame above, "
        "decorative dashed cream stitch outline border motif, subtle golden "
        "petal ring behind book. 256x256 square.\n\n"
        "Avoid: text, question mark letter, logo, cartoon chibi, 3D, "
        "photorealistic.",
        "1024x1024", "png", "medium",
    ),
    "japa_badge": (
        "DivyaVaani app illustration. Soft devotional app badge icon — smooth "
        "shading, slightly flat but polished. NO text, NO watermark, NO cartoon "
        "chibi.\n\n"
        "Japa badge icon: rounded square shape filled warm gold #FBE3B0 with "
        "brown border #8A5A2B, japa mala prayer beads in circle at center, small "
        "lotus flower below, decorative dashed cream stitch outline border "
        "motif. 256x256 square.\n\n"
        "Avoid: text, logo, cartoon chibi, 3D, photorealistic.",
        "1024x1024", "png", "medium",
    ),
    "streak_badge": (
        "DivyaVaani app illustration. Soft devotional app badge icon — smooth "
        "shading, slightly flat but polished. NO text, NO watermark, NO cartoon "
        "chibi.\n\n"
        "Streak badge icon: rounded square shape filled peach #F8C9A8 with deep "
        "terracotta border #8E2E14, sacred flame at top center, four small "
        "day-streak tick boxes below (three filled terracotta, one pale), "
        "decorative dashed cream stitch outline border motif. 256x256 "
        "square.\n\n"
        "Avoid: text, numbers, logo, cartoon chibi, 3D, photorealistic.",
        "1024x1024", "png", "medium",
    ),
    "pan": (
        "DivyaVaani app illustration. Soft devotional app tile — readable at "
        "small size. NO text, NO watermark.\n\n"
        "Panchang calendar tiny app tile: cream rounded square #F6E4C4, small "
        "golden sun with petal rays at top #E8B33C, mini calendar grid of warm "
        "pastel colored cells below, simple clean composition readable at "
        "128px. 128x128 square.\n\n"
        "Avoid: text, numbers, dates, logo, cartoon, fine details, border "
        "frame.",
        "1024x1024", "png", "medium",
    ),
    "currency": (
        "DivyaVaani app illustration. Soft traditional Indian devotional digital "
        "art. NO text, NO watermark, NO cartoon.\n\n"
        "App reward token \"Kamal\" icon: pink lotus flower #E0708F #D8567A with "
        "small gold center #D4AF37, two antique gold coins stacked behind, warm "
        "devotional colors, transparent background, horizontal composition. "
        "257x171.\n\n"
        "Avoid: text, logo, cartoon, chibi, 3D, photorealistic, border frame.",
        "1024x1024", "png", "medium",
    ),
    "hor": (
        "DivyaVaani app illustration. Soft devotional icon — readable at small "
        "size. NO text, NO watermark.\n\n"
        "Hindu zodiac rashi chakra wheel tiny icon: 12 houses in alternating "
        "deep indigo blue #4A5A8C and terracotta red #B8452E, gold center dot "
        "#D4AF37, cream outer ring #F3E4C6, flat but smoothly shaded, clean and "
        "readable at 128px. 128x128 square.\n\n"
        "Avoid: text, zodiac English letters, logo, cartoon, fine details, "
        "border frame.",
        "1024x1024", "png", "medium",
    ),
}


def load_api_key() -> str:
    if not ENV_FILE.exists():
        sys.exit(f"Missing {ENV_FILE}. Copy .env.example to .env and add your key.")
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if line.startswith("OPENAI_API_KEY="):
            key = line.split("=", 1)[1].strip()
            if key:
                return key
    sys.exit("OPENAI_API_KEY not set in .env")


def generate_one(client, name: str) -> None:
    prompt, size, ext, quality = ITEMS[name]
    print(f"Generating {name}.{ext} ({quality} quality, {size})...")
    kwargs = {"model": "gpt-image-1", "prompt": prompt, "size": size, "quality": quality, "n": 1}
    if ext == "png":
        kwargs["background"] = "transparent"
    result = client.images.generate(**kwargs)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / f"{name}.{ext}"
    image_bytes = base64.b64decode(result.data[0].b64_json)
    out_path.write_bytes(image_bytes)
    print(f"Saved: {out_path}")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(f"Usage: python {sys.argv[0]} <name> [<name> ...] | --all")

    names = list(ITEMS.keys()) if sys.argv[1] == "--all" else sys.argv[1:]
    unknown = [n for n in names if n not in ITEMS]
    if unknown:
        sys.exit(f"Unknown item(s): {unknown}\nAvailable: {list(ITEMS.keys())}")

    try:
        from openai import OpenAI
    except ImportError:
        sys.exit("Run: pip install openai")

    client = OpenAI(api_key=load_api_key())
    for name in names:
        generate_one(client, name)


if __name__ == "__main__":
    main()
