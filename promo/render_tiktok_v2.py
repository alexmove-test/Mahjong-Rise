# -*- coding: utf-8 -*-
"""Short 9:16 motion-design TikTok for Mahjong Rise."""
from __future__ import annotations

import math
import struct
import subprocess
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(r"C:\Code\Mahjong")
ICON_PATH = ROOT / "store" / "play-icon-512.png"
FRUIT_PATH = ROOT / "assets" / "titles" / "fruit" / "01.png"
OUT = ROOT / "promo" / "Mahjong-Rise-TikTok.mp4"
PREVIEW = ROOT / "promo" / "preview_v2"
FFMPEG = r"C:\Users\Main\AppData\Local\Programs\Python\Python312\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"

W, H = 1080, 1920
FPS = 30
DUR = 12.0
N = int(FPS * DUR)

CREAM = (247, 243, 232, 255)
GOLD = (232, 201, 106, 255)
GOLD_DEEP = (184, 146, 58, 255)
GREEN = (14, 92, 64, 255)

FONT_B = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_R = r"C:\Windows\Fonts\segoeui.ttf"
FONT_L = r"C:\Windows\Fonts\segoeuil.ttf"


def clamp(t: float) -> float:
    return 0.0 if t < 0 else 1.0 if t > 1 else t


def ease_out_cubic(t: float) -> float:
    t = clamp(t)
    return 1 - (1 - t) ** 3


def ease_out_back(t: float) -> float:
    t = clamp(t)
    c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1) ** 3 + c1 * (t - 1) ** 2


def ease_in_out(t: float) -> float:
    t = clamp(t)
    return 4 * t * t * t if t < 0.5 else 1 - ((-2 * t + 2) ** 3) / 2


def seg(t: float, a: float, b: float) -> float:
    return clamp((t - a) / (b - a))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def build_bg() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    ys = np.linspace(0, 1, H, dtype=np.float32)[:, None]
    xs = np.linspace(0, 1, W, dtype=np.float32)[None, :]
    top = np.array([8, 36, 28], dtype=np.float32)
    bot = np.array([2, 12, 10], dtype=np.float32)
    ycol = ys[:, :, None]
    base = top.reshape(1, 1, 3) * (1 - ycol) + bot.reshape(1, 1, 3) * ycol
    cy, cx = 0.40, 0.50
    dist = np.sqrt(((ys - cy) * 1.05) ** 2 + ((xs - cx) * 0.72) ** 2)
    glow = np.clip(1 - dist / 0.62, 0, 1) ** 1.6
    glow_col = np.array([28, 110, 74], dtype=np.float32)
    vig = np.clip((dist - 0.28) / 0.85, 0, 1) ** 1.4
    return base, glow[:, :, None] * glow_col.reshape(1, 1, 3), vig[:, :, None]


def key_black(path: Path) -> Image.Image:
    arr = np.array(Image.open(path).convert("RGBA"))
    lum = arr[:, :, :3].max(axis=2).astype(np.int16)
    alpha = np.clip((lum - 12) * 10, 0, 255).astype(np.uint8)
    arr[:, :, 3] = np.minimum(arr[:, :, 3], alpha)
    return Image.fromarray(arr)


def rounded_icon(size: int) -> Image.Image:
    icon = Image.open(ICON_PATH).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    icon.putalpha(mask)
    return icon


