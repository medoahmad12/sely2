#!/usr/bin/env python3
"""Cuts the individual illustrations out of the Sili Kids sticker sheet into
assets/images/art/<name>.png using the sheet's own alpha channel (real transparency).

    python3 tool/extract_sticker_sheet.py path/to/sheet.png

Needs Pillow, numpy and scipy. Prints the size of every file and writes docs/art_preview.png
(every asset on a checkerboard) so the cut-outs can be checked by eye.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

# name -> seed points (one inside every piece of that sticker; satellites like the "?" and the
# held star are separate pieces and are listed too)
STICKERS = {
    "sili_wave": [(149, 178)],
    "sili_happy": [(360, 182)],
    "sili_think": [(554, 191), (643, 75)],
    "sili_encourage": [(752, 191)],
    "bunny_wave": [(954, 179)],
    "bunny_happy": [(1114, 173)],
    "bunny_think": [(1278, 183), (1342, 124)],
    "bunny_star": [(1440, 177), (1509, 224)],
    "cat_happy": [(112, 428)],
    "dog": [(321, 422)],
    "chick": [(532, 427)],
    "apple": [(740, 441)],
    "strawberry": [(935, 447)],
    "bowl": [(1156, 466)],
    "star": [(1419, 436)],
    "sign_alef": [(122, 642)],
    "shape_house": [(348, 637)],
    "strawberry_crate": [(587, 645)],
    "stars_group": [(761, 661), (826, 598), (859, 685)],
    "butterfly": [(1010, 644)],
    "bird_blue": [(1217, 637)],
    "gift_box": [(1426, 643)],
    "panorama_banner": [(768, 874)],
}


def main(sheet, out_dir="assets/images/art"):
    im = Image.open(sheet).convert("RGBA")
    a = np.array(im)
    alpha = a[:, :, 3].astype(float)
    fg = alpha > 110
    lab, n = ndi.label(fg, structure=np.ones((3, 3)))
    boxes = ndi.find_objects(lab)
    centers = {}
    for i, sl in enumerate(boxes):
        if (lab[sl] == i + 1).sum() > 250:
            centers[i + 1] = ((sl[1].start + sl[1].stop) / 2, (sl[0].start + sl[0].stop) / 2)
    os.makedirs(out_dir, exist_ok=True)
    clean = np.clip((alpha - 4) / (250 - 4), 0, 1)  # the sheet's background alpha is 1..4, foreground ~252
    results = {}
    for name, seeds in STICKERS.items():
        ids = set()
        for (x, y) in seeds:
            cid = int(lab[y, x]) if lab[y, x] else min(centers, key=lambda k: (centers[k][0] - x) ** 2 + (centers[k][1] - y) ** 2)
            ids.add(cid)
        mask = ndi.binary_dilation(np.isin(lab, list(ids)), iterations=3)
        out = a.copy()
        out[:, :, 3] = (clean * mask * 255).astype("uint8")
        img = Image.fromarray(out)
        bb = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        img = img.crop(bb)
        path = os.path.join(out_dir, name + ".png")
        img.save(path, optimize=True)
        results[name] = img
        print(f"{name:18s} {img.size[0]:4d}x{img.size[1]:<4d} {os.path.getsize(path)//1024:4d} KB")
    # preview on a checkerboard
    cols, cell = 6, 230
    rows = (len(results) + cols - 1) // cols
    sheet_prev = Image.new("RGB", (cols * cell, rows * cell), (255, 255, 255))
    d = ImageDraw.Draw(sheet_prev)
    for yy in range(0, rows * cell, 16):
        for xx in range(0, cols * cell, 16):
            if (xx // 16 + yy // 16) % 2:
                d.rectangle((xx, yy, xx + 15, yy + 15), fill=(222, 222, 222))
    for k, (name, img) in enumerate(results.items()):
        t = img.copy(); t.thumbnail((cell - 12, cell - 28))
        x, y = (k % cols) * cell + 6, (k // cols) * cell + 20
        sheet_prev.paste(t, (x, y), t)
        d.text((x, y - 16), name, fill=(180, 0, 0))
    os.makedirs("docs", exist_ok=True)
    sheet_prev.save("docs/art_preview.png")


if __name__ == "__main__":
    main(sys.argv[1])
