from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


OUT_DIR = Path("assets/packs")
LOGO_PATH = Path("assets/logos/magic-the-gathering-2017-thumb.png")
SIZE = (542, 958)


PACKS = {
    "---": ("BOOSTER", "GENERATOR", ("#d9d9d9", "#fafafa", "#8a8a8a")),
    "TLA": ("AVATAR", "PLAY BOOSTER", ("#54a6dd", "#f37035", "#f7d358")),
    "TLAC": ("AVATAR COLLECTOR", "COLLECTOR BOOSTER", ("#8e3d2f", "#d8a15d", "#f7ead0")),
    "SPM": ("SPIDER-MAN", "PLAY BOOSTER", ("#103f82", "#c8232c", "#2a78b8")),
    "SPMC": ("SPIDER-MAN COLLECTOR", "COLLECTOR BOOSTER", ("#ffffff", "#e5252f", "#f0d64e")),
    "FIN": ("FINAL FANTASY", "PLAY BOOSTER", ("#f7f7f7", "#7fc4e8", "#342f87")),
    "FINC": ("FINAL FANTASY COLLECTOR", "COLLECTOR BOOSTER", ("#f7f7f7", "#111111", "#d7d7d7")),
    "BOK": ("BETRAYERS OF KAMIGAWA", "BOOSTER PACK", ("#21325f", "#c43c3c", "#d6c392")),
    "CHK": ("CHAMPIONS OF KAMIGAWA", "BOOSTER PACK", ("#1f2b45", "#e0c56d", "#9b2b2b")),
    "INR": ("INNISTRAD REMASTERED", "PLAY BOOSTER", ("#1c2434", "#b7c4d8", "#5a2b72")),
    "DFT": ("AETHERDRIFT", "PLAY BOOSTER", ("#f05a28", "#2f9fd8", "#f6d04d")),
    "EOE": ("EDGE OF ETERNITIES", "PLAY BOOSTER", ("#151a4d", "#48d8ff", "#e84bc6")),
    "TDM": ("TARKIR DRAGONSTORM", "PLAY BOOSTER", ("#c53d2f", "#f2b84b", "#3a5f9f")),
    "FDN": ("FOUNDATIONS", "PLAY BOOSTER", ("#f7f7f7", "#1d3c78", "#d9b66f")),
    "DSK": ("DUSKMOURN", "PLAY BOOSTER", ("#15151d", "#d8d8d8", "#8b2d4f")),
    "BLB": ("BLOOMBURROW", "PLAY BOOSTER", ("#64b96a", "#f2d476", "#77a9df")),
    "MH3": ("MODERN HORIZONS III", "PLAY BOOSTER", ("#6e38bf", "#f46a2f", "#38c7d8")),
    "MKM": ("MURDERS AT KARLOV MANOR", "PLAY BOOSTER", ("#253a5a", "#b09a6a", "#8a1d2c")),
    "OTJ": ("OUTLAWS OF THUNDER JUNCTION", "PLAY BOOSTER", ("#9d5630", "#e3b15c", "#3f6f8f")),
    "RVR": ("RAVNICA REMASTERED", "DRAFT BOOSTER", ("#d7c79b", "#1e2a46", "#7b2d8f")),
    "XLN": ("IXALAN", "BOOSTER PACK", ("#138a72", "#f0c45b", "#b0342f")),
    "MID": ("MIDNIGHT HUNT", "BOOSTER PACK", ("#1b2a3c", "#d1d5dd", "#4c6f91")),
    "STX": ("STRIXHAVEN", "BOOSTER PACK", ("#4d254f", "#d8b25b", "#263d73")),
    "AFR": ("FORGOTTEN REALMS", "BOOSTER PACK", ("#7a2e24", "#d7aa52", "#334875")),
    "CMB1": ("MYSTERY BOOSTER", "PLAYTEST CARDS", ("#f2f2f2", "#111111", "#e83b32")),
    "UST": ("UNSTABLE", "BOOSTER PACK", ("#d9d9d9", "#202020", "#e33b3b")),
    "UGL": ("UNGLUED", "BOOSTER PACK", ("#f2e8c9", "#cc4a2f", "#3673bd")),
    "UNH": ("UNHINGED", "BOOSTER PACK", ("#d8f2e4", "#6b3ca0", "#f0b34d")),
    "VOW": ("CRIMSON VOW", "BOOSTER PACK", ("#2b1421", "#c0364a", "#d8c3aa")),
    "UMA": ("ULTIMATE MASTERS", "BOOSTER PACK", ("#1f1b38", "#e3cf83", "#8a69c7")),
    "CMM": ("COMMANDER MASTERS", "BOOSTER PACK", ("#292131", "#d6b56d", "#6c90d8")),
    "MMA": ("MODERN MASTERS", "BOOSTER PACK", ("#28334e", "#d8d8d8", "#c54444")),
    "SOK": ("SAVIORS OF KAMIGAWA", "BOOSTER PACK", ("#efe0ba", "#ab2d2d", "#2c4f7a")),
    "NEO": ("NEON DYNASTY", "BOOSTER PACK", ("#151729", "#e342b8", "#26d7e8")),
    "KHM": ("KALDHEIM", "BOOSTER PACK", ("#233957", "#d9eef7", "#8b5b2e")),
    "LEA": ("LIMITED EDITION ALPHA", "BOOSTER PACK", ("#efe0bd", "#8c5b32", "#2f5d8c")),
    "2XM": ("DOUBLE MASTERS", "BOOSTER PACK", ("#222222", "#d7d7d7", "#d7a33f")),
    "DOM": ("DOMINARIA", "PLAY BOOSTER", ("#e0c779", "#486c9b", "#f8f5d8")),
    "WAR": ("WAR OF THE SPARK", "PLAY BOOSTER", ("#1f255a", "#f0b64c", "#9d55d4")),
    "ZNR": ("ZENDIKAR RISING", "PLAY BOOSTER", ("#1d8a86", "#d8c262", "#4b78b8")),
    "CNS": ("CONSPIRACY", "BOOSTER PACK", ("#171513", "#c49a49", "#78231f")),
    "CN2": ("TAKE THE CROWN", "BOOSTER PACK", ("#271313", "#c59a42", "#9d2222")),
    "ISD": ("INNISTRAD", "BOOSTER PACK", ("#14243a", "#d5dbe8", "#46506c")),
    "DKA": ("DARK ASCENSION", "BOOSTER PACK", ("#1c152b", "#9d7ac4", "#d6d1de")),
    "SOI": ("SHADOWS OVER INNISTRAD", "BOOSTER PACK", ("#162936", "#d9dce4", "#a87445")),
    "EMN": ("ELDRITCH MOON", "BOOSTER PACK", ("#24152f", "#c99de8", "#cfd0d6")),
    "ICE": ("ICE AGE", "BOOSTER PACK", ("#1e5d8f", "#d9f3ff", "#5b8fb5")),
    "ALL": ("ALLIANCES", "BOOSTER PACK", ("#253c56", "#d8e5ee", "#9b2c2c")),
    "CSP": ("COLDSNAP", "BOOSTER PACK", ("#114f86", "#d8f1ff", "#6eaad1")),
    "MH1": ("MODERN HORIZONS", "BOOSTER PACK", ("#251d4f", "#f08a3e", "#d450b8")),
    "ECL": ("LORWYN ECLIPSED", "PLAY BOOSTER", ("#2d1738", "#e0b85f", "#65a66f")),
    "TMT": ("TURTLE NINJA TEAM", "PLAY BOOSTER", ("#1d6f4d", "#7cc44a", "#2d2d38")),
    "SOS": ("SECRETS OF STRIXHAVEN", "PLAY BOOSTER", ("#34205d", "#d8b96b", "#4f75c7")),
    "MSH": ("MARVEL SUPER HEROES", "PLAY BOOSTER", ("#1d3f8f", "#d13232", "#f0d24d")),
    "HOB": ("THE HOBBIT", "PLAY BOOSTER", ("#36582d", "#c89d54", "#e8ddbd")),
    "FRA": ("REALITY FRACTURE", "PLAY BOOSTER", ("#18284f", "#4dd7e8", "#f04db6")),
    "TRK": ("STAR TREK", "PLAY BOOSTER", ("#0c1738", "#f0c24c", "#57a4d8")),
    "OM1": ("THROUGH THE OMENPATHS", "BOOSTER PACK", ("#5d2b83", "#e48a43", "#3bc5c3")),
    "PIO": ("PIONEER MASTERS", "BOOSTER PACK", ("#1d2d44", "#e2c36f", "#b04a3b")),
    "J25": ("FOUNDATIONS JUMPSTART", "JUMPSTART BOOSTER", ("#f6f6f6", "#375bb0", "#dbb85d")),
    "MB2": ("MYSTERY BOOSTER 2", "BOOSTER PACK", ("#eeeeee", "#111111", "#e23b35")),
    "ACR": ("ASSASSIN'S CREED", "BEYOND BOOSTER", ("#f2f2f2", "#9d1f25", "#222222")),
    "CLU": ("RAVNICA CLUE EDITION", "BOOSTER PACK", ("#2e2f42", "#d6b56d", "#7c2c2c")),
    "BIG": ("THE BIG SCORE", "BONUS BOOSTER", ("#51331d", "#e0b152", "#38a2b8")),
}