def make_tile(fruit: Image.Image, size=(168, 214)) -> Image.Image:
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((1, 1, size[0] - 2, size[1] - 2), radius=22, fill=(248, 241, 222, 255))
    d.rounded_rectangle((5, 5, size[0] - 6, size[1] - 6), radius=18, outline=(212, 175, 55, 255), width=4)
    glyph = fruit.resize((118, 118), Image.Resampling.LANCZOS)
    im.alpha_composite(glyph, ((size[0] - 118) // 2, (size[1] - 118) // 2 + 2))
    return im


def glyph_cache(font: ImageFont.FreeTypeFont, fill: tuple[int, int, int, int]) -> dict[str, Image.Image]:
    cache: dict[str, Image.Image] = {}

    def get(ch: str) -> Image.Image:
        if ch not in cache:
            w = max(4, int(font.getlength(ch)) + 8)
            h = font.size + 28
            im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            ImageDraw.Draw(im).text((2, 6), ch, font=font, fill=fill)
            cache[ch] = im
        return cache[ch]

    return {"get": get}  # type: ignore[return-value]


def blit_line(
    canvas: Image.Image,
    text: str,
    font: ImageFont.FreeTypeFont,
    cache: dict,
    cx: float,
    cy: float,
    tracking: float,
    alpha: float,
    per_char: list[float] | None = None,
    dy: float = 0,
) -> None:
    if alpha <= 0.004:
        return
    widths = [font.getlength(ch) for ch in text]
    total = sum(widths) + tracking * max(0, len(text) - 1)
    x = cx - total / 2
    for i, ch in enumerate(text):
        a = alpha * (1 if per_char is None else per_char[i])
        if a > 0.004 and ch != " ":
            g = cache["get"](ch)
            if a < 0.995:
                arr = np.array(g)
                arr[:, :, 3] = (arr[:, :, 3].astype(np.float32) * a).astype(np.uint8)
                g = Image.fromarray(arr)
            canvas.alpha_composite(g, (int(x), int(cy - g.height / 2 + dy)))
        x += widths[i] + tracking


def paste_center(canvas: Image.Image, im: Image.Image, cx: float, cy: float, alpha: float = 1) -> None:
    if alpha <= 0.004:
        return
    if alpha < 0.995:
        arr = np.array(im)
        arr[:, :, 3] = (arr[:, :, 3].astype(np.float32) * alpha).astype(np.uint8)
        im = Image.fromarray(arr)
    canvas.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))


def scale_img(im: Image.Image, scale: float) -> Image.Image:
    w = max(2, int(im.width * scale))
    h = max(2, int(im.height * scale))
    return im.resize((w, h), Image.Resampling.LANCZOS)


def shadow_for(im: Image.Image) -> Image.Image:
    pad = 48
    sh = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    mask = im.split()[-1].resize(im.size)
    black = Image.new("RGBA", im.size, (0, 0, 0, 150))
    black.putalpha(mask)
    sh.alpha_composite(black, (pad, pad + 10))
    return sh.filter(ImageFilter.GaussianBlur(16))


