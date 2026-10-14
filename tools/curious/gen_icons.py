"""gen_icons.py TABLET.png OUTDIR: the Curious Door's icons, drawn here (256 x 256, transparent).

    GoldenSkeletonKey.png  a skeleton key of gold, its skull bow with glowing eyes, in the Curious Light's glow
    CuriousLockpicks.png   two little golden keys (the picks) on a ring, their tips glowing
    CuriousShakeLight.png  a shake light of yellow glass, its beam lit
    GoldenTablet.png       the tablet's own icon (TABLET.png), its body gold and its screen the Curious Light's

Each is drawn four times bigger and made small (smooth edges), over a soft yellow glow, with a few sparkles."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

tablet_src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(7)
S = 256
K = 4
B = S * K
GOLD = [(118, 70, 8), (190, 128, 22), (236, 184, 58), (255, 232, 140)]  # dark, mid, light, highlight
GLOW = (255, 214, 70)


def gradient(size, colors, angle):
    """A linear gradient over `size` through `colors`, at `angle` (radians)."""
    w, h = size
    y, x = np.mgrid[0:h, 0:w].astype(float)
    u = (x * math.cos(angle) + y * math.sin(angle))
    u = (u - u.min()) / max(u.max() - u.min(), 1)
    stops = np.linspace(0, 1, len(colors))
    out = np.zeros((h, w, 3))
    for c in range(3):
        out[..., c] = np.interp(u, stops, [col[c] for col in colors])
    return Image.fromarray(out.astype(np.uint8), "RGB")


def fill(shape_mask, colors, angle):
    """The mask filled with a gradient, as RGBA."""
    g = gradient(shape_mask.size, colors, angle).convert("RGBA")
    g.putalpha(shape_mask)
    return g


def glow_under(icon, color=GLOW, radius=22, strength=0.75):
    a = icon.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    a = a.point(lambda v: int(min(255, v * strength * 1.6)))
    g = Image.new("RGBA", icon.size, color + (0,))
    g.putalpha(a)
    return Image.alpha_composite(g, icon)


def sparkles(icon, count, area):
    d = ImageDraw.Draw(icon)
    x0, y0, x1, y1 = area
    for _ in range(count):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        r = rng.uniform(3, 7)
        for k in (1.0, 0.45):
            d.polygon([(x, y - r * 2.2 * k), (x + r * 0.45 * k, y - r * 0.45 * k), (x + r * 2.2 * k, y), (x + r * 0.45 * k, y + r * 0.45 * k),
                       (x, y + r * 2.2 * k), (x - r * 0.45 * k, y + r * 0.45 * k), (x - r * 2.2 * k, y), (x - r * 0.45 * k, y - r * 0.45 * k)],
                      fill=(255, 248, 200, 255) if k < 1 else (255, 220, 90, 230))
    return icon


def outline(mask, width):
    return mask.filter(ImageFilter.MaxFilter(width * 2 + 1))


def finish(big, name):
    small = big.resize((S, S), Image.LANCZOS)
    small = glow_under(small, radius=9, strength=0.7)
    small = sparkles(small, 5, (24, 24, 232, 232))
    small.save(os.path.join(out, name))
    return small


def key_mask(size, bow_skull=True):
    """A key along +x: its bow at the left, its bit (teeth) at the right, at scale size (pixels across)."""
    m = Image.new("L", (B, B), 0)
    d = ImageDraw.Draw(m)
    s = size / 1000
    cx, cy = B / 2, B / 2
    def P(x, y): return (cx + (x - 500) * s, cy + (y) * s)
    # shaft
    d.rounded_rectangle([P(330, -38), P(900, 38)], radius=int(30 * s), fill=255)
    # bit: two teeth and a notch
    d.rectangle([P(760, 30), P(820, 170)], fill=255)
    d.rectangle([P(840, 30), P(900, 130)], fill=255)
    d.rectangle([P(760, 100), P(900, 130)], fill=255)
    # collar rings
    for x in (360, 420):
        d.rounded_rectangle([P(x, -70), P(x + 34, 70)], radius=int(12 * s), fill=255)
    # bow
    if bow_skull:
        d.ellipse([P(40, -200), P(340, 150)], fill=255)  # cranium
        d.rounded_rectangle([P(110, 80), P(270, 220)], radius=int(40 * s), fill=255)  # jaw
    else:
        d.ellipse([P(60, -160), P(360, 160)], fill=255)
    return m


def skull_holes(size):
    m = Image.new("L", (B, B), 0)
    d = ImageDraw.Draw(m)
    s = size / 1000
    cx, cy = B / 2, B / 2
    def P(x, y): return (cx + (x - 500) * s, cy + (y) * s)
    d.ellipse([P(95, -90), P(180, 10)], fill=255)  # eyes
    d.ellipse([P(200, -90), P(285, 10)], fill=255)
    d.polygon([P(190, 30), P(170, 90), P(210, 90)], fill=255)  # nose
    for x in (130, 170, 210):
        d.rectangle([P(x, 150), P(x + 18, 205)], fill=255)  # teeth gaps
    return m


def rotate(img, deg):
    return img.rotate(deg, resample=Image.BICUBIC, center=(B / 2, B / 2))


# ---- the golden skeleton key ----
size = B * 0.9
mask = rotate(key_mask(size), 38)
holes = rotate(skull_holes(size), 38)
body = fill(mask, [GOLD[1], GOLD[2], GOLD[3], GOLD[2], GOLD[1], GOLD[0]], math.radians(60))
edge = fill(outline(mask, 7), [(70, 40, 6), (90, 55, 10)], 0)
key = Image.alpha_composite(edge, body)
# the skull's eyes and nose: glowing yellow, its teeth gaps dark
eyes = Image.new("RGBA", (B, B), (255, 240, 120, 0))
eyes.putalpha(holes)
eyes_glow = Image.new("RGBA", (B, B), (255, 200, 40, 0))
eyes_glow.putalpha(holes.filter(ImageFilter.GaussianBlur(18)).point(lambda v: min(255, v * 2)))
key = Image.alpha_composite(key, eyes_glow)
key = Image.alpha_composite(key, eyes)
# a highlight along the shaft
hl = Image.new("L", (B, B), 0)
ImageDraw.Draw(hl).rounded_rectangle([B / 2 + (330 - 500) * size / 1000, B / 2 - 30 * size / 1000, B / 2 + (880 - 500) * size / 1000, B / 2 - 12 * size / 1000],
                                     radius=6, fill=150)
hl = rotate(hl, 38)
shine = Image.new("RGBA", (B, B), (255, 255, 235, 0))
shine.putalpha(hl.filter(ImageFilter.GaussianBlur(4)))
key = Image.alpha_composite(key, shine)
key = glow_under(key, radius=60, strength=0.55)
finish(key, "GoldenSkeletonKey.png")

# ---- the lockpicks: two little keys on a ring ----
ring = Image.new("L", (B, B), 0)
d = ImageDraw.Draw(ring)
rc, rr = (B * 0.36, B * 0.34), B * 0.13
d.ellipse([rc[0] - rr, rc[1] - rr, rc[0] + rr, rc[1] + rr], outline=255, width=int(B * 0.035))
picks = Image.new("RGBA", (B, B), (0, 0, 0, 0))
for angle, shift, colors in ((-62, (B * 0.0, B * 0.02), [GOLD[0], GOLD[1], GOLD[2], GOLD[1]]), (-22, (B * 0.0, B * 0.02), [GOLD[1], GOLD[2], GOLD[3], GOLD[2]])):
    m = key_mask(B * 0.62, bow_skull=False)
    m = m.transform(m.size, Image.AFFINE, (1, 0, -shift[0], 0, 1, -shift[1]))
    m = rotate(m, angle)
    hole = Image.new("L", (B, B), 0)
    s = B * 0.62 / 1000
    hx, hy = B / 2 + (210 - 500) * s, B / 2
    ImageDraw.Draw(hole).ellipse([hx - 60 * s, hy - 60 * s, hx + 60 * s, hy + 60 * s], fill=255)
    hole = rotate(hole.transform(hole.size, Image.AFFINE, (1, 0, -shift[0], 0, 1, -shift[1])), angle)
    m = Image.fromarray(np.clip(np.asarray(m, float) - np.asarray(hole, float), 0, 255).astype(np.uint8))
    edge = fill(outline(m, 6), [(70, 40, 6), (90, 55, 10)], 0)
    picks = Image.alpha_composite(picks, edge)
    picks = Image.alpha_composite(picks, fill(m, colors, math.radians(angle + 90)))
    # its tip glowing
    tip = Image.new("L", (B, B), 0)
    tx, ty = B / 2 + (880 - 500) * s, B / 2 + 60 * s
    ImageDraw.Draw(tip).ellipse([tx - 70 * s, ty - 90 * s, tx + 70 * s, ty + 90 * s], fill=255)
    tip = rotate(tip.transform(tip.size, Image.AFFINE, (1, 0, -shift[0], 0, 1, -shift[1])), angle)
    tglow = Image.new("RGBA", (B, B), (255, 230, 90, 0))
    tglow.putalpha(tip.filter(ImageFilter.GaussianBlur(30)))
    picks = Image.alpha_composite(picks, tglow)
ring_img = Image.alpha_composite(fill(outline(ring, 5), [(70, 40, 6), (90, 55, 10)], 0), fill(ring, GOLD, math.radians(45)))
lp = Image.alpha_composite(picks, ring_img)
lp = glow_under(lp, radius=55, strength=0.55)
finish(lp, "CuriousLockpicks.png")

# ---- the shake light: yellow glass, an orange switch, its beam ----
sl = Image.new("RGBA", (B, B), (0, 0, 0, 0))
beam = Image.new("L", (B, B), 0)
ImageDraw.Draw(beam).polygon([(B * 0.64, B * 0.42), (B * 0.9, B * 0.26), (B * 0.9, B * 0.74), (B * 0.64, B * 0.58)], fill=110)
beam = beam.filter(ImageFilter.GaussianBlur(40))
bl = Image.new("RGBA", (B, B), (255, 236, 120, 0))
bl.putalpha(beam)
body = Image.new("L", (B, B), 0)
d = ImageDraw.Draw(body)
d.rounded_rectangle([B * 0.14, B * 0.38, B * 0.56, B * 0.62], radius=int(B * 0.06), fill=255)  # handle
head = Image.new("L", (B, B), 0)
ImageDraw.Draw(head).rounded_rectangle([B * 0.52, B * 0.33, B * 0.66, B * 0.67], radius=int(B * 0.04), fill=255)
lens = Image.new("L", (B, B), 0)
ImageDraw.Draw(lens).ellipse([B * 0.62, B * 0.36, B * 0.69, B * 0.64], fill=255)
switch = Image.new("L", (B, B), 0)
ImageDraw.Draw(switch).rounded_rectangle([B * 0.26, B * 0.33, B * 0.4, B * 0.4], radius=int(B * 0.02), fill=255)
for m, colors, ang in ((body, [(255, 214, 40), (255, 243, 140), (226, 160, 10)], 90), (head, [(150, 82, 8), (226, 150, 30), (120, 60, 6)], 90),
                       (switch, [(255, 150, 20), (210, 100, 0)], 90)):
    sl = Image.alpha_composite(sl, fill(outline(m, 6), [(60, 34, 4), (80, 46, 8)], 0))
    sl = Image.alpha_composite(sl, fill(m, colors, math.radians(ang)))
# glass: the inside glowing through (bands)
bands = Image.new("L", (B, B), 0)
d = ImageDraw.Draw(bands)
for k in range(5):
    x = B * (0.19 + k * 0.07)
    d.rounded_rectangle([x, B * 0.41, x + B * 0.035, B * 0.59], radius=8, fill=110)
inner = Image.new("RGBA", (B, B), (255, 255, 210, 0))
inner.putalpha(bands.filter(ImageFilter.GaussianBlur(6)))
sl = Image.alpha_composite(sl, inner)
lglow = Image.new("RGBA", (B, B), (255, 250, 200, 0))
lglow.putalpha(lens)
sl = Image.alpha_composite(bl, sl)
sl = Image.alpha_composite(sl, lglow)
lg2 = Image.new("RGBA", (B, B), (255, 230, 100, 0))
lg2.putalpha(lens.filter(ImageFilter.GaussianBlur(35)).point(lambda v: min(255, v * 2)))
sl = Image.alpha_composite(sl, lg2)
sl = rotate(sl, 30)
sl = glow_under(sl, radius=50, strength=0.5)
finish(sl, "CuriousShakeLight.png")

# ---- the golden tablet: the tablet's own icon, its body gold, its screen yellow ----
src = Image.open(tablet_src).convert("RGBA").resize((B, B), Image.LANCZOS)
a = np.asarray(src).astype(float) / 255
rgb, alpha = a[..., :3], a[..., 3]
mx, mn = rgb.max(-1), rgb.min(-1)
sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
lum = rgb @ np.array([0.299, 0.587, 0.114])
screen = np.clip((sat - 0.25) / 0.2, 0, 1) * (rgb[..., 1] >= rgb[..., 0])  # its green screen (and its glow)
gold_lo, gold_mid, gold_hi = np.array(GOLD[0]) / 255, np.array(GOLD[2]) / 255, np.array(GOLD[3]) / 255
t = np.clip(lum / 0.85, 0, 1)[..., None]
body = np.where(t < 0.5, gold_lo + (gold_mid - gold_lo) * (t / 0.5), gold_mid + (gold_hi - gold_mid) * ((t - 0.5) / 0.5))
amber = np.array([1.0, 0.82, 0.25])
scr = amber * (0.5 + 0.7 * np.clip(lum / 0.45, 0, 1))[..., None]
out_rgb = body * (1 - screen[..., None]) + scr * screen[..., None]
tab = Image.fromarray((np.dstack([np.clip(out_rgb, 0, 1), alpha]) * 255).astype(np.uint8), "RGBA")
tab = glow_under(tab, radius=50, strength=0.5)
finish(tab, "GoldenTablet.png")

# A sheet of all four, to look at
sheet = Image.new("RGBA", (S * 4, S), (40, 40, 40, 255))
for i, n in enumerate(("GoldenSkeletonKey.png", "CuriousLockpicks.png", "CuriousShakeLight.png", "GoldenTablet.png")):
    sheet.alpha_composite(Image.open(os.path.join(out, n)), (i * S, 0))
sheet.save(os.path.join(out, "_sheet.png"))
print("ok")
