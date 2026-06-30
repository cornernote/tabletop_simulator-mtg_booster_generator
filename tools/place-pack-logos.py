from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PACK_DIR = ROOT / "assets" / "packs"
LOGO_PATH = ROOT / "assets" / "logos" / "magic-the-gathering-2017-thumb.png"
GENERATOR_PATH = ROOT / "tools" / "generate-pack-assets.py"

HAND_TUNED = {
    "----",
    "---_",
    "ALL",
    "CN2",
    "CNS",
    "CSP",
    "CUSTOM",
    "DKA",
    "DOM",
    "EMN",
    "FDN",
    "ICE",
    "ISD",
    "MH1",
    "SOI",
    "TLA",
    "WAR",
    "ZNR",
}

LOGO_LAYOUTS = [
    ("top_left", 62, 95, 205, "auto"),
    ("top_center", 166, 88, 210, "auto"),
    ("top_right", 278, 95, 198, "auto"),
    ("upper_left", 58, 176, 190, "auto"),
    ("upper_right", 292, 176, 185, "auto"),
    ("vertical_left", 38, 232, 170, "auto"),
    ("vertical_right", 446, 232, 170, "auto"),
]

PREFERRED_LAYOUT = {
    "2XM": "top_right",
    "ACR": "upper_left",
    "AFR": "top_center",
    "BIG": "upper_right",
    "BLB": "top_right",
    "BOK": "upper_left",
    "CHK": "top_center",
    "CLU": "top_left",
    "CMB1": "upper_right",
    "CMM": "top_right",
    "DFT": "top_left",
    "DSK": "upper_right",
    "ECL": "top_center",
    "EOE": "top_left",
    "FIN": "top_right",
    "FINC": "upper_left",
    "FRA": "top_center",
    "HOB": "upper_right",
    "INR": "top_left",
    "J25": "vertical_left",
    "KHM": "top_right",
    "LEA": "upper_left",
    "MB2": "top_center",
    "MH3": "top_left",
    "MID": "top_right",
    "MKM": "upper_left",
    "MMA": "top_center",
    "MSH": "top_right",
    "NEO": "upper_right",
    "OM1": "top_left",
    "OTJ": "upper_right",
    "PIO": "top_center",
    "RVR": "upper_left",
    "SOK": "top_right",
    "SOS": "top_left",
    "SPM": "top_center",
    "SPMC": "upper_right",
    "STX": "vertical_right",
    "TDM": "top_left",
    "TLAC": "upper_right",
    "TMT": "top_center",
    "TRK": "upper_left",
    "UGL": "top_right",
    "UMA": "top_center",
    "UNH": "upper_left",
    "UST": "top_center",
    "VOW": "top_right",
    "XLN": "upper_left",
}


def load_generator():
    spec = importlib.util.spec_from_file_location("pack_generator", GENERATOR_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {GENERATOR_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def resize_logo(width: int, rotate: bool = False) -> Image.Image:
    logo = Image.open(LOGO_PATH).convert("RGBA")
    logo = logo.crop(logo.getchannel("A").getbbox())
    alpha = logo.getchannel("A")
    height = round(width * logo.height / logo.width)
    alpha = alpha.resize((width, height), Image.Resampling.LANCZOS)
    mark = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    mark.putalpha(alpha)
    if rotate:
        mark = mark.rotate(90, expand=True, resample=Image.Resampling.BICUBIC)
    return mark


def average_luma(img: Image.Image, box: tuple[int, int, int, int]) -> float:
    crop = img.crop(box).convert("RGBA")
    total = 0
    count = 0
    for r, g, b, a in crop.getdata():
        if a < 40:
            continue
        total += 0.2126 * r + 0.7152 * g + 0.0722 * b
        count += 1
    return total / max(count, 1)


def tint_logo(masked_logo: Image.Image, fill: tuple[int, int, int, int]) -> Image.Image:
    alpha = masked_logo.getchannel("A")
    mark = Image.new("RGBA", masked_logo.size, fill)
    mark.putalpha(alpha)
    return mark


def place_logo(img: Image.Image, code: str) -> Image.Image:
    layout_name = PREFERRED_LAYOUT.get(code, LOGO_LAYOUTS[hash(code) % len(LOGO_LAYOUTS)][0])
    layout = next(item for item in LOGO_LAYOUTS if item[0] == layout_name)
    _, x, y, width, _ = layout
    vertical = layout_name.startswith("vertical")
    logo = resize_logo(width, rotate=vertical)
    box = (x, y, x + logo.width, y + logo.height)
    luma = average_luma(img, box)
    if luma > 170:
        fill = (22, 22, 24, 230)
        shadow_fill = (255, 255, 245, 105)
    elif luma < 75:
        fill = (245, 242, 232, 230)
        shadow_fill = (0, 0, 0, 150)
    else:
        fill = (228, 203, 148, 225)
        shadow_fill = (0, 0, 0, 135)
    shadow = tint_logo(logo, shadow_fill).filter(ImageFilter.GaussianBlur(1.0))
    mark = tint_logo(logo, fill)
    img.alpha_composite(shadow, (x + 2, y + 2))
    img.alpha_composite(mark, (x, y))
    return img


def output_path(code: str, variant: int | None = None) -> Path:
    if code == "---":
        return PACK_DIR / "---_pack.png"
    suffix = f"-{variant}" if variant else ""
    return PACK_DIR / f"{code.lower()}-pack{suffix}.png"


def main():
    generator = load_generator()
    PACK_DIR.mkdir(parents=True, exist_ok=True)
    for code, spec in generator.PACKS.items():
        if code in HAND_TUNED or code in generator.PRESERVE:
            continue
        title, subtitle, colors = spec
        variants = 3 if code == "UST" else 1
        for index in range(variants):
            img = generator.make_pack(code, title, subtitle, colors, index, include_logo=False)
            img = place_logo(img, code)
            out = output_path(code, index + 1 if variants > 1 else None)
            img.save(out, optimize=True)
            print(out.relative_to(ROOT))


if __name__ == "__main__":
    main()
