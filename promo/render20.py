# -*- coding: utf-8 -*-
"""20-second 9:16 motion-design promo for Mahjong Rise, built from the real game assets."""
from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import music20

ROOT = Path(r"C:\Code\Mahjong")
ASSETS = ROOT / "assets"
BUILD = ROOT / "promo" / "build"
OUT = Path.home() / "Desktop" / "Mahjong-Rise-TikTok-20s.mp4"
FFMPEG = (
    Path(sys.prefix) / "Lib" / "site-packages" / "imageio_ffmpeg" / "binaries" / "ffmpeg-win-x86_64-v7.1.exe"
)

W, H = 1080, 1920
FPS = 30
DUR = 20.0
N = int(FPS * DUR)
BEAT = 60.0 / 96.0

CREAM = (247, 243, 232, 255)
GOLD = (232, 201, 106, 255)
FONT_B = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_R = r"C:\Windows\Fonts\segoeui.ttf"
FONT_L = r"C:\Windows\Fonts\segoeuil.ttf"


# ---------------------------------------------------------------- easing helpers
def clamp(x: float) -> float:
    return 0.0 if x < 0 else 1.0 if x > 1 else x


def seg(t: float, a: float, b: float) -> float:
    return clamp((t - a) / (b - a))


def out_cubic(x: float) -> float:
    x = clamp(x)
    return 1 - (1 - x) ** 3


def out_back(x: float) -> float:
    x = clamp(x)
    return 1 + 2.70158 * (x - 1) ** 3 + 1.70158 * (x - 1) ** 2


def in_out(x: float) -> float:
    x = clamp(x)
    return 4 * x**3 if x < 0.5 else 1 - ((-2 * x + 2) ** 3) / 2


def lerp(a: float, b: float, x: float) -> float:
    return a + (b - a) * x


def bump(x: float) -> float:
    """0 -> 1 -> 0 over the unit interval."""
    return math.sin(clamp(x) * math.pi)


# ---------------------------------------------------------------- image helpers
def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def fit_h(im: Image.Image, height: int) -> Image.Image:
    w = max(2, round(im.width * height / im.height))
    return im.resize((w, height), Image.Resampling.LANCZOS)


def scaled(im: Image.Image, f: float) -> Image.Image:
    if abs(f - 1) < 0.004:
        return im
    return im.resize((max(2, round(im.width * f)), max(2, round(im.height * f))), Image.Resampling.LANCZOS)


def with_alpha(im: Image.Image, a: float) -> Image.Image:
    if a >= 0.996:
        return im
    arr = np.array(im)
    arr[:, :, 3] = (arr[:, :, 3].astype(np.float32) * a).astype(np.uint8)
    return Image.fromarray(arr)


def paste(canvas: Image.Image, im: Image.Image, cx: float, cy: float, a: float = 1.0, anchor: str = "c") -> None:
    if a <= 0.004:
        return
    x = int(cx - im.width / 2)
    y = int(cy - im.height / 2) if anchor == "c" else int(cy - im.height)
    canvas.alpha_composite(with_alpha(im, a), (x, y))


def drop_shadow(im: Image.Image, blur: int = 18, opacity: int = 150, dy: int = 12) -> Image.Image:
    pad = blur * 3
    sh = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    black = Image.new("RGBA", im.size, (0, 0, 0, opacity))
    black.putalpha(im.split()[-1])
    sh.alpha_composite(black, (pad, pad + dy))
    return sh.filter(ImageFilter.GaussianBlur(blur))


def radial_glow(radius: int, color: tuple[int, int, int], strength: float = 1.0) -> Image.Image:
    d = radius * 2
    yy, xx = np.mgrid[0:d, 0:d].astype(np.float32)
    r = np.sqrt((xx - radius) ** 2 + (yy - radius) ** 2) / radius
    a = np.clip(1 - r, 0, 1) ** 2.2 * 255 * strength
    arr = np.zeros((d, d, 4), dtype=np.uint8)
    arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = color
    arr[:, :, 3] = a.astype(np.uint8)
    return Image.fromarray(arr)