PRESERVE = {
    "DOM", "WAR", "ZNR", "MH1", "ISD", "DKA", "SOI", "EMN", "CNS", "CN2", "ICE", "ALL", "CSP", "FDN"
}


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def interp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))


def load_logo() -> Image.Image:
    logo = Image.open(LOGO_PATH).convert("RGBA")
    return logo.crop(logo.getchannel("A").getbbox())


def logo_mark(width: int, fill: tuple[int, int, int, int]) -> Image.Image:
    logo = load_logo()
    alpha = logo.getchannel("A")
    height = round(width * logo.height / logo.width)
    alpha = alpha.resize((width, height), Image.Resampling.LANCZOS)
    mark = Image.new("RGBA", (width, height), fill)
    mark.putalpha(alpha)
    return mark


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int, font: ImageFont.FreeTypeFont, fill, stroke=0):
    bbox = draw.textbbox((0, 0), text, font=font, stroke_width=stroke)
    x = (SIZE[0] - (bbox[2] - bbox[0])) // 2
    draw.text((x, y), text, font=font, fill=fill, stroke_width=stroke, stroke_fill=(0, 0, 0, 180))


def make_pack(code: str, title: str, subtitle: str, colors: tuple[str, str, str], variant: int = 0):
    random.seed(f"{code}-{variant}")
    c1, c2, c3 = map(hex_to_rgb, colors)
    w, h = SIZE
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Wrapper body reaches edges with transparent notches at corners.
    body = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    bp = body.load()
    for y in range(h):
        t = y / (h - 1)
        base = interp(c2, c1, abs(t - 0.5) * 1.7)
        for x in range(w):
            edge = min(x, w - 1 - x) / 72
            shade = max(0.28, min(1.0, edge))
            ripple = 0.06 * math.sin((x + y * 0.35) / 18) + 0.04 * math.sin((x * 0.7 - y) / 31)
            val = max(0.15, min(1.15, shade + ripple))
            bp[x, y] = (round(base[0] * val), round(base[1] * val), round(base[2] * val), 255)
    img.alpha_composite(body)

    # Transparent corner bevels.
    mask = Image.new("L", SIZE, 255)
    md = ImageDraw.Draw(mask)
    r = 18
    md.polygon([(0, 0), (r, 0), (0, r)], fill=0)
    md.polygon([(w, 0), (w - r, 0), (w, r)], fill=0)
    md.polygon([(0, h), (0, h - r), (r, h)], fill=0)
    md.polygon([(w, h), (w - r, h), (w, h - r)], fill=0)
    img.putalpha(mask)
    draw = ImageDraw.Draw(img)

    # Crimped foil bands and side seams.
    top_h, bottom_h = 86, 86
    for y0, y1 in [(0, top_h), (h - bottom_h, h)]:
        draw.rectangle((0, y0, w, y1), fill=(*interp(c1, (10, 10, 18), 0.55), 245))
        for x in range(0, w, 8):
            shade = 70 + (x % 24) * 5
            draw.rounded_rectangle((x, y0 + 8, x + 5, y1 - 8), radius=3, fill=(shade, shade, shade + 10, 90))
    for x0, x1 in [(0, 44), (w - 44, w)]:
        draw.rectangle((x0, 0, x1, h), fill=(*interp(c1, (5, 8, 18), 0.62), 210))
        for y in range(88, h - 88, 78):
            draw.rounded_rectangle((x0 + 8, y, x1 - 8, y + 18), radius=5, outline=(255, 255, 255, 55), width=1)

    # Art panel.
    panel = Image.new("RGBA", (w - 86, 570), (0, 0, 0, 0))
    pd = ImageDraw.Draw(panel)
    for i in range(34):
        x = random.randint(0, panel.width)
        y = random.randint(0, panel.height)
        rr = random.randint(45, 165)
        col = (*interp(c2, c3, random.random()), random.randint(35, 95))
        pd.ellipse((x - rr, y - rr, x + rr, y + rr), fill=col)
    cx, cy = panel.width // 2, 260
    for i in range(10):
        angle = i * math.pi * 2 / 10 + variant * 0.15
        x = cx + math.cos(angle) * random.randint(80, 185)
        y = cy + math.sin(angle) * random.randint(70, 190)
        pd.line((cx, cy, x, y), fill=(*c3, 105), width=random.randint(2, 5))
    pd.polygon([(cx, 115), (cx + 78, 295), (cx, 430), (cx - 78, 295)], fill=(*interp(c1, c3, 0.45), 210), outline=(255, 255, 255, 160))
    pd.polygon([(cx, 155), (cx + 38, 295), (cx, 378), (cx - 38, 295)], fill=(255, 255, 255, 120), outline=(*c3, 190))
    panel = panel.filter(ImageFilter.GaussianBlur(0.25))
    img.alpha_composite(panel, (43, 128))
    draw = ImageDraw.Draw(img)

    # Header text.
    try:
        sans_bold = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 22)
        title_font = ImageFont.truetype(r"C:\Windows\Fonts\georgiab.ttf", 46)
        title_small = ImageFont.truetype(r"C:\Windows\Fonts\georgiab.ttf", 34)
        subtitle_font = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 22)
    except OSError:
        sans_bold = ImageFont.load_default()
        title_font = ImageFont.load_default()
        title_small = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    draw.text((57, 104), "14 CARDS" if subtitle in {"PLAY BOOSTER", "JUMPSTART BOOSTER", "BEYOND BOOSTER"} else "15 CARDS", font=sans_bold, fill=(255, 255, 255, 235), stroke_width=1, stroke_fill=(0, 0, 0, 160))
    draw.ellipse((468, 96, 520, 148), fill=(255, 255, 255, 235))
    draw.text((480, 109), "13+", font=sans_bold, fill=(18, 24, 38, 255))

    # Real logo.
    logo_w = 270
    logo_y = 92
    mark = logo_mark(logo_w, (255, 255, 250, 245))
    shadow = logo_mark(logo_w, (0, 0, 0, 180)).filter(ImageFilter.GaussianBlur(1.0))
    lx = (w - logo_w) // 2
    img.alpha_composite(shadow, (lx + 2, logo_y + 2))
    img.alpha_composite(mark, (lx, logo_y))
    draw = ImageDraw.Draw(img)

    # Set title plate.
    plate_y = 695
    draw.rounded_rectangle((38, plate_y - 18, w - 38, 852), radius=10, fill=(0, 0, 0, 100))
    font = title_small if len(title) > 16 else title_font
    lines = title.split(" ")
    if len(title) > 21 and len(lines) > 1:
        mid = len(lines) // 2
        first = " ".join(lines[:mid])
        second = " ".join(lines[mid:])
        draw_centered(draw, first, plate_y, font, (255, 255, 245, 255), 1)
        draw_centered(draw, second, plate_y + 44, font, (255, 255, 245, 255), 1)
        sub_y = plate_y + 98
    else:
        draw_centered(draw, title, plate_y + 20, font, (255, 255, 245, 255), 1)
        sub_y = plate_y + 82
    draw_centered(draw, subtitle, sub_y, subtitle_font, (*c3, 255), 1)

    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for code, spec in PACKS.items():
        if code in PRESERVE:
            continue
        title, subtitle, colors = spec
        variants = 3 if code == "UST" else 1
        for variant in range(variants):
            suffix = f"-{variant + 1}" if variants > 1 else ""
            if code == "---":
                out = OUT_DIR / "---_pack.png"
            else:
                out = OUT_DIR / f"{code.lower()}-pack{suffix}.png"
            make_pack(code, title, subtitle, colors, variant).save(out, optimize=True)
            print(out)


if __name__ == "__main__":
    main()
