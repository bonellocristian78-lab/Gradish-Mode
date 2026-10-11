"""gen_images.py OUTDIR: the Halloween Mode's images, drawn here.

    Eye.png      Seek's eye for Halloween: a glowing orange iris with a cat's slit, purple veins on a sickly white
    JackFace.png a jack o' lantern's carved face, glowing (only if the kit's pumpkin head will not load)
    Fog.png      a soft puff of fog (only if the kit's fog texture will not load)"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(31)
S = 512

# The eye: full square (it covers the eye's face as DOORS' own does)
y, x = np.mgrid[0:S, 0:S].astype(float)
cx = cy = S / 2
r = np.hypot(x - cx, y - cy) / (S / 2)
img = np.zeros((S, S, 4))
sclera = np.array([236, 228, 196]) / 255
edge = np.array([60, 20, 70]) / 255
t = np.clip((r - 0.55) / 0.45, 0, 1) ** 1.6
img[..., :3] = sclera * (1 - t[..., None]) + edge * t[..., None]
img[..., 3] = 1
vein = Image.new("L", (S, S), 0)
d = ImageDraw.Draw(vein)
for k in range(26):
    a = rng.uniform(0, 2 * math.pi)
    px, py = cx + math.cos(a) * S * 0.49, cy + math.sin(a) * S * 0.49
    width = rng.uniform(2, 5)
    for _ in range(14):
        a2 = math.atan2(cy - py, cx - px) + rng.uniform(-0.7, 0.7)
        step = rng.uniform(8, 16)
        nx, ny = px + math.cos(a2) * step, py + math.sin(a2) * step
        if math.hypot(nx - cx, ny - cy) < S * 0.25:
            break
        d.line([(px, py), (nx, ny)], fill=255, width=max(1, int(width)))
        px, py, width = nx, ny, width * 0.9
vein = np.asarray(vein.filter(ImageFilter.GaussianBlur(1.2))) / 255
purple = np.array([140, 40, 170]) / 255
img[..., :3] = img[..., :3] * (1 - vein[..., None] * 0.85) + purple * vein[..., None] * 0.85
iris_r = 0.5
inside = r < iris_r
ir = np.clip(r / iris_r, 0, 1)
iris = (np.array([255, 236, 120]) / 255 * (1 - ir[..., None]) ** 1.5 + np.array([255, 120, 10]) / 255 * (1 - (1 - ir[..., None]) ** 1.5))
streaks = 0.85 + 0.15 * np.sin(np.arctan2(y - cy, x - cx) * 40 + rng.uniform(0, 6))
iris = iris * streaks[..., None]
ring = np.clip((ir - 0.85) / 0.15, 0, 1)
iris = iris * (1 - ring[..., None]) + np.array([90, 20, 0]) / 255 * ring[..., None]
img[inside, :3] = iris[inside]
slit = (np.abs(x - cx) / (S * 0.045 * np.clip(1 - ((y - cy) / (S / 2 * iris_r * 0.97)) ** 2, 0, 1) ** 0.9 + 1e-6)) < 1
slit &= inside
img[slit, :3] = np.array([10, 0, 12]) / 255
glint = np.hypot(x - (cx - S * 0.12), y - (cy - S * 0.13)) < S * 0.035
img[glint, :3] = 1
Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(out, "Eye.png"))

# The jack o' lantern's face: carved triangles and a jagged grin, glowing yellow, on nothing
face = Image.new("RGBA", (S, S), (0, 0, 0, 0))
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shapes = [[(130, 200), (215, 200), (172, 120)], [(297, 200), (382, 200), (340, 120)], [(236, 260), (276, 260), (256, 225)],
          [(110, 300), (160, 330), (190, 300), (225, 340), (256, 305), (287, 340), (322, 300), (352, 330), (402, 300), (370, 400),
           (322, 375), (290, 410), (256, 380), (222, 410), (190, 375), (142, 400)]]
for shape in shapes:
    ImageDraw.Draw(glow).polygon(shape, fill=(255, 150, 20, 255))
    ImageDraw.Draw(face).polygon(shape, fill=(255, 225, 90, 255))
glow = glow.filter(ImageFilter.GaussianBlur(10))
Image.alpha_composite(glow, face).save(os.path.join(out, "JackFace.png"))

# A puff of fog: soft, white, fading to nothing at its edges
F = 256
fy, fx = np.mgrid[0:F, 0:F].astype(float)
fr = np.hypot(fx - F / 2, fy - F / 2) / (F / 2)
noise = Image.fromarray((rng.uniform(0, 255, (F // 8, F // 8))).astype(np.uint8)).resize((F, F), Image.BICUBIC)
noise = np.asarray(noise.filter(ImageFilter.GaussianBlur(6))) / 255
alpha = np.clip(1 - fr, 0, 1) ** 1.8 * (0.6 + 0.4 * noise)
fog = np.zeros((F, F, 4))
fog[..., :3] = 1
fog[..., 3] = alpha
Image.fromarray((fog * 255).astype(np.uint8), "RGBA").save(os.path.join(out, "Fog.png"))
print("ok")