def draw_rings(canvas: Image.Image, cx: float, cy: float, t: float, alpha: float) -> None:
    if alpha <= 0.01:
        return
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for i, radius in enumerate((250, 310, 372)):
        spin = t * (28 + i * 12) * (1 if i % 2 == 0 else -1)
        span = 250 - i * 18
        a = int(180 * alpha * (0.55 if i else 0.9))
        col = (232, 201, 106, a)
        box = (cx - radius, cy - radius, cx + radius, cy + radius)
        d.arc(box, start=spin, end=spin + span, fill=col, width=3)
        d.arc(box, start=spin + 180, end=spin + 180 + span * 0.65, fill=(232, 201, 106, a // 2), width=2)
    canvas.alpha_composite(overlay)


def draw_button(canvas: Image.Image, cx: float, cy: float, alpha: float, scale: float) -> None:
    if alpha <= 0.01:
        return
    bw, bh = 820, 176
    im = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((2, 2, bw - 3, bh - 3), radius=40, fill=(10, 64, 46, 255))
    d.rounded_rectangle((2, 2, bw - 3, bh - 3), radius=40, outline=(232, 201, 106, 255), width=3)
    # play disc
    d.ellipse((36, 44, 132, 140), fill=(232, 201, 106, 255))
    d.polygon([(74, 68), (74, 116), (112, 92)], fill=(10, 48, 34, 255))
    font_b = ImageFont.truetype(FONT_B, 52)
    font_s = ImageFont.truetype(FONT_R, 30)
    d.text((160, 36), "Google Play", font=font_b, fill=CREAM)
    d.text((160, 102), "Установи и попробуй играть", font=font_s, fill=GOLD)
    im = scale_img(im, scale)
    paste_center(canvas, im, cx, cy, alpha)


def synth_audio(path: Path) -> None:
    sr = 44100
    n = int(sr * DUR)
    t = np.arange(n, dtype=np.float64) / sr
    audio = np.zeros(n, dtype=np.float64)

    def bell(freq: float, start: float, decay: float, amp: float, harmonics: tuple[float, ...] = (1, 0.35, 0.12)) -> None:
        start *= DUR / 7.0
        i0 = int(start * sr)
        length = int(min(decay * 4, DUR - start) * sr)
        if length <= 0:
            return
        tt = np.arange(length) / sr
        env = np.exp(-tt / decay) * (1 - np.exp(-tt / 0.012))
        wave = np.zeros(length)
        for k, hamp in enumerate(harmonics, start=1):
            wave += hamp * np.sin(2 * math.pi * freq * k * tt)
        audio[i0 : i0 + length] += amp * env * wave

    # quiet bed
    bed = 0.012 * np.sin(2 * math.pi * 110 * t) * np.sin(2 * math.pi * 0.2 * t + 0.4)
    bed *= np.clip(t / 0.3, 0, 1) * np.clip((DUR - t) / 0.4, 0, 1)
    audio += bed
    bell(523.25, 0.28, 0.55, 0.11)
    bell(659.25, 0.42, 0.7, 0.07)
    bell(392.0, 2.15, 0.45, 0.09)
    bell(523.25, 2.28, 0.8, 0.12)
    bell(783.99, 2.42, 0.9, 0.06)
    bell(659.25, 3.15, 0.28, 0.08)  # match
    bell(987.77, 3.18, 0.22, 0.05)
    bell(440.0, 4.55, 0.4, 0.07)
    bell(659.25, 4.68, 0.85, 0.11)
    bell(880.0, 4.82, 0.7, 0.05)
    audio *= np.clip((DUR - t) / 0.25, 0, 1)
    peak = np.max(np.abs(audio)) or 1
    audio = audio / peak * 0.85
    pcm = (audio * 32767).astype(np.int16)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())


def main(preview_only: bool = False) -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    base, glow, vig = build_bg()
    fruit = key_black(FRUIT_PATH)
    icon_master = rounded_icon(560)
    icon_shadow = shadow_for(icon_master)
    tile = make_tile(fruit)
    tile_shadow = shadow_for(tile)

    font_kicker = ImageFont.truetype(FONT_L, 34)
    font_line = ImageFont.truetype(FONT_B, 78)
    font_hero = ImageFont.truetype(FONT_B, 156)
    font_brand = ImageFont.truetype(FONT_B, 78)
    font_sub = ImageFont.truetype(FONT_L, 36)
    font_foot = ImageFont.truetype(FONT_L, 28)

    cache_line = glyph_cache(font_line, CREAM)
    cache_hero = glyph_cache(font_hero, GOLD)
    cache_brand = glyph_cache(font_brand, CREAM)
    cache_sub = glyph_cache(font_sub, GOLD)
    cache_kick = glyph_cache(font_kicker, GOLD)
    cache_foot = glyph_cache(font_foot, (247, 243, 232, 210))

    rng = np.random.default_rng(4)
    particles = [
        (
            float(rng.random()),
            float(rng.random()),
            float(rng.uniform(1.4, 3.2)),
            float(rng.uniform(0, math.tau)),
            float(rng.uniform(0.012, 0.035)),
            float(rng.uniform(0.25, 0.7)),
        )
        for _ in range(42)
    ]
    line = "Я разрабатываю"
    hero = "игру"

    def frame_at(i: int) -> Image.Image:
        t = i / FPS * 7.0 / DUR
        breathe = 0.82 + 0.18 * math.sin(t * 1.4)
        rgb = np.clip(base + glow * breathe - vig * 28, 0, 255).astype(np.uint8)
        canvas = Image.fromarray(rgb, "RGB").convert("RGBA")

        # dust
        dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dust)
        for x0, y0, s, ph, sp, al in particles:
            y = (y0 - t * sp) % 1.0
            x = x0 + 0.012 * math.sin(t * 0.8 + ph)
            tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 1.7 + ph))
            a = int(170 * al * tw)
            px, py = x * W, y * H
            dd.ellipse((px, py, px + s, py + s), fill=(232, 201, 106, a))
        canvas.alpha_composite(dust)

        # --- act 1: 0.15–2.15, exit by 2.55
        intro_in = ease_out_cubic(seg(t, 0.12, 0.7))
        intro_out = 1 - ease_in_out(seg(t, 1.85, 2.35))
        intro_a = intro_in * intro_out
        if intro_a > 0.01:
            rise = (1 - intro_in) * 36 - (1 - intro_out) * 50
            per = [ease_out_cubic(seg(t, 0.18 + k * 0.028, 0.48 + k * 0.028)) for k in range(len(line))]
            blit_line(canvas, "НОВАЯ ИГРА", font_kicker, cache_kick, W / 2, 760 + rise, 10, intro_a * 0.9, dy=0)
            # underline
            rule_p = ease_out_cubic(seg(t, 0.45, 0.95)) * intro_out
            if rule_p > 0.01:
                rw = int(280 * rule_p)
                rule = Image.new("RGBA", (W, H), (0, 0, 0, 0))
                ImageDraw.Draw(rule).rectangle((W / 2 - rw / 2, 812 + rise, W / 2 + rw / 2, 815 + rise), fill=(232, 201, 106, int(220 * intro_a)))
                canvas.alpha_composite(rule)
            blit_line(canvas, line, font_line, cache_line, W / 2, 900 + rise, 1.5, intro_a, per_char=per)
            hero_a = ease_out_cubic(seg(t, 0.55, 1.05)) * intro_out
            hero_sc = lerp(0.92, 1.0, ease_out_back(seg(t, 0.55, 1.15)))
            # draw hero via temporary scale of a rendered line
            if hero_a > 0.01:
                layer = Image.new("RGBA", (W, 260), (0, 0, 0, 0))
                blit_line(layer, hero, font_hero, cache_hero, W / 2, 130, -2, 1)
                if abs(hero_sc - 1) > 0.01:
                    layer = scale_img(layer, hero_sc)
                paste_center(canvas, layer, W / 2, 1040 + rise, hero_a)

        # --- act 2 logo: 2.05–4.7, then lifts into CTA
        logo_in = ease_out_back(seg(t, 2.05, 2.7))
        to_cta = ease_in_out(seg(t, 4.35, 5.05))
        logo_a = ease_out_cubic(seg(t, 2.05, 2.45))
        if logo_a > 0.01:
            icon_scale = lerp(0.78, 1.0, min(logo_in, 1)) * lerp(1.0, 0.52, to_cta)
            icon_y = lerp(760, 520, to_cta) + (1 - min(logo_in, 1)) * 40
            icon = scale_img(icon_master, icon_scale)
            sh = scale_img(icon_shadow, icon_scale)
            paste_center(canvas, sh, W / 2, icon_y + 8, logo_a * (1 - 0.35 * to_cta))
            draw_rings(canvas, W / 2, icon_y, t, logo_a * (1 - to_cta))
            paste_center(canvas, icon, W / 2, icon_y, logo_a)

            brand_a = ease_out_cubic(seg(t, 2.35, 2.8)) * (1 - to_cta)
            brand_dy = (1 - ease_out_cubic(seg(t, 2.35, 2.9))) * 28
            blit_line(canvas, "Mahjong Rise", font_brand, cache_brand, W / 2, 1125 + brand_dy, 1, brand_a)
            sub_a = ease_out_cubic(seg(t, 2.6, 3.05)) * (1 - ease_in_out(seg(t, 4.15, 4.6)))
            blit_line(canvas, "ПАСЬЯНС С ПЛИТКАМИ", font_sub, cache_sub, W / 2, 1225, 6, sub_a)

        # tiles match between subtitle and lower third, 2.2–4.3
        match_in = ease_out_cubic(seg(t, 2.25, 3.05))
        meet = ease_in_out(seg(t, 2.25, 3.15))
        pop = seg(t, 3.15, 3.55)
        tile_out = ease_in_out(seg(t, 3.45, 4.05))
        tile_a = (1 - tile_out) * (1 if t > 2.2 else 0)
        if tile_a > 0.02 and t < 4.15:
            spread = lerp(420, 98, meet)
            bounce = math.sin(clamp(pop) * math.pi) * 14
            sc = 1 + 0.08 * math.sin(clamp(pop) * math.pi)
            cy_t = 1470 - bounce
            if pop > 0.02:
                flash_a = math.sin(clamp(pop) * math.pi) * tile_a
                flash = Image.new("RGBA", (W, H), (0, 0, 0, 0))
                fd = ImageDraw.Draw(flash)
                r = 70 + 80 * pop
                fd.ellipse(
                    (W / 2 - r, cy_t - r * 0.72, W / 2 + r, cy_t + r * 0.72),
                    fill=(232, 201, 106, int(70 * flash_a)),
                )
                canvas.alpha_composite(flash)
            tt = scale_img(tile, sc)
            sh = scale_img(tile_shadow, sc)
            for side in (-1, 1):
                x = W / 2 + side * spread
                paste_center(canvas, sh, x, cy_t + 8, tile_a * 0.9)
                paste_center(canvas, tt, x, cy_t, tile_a)

        # --- CTA 4.5–7.0
        cta = ease_out_back(seg(t, 4.55, 5.15))
        cta_a = ease_out_cubic(seg(t, 4.5, 4.95))
        if cta_a > 0.01:
            by = lerp(1180, 1040, min(cta, 1))
            draw_button(canvas, W / 2, by, cta_a, lerp(0.94, 1.0, min(cta, 1)))
            foot_a = ease_out_cubic(seg(t, 5.05, 5.45))
            blit_line(canvas, "Mahjong Rise", font_foot, cache_foot, W / 2, 1188, 8, foot_a)

        fin = ease_out_cubic(seg(t, 0.0, 0.28))
        fout = 1 - ease_in_out(seg(t, 6.8, 7.0))
        veil = fin * fout
        if veil < 0.999:
            black = Image.new("RGBA", (W, H), (0, 0, 0, int(255 * (1 - veil))))
            canvas.alpha_composite(black)
        return canvas.convert("RGB")

    if preview_only:
        for mark in (1.95, 4.9, 5.75, 10.5):
            im = frame_at(int(mark * FPS))
            path = PREVIEW / f"t{mark:.2f}.png"
            im.save(path, quality=95)
            print("preview", path)
        return

    wav = PREVIEW / "sting.wav"
    synth_audio(wav)
    cmd = [
        FFMPEG, "-y",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "pipe:0",
        "-i", str(wav),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "17", "-preset", "medium",
        "-c:a", "aac", "-b:a", "160k",
        "-shortest", "-movflags", "+faststart",
        str(OUT),
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    assert proc.stdin is not None
    for i in range(N):
        im = frame_at(i)
        proc.stdin.write(np.ascontiguousarray(im).tobytes())
        if i % 30 == 0:
            print(f"frame {i}/{N}")
    proc.stdin.close()
    code = proc.wait()
    if code != 0:
        raise SystemExit(f"ffmpeg failed: {code}")
    print("wrote", OUT, OUT.stat().st_size)


if __name__ == "__main__":
    import sys

    main(preview_only="--preview" in sys.argv)
