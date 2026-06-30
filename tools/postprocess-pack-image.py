from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
LOGO_PATH = ROOT / "assets" / "logos" / "magic-the-gathering-2017-thumb.png"
SIZE = (542, 958)


def find_edge_alpha(alpha: Image.Image) -> set[tuple[int, int]]:
    w, h = alpha.size
    pix = alpha.load()
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(w):
        if pix[x, 0] < 255:
            q.append((x, 0))
        if pix[x, h - 1] < 255:
            q.append((x, h - 1))
    for y in range(h):
        if pix[0, y] < 255:
            q.append((0, y))
        if pix[w - 1, y] < 255:
            q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or (x, y) in seen:
            continue
        if pix[x, y] >= 255:
            continue
        seen.add((x, y))
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    return seen


def remove_green_background(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
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

    def is_key(x: int, y: int) -> bool:
        r, g, b, a = pix[x, y]
        return a > 0 and g > 165 and r < 145 and b < 145 and g > r * 1.25 and g > b * 1.25

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or (x, y) in seen:
            continue
        seen.add((x, y))
        if not is_key(x, y):
            continue
        pix[x, y] = (0, 255, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    bbox = img.getchannel("A").getbbox()
    if bbox:
        img = img.crop(bbox)
    img = img.resize(SIZE, Image.Resampling.LANCZOS)

    pix = img.load()
    alpha = img.getchannel("A")
    edge_alpha = find_edge_alpha(alpha)
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue
            if (x, y) in edge_alpha and g > 115 and g > r * 1.3 and g > b * 1.3:
                pix[x, y] = (r, g, b, 0)
            elif g > r + 35 and g > b + 35:
                pix[x, y] = (r, max(r, b, int((r + b) / 2)), b, a)
    return img


def logo_mask(width: int, vertical: bool) -> Image.Image:
    logo = Image.open(LOGO_PATH).convert("RGBA")
    logo = logo.crop(logo.getchannel("A").getbbox())
    alpha = logo.getchannel("A")
    height = round(width * logo.height / logo.width)
    alpha = alpha.resize((width, height), Image.Resampling.LANCZOS)
    mask = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    mask.putalpha(alpha)
    if vertical:
        mask = mask.rotate(90, expand=True, resample=Image.Resampling.BICUBIC)
    return mask


def tint(mask: Image.Image, fill: tuple[int, int, int, int]) -> Image.Image:
    alpha = mask.getchannel("A")
    mark = Image.new("RGBA", mask.size, fill)
    mark.putalpha(alpha)
    return mark


def add_logo(img: Image.Image, x: int, y: int, width: int, color: str, vertical: bool) -> Image.Image:
    colors = {
        "white": (245, 242, 232, 232),
        "black": (18, 18, 20, 232),
        "gold": (226, 202, 145, 226),
        "silver": (218, 222, 224, 226),
    }
    fill = colors[color]
    shadow_fill = (0, 0, 0, 145) if color != "black" else (255, 255, 245, 95)
    mask = logo_mask(width, vertical)
    shadow = tint(mask, shadow_fill).filter(ImageFilter.GaussianBlur(1.0))
    mark = tint(mask, fill)
    img.alpha_composite(shadow, (x + 2, y + 2))
    img.alpha_composite(mark, (x, y))
    return img


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--logo-x", type=int, default=150)
    parser.add_argument("--logo-y", type=int, default=90)
    parser.add_argument("--logo-width", type=int, default=220)
    parser.add_argument("--logo-color", choices=("white", "black", "gold", "silver"), default="white")
    parser.add_argument("--vertical-logo", action="store_true")
    args = parser.parse_args()

    img = remove_green_background(Image.open(args.input))
    img = add_logo(img, args.logo_x, args.logo_y, args.logo_width, args.logo_color, args.vertical_logo)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    img.save(args.output, optimize=True)
    print(args.output)


if __name__ == "__main__":
    main()