# ---------------------------------------------------------------- text helpers
class Text:
    def __init__(self, font_path: str, size: int, fill=CREAM):
        self.font = ImageFont.truetype(font_path, size)
        self.fill = fill
        self._cache: dict[str, Image.Image] = {}

    def glyph(self, ch: str) -> Image.Image:
        if ch not in self._cache:
            w = max(4, int(self.font.getlength(ch)) + 10)
            h = self.font.size + 34
            im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            ImageDraw.Draw(im).text((3, 8), ch, font=self.font, fill=self.fill)
            self._cache[ch] = im
        return self._cache[ch]

    def width(self, s: str, tracking: float = 0.0) -> float:
        return sum(self.font.getlength(c) for c in s) + tracking * max(0, len(s) - 1)

    def draw(
        self,
        canvas: Image.Image,
        s: str,
        cx: float,
        cy: float,
        a: float = 1.0,
        tracking: float = 0.0,
        reveal: float | None = None,
        stagger: float = 0.03,
    ) -> None:
        """reveal: 0..1 progress that fades characters in left to right."""
        if a <= 0.004:
            return
        widths = [self.font.getlength(c) for c in s]
        x = cx - (sum(widths) + tracking * max(0, len(s) - 1)) / 2
        for i, ch in enumerate(s):
            ca = a
            if reveal is not None:
                span = max(1e-3, 1 - stagger * (len(s) - 1))
                ca *= out_cubic(clamp((reveal - i * stagger) / span))
            if ch != " " and ca > 0.004:
                g = self.glyph(ch)
                canvas.alpha_composite(with_alpha(g, ca), (int(x), int(cy - g.height / 2)))
            x += widths[i] + tracking


def rule(canvas: Image.Image, cx: float, cy: float, width: float, a: float) -> None:
    if a <= 0.01 or width < 2:
        return
    layer = Image.new("RGBA", (max(2, int(width)), 3), (232, 201, 106, int(225 * a)))
    paste(canvas, layer, cx, cy, 1.0)


# ---------------------------------------------------------------- static art
print("preparing art...")
ICON_RAW = load(ROOT / "store" / "play-icon-512.png")


def rounded_icon(size: int) -> Image.Image:
    icon = ICON_RAW.resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    icon.putalpha(mask)
    return icon


ICON_BIG = rounded_icon(520)
ICON_BIG_SH = drop_shadow(ICON_BIG, 22, 160, 16)
ICON_SMALL = rounded_icon(300)
ICON_SMALL_SH = drop_shadow(ICON_SMALL, 16, 140, 12)
GLOW_GOLD = radial_glow(320, (232, 201, 106), 0.5)
GLOW_WARM = radial_glow(420, (60, 200, 140), 0.32)

SYMBOL_FILES = [ASSETS / "titles" / "fruit" / f"{i:02d}.png" for i in range(1, 13)]
SYMBOLS = [load(p) for p in SYMBOL_FILES]

TILE_W, TILE_H = 132, 168


