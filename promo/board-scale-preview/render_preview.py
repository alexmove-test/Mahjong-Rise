"""Макет стола в теме «Новая»: зазоры и стыки как в игре, верх поля у лотка.

Код игры не меняет. Пишет два PNG в эту же папку.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
OUT = Path(__file__).resolve().parent

ASPECT = 709 / 514
S = 2
PHONE_W = 390
PHONE_H = 844
PLAY_MAX_X = 10
PLAY_MAX_Y = 8

# Тёплый стол и фарфор темы «Новая».
WOOD_HI = (199, 154, 92)
WOOD_MID = (107, 67, 36)
WOOD_DEEP = (42, 23, 10)
SIDE_HI = (238, 225, 192)
SIDE_MID = (203, 174, 120)
SIDE_LO = (140, 107, 60)
FACE_HI = (255, 254, 250)
FACE_LO = (248, 243, 227)
STROKE = (107, 58, 32)
TRAY = (58, 36, 18, 230)

DRAGON = [
    [2, 2, 2, 2, 2, 2],
    [3, 4, 4, 4, 4, 3],
    [3, 5, 14, 14, 5, 3],
    [3, 4, 4, 4, 4, 3],
    [2, 2, 2, 2, 2, 2],
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    path = Path(r"C:\Windows\Fonts") / name
    if path.exists():
        return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def mix(t: float) -> tuple[int, int, int]:
    if t < 0.55:
        return lerp(WOOD_HI, WOOD_MID, t / 0.55)
    return lerp(WOOD_MID, WOOD_DEEP, (t - 0.55) / 0.45)


def premium_backdrop(w: int, h: int) -> Image.Image:
    sw, sh = max(1, w // 3), max(1, h // 3)
    cx, cy = sw / 2, sh * 0.46
    reach = ((sw * 0.7) ** 2 + (sh * 0.85) ** 2) ** 0.5
    small = Image.new("RGB", (sw, sh))
    pix = small.load()
    for y in range(sh):
        for x in range(sw):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / reach
            pix[x, y] = mix(min(1.0, d))
    image = small.resize((w, h), Image.Resampling.BILINEAR)
    draw = ImageDraw.Draw(image, "RGBA")
    step = int(26 * S)
    for i in range(-h, w, step):
        color = (255, 255, 255, 9) if (i // step) % 2 == 0 else (0, 0, 0, 14)
        draw.line([(i, 0), (i + h, h)], fill=color, width=max(1, S // 2))
    vignette = Image.new("L", (sw, sh), 0)
    vp = vignette.load()
    for y in range(sh):
        for x in range(sw):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / (reach * 0.85)
            vp[x, y] = int(min(1.0, max(0.0, (d - 0.35) / 0.75)) * 150)
    shade = Image.new("RGBA", (w, h), (15, 8, 3, 255))
    shade.putalpha(vignette.resize((w, h), Image.Resampling.BILINEAR))
    image.paste(shade, (0, 0), shade)
    return image.convert("RGBA")


def footprint_overlaps(ax: int, ay: int, bx: int, by: int) -> bool:
    return ax < bx + 2 and ax + 2 > bx and ay < by + 2 and ay + 2 > by


def spread_onto_seams(heights: dict[tuple[int, int], int]) -> list[tuple[int, int, int]]:
    """Лишние кости стопки садятся на швы, как Layouts._spreadOntoSeams."""
    cells = sorted(heights, key=lambda c: (c[1], c[0]))
    occupied = set(cells)
    placed: list[tuple[int, int, int]] = [(x, y, 0) for x, y in cells]

    def has(x: int, y: int) -> bool:
        return (x, y) in occupied

    def layer_at(x: int, y: int) -> int:
        max_l = -1
        for px, py, pz in placed:
            if footprint_overlaps(x, y, px, py) and pz > max_l:
                max_l = pz
        return max_l + 1

    def caps_at(x: int, y: int) -> int:
        return sum(1 for px, py, _pz in placed if px == x and py == y)

    def junctions_for(x: int, y: int) -> list[tuple[int, int, int, int]]:
        out: list[tuple[int, int, int, int]] = []

        def add(jx: int, jy: int, kind: int, support_cells: list[tuple[int, int]]) -> None:
            if jx < 0 or jy < 0 or jx > PLAY_MAX_X or jy > PLAY_MAX_Y:
                return
            support = sum(heights.get(cell, 0) for cell in support_cells)
            out.append((jx, jy, kind, support))

        if has(x + 2, y) and has(x, y + 2) and has(x + 2, y + 2):
            add(x + 1, y + 1, 3, [(x, y), (x + 2, y), (x, y + 2), (x + 2, y + 2)])
        if has(x - 2, y) and has(x, y + 2) and has(x - 2, y + 2):
            add(x - 1, y + 1, 3, [(x - 2, y), (x, y), (x - 2, y + 2), (x, y + 2)])
        if has(x + 2, y) and has(x, y - 2) and has(x + 2, y - 2):
            add(x + 1, y - 1, 3, [(x, y - 2), (x + 2, y - 2), (x, y), (x + 2, y)])
        if has(x - 2, y) and has(x, y - 2) and has(x - 2, y - 2):
            add(x - 1, y - 1, 3, [(x - 2, y - 2), (x, y - 2), (x - 2, y), (x, y)])
        if has(x + 2, y):
            add(x + 1, y, 2, [(x, y), (x + 2, y)])
        if has(x - 2, y):
            add(x - 1, y, 2, [(x - 2, y), (x, y)])
        if has(x, y + 2):
            add(x, y + 1, 1, [(x, y), (x, y + 2)])
        if has(x, y - 2):
            add(x, y - 1, 1, [(x, y - 2), (x, y)])
        return out

    jobs: list[tuple[int, int]] = []
    for cell in sorted(cells, key=lambda c: (-heights[c], c[1], c[0])):
        jobs.extend([cell] * (heights[cell] - 1))

    for cell in jobs:
        options = junctions_for(cell[0], cell[1])
        if not options:
            placed.append((cell[0], cell[1], layer_at(cell[0], cell[1])))
            continue
        options.sort(key=lambda item: (caps_at(item[0], item[1]), -item[2], -item[3], item[1], item[0]))
        best = options[0]
        placed.append((best[0], best[1], layer_at(best[0], best[1])))
    return placed


def dragon_tiles() -> list[tuple[int, int, int, int]]:
    heights: dict[tuple[int, int], int] = {}
    for row, line in enumerate(DRAGON):
        for col, height in enumerate(line):
            if height:
                heights[(col * 2, row * 2)] = height
    placed = spread_onto_seams(heights)
    tiles = [
        (x, y, z, (x * 3 + y * 5 + z * 7) % 20)
        for x, y, z in placed
    ]
    tiles.sort(key=lambda t: (t[2], t[1], t[0]))
    return tiles


def fit_tile_w(usable_w: float) -> float:
    # Сцена 6×5, шаг = ширина кости: content_w = tile_w * (5 + 1 + 0.125).
    return usable_w / (6 + 10 / 80)


def board_metrics(tile_w: float, gap: float = 1.0) -> dict[str, float]:
    scale = tile_w / 80.0
    tile_h = tile_w * ASPECT
    return {
        "tile_w": tile_w,
        "tile_h": tile_h,
        "cell_w": tile_w * gap,
        "cell_h": tile_h * gap,
        "origin_x": 4 * 2.5 * scale,
        "origin_y": 4 * 9.0 * scale,
        "scale": scale,
        "gap": gap,
    }


def gap_to_fit(tiles: list[tuple[int, int, int, int]], tile_w: float, usable_w: float) -> float:
    """Самый свободный шаг, при котором поле с костью [tile_w] ещё входит в ширину."""
    lo, hi = 0.45, 1.0
    best = lo
    for _ in range(20):
        mid = (lo + hi) / 2
        left, _top, right, _bottom = visual_bounds(tiles, board_metrics(tile_w, mid))
        if right - left <= usable_w:
            best = mid
            lo = mid
        else:
            hi = mid
    return best


def tile_pos(x: int, y: int, z: int, m: dict[str, float]) -> tuple[float, float]:
    lift_x = -z * 2.5 * m["scale"]
    lift_y = -z * 9.0 * m["scale"]
    return (
        m["origin_x"] + (x / 2) * m["cell_w"] + lift_x,
        m["origin_y"] + (y / 2) * m["cell_h"] + lift_y,
    )


def visual_bounds(tiles: list[tuple[int, int, int, int]], m: dict[str, float]) -> tuple[float, float, float, float]:
    left = top = 1e9
    right = bottom = -1e9
    for x, y, z, _symbol in tiles:
        px, py = tile_pos(x, y, z, m)
        left = min(left, px)
        top = min(top, py)
        right = max(right, px + m["tile_w"])
        bottom = max(bottom, py + m["tile_h"])
    return left, top, right, bottom


def symbol_box(tile_w: int, tile_h: int) -> tuple[int, int, int, int]:
    face_w = tile_w * (1 - 0.11)
    face_h = tile_h * (1 - 0.13)
    inset = 0.08
    x = face_w * inset
    y = face_h * inset
    w = face_w * (1 - 2 * inset)
    h = face_h * (1 - 2 * inset)
    return round(x), round(y), max(1, round(w)), max(1, round(h))


def fit_symbol(src: Image.Image, w: int, h: int, resample: Image.Resampling) -> Image.Image:
    scale = min(w / src.width, h / src.height)
    sw = max(1, round(src.width * scale))
    sh = max(1, round(src.height * scale))
    resized = src.resize((sw, sh), resample)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((w - sw) // 2, (h - sh) // 2))
    return canvas


def soften(im: Image.Image, factor: float = 0.2) -> Image.Image:
    small = im.resize(
        (max(1, round(im.width * factor)), max(1, round(im.height * factor))),
        Image.Resampling.BOX,
    )
    return small.resize(im.size, Image.Resampling.BILINEAR)


def vertical_gradient(w: int, h: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    column = Image.new("RGB", (1, max(1, h)))
    pix = column.load()
    for y in range(column.height):
        t = y / max(1, column.height - 1)
        pix[0, y] = lerp(top, bottom, t)
    return column.resize((w, h), Image.Resampling.BILINEAR).convert("RGBA")


def rounded_mask(w: int, h: int, radius: int, box: tuple[int, int, int, int] | None = None) -> Image.Image:
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    rect = box if box is not None else (0, 0, w - 1, h - 1)
    draw.rounded_rectangle(rect, radius=radius, fill=255)
    return mask


def premium_body(tile_w: int) -> Image.Image:
    tile_h = max(1, round(tile_w * ASPECT))
    radius = max(2, int(tile_w * 0.14))
    face_r = max(2, int(radius * 0.9))
    body = vertical_gradient(tile_w, tile_h, SIDE_HI, SIDE_LO)
    # Тёплый торец темнеет к правому нижнему углу.
    shade = Image.new("RGBA", (tile_w, tile_h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.polygon(
        [(int(tile_w * 0.55), 0), (tile_w, 0), (tile_w, tile_h), (int(tile_w * 0.2), tile_h)],
        fill=(*SIDE_LO, 90),
    )
    body.alpha_composite(shade)
    body.putalpha(rounded_mask(tile_w, tile_h, radius))

    face_w = max(1, round(tile_w * (1 - 0.11)))
    face_h = max(1, round(tile_h * (1 - 0.13)))
    face = vertical_gradient(face_w, face_h, FACE_HI, FACE_LO)
    highlight = Image.new("RGBA", (face_w, face_h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    hd.ellipse(
        [-face_w * 0.15, -face_h * 0.2, face_w * 0.55, face_h * 0.45],
        fill=(255, 255, 255, 48),
    )
    face.alpha_composite(highlight)
    face.putalpha(rounded_mask(face_w, face_h, face_r))
    body.alpha_composite(face, (0, 0))

    draw = ImageDraw.Draw(body)
    stroke = max(2, round(tile_w * 0.02))
    draw.rounded_rectangle(
        [1, 1, tile_w - 2, tile_h - 2],
        radius=radius,
        outline=(*STROKE, 200),
        width=stroke,
    )
    draw.rounded_rectangle(
        [3, 3, face_w - 4, face_h - 4],
        radius=max(2, face_r - 2),
        outline=(255, 251, 239, 70),
        width=max(1, stroke // 3),
    )
    return body


def compose_tile(body: Image.Image, fruit: Image.Image, *, soft: bool = False) -> Image.Image:
    tile = body.copy()
    src = soften(fruit) if soft else fruit
    resample = Image.Resampling.BILINEAR if soft else Image.Resampling.LANCZOS
    x, y, w, h = symbol_box(tile.width, tile.height)
    tile.alpha_composite(fit_symbol(src, w, h, resample), (x, y))
    if soft:
        mask = tile.getchannel("A")
        tile = soften(tile)
        tile.putalpha(mask)
    return tile


def shadow_sprite(tile_w: int, tile_h: int) -> Image.Image:
    pad = max(6, tile_w // 6)
    image = Image.new("RGBA", (tile_w + pad, tile_h + pad), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        [pad // 4, pad // 3, tile_w, tile_h],
        radius=max(3, int(tile_w * 0.14)),
        fill=(32, 14, 4, 110),
    )
    return image.filter(ImageFilter.GaussianBlur(radius=max(1.2, tile_w * 0.035)))


def load_fruits() -> list[Image.Image]:
    return [
        Image.open(ASSETS / "titles" / "fruit" / f"{i:02d}.png").convert("RGBA")
        for i in range(1, 21)
    ]


def paste_clipped(
    dest: Image.Image,
    sprite: Image.Image,
    x: int,
    y: int,
    clip: tuple[int, int, int, int],
) -> None:
    cl, ct, cr, cb = clip
    sx0 = max(0, cl - x)
    sy0 = max(0, ct - y)
    sx1 = min(sprite.width, cr - x)
    sy1 = min(sprite.height, cb - y)
    if sx1 <= sx0 or sy1 <= sy0:
        return
    dest.alpha_composite(sprite.crop((sx0, sy0, sx1, sy1)), (x + sx0, y + sy0))


def circle_button(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int, icon: str) -> None:
    draw.ellipse([cx - r - 2, cy - r + 2, cx + r + 2, cy + r + 4], fill=(0, 0, 0, 70))
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(180, 104, 40, 255))
    draw.ellipse(
        [cx - r + 3, cy - r + 3, cx + r - 3, cy + int(r * 0.15)],
        fill=(224, 154, 74, 255),
    )
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(240, 200, 136, 255), width=max(2, r // 14))
    ink = (255, 248, 236, 255)
    arm = max(2, r // 7)
    if icon == "back":
        draw.line([(cx + r * 0.28, cy), (cx - r * 0.22, cy)], fill=ink, width=arm)
        draw.line(
            [(cx - r * 0.05, cy - r * 0.28), (cx - r * 0.32, cy), (cx - r * 0.05, cy + r * 0.28)],
            fill=ink,
            width=arm,
        )
    elif icon == "menu":
        for dy in (-0.28, 0.0, 0.28):
            draw.line(
                [(cx - r * 0.34, cy + r * dy), (cx + r * 0.34, cy + r * dy)],
                fill=ink,
                width=arm,
            )
    elif icon == "shuffle":
        draw.arc([cx - r * 0.42, cy - r * 0.46, cx + r * 0.2, cy + r * 0.05], 200, 20, fill=ink, width=arm)
        draw.arc([cx - r * 0.2, cy - r * 0.05, cx + r * 0.42, cy + r * 0.46], 20, 200, fill=ink, width=arm)
    elif icon == "magnet":
        draw.arc([cx - r * 0.38, cy - r * 0.42, cx + r * 0.38, cy + r * 0.28], 200, 340, fill=ink, width=arm + 1)
        draw.line([(cx - r * 0.38, cy), (cx - r * 0.38, cy + r * 0.28)], fill=(226, 59, 59, 255), width=arm + 1)
        draw.line([(cx + r * 0.38, cy), (cx + r * 0.38, cy + r * 0.28)], fill=(226, 59, 59, 255), width=arm + 1)
    elif icon == "hint":
        draw.ellipse(
            [cx - r * 0.18, cy - r * 0.4, cx + r * 0.18, cy - r * 0.04],
            outline=ink,
            width=arm,
        )
        draw.line([(cx - r * 0.1, cy), (cx - r * 0.06, cy + r * 0.18)], fill=ink, width=arm)
        draw.line([(cx + r * 0.1, cy), (cx + r * 0.06, cy + r * 0.18)], fill=ink, width=arm)
        draw.line([(cx - r * 0.08, cy + r * 0.28), (cx + r * 0.08, cy + r * 0.28)], fill=ink, width=arm)
    elif icon == "undo":
        draw.arc(
            [cx - r * 0.34, cy - r * 0.34, cx + r * 0.38, cy + r * 0.34],
            120,
            400,
            fill=ink,
            width=arm,
        )
        draw.polygon(
            [
                (cx - r * 0.42, cy - r * 0.02),
                (cx - r * 0.08, cy - r * 0.2),
                (cx - r * 0.08, cy + r * 0.16),
            ],
            fill=ink,
        )


def badge(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, fnt: ImageFont.ImageFont) -> None:
    r = max(11, S * 11)
    draw.ellipse([x - r, y - r, x + r, y + r], fill=(226, 59, 59, 255), outline=(255, 243, 192, 255), width=2)
    draw.text((x, y), text, font=fnt, fill=(255, 255, 255, 255), anchor="mm")


def draw_hud(draw: ImageDraw.ImageDraw) -> int:
    top = int(36 * S)
    r = int(20 * S)
    y = top + int(24 * S)
    circle_button(draw, int(28 * S), y, r, "back")
    circle_button(draw, int((PHONE_W - 28) * S), y, r, "menu")
    return top + int(48 * S)


def draw_tray(screen: Image.Image, tiles: list[Image.Image], top: int) -> int:
    slot_h = tiles[0].height if tiles else int(round(46 * ASPECT * S))
    height = slot_h + int(16 * S)
    margin = int(18 * S)
    well = [margin, top + int(2 * S), int(PHONE_W * S) - margin, top + height - int(4 * S)]
    overlay = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rounded_rectangle(well, radius=int(16 * S), fill=TRAY)
    screen.alpha_composite(overlay)
    inner_w = well[2] - well[0]
    slot_w = tiles[0].width
    gap = (inner_w - 4 * slot_w) // 5
    for i, sprite in enumerate(tiles):
        x = well[0] + gap + i * (slot_w + gap)
        y = well[1] + (well[3] - well[1] - sprite.height) // 2
        screen.alpha_composite(sprite, (x, y))
    return top + height


def draw_actions(screen: Image.Image, top: int) -> None:
    draw = ImageDraw.Draw(screen)
    icons = ["shuffle", "magnet", "hint", "undo"]
    labels = ["3", "2", "1", "5"]
    size = int(56 * S)
    gap = int(22 * S)
    total = 4 * size + 3 * gap
    x0 = (screen.width - total) // 2 + size // 2
    y = top + int(8 * S) + size // 2
    fnt = font(int(12 * S), bold=True)
    for i, icon in enumerate(icons):
        cx = x0 + i * (size + gap)
        circle_button(draw, cx, y, size // 2, icon)
        badge(draw, cx + size // 2 - int(6 * S), y - size // 2 + int(6 * S), labels[i], fnt)


def render_phone(
    *,
    backdrop: Image.Image,
    sprites: list[Image.Image],
    shade: Image.Image,
    tray_sprites: list[Image.Image],
    tiles: list[tuple[int, int, int, int]],
    metrics: dict[str, float],
    board_left: float,
    board_top: float,
) -> Image.Image:
    screen = backdrop.copy()
    hud_bottom = draw_hud(ImageDraw.Draw(screen))
    tray_bottom = draw_tray(screen, tray_sprites, hud_bottom)
    clip = (0, tray_bottom - int(4 * S), screen.width, screen.height)
    scale = metrics["scale"]
    for x, y, z, symbol in tiles:
        px, py = tile_pos(x, y, z, metrics)
        sx = round((board_left + px) * S)
        sy = round((board_top + py) * S)
        shift = (4 + z * 3) * scale * S * 0.45
        paste_clipped(screen, shade, round(sx + shift * 0.35), round(sy + shift), clip)
        paste_clipped(screen, sprites[symbol], sx, sy, clip)
    return screen


def phone_frame(screen: Image.Image) -> Image.Image:
    bezel = int(14 * S)
    w = screen.width + bezel * 2
    h = screen.height + bezel * 2
    frame = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle([0, 0, w - 1, h - 1], radius=int(36 * S), fill=(28, 16, 8, 255))
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, screen.width - 1, screen.height - 1],
        radius=int(24 * S),
        fill=255,
    )
    framed = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    framed.paste(screen, (0, 0), mask)
    frame.alpha_composite(framed, (bezel, bezel))
    return frame


def caption(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int, fill, bold=False) -> None:
    draw.text(xy, text, font=font(size, bold), fill=fill, anchor="ma")


def chrome_bands() -> tuple[float, float]:
    safe_top = 36
    hud = 48
    tray = 46 * ASPECT + 16
    action = 4 + 56 + 6 + 10
    tray_bottom = safe_top + hud + tray
    action_top = PHONE_H - 16 - action
    return tray_bottom, action_top


def render_table(fruits: list[Image.Image]) -> None:
    tiles = dragon_tiles()
    tile_w = fit_tile_w(PHONE_W - 8)
    now_metrics = board_metrics(tile_w, 1.0)
    now_left, now_top_b, now_right, now_bottom = visual_bounds(tiles, now_metrics)
    now_w = now_right - now_left
    now_h = now_bottom - now_top_b

    big_w = tile_w * 1.3
    usable_w = PHONE_W - 4
    big_gap = gap_to_fit(tiles, big_w, usable_w)
    big_metrics = board_metrics(big_w, big_gap)
    big_left, big_top_b, big_right, big_bottom = visual_bounds(tiles, big_metrics)
    big_visual_w = big_right - big_left
    big_visual_h = big_bottom - big_top_b

    tray_bottom, action_top = chrome_bands()
    now_board_top = tray_bottom + (action_top - tray_bottom - now_h) / 2 - now_top_b
    now_board_left = (PHONE_W - now_w) / 2 - now_left
    # Крупное поле упирается в лоток и остаётся внутри экрана.
    big_board_top = tray_bottom + 2 - big_top_b
    big_board_left = (PHONE_W - big_visual_w) / 2 - big_left
    print(
        f"now tile {tile_w:.1f} visual {now_w:.0f}x{now_h:.0f} "
        f"big tile {big_w:.1f} gap {big_gap:.3f} visual {big_visual_w:.0f}x{big_visual_h:.0f}"
    )

    pw, ph = int(PHONE_W * S), int(PHONE_H * S)
    backdrop = premium_backdrop(pw, ph)
    tray_body = premium_body(int(46 * S))
    tray_sprites = [compose_tile(tray_body, fruits[0]), compose_tile(tray_body, fruits[4])]

    def phone(metrics: dict[str, float], board_left: float, board_top: float) -> Image.Image:
        px = max(1, round(metrics["tile_w"] * S))
        body = premium_body(px)
        screen = render_phone(
            backdrop=backdrop,
            sprites=[compose_tile(body, fruit) for fruit in fruits],
            shade=shadow_sprite(body.width, body.height),
            tray_sprites=tray_sprites,
            tiles=tiles,
            metrics=metrics,
            board_left=board_left,
            board_top=board_top,
        )
        draw_actions(screen, int(action_top * S))
        return phone_frame(screen)

    now = phone(now_metrics, now_board_left, now_board_top)
    bigger = phone(big_metrics, big_board_left, big_board_top)

    gap_x = 64
    title_h = 168
    foot_h = 160
    canvas = Image.new(
        "RGB",
        (gap_x + now.width + gap_x + bigger.width + gap_x, title_h + now.height + foot_h),
        (244, 240, 232),
    )
    draw = ImageDraw.Draw(canvas)
    caption(draw, (canvas.width // 2, 34), "Новая тема", 42, (40, 32, 24), bold=True)
    caption(
        draw,
        (canvas.width // 2, 88),
        "Раскладка «дракон»: кости на стыках, дыры раскладки на месте",
        22,
        (90, 78, 64),
    )
    caption(
        draw,
        (canvas.width // 2, 122),
        f"Справа кость +30% ({big_w:.0f} px), шаг {big_gap:.2f}, чтобы войти в экран",
        20,
        (90, 78, 64),
    )
    y = title_h
    canvas.paste(now, (gap_x, y), now)
    canvas.paste(bigger, (gap_x + now.width + gap_x, y), bigger)
    left_cx = gap_x + now.width // 2
    right_cx = gap_x + now.width + gap_x + bigger.width // 2
    label_y = y + now.height + 24
    caption(draw, (left_cx, label_y), "Сейчас", 32, (40, 32, 24), bold=True)
    caption(draw, (left_cx, label_y + 42), f"кость {tile_w:.0f} px, поле по центру", 20, (90, 78, 64))
    caption(draw, (right_cx, label_y), "Плитки +30%", 32, (40, 32, 24), bold=True)
    caption(draw, (right_cx, label_y + 42), "верх у лотка, целиком на экране", 20, (90, 78, 64))
    canvas.save(OUT / "table-plus-30.png", quality=95)
    print("wrote", OUT / "table-plus-30.png")


def render_sharpness(fruits: list[Image.Image]) -> None:
    tile_w = 460
    body = premium_body(tile_w)
    soft = compose_tile(body, fruits[0], soft=True)
    sharp = compose_tile(body, fruits[0], soft=False)

    def zoom(tile: Image.Image) -> Image.Image:
        x, y, w, h = symbol_box(tile.width, tile.height)
        crop = tile.crop((x + int(w * 0.08), y + int(h * 0.06), x + int(w * 0.58), y + int(h * 0.46)))
        return crop.resize((crop.width * 2, crop.height * 2), Image.Resampling.NEAREST)

    soft_z = zoom(soft)
    sharp_z = zoom(sharp)
    pad = 48
    col_w = max(tile_w, soft_z.width) + 80
    width = pad + col_w + 40 + col_w + pad
    top = 150
    ztop = top + soft.height + 28
    foot = ztop + soft_z.height + 24
    height = foot + 90
    canvas = Image.new("RGB", (width, height), (244, 240, 232))
    draw = ImageDraw.Draw(canvas)
    caption(draw, (width // 2, 36), "Кость новой темы", 40, (40, 32, 24), bold=True)
    caption(
        draw,
        (width // 2, 92),
        "Слева растр растянут второй раз, справа символ сразу в размер грани",
        22,
        (90, 78, 64),
    )
    canvas.paste(soft, (pad + (col_w - tile_w) // 2, top), soft)
    canvas.paste(sharp, (pad + col_w + 40 + (col_w - tile_w) // 2, top), sharp)
    canvas.paste(soft_z, (pad + (col_w - soft_z.width) // 2, ztop))
    canvas.paste(sharp_z, (pad + col_w + 40 + (col_w - sharp_z.width) // 2, ztop))
    caption(draw, (pad + col_w // 2, foot), "Мягко", 30, (40, 32, 24), bold=True)
    caption(draw, (pad + col_w // 2, foot + 40), "сначала мелкая копия, потом увеличение", 18, (90, 78, 64))
    caption(draw, (pad + col_w + 40 + col_w // 2, foot), "Резко", 30, (40, 32, 24), bold=True)
    caption(
        draw,
        (pad + col_w + 40 + col_w // 2, foot + 40),
        "один раз из исходника в размер экрана",
        18,
        (90, 78, 64),
    )
    canvas.save(OUT / "tile-sharp.png", quality=95)
    print("wrote", OUT / "tile-sharp.png")


def main() -> None:
    fruits = load_fruits()
    render_table(fruits)
    render_sharpness(fruits)


if __name__ == "__main__":
    main()
