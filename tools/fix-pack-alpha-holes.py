from __future__ import annotations

from collections import deque
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


PACK_DIR = Path("assets/packs")


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


def fix_image(path: Path) -> tuple[int, int]:
    img = Image.open(path).convert("RGBA")
    alpha = img.getchannel("A")
    edge_alpha = find_edge_alpha(alpha)

    src = img.load()
    w, h = img.size
    mask = np.zeros((h, w), dtype=np.uint8)

    for y in range(h):
        for x in range(w):
            if a < 255 and (x, y) not in edge_alpha:
                mask[y, x] = 255

    repaired = int(np.count_nonzero(mask))
    if repaired:
        rgb = np.array(img.convert("RGB"))
        inpainted = cv2.inpaint(rgb, mask, 3, cv2.INPAINT_TELEA)
        out = Image.fromarray(inpainted).convert("RGBA")
        out_alpha = alpha.copy()
        out_pix = out_alpha.load()
        for y in range(h):
            for x in range(w):
                if mask[y, x]:
                    out_pix[x, y] = 255
        out.putalpha(out_alpha)
        out.save(path, optimize=True)
    return repaired, len(edge_alpha)


def main() -> None:
    for path in sorted(PACK_DIR.glob("*.png")):
        repaired, edge = fix_image(path)
        if repaired:
            print(f"{path}: repaired={repaired} edge_alpha={edge}")


if __name__ == "__main__":
    main()