def make_tile(sym: Image.Image, w: int = TILE_W, h: int = TILE_H) -> Image.Image:
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = int(w * 0.16)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=(208, 196, 168, 255))
    d.rounded_rectangle((0, 0, w - 1, h - 6), radius=r, fill=(248, 241, 222, 255))
    d.rounded_rectangle((4, 4, w - 5, h - 10), radius=r - 3, outline=(212, 175, 55, 220), width=3)
    g = int(w * 0.62)
    im.alpha_composite(sym.resize((g, g), Image.Resampling.LANCZOS), ((w - g) // 2, (h - g) // 2 - 2))
    return im


TILES = [make_tile(s) for s in SYMBOLS]
# higher board layers cast a longer shadow so the pyramid reads at a glance
TILE_SH = [drop_shadow(TILES[0], 10 + 5 * layer, 135, 7 + 11 * layer) for layer in range(3)]

def trimmed(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    return im.crop(box) if box else im


def build_art(kind: str, index: int, height: int) -> Image.Image:
    return fit_h(trimmed(load(ASSETS / "courtyard" / "builds" / kind / f"{index:02d}.png")), height)


# each stage is a bit taller than the last, so the upgrades read as growth
HOUSES = {n: build_art("house", n, h) for n, h in ((3, 330), (10, 400), (17, 475), (24, 540))}
PET_PLOT = build_art("pets", 20, 360)
POND_PLOT = build_art("pond", 16, 300)
FOX = fit_h(load(ASSETS / "pets" / "fox.png"), 260)

T_KICKER = Text(FONT_L, 36, GOLD)
T_LINE = Text(FONT_B, 80)
T_HERO = Text(FONT_B, 150, GOLD)
T_SMALL = Text(FONT_L, 38, (247, 243, 232, 225))
T_BRAND = Text(FONT_B, 84)
T_TAG = Text(FONT_L, 38, GOLD)
T_CAP = Text(FONT_B, 54)
T_CAP2 = Text(FONT_L, 36, (247, 243, 232, 215))
T_SCORE = Text(FONT_B, 46, GOLD)
T_POP = Text(FONT_B, 58, GOLD)
T_FOOT = Text(FONT_L, 32, (247, 243, 232, 205))
T_PILL = Text(FONT_R, 34, GOLD)


# ---------------------------------------------------------------- background
_ys = np.linspace(0, 1, H, dtype=np.float32)[:, None]
_xs = np.linspace(0, 1, W, dtype=np.float32)[None, :]
_top = np.array([9, 38, 30], dtype=np.float32).reshape(1, 1, 3)
_bot = np.array([2, 12, 10], dtype=np.float32).reshape(1, 1, 3)
_BASE = _top * (1 - _ys[:, :, None]) + _bot * _ys[:, :, None]
_dist = np.sqrt(((_ys - 0.40) * 1.05) ** 2 + ((_xs - 0.5) * 0.72) ** 2)
_GLOW = (np.clip(1 - _dist / 0.62, 0, 1) ** 1.6)[:, :, None] * np.array([30, 112, 76], dtype=np.float32).reshape(1, 1, 3)
_VIG = (np.clip((_dist - 0.28) / 0.85, 0, 1) ** 1.4)[:, :, None] * 30

_rng = np.random.default_rng(12)
DUST = [
    (
        float(_rng.random()),
        float(_rng.random()),
        float(_rng.uniform(1.6, 3.6)),
        float(_rng.uniform(0, math.tau)),
        float(_rng.uniform(0.010, 0.030)),
        float(_rng.uniform(0.25, 0.75)),
    )
    for _ in range(54)
]


def background(t: float) -> Image.Image:
    breathe = 0.80 + 0.20 * math.sin(t * 1.15)
    rgb = np.clip(_BASE + _GLOW * breathe - _VIG, 0, 255).astype(np.uint8)
    canvas = Image.fromarray(rgb, "RGB").convert("RGBA")
    dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(dust)
    for x0, y0, s, ph, sp, al in DUST:
        y = (y0 - t * sp) % 1.0
        x = x0 + 0.014 * math.sin(t * 0.7 + ph)
        tw = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 1.6 + ph))
        px, py = x * W, y * H
        d.ellipse((px, py, px + s, py + s), fill=(232, 201, 106, int(165 * al * tw)))
    canvas.alpha_composite(dust)
    return canvas


# ---------------------------------------------------------------- scene 1: hook
def scene_hook(c: Image.Image, t: float) -> None:
    local = t
    intro = out_cubic(seg(local, 0.15, 0.75))
    rise = (1 - intro) * 34
    T_KICKER.draw(c, "НОВАЯ ИГРА", W / 2, 700 + rise, intro * 0.95, tracking=11)
    rule(c, W / 2, 752 + rise, 300 * out_cubic(seg(local, 0.45, 1.05)), out_cubic(seg(local, 0.45, 0.9)))
    T_LINE.draw(c, "Я разрабатываю", W / 2, 856 + rise, 1.0, tracking=1.5, reveal=seg(local, 0.2, 1.0), stagger=0.035)

    hero_p = seg(local, 0.6, 1.25)
    hero_a = out_cubic(seg(local, 0.6, 1.0))
    if hero_a > 0.01:
        layer = Image.new("RGBA", (W, 250), (0, 0, 0, 0))
        T_HERO.draw(layer, "игру", W / 2, 125, 1.0, tracking=-2)
        paste(c, scaled(layer, lerp(0.9, 1.0, out_back(hero_p))), W / 2, 1000 + rise, hero_a)
        paste(c, GLOW_GOLD, W / 2, 1000 + rise, 0.30 * hero_a * (0.7 + 0.3 * math.sin(local * 3)))

    sub_a = out_cubic(seg(local, 1.9, 2.5))
    T_SMALL.draw(c, "и хочу показать, что получилось", W / 2, 1140, sub_a * 0.95, tracking=1.5)

    # two tiles drifting in the lower third as a teaser
    for k, (sx, base_x, base_y) in enumerate(((0, 300, 1430), (1, 790, 1520))):
        a = out_cubic(seg(local, 1.15 + k * 0.25, 1.9 + k * 0.25))
        if a <= 0.01:
            continue
        tile = scaled(TILES[k * 3], 0.82)
        y = base_y - 18 * math.sin(local * 1.5 + k) - (1 - a) * 40
        rot = tile.rotate(-9 + 18 * k, resample=Image.Resampling.BICUBIC, expand=True)
        paste(c, scaled(TILE_SH[0], 0.82), base_x, y + 10, a * 0.7)
        paste(c, rot, base_x, y, a)


# ---------------------------------------------------------------- scene 2: logo
def scene_logo(c: Image.Image, t: float) -> None:
    local = t - 3.65
    pop = out_back(seg(local, 0.05, 0.75))
    a_icon = out_cubic(seg(local, 0.05, 0.45))
    icon_y = 760 - 26 * (1 - clamp(pop))
    paste(c, GLOW_WARM, W / 2, icon_y, 0.55 * a_icon)
    icon = scaled(ICON_BIG, lerp(0.8, 1.0, min(pop, 1.08)))
    paste(c, scaled(ICON_BIG_SH, lerp(0.8, 1.0, min(pop, 1.08))), W / 2, icon_y + 10, a_icon * 0.85)

    # spinning gold rings
    rings = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rings)
    for i, rad in enumerate((300, 360, 424)):
        spin = local * (34 + i * 14) * (1 if i % 2 == 0 else -1)
        span = 240 - i * 22
        alpha = int(170 * a_icon * (0.95 if i == 0 else 0.55))
        box = (W / 2 - rad, icon_y - rad, W / 2 + rad, icon_y + rad)
        rd.arc(box, spin, spin + span, fill=(232, 201, 106, alpha), width=3)
        rd.arc(box, spin + 175, spin + 175 + span * 0.6, fill=(232, 201, 106, alpha // 2), width=2)
    c.alpha_composite(rings)
    paste(c, icon, W / 2, icon_y, a_icon)

    # ray burst on the beat the icon lands
    burst = bump(seg(local, 0.25, 0.85))
    if burst > 0.02:
        ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring)
        r = 240 + 300 * seg(local, 0.25, 0.85)
        rd.ellipse((W / 2 - r, icon_y - r, W / 2 + r, icon_y + r), outline=(255, 240, 190, int(150 * burst)), width=5)
        c.alpha_composite(ring)

    T_BRAND.draw(c, "Mahjong Rise", W / 2, 1180, 1.0, tracking=1, reveal=seg(local, 0.55, 1.35), stagger=0.045)
    T_TAG.draw(c, "СПОКОЙНЫЙ ПАСЬЯНС С ПЛИТКАМИ", W / 2, 1268, out_cubic(seg(local, 1.0, 1.6)), tracking=4)

    # feature pills
    pills = (("Офлайн", -230), ("Без регистрации", 210))
    for i, (label, dx) in enumerate(pills):
        pa = out_cubic(seg(local, 1.55 + i * 0.22, 2.15 + i * 0.22))
        if pa <= 0.01:
            continue
        tw = T_PILL.width(label, 2) + 68
        pill = Image.new("RGBA", (int(tw), 78), (0, 0, 0, 0))
        pd = ImageDraw.Draw(pill)
        pd.rounded_rectangle((0, 0, tw - 1, 77), radius=39, fill=(9, 58, 42, 235), outline=GOLD, width=2)
        T_PILL.draw(pill, label, tw / 2, 39, 1.0, tracking=2)
        paste(c, pill, W / 2 + dx, 1390 + (1 - pa) * 18, pa)


# ---------------------------------------------------------------- scene 3: board
BOARD_CX, BOARD_CY = W / 2, 910
STEP_X, STEP_Y = 138, 174
TRAY_Y = 1600


def build_layout() -> list[dict]:
    tiles: list[dict] = []
    for row in range(4):
        for col in range(5):
            tiles.append({"layer": 0, "x": BOARD_CX + (col - 2) * STEP_X, "y": BOARD_CY + (row - 1.5) * STEP_Y})
    for row in range(2):
        for col in range(3):
            tiles.append(
                {"layer": 1, "x": BOARD_CX + (col - 1) * STEP_X - 12, "y": BOARD_CY + (row - 0.5) * STEP_Y - 18}
            )
    for i in range(2):
        tiles.append({"layer": 2, "x": BOARD_CX + (i - 0.5) * STEP_X - 24, "y": BOARD_CY - 36})
    return tiles


LAYOUT = build_layout()
_sym_rng = np.random.default_rng(5)
_pool = [s for s in range(len(TILES)) for _ in range(2)]
_pool += [3, 3, 9, 9]  # 28 tiles = 14 pairs
_sym_rng.shuffle(_pool)
for _i, _tl in enumerate(LAYOUT):
    _tl["sym"] = _pool[_i]
    _tl["delay"] = 0.02 * ((_tl["layer"] * 6) + (_i % 7))

# indices of the three pairs that get matched, top layers first
TOP = len(LAYOUT) - 1
PAIRS = [
    (TOP, TOP - 1, 8.90, 120),
    (TOP - 3, TOP - 6, 10.15, 160),
    (TOP - 2, TOP - 7, 11.45, 200),
]
_locked = {i for pair in PAIRS for i in pair[:2]}
for _a, _b, _t0, _pts in PAIRS:
    want = LAYOUT[_a]["sym"]
    if LAYOUT[_b]["sym"] == want:
        continue
    # swap with a free tile that already holds the symbol, so the deck stays paired
    twin = next((j for j, tl in enumerate(LAYOUT) if tl["sym"] == want and j not in _locked), None)
    if twin is not None:
        LAYOUT[twin]["sym"], LAYOUT[_b]["sym"] = LAYOUT[_b]["sym"], want

CASCADE_START = 12.25
CASCADE_SPAN = 0.7
_cx_ref, _cy_ref = BOARD_CX, BOARD_CY
_order = sorted(
    (i for i in range(len(LAYOUT)) if all(i not in (a, b) for a, b, _, _ in PAIRS)),
    key=lambda i: -(abs(LAYOUT[i]["x"] - _cx_ref) + abs(LAYOUT[i]["y"] - _cy_ref)),
)
for _k, _i in enumerate(_order):
    LAYOUT[_i]["cascade"] = CASCADE_START + CASCADE_SPAN * _k / max(1, len(_order) - 1)


def tray_slot_x(i: int) -> float:
    return W / 2 + (i - 1.5) * 120


def scene_board(c: Image.Image, t: float) -> None:
    local = t - 7.40

    T_CAP.draw(c, "Снимай пары", W / 2, 340, out_cubic(seg(local, 0.35, 0.9)), tracking=1)
    T_CAP2.draw(c, "открытые плитки идут в лоток на 4 места", W / 2, 412, out_cubic(seg(local, 0.7, 1.3)), tracking=1)

    score = sum(pts for _, _, t0, pts in PAIRS if t > t0 + 0.45)
    hud_a = out_cubic(seg(local, 0.6, 1.1))
    T_CAP2.draw(c, "СЧЁТ", W / 2 + 350, 462, hud_a * 0.8, tracking=5)
    T_SCORE.draw(c, f"{score}", W / 2 + 350, 512, hud_a, tracking=2)

    # ---- tray
    tray_a = out_cubic(seg(local, 0.5, 1.1))
    if tray_a > 0.01:
        tw, th = 560, 150
        tray = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        td = ImageDraw.Draw(tray)
        td.rounded_rectangle((0, 0, tw - 1, th - 1), radius=32, fill=(10, 48, 36, 232), outline=GOLD, width=3)
        for i in range(4):
            sx = 24 + i * 128
            td.rounded_rectangle((sx, 18, sx + 112, th - 19), radius=18, outline=(232, 201, 106, 110), width=2)
        paste(c, tray, W / 2, TRAY_Y, tray_a)

    # ---- tiles, drawn back to front
    order = sorted(range(len(LAYOUT)), key=lambda i: (LAYOUT[i]["layer"], LAYOUT[i]["y"], LAYOUT[i]["x"]))
    for i in order:
        tl = LAYOUT[i]
        appear = out_cubic(seg(local, 0.1 + tl["delay"], 0.6 + tl["delay"]))
        if appear <= 0.01:
            continue
        wave = 4.5 * math.sin(t * 1.25 + tl["x"] * 0.006 + tl["y"] * 0.004)
        x, y = tl["x"], tl["y"] + wave - (1 - appear) * 120
        a, sc = appear, 1.0
        flying = None
        for slot, (pa, pb, t0, pts) in enumerate(PAIRS):
            if i not in (pa, pb):
                continue
            which = 0 if i == pa else 1
            fly = seg(t, t0, t0 + 0.45)
            if fly <= 0:
                continue
            gone = seg(t, t0 + 0.58, t0 + 0.82)
            tx, ty = tray_slot_x(which), TRAY_Y
            e = in_out(fly)
            x = lerp(tl["x"], tx, e)
            y = lerp(tl["y"], ty, e) - 190 * bump(fly)
            sc = lerp(1.0, 0.73, e) * (1 + 0.16 * bump(gone))
            a = appear * (1 - gone)
            flying = (slot, which, fly, gone, t0, pts)
        if "cascade" in tl and t > tl["cascade"]:
            cg = seg(t, tl["cascade"], tl["cascade"] + 0.3)
            a *= 1 - cg
            sc *= 1 + 0.3 * cg
            y -= 40 * cg
        if a <= 0.01:
            continue
        tile = scaled(TILES[tl["sym"]], sc)
        paste(c, scaled(TILE_SH[tl["layer"]], sc), x, y + 8 + 8 * tl["layer"], a * 0.8)
        # pulse the pair for a moment before it lifts off
        for pa_i, pb_i, t0, _pts in PAIRS:
            if i in (pa_i, pb_i) and t0 - 0.35 < t < t0 + 0.05:
                paste(c, scaled(GLOW_GOLD, 0.55), x, y, 0.45 * bump(seg(t, t0 - 0.35, t0 + 0.05)))
        paste(c, tile, x, y, a)

    # ---- match bursts and score popups
    for pa, pb, t0, pts in PAIRS:
        bp = seg(t, t0 + 0.5, t0 + 1.0)
        if 0 < bp < 1:
            slot_cx = (tray_slot_x(0) + tray_slot_x(1)) / 2
            paste(c, scaled(GLOW_GOLD, 0.7), slot_cx, TRAY_Y, 0.85 * (1 - bp) ** 0.6)
            sparks = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            sd = ImageDraw.Draw(sparks)
            for k in range(10):
                ang = k * math.tau / 10 + bp * 0.9
                d2 = 60 + 190 * out_cubic(bp)
                sx = slot_cx + math.cos(ang) * d2
                sy = TRAY_Y + math.sin(ang) * d2 * 0.7
                s = 10 * (1 - bp)
                sd.ellipse((sx - s, sy - s, sx + s, sy + s), fill=(255, 240, 195, int(225 * (1 - bp))))
            c.alpha_composite(sparks)
        pp = seg(t, t0 + 0.5, t0 + 1.4)
        if 0 < pp < 1:
            T_POP.draw(c, f"+{pts}", W / 2, TRAY_Y - 130 - 110 * out_cubic(pp), (1 - pp) ** 0.7, tracking=1)


# ---------------------------------------------------------------- scene 4: courtyard
def ground_blob(width: int, height: int, opacity: int = 130) -> Image.Image:
    blur = max(8, width // 12)
    im = Image.new("RGBA", (width + blur * 4, height + blur * 4), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((blur * 2, blur * 2, blur * 2 + width, blur * 2 + height), fill=(0, 12, 8, opacity))
    return im.filter(ImageFilter.GaussianBlur(blur))


HOUSE_SHADOW = ground_blob(520, 150)
PLOT_SHADOW = ground_blob(380, 120, 110)
FOX_SHADOW = ground_blob(190, 64, 120)
HOUSE_STAGES = ((3, 13.40), (10, 14.40), (17, 15.40), (24, 16.25))
HOUSE_BASE_Y = 1230


def scene_yard(c: Image.Image, t: float) -> None:
    local = t - 13.00
    T_CAP.draw(c, "Победы растят двор", W / 2, 420, out_cubic(seg(local, 0.25, 0.85)), tracking=1)
    T_CAP2.draw(c, "дом · питомцы · украшения", W / 2, 492, out_cubic(seg(local, 0.6, 1.2)), tracking=3)

    warm = out_cubic(seg(local, 0.1, 0.9))
    paste(c, GLOW_WARM, W / 2, 1320, 0.45 * warm)

    # the house climbs through four build stages
    for idx, (stage, t0) in enumerate(HOUSE_STAGES):
        nxt = HOUSE_STAGES[idx + 1][1] if idx + 1 < len(HOUSE_STAGES) else None
        a = out_cubic(seg(t, t0 - 0.1, t0 + 0.25))
        if nxt is not None:
            a *= 1 - in_out(seg(t, nxt - 0.08, nxt + 0.2))
        if a <= 0.01:
            continue
        sc = lerp(0.86, 1.0, out_back(seg(t, t0 - 0.1, t0 + 0.5)))
        paste(c, HOUSE_SHADOW, W / 2, HOUSE_BASE_Y - 36, a * 0.9)
        paste(c, scaled(HOUSES[stage], sc), W / 2, HOUSE_BASE_Y, a, anchor="b")
        up = seg(t, t0, t0 + 0.55)
        if 0 < up < 1:
            fx = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            fd = ImageDraw.Draw(fx)
            r = 150 + 240 * out_cubic(up)
            fd.ellipse(
                (W / 2 - r, HOUSE_BASE_Y - 30 - r * 0.2, W / 2 + r, HOUSE_BASE_Y - 30 + r * 0.2),
                outline=(255, 240, 195, int(95 * (1 - up) ** 1.4)),
                width=3,
            )
            # sparkles fly outward past the silhouette instead of sitting on top of it
            for k in range(10):
                ang = math.pi * (0.12 + 0.76 * k / 9)
                d2 = 240 + 260 * out_cubic(up)
                sx = W / 2 + math.cos(ang) * d2
                sy = HOUSE_BASE_Y - 120 - math.sin(ang) * d2 * 0.62
                s = 7 * (1 - up)
                fd.ellipse((sx - s, sy - s, sx + s, sy + s), fill=(255, 238, 190, int(200 * (1 - up))))
            c.alpha_composite(fx)

    # decorations slide into the yard
    for plot, shadow, px, py, t0 in (
        (PET_PLOT, PLOT_SHADOW, 300, 1530, 2.05),
        (POND_PLOT, PLOT_SHADOW, 800, 1620, 2.75),
    ):
        pa = out_cubic(seg(local, t0, t0 + 0.55))
        if pa <= 0.01:
            continue
        sc = lerp(0.88, 1.0, out_back(seg(local, t0, t0 + 0.8)))
        dy = (1 - pa) * 70
        paste(c, scaled(shadow, sc * 0.9), px, py - 34 + dy, pa * 0.85)
        paste(c, scaled(plot, sc), px, py + dy, pa, anchor="b")

    # the fox trots in front
    fox_a = out_cubic(seg(local, 3.35, 3.8))
    if fox_a > 0.01:
        fx = lerp(W + 150, 566, out_cubic(seg(local, 3.35, 4.05)))
        hop = 12 * abs(math.sin(local * 5.2))
        paste(c, FOX_SHADOW, fx, 1745, fox_a * 0.8)
        paste(c, FOX, fx, 1730 - hop, fox_a, anchor="b")


# ---------------------------------------------------------------- scene 5: CTA
def make_button() -> Image.Image:
    bw, bh = 840, 184
    im = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((3, 3, bw - 4, bh - 4), radius=44, fill=(10, 64, 46, 255), outline=GOLD, width=3)
    d.ellipse((40, 46, 138, 144), fill=GOLD)
    d.polygon([(78, 70), (78, 120), (118, 95)], fill=(10, 48, 34, 255))
    d.text((168, 40), "Google Play", font=ImageFont.truetype(FONT_B, 56), fill=CREAM)
    d.text((170, 110), "установи и попробуй играть", font=ImageFont.truetype(FONT_R, 31), fill=GOLD)
    return im


BUTTON = make_button()
BUTTON_SH = drop_shadow(BUTTON, 18, 150, 14)


def shimmer(width: int, height: int) -> Image.Image:
    xx = np.linspace(-1, 1, width, dtype=np.float32)[None, :]
    a = np.clip(1 - np.abs(xx) * 3.2, 0, 1) ** 2 * 120
    arr = np.zeros((height, width, 4), dtype=np.uint8)
    arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = 255, 245, 205
    arr[:, :, 3] = np.repeat(a.astype(np.uint8), height, axis=0)
    return Image.fromarray(arr)


SHIMMER = shimmer(360, BUTTON.height - 14)


def scene_cta(c: Image.Image, t: float) -> None:
    local = t - 17.35
    ia = out_cubic(seg(local, 0.1, 0.55))
    iy = 640 - 24 * (1 - clamp(out_back(seg(local, 0.1, 0.8))))
    paste(c, GLOW_WARM, W / 2, iy, 0.5 * ia)
    sc = lerp(0.86, 1.0, out_back(seg(local, 0.1, 0.8)))
    paste(c, scaled(ICON_SMALL_SH, sc), W / 2, iy + 8, ia * 0.85)
    paste(c, scaled(ICON_SMALL, sc), W / 2, iy, ia)

    T_BRAND.draw(c, "Mahjong Rise", W / 2, 900, 1.0, tracking=1, reveal=seg(local, 0.35, 1.1), stagger=0.04)
    T_TAG.draw(c, "УЖЕ В GOOGLE PLAY", W / 2, 984, out_cubic(seg(local, 0.7, 1.25)), tracking=6)

    ba = out_cubic(seg(local, 0.85, 1.35))
    if ba > 0.01:
        bs = lerp(0.92, 1.0, out_back(seg(local, 0.85, 1.5)))
        btn = scaled(BUTTON, bs).copy()
        sweep = seg(local, 1.35, 2.15)
        if 0 < sweep < 1:
            band = SHIMMER.rotate(0)
            x = int(lerp(-band.width, btn.width, sweep))
            mask = Image.new("RGBA", btn.size, (0, 0, 0, 0))
            mask.alpha_composite(band, (x, 7))
            alpha = np.minimum(np.array(mask)[:, :, 3], np.array(btn)[:, :, 3])
            m2 = np.array(mask)
            m2[:, :, 3] = alpha
            btn.alpha_composite(Image.fromarray(m2))
        paste(c, scaled(BUTTON_SH, bs), W / 2, 1180 + 10, ba * 0.85)
        paste(c, btn, W / 2, 1180, ba)
        pulse = 0.5 + 0.5 * math.sin(local * 4.2)
        paste(c, GLOW_GOLD, W / 2, 1180, 0.10 * ba * pulse)

    T_FOOT.draw(c, "офлайн · без регистрации · ссылка в профиле", W / 2, 1330, out_cubic(seg(local, 1.5, 2.0)), tracking=2)


# ---------------------------------------------------------------- compositing
SCENES = (
    (scene_hook, 0.00, 3.95),
    (scene_logo, 3.65, 7.70),
    (scene_board, 7.40, 13.30),
    (scene_yard, 13.00, 17.65),
    (scene_cta, 17.35, 20.00),
)
CUTS = (3.75, 7.50, 13.125, 17.50)


def scene_alpha(t: float, a: float, b: float) -> float:
    fade_in = out_cubic(seg(t, a, a + 0.30)) if a > 0 else out_cubic(seg(t, 0, 0.30))
    fade_out = 1 - in_out(seg(t, b - 0.30, b))
    return fade_in * fade_out


def sweep_band() -> Image.Image:
    yy = np.linspace(-1, 1, 420, dtype=np.float32)[:, None]
    a = np.clip(1 - np.abs(yy) * 1.15, 0, 1) ** 2.4 * 150
    arr = np.zeros((420, W, 4), dtype=np.uint8)
    arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = 255, 238, 185
    arr[:, :, 3] = np.repeat(a.astype(np.uint8), W, axis=1)
    return Image.fromarray(arr)


SWEEP = sweep_band()


def frame_at(i: int) -> Image.Image:
    t = i / FPS
    canvas = background(t)
    for fn, a, b in SCENES:
        al = scene_alpha(t, a, b)
        if al <= 0.004:
            continue
        if al >= 0.996:
            fn(canvas, t)
        else:
            layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            fn(layer, t)
            canvas.alpha_composite(with_alpha(layer, al))

    for cut in CUTS:
        p = seg(t, cut - 0.22, cut + 0.20)
        if 0 < p < 1:
            y = lerp(-260, H + 260, in_out(p))
            paste(canvas, SWEEP, W / 2, y, 0.85 * bump(p) ** 0.4)

    fin = out_cubic(seg(t, 0, 0.30))
    fout = 1 - in_out(seg(t, DUR - 0.55, DUR))
    veil = fin * fout
    if veil < 0.998:
        canvas.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, int(255 * (1 - veil)))))
    return canvas.convert("RGB")


def main() -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    if "--preview" in sys.argv:
        for mark in (1.4, 2.9, 5.0, 6.6, 8.6, 9.5, 12.0, 13.9, 15.6, 17.0, 18.4, 19.4):
            frame_at(int(mark * FPS)).save(BUILD / f"f{mark:05.2f}.png")
            print("preview", mark)
        return

    wav = BUILD / "music20.wav"
    if not wav.exists():
        music20.write_wav(wav)
    cmd = [
        str(FFMPEG), "-y", "-loglevel", "error",
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "pipe:0",
        "-i", str(wav),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-preset", "medium",
        "-c:a", "aac", "-b:a", "192k", "-ar", "44100",
        "-shortest", "-movflags", "+faststart", str(OUT),
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    assert proc.stdin is not None
    for i in range(N):
        proc.stdin.write(np.ascontiguousarray(frame_at(i)).tobytes())
        if i % 60 == 0:
            print(f"frame {i}/{N}")
    proc.stdin.close()
    if proc.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print("wrote", OUT, OUT.stat().st_size)


if __name__ == "__main__":
    main()
