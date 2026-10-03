"""python3 recolor.py in.mp4 out.mp4 -> every red hue turned blue, the rest untouched (needs ffmpeg and numpy)"""
import subprocess, sys, numpy as np
FF = "ffmpeg"
src, dst = sys.argv[1], sys.argv[2]
W, H = 480, 360

def to_blue(frame):
    f = frame.astype(np.float32) / 255
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    mx, mn = f.max(-1), f.min(-1)
    d = mx - mn
    sat = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    # hue in degrees
    h = np.zeros_like(mx)
    m = d > 1e-6
    rm = m & (mx == r)
    gm = m & (mx == g) & ~rm
    bm = m & ~rm & ~gm
    h[rm] = (60 * ((g[rm] - b[rm]) / d[rm])) % 360
    h[gm] = 60 * ((b[gm] - r[gm]) / d[gm]) + 120
    h[bm] = 60 * ((r[bm] - g[bm]) / d[bm]) + 240
    signed = np.where(h > 180, h - 360, h)     # around red: + towards orange, - towards pink
    # reds and red-oranges up to 30 degrees (gone by 48), pinks up to -45 (gone by -60)
    hue_w = np.where(signed >= 0, np.clip((48 - signed) / 18, 0, 1), np.clip((60 + signed) / 15, 0, 1))
    sat_w = np.clip((sat - 0.08) / 0.14, 0, 1) # greys and whites stay as they are
    w = hue_w * sat_w
    # the same pixel turned blue: red channel goes to blue, a little green for DOORS' cold blue
    nh = (225 + signed * 0.4) % 360
    v = mx
    c = v * sat
    x = c * (1 - np.abs((nh / 60) % 2 - 1))
    z = np.zeros_like(c)
    sector = (nh // 60).astype(int)
    rgb = np.stack([
        np.choose(sector, [c, x, z, z, x, c]),
        np.choose(sector, [x, c, c, x, z, z]),
        np.choose(sector, [z, z, x, c, c, x]),
    ], -1) + (v - c)[..., None]
    out = f * (1 - w[..., None]) + rgb * w[..., None]
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)

dec = subprocess.Popen([FF, "-loglevel", "error", "-i", src, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
enc = subprocess.Popen([FF, "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", "24000/1001", "-i", "-",
                        "-i", src, "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "copy", "-shortest", dst],
                       stdin=subprocess.PIPE)
n = 0
while True:
    buf = dec.stdout.read(W * H * 3)
    if len(buf) < W * H * 3: break
    enc.stdin.write(to_blue(np.frombuffer(buf, np.uint8).reshape(H, W, 3)).tobytes())
    n += 1
enc.stdin.close(); enc.wait(); dec.wait()
print("frames", n)
