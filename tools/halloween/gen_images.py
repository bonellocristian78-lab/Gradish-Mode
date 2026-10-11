"""gen_images.py OUTDIR: the Halloween Mode's images, drawn here.

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
