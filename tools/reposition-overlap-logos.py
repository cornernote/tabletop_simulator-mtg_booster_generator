from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


PACK_DIR = Path("assets/packs")
LOGO_PATH = Path("assets/logos/magic-the-gathering-2017-thumb.png")


CONFIGS = {
    "all": ("vertical_left", 34, 238, 150, "white"),
    "cns": ("top_center", 176, 112, 185, "gold"),
    "csp": ("top_center", 176, 116, 185, "white"),
    "dka": ("top_center", 176, 112, 185, "white"),
    "dom": ("vertical_left", 34, 250, 150, "gold"),
    "emn": ("top_center", 176, 112, 185, "white"),
    "fdn": ("top_center", 180, 128, 170, "black"),
    "ice": ("top_center", 176, 118, 185, "white"),
    "isd": ("vertical_right", 450, 240, 150, "white"),
    "mh1": ("top_center", 176, 112, 185, "white"),
    "soi": ("vertical_right", 450, 240, 150, "white"),
    "war": ("top_center", 176, 112, 185, "white"),
    "znr": ("top_center", 176, 112, 185, "white"),
}

OLD_LOGO_BOX = (116, 72, 432, 164)


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


def add_logo(img: Image.Image, layout: str, x: int, y: int, width: int, color: str) -> Image.Image:
    colors = {
        "white": (245, 242, 232, 232),
        "black": (18, 18, 20, 232),
        "gold": (226, 202, 145, 226),
        "silver": (218, 222, 224, 226),
    }
    vertical = layout.startswith("vertical")
    fill = colors[color]
    shadow_fill = (0, 0, 0, 145) if color != "black" else (255, 255, 245, 95)
    mask = logo_mask(width, vertical)
    img.alpha_composite(tint(mask, shadow_fill).filter(ImageFilter.GaussianBlur(1.0)), (x + 2, y + 2))
    img.alpha_composite(tint(mask, fill), (x, y))
    return img


def inpaint_box(img: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    rgba = img.convert("RGBA")
    rgb = np.array(rgba.convert("RGB"))
    mask = np.zeros(rgb.shape[:2], dtype=np.uint8)
    x1, y1, x2, y2 = box
    mask[y1:y2, x1:x2] = 255
    # Keep card-count corners out of the inpaint mask.
    mask[:150, :105] = 0
    mask[:150, 440:] = 0
    inpainted = cv2.inpaint(rgb, mask, 7, cv2.INPAINT_TELEA)
    out = Image.fromarray(inpainted).convert("RGBA")
    out.putalpha(rgba.getchannel("A"))
    return out


def fix_pack(code: str) -> None:
    path = PACK_DIR / f"{code}-pack.png"
    layout, x, y, width, color = CONFIGS[code]
    img = Image.open(path).convert("RGBA")
    img = inpaint_box(img, OLD_LOGO_BOX)
    img = add_logo(img, layout, x, y, width, color)
    img.save(path, optimize=True)
    print(path)


def main() -> None:
    for code in CONFIGS:
        fix_pack(code)


if __name__ == "__main__":
    main()
