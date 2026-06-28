# Agent Notes

## Booster Pack Image Workflow

Use this process when generating missing `assets/packs/*-pack.png` textures.

For bulk placeholder-compatible textures, prefer:

```bash
'/mnt/c/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/generate-pack-assets.py
```

That script generates `542 x 958` transparent PNGs, applies the real local logo mark, and preserves the hand-tuned generated packs listed in its `PRESERVE` set. Use the manual `image_gen` flow below when a pack needs a better set-specific art pass.

1. Generate one image per set with the built-in `image_gen` tool.
   - Use a tall sealed foil booster wrapper prompt.
   - Required format: full wrapper, crimped top/bottom, vertical side seams, pack reaches image edges.
   - Include set-specific fantasy theme and readable set text.
   - Avoid official logos, mana symbols, copyrighted characters, Magic branding, and watermarks.
   - Ask for a perfectly flat solid `#00ff00` chroma-key background outside the pack only.

2. Prompt template:

```text
A tall vertical trading-card booster pack wrapper texture for CODE Set Name, full front sealed foil booster pack, aspect ratio 542:958.
Full wrapper from crimped top to bottom, vertical side seams, realistic foil wrinkles, pack reaches edges.
Theme: <set-specific visual theme>.
Text verbatim: "SET NAME" and "BOOSTER PACK" or "PLAY BOOSTER", small "15 CARDS" top left and "13+" top right.
Perfectly flat solid #00ff00 chroma-key background outside the pack only.
No official logos, no mana symbols, no copyrighted characters, no Magic: The Gathering branding, no watermark.
```

3. Save generated output into `assets/packs/<lowercase-code>-pack.png`.
   - Leave the original generated image in `.codex/generated_images`.
   - Existing texture convention is exactly `542 x 958`, `RGBA`.
   - Use lowercase set code filenames, for example `dom-pack.png`, `war-pack.png`, `fdn-pack.png`.

4. Post-process each generated file:
   - Remove the solid green background connected to the image edges.
   - Crop to the pack alpha bounds.
   - Resize back to `542 x 958`.
   - Save as optimized PNG with alpha.
   - Add a centered top `Magic: The Gathering` logo mark from `assets/logos/magic-the-gathering-2017-thumb.png`, matching the real logo shape used by the existing modern pack textures.
   - Do not fake the logo with typed serif text; it looks wrong.
   - Place the logo below the `14/15 CARDS` row, roughly in the upper art field like `spm-pack.png`.
   - Use a smaller width around `270px` on the `542px` texture, with top around `y=90`; adjust only when it collides with generated set-title art.
   - Choose white or dark logo color based on the art behind the mark, with a small contrasting halo/shadow for readability.

Example conversion command, after setting `latest` to the generated PNG path:

```bash
latest_win=$(wslpath -w "$latest")
'/mnt/c/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' - "$latest_win" assets/packs/dom-pack.png <<'PY'
import sys
from PIL import Image
from collections import deque

src, out = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGBA")
w, h = img.size
pix = img.load()
q = deque()
seen = set()

for x in range(w):
    q.append((x, 0))
    q.append((x, h - 1))
for y in range(h):
    q.append((0, y))
    q.append((w - 1, y))

def is_bg(x, y):
    r, g, b, a = pix[x, y]
    return a and g > 185 and r < 100 and b < 130

while q:
    x, y = q.popleft()
    if x < 0 or y < 0 or x >= w or y >= h or (x, y) in seen:
        continue
    seen.add((x, y))
    if not is_bg(x, y):
        continue
    pix[x, y] = (0, 255, 0, 0)
    q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

bbox = img.getchannel("A").getbbox()
if bbox:
    img = img.crop(bbox)
img = img.resize((542, 958), Image.Resampling.LANCZOS)
img.save(out, optimize=True)
PY
```

5. Validate outputs:

```bash
'/mnt/c/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' - <<'PY'
from PIL import Image
from pathlib import Path

for p in sorted(Path("assets/packs").glob("*-pack.png")):
    img = Image.open(p).convert("RGBA")
    alpha = img.getchannel("A")
    transparent = sum(1 for v in alpha.getdata() if v == 0)
    print(p.name, img.size, "bbox=", alpha.getbbox(), "transparent=", transparent)
PY
```

Expected:
   - Size is `(542, 958)`.
   - Mode is `RGBA`.
   - The pack fills the image bounds.
   - There are transparent pixels outside the wrapper.

6. Do not update `src/set_definitions.lua` with local file paths.
   - Pack images should be committed under `assets/packs`.
   - Use GitHub raw URLs via the `packImage()` helper in `src/set_definitions.lua`.
   - The URLs only work for users after the generated assets have been pushed to the GitHub default branch.

7. Rebuild Lua only when set definitions or script behavior changes:

```bash
'/mnt/c/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' tools/build-lua-bundle.js
```

Do not update `backup/Saves/TS_Save_mtg_booster_generator.json` or `backup/Mods/Workshop/3558729769.json` unless the user explicitly asks.

Logo source:
- Wikimedia Commons: `File:Magic_the_Gathering_2017.svg`
- Original SVG URL: `https://upload.wikimedia.org/wikipedia/commons/a/ad/Magic_the_Gathering_2017.svg`
- Rendered thumbnail used locally: `https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Magic_the_Gathering_2017.svg/1280px-Magic_the_Gathering_2017.svg.png`
