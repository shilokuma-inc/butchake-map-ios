#!/usr/bin/env python3
"""アプリアイコンの候補（30 案）の SVG と、比べるための一覧の SVG を書き出す。

  python3 design/app-icon/scripts/make_candidates.py

- 候補: design/app-icon/candidates/NN.svg（1024×1024。角丸は iOS がかけるので描かず、背景は全面に敷く）
- 一覧: build/app-icon/sheets/*.svg（ホーム画面の角丸をかけて並べたもの。export_png.sh が PNG にする）

標準ライブラリだけで動く。文字は glyphs.json（extract_glyphs.sh で OFL の書体から取り出したアウトライン）を
パスで埋め込むので、端末やフォントの有無で見た目が変わらない。
"""

import json
import math
import os

SIZE = 1024
C = SIZE / 2

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.dirname(SCRIPTS_DIR)
REPO_DIR = os.path.dirname(os.path.dirname(ICON_DIR))
CANDIDATES_DIR = os.path.join(ICON_DIR, "candidates")
SHEETS_DIR = os.path.join(REPO_DIR, "build", "app-icon", "sheets")

with open(os.path.join(ICON_DIR, "glyphs.json"), encoding="utf-8") as file:
    GLYPHS = json.load(file)

# ポップ＆ツッコミ（A）
ORANGE = "#FF7A1A"
YELLOW = "#FFD23F"
INK = "#1A1A1A"
WHITE = "#FFFFFF"
PINK = "#FF5C8A"
RED = "#F2433D"
# レトロ観光パンフ（B）
CREAM = "#F4E8CF"
PAPER = "#FBF4E4"
VERMILION = "#D9482B"
NAVY = "#1E3557"
MUSTARD = "#E3A72F"
TEAL = "#2F7F79"
BROWN = "#6B3E26"
# シンプル（今のブランドカラー）
BLUE = "#2B6CB0"
BLUE_DARK = "#1F4F85"
BLUE_LIGHT = "#63A4E8"
BLUE_PALE = "#DCEBFA"
BRAND_ORANGE = "#DD6B20"
BRAND_ORANGE_LIGHT = "#F08A4B"


# ---------------------------------------------------------------------------
# 数値・乱数


def n(value):
    """座標を小数 1 桁の文字列にする（末尾の 0 は落とす）"""
    text = f"{value:.1f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def pt(x, y):
    return f"{n(x)} {n(y)}"


class Random:
    """案ごとに同じ結果になる疑似乱数（線形合同法）"""

    def __init__(self, seed):
        self.state = seed

    def next(self):
        self.state = (self.state * 1103515245 + 12345) % 2147483648
        return self.state / 2147483648

    def uniform(self, low, high):
        return low + (high - low) * self.next()


# ---------------------------------------------------------------------------
# 形（SVG の d 属性）


def circle_d(cx, cy, r):
    return f"M{pt(cx - r, cy)}A{n(r)} {n(r)} 0 1 0 {pt(cx + r, cy)}A{n(r)} {n(r)} 0 1 0 {pt(cx - r, cy)}Z"


def ellipse_d(cx, cy, rx, ry):
    return f"M{pt(cx - rx, cy)}A{n(rx)} {n(ry)} 0 1 0 {pt(cx + rx, cy)}A{n(rx)} {n(ry)} 0 1 0 {pt(cx - rx, cy)}Z"


def rect_d(x, y, w, h, r=0):
    if r <= 0:
        return f"M{pt(x, y)}H{n(x + w)}V{n(y + h)}H{n(x)}Z"
    return (
        f"M{pt(x + r, y)}H{n(x + w - r)}A{n(r)} {n(r)} 0 0 1 {pt(x + w, y + r)}V{n(y + h - r)}"
        f"A{n(r)} {n(r)} 0 0 1 {pt(x + w - r, y + h)}H{n(x + r)}A{n(r)} {n(r)} 0 0 1 {pt(x, y + h - r)}"
        f"V{n(y + r)}A{n(r)} {n(r)} 0 0 1 {pt(x + r, y)}Z"
    )


def polygon_d(points):
    return "M" + "L".join(pt(x, y) for x, y in points) + "Z"


def pin_d(cx, cy, r, tip, tip_round=16):
    """地図のピン。頭の円（中心 cx, cy・半径 r）から、真下の tip（y 座標）に向かって細くなる"""
    distance = tip - cy
    phi = math.acos(r / distance)
    ax, ay = cx + r * math.sin(phi), cy + r * math.cos(phi)
    bx, by = cx - r * math.sin(phi), ay

    def toward(px, py):
        length = math.hypot(px - cx, py - tip)
        return cx + (px - cx) * tip_round / length, tip + (py - tip) * tip_round / length

    t1, t2 = toward(ax, ay), toward(bx, by)
    return (
        f"M{pt(*t1)}L{pt(ax, ay)}A{n(r)} {n(r)} 0 1 0 {pt(bx, by)}L{pt(*t2)}"
        f"Q{pt(cx, tip)} {pt(*t1)}Z"
    )


def bubble_rect_d(x, y, w, h, r, tail_left, tail_right, tip_x, tip_y):
    """角丸の四角の吹き出し。しっぽは下の辺（tail_left〜tail_right）から (tip_x, tip_y) に伸びる"""
    return (
        f"M{pt(x + r, y)}H{n(x + w - r)}A{n(r)} {n(r)} 0 0 1 {pt(x + w, y + r)}V{n(y + h - r)}"
        f"A{n(r)} {n(r)} 0 0 1 {pt(x + w - r, y + h)}H{n(tail_right)}L{pt(tip_x, tip_y)}L{pt(tail_left, y + h)}"
        f"H{n(x + r)}A{n(r)} {n(r)} 0 0 1 {pt(x, y + h - r)}V{n(y + r)}A{n(r)} {n(r)} 0 0 1 {pt(x + r, y)}Z"
    )


def bubble_ellipse_d(cx, cy, rx, ry, angle1, angle2, tip_x, tip_y):
    """楕円の吹き出し。しっぽは楕円の angle1〜angle2 度（右から時計回り）の間から (tip_x, tip_y) に伸びる"""
    a1, a2 = math.radians(angle1), math.radians(angle2)
    p1 = (cx + rx * math.cos(a1), cy + ry * math.sin(a1))
    p2 = (cx + rx * math.cos(a2), cy + ry * math.sin(a2))
    return f"M{pt(*p2)}A{n(rx)} {n(ry)} 0 1 1 {pt(*p1)}L{pt(tip_x, tip_y)}Z"


def star_d(cx, cy, outer, inner, points=5, rotation=-90):
    vertices = []
    for i in range(points * 2):
        radius = outer if i % 2 == 0 else inner
        angle = math.radians(rotation + 180 * i / points)
        vertices.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return polygon_d(vertices)


def spiky_d(cx, cy, outer, inner, points, seed, sx=1.0):
    """叫びの吹き出し（ギザギザ）。とげの長さを少しずつ変える"""
    rnd = Random(seed)
    vertices = []
    for i in range(points * 2):
        base = outer if i % 2 == 0 else inner
        radius = base * rnd.uniform(0.92, 1.06) if i % 2 == 0 else base * rnd.uniform(0.96, 1.03)
        angle = math.radians(-90 + 180 * i / points + rnd.uniform(-3, 3))
        vertices.append((cx + radius * math.cos(angle) * sx, cy + radius * math.sin(angle)))
    return polygon_d(vertices)


def sparkle_d(cx, cy, r):
    """4 つの角のきらめき"""
    return (
        f"M{pt(cx, cy - r)}Q{pt(cx, cy)} {pt(cx + r, cy)}Q{pt(cx, cy)} {pt(cx, cy + r)}"
        f"Q{pt(cx, cy)} {pt(cx - r, cy)}Q{pt(cx, cy)} {pt(cx, cy - r)}Z"
    )


def rays_d(cx, cy, count, inner, outer, width_deg, seed=None, offset=0):
    """中心から放射状に伸びる三角形（集中線・サンバースト）"""
    rnd = Random(seed) if seed is not None else None
    parts = []
    for i in range(count):
        angle = offset + 360 * i / count
        width = width_deg
        start = inner
        if rnd:
            angle += rnd.uniform(-2, 2)
            width = width_deg * rnd.uniform(0.5, 1.4)
            start = inner * rnd.uniform(0.85, 1.25)
        a = math.radians(angle)
        a1, a2 = math.radians(angle - width / 2), math.radians(angle + width / 2)
        parts.append(polygon_d([
            (cx + start * math.cos(a), cy + start * math.sin(a)),
            (cx + outer * math.cos(a1), cy + outer * math.sin(a1)),
            (cx + outer * math.cos(a2), cy + outer * math.sin(a2)),
        ]))
    return "".join(parts)


# ---------------------------------------------------------------------------
# 描画の部品


def path(d, **attributes):
    attrs = "".join(f' {key.replace("_", "-")}="{value}"' for key, value in attributes.items())
    return f'<path d="{d}"{attrs}/>'


def group(content, transform=None, **attributes):
    attrs = f' transform="{transform}"' if transform else ""
    attrs += "".join(f' {key.replace("_", "-")}="{value}"' for key, value in attributes.items())
    return f"<g{attrs}>{content}</g>"


def rotate(angle, cx=C, cy=C):
    return f"rotate({n(angle)} {n(cx)} {n(cy)})"


def background(fill):
    return f'<rect width="{SIZE}" height="{SIZE}" fill="{fill}"/>'


def layered(ds, fill, line=None, thickness=0, border=None, border_width=0, shadow=None, shadow_offset=(0, 0)):
    """形に太い輪郭線・ステッカーの白い縁・ずらした影を付ける。
    輪郭線は形の外側に thickness だけ出る（線を先に描き、同じ形の塗りを上に重ねる）。
    ds は 1 つの形として扱う d の一覧（重なった部分の線は塗りで隠れる）"""
    ds = ds if isinstance(ds, list) else [ds]
    layers = []
    stroke_width = thickness * 2

    def paths(fill_value, stroke_value=None, width=0):
        stroke = f' stroke="{stroke_value}" stroke-width="{n(width)}" stroke-linejoin="round"' if stroke_value else ""
        return "".join(f'<path d="{d}" fill="{fill_value}"{stroke}/>' for d in ds)

    if shadow:
        dx, dy = shadow_offset
        width = stroke_width + border_width * 2
        layers.append(group(paths(shadow, shadow if width else None, width), f"translate({n(dx)} {n(dy)})"))
    if border:
        layers.append(paths(border, border, stroke_width + border_width * 2))
    if line:
        layers.append(paths(line, line, stroke_width))
    layers.append(paths(fill))
    return "".join(layers)


def glyph_run(font, text, cx, cy, size, gap=0, vertical=False, fill=INK, line=None, thickness=0, border=None,
              border_width=0):
    """glyphs.json の文字を、字面の中心が (cx, cy) に来るように並べる。size は 1em の大きさ（px）"""
    data = GLYPHS[font]
    scale = size / data["unitsPerEm"]
    glyphs = [data["glyphs"][character] for character in text]
    boxes = [glyph["bbox"] for glyph in glyphs]
    placements = []
    if vertical:
        heights = [(box[3] - box[1]) * scale for box in boxes]
        cursor = cy - (sum(heights) + gap * (len(glyphs) - 1)) / 2
        for glyph, box, height in zip(glyphs, boxes, heights):
            tx = cx - (box[0] + box[2]) / 2 * scale
            ty = cursor - box[1] * scale
            placements.append((glyph, tx, ty))
            cursor += height + gap
    else:
        widths = [(box[2] - box[0]) * scale for box in boxes]
        top = min(box[1] for box in boxes)
        bottom = max(box[3] for box in boxes)
        ty = cy - (top + bottom) / 2 * scale
        cursor = cx - (sum(widths) + gap * (len(glyphs) - 1)) / 2
        for glyph, box, width in zip(glyphs, boxes, widths):
            placements.append((glyph, cursor - box[0] * scale, ty))
            cursor += width + gap

    layers = []
    for paint, width in ((border, thickness + border_width), (line, thickness)):
        if paint and width:
            stroke = f' stroke="{paint}" stroke-width="{n(width * 2 / scale)}" stroke-linejoin="round"'
            layers.append("".join(
                f'<path d="{glyph["d"]}" transform="translate({n(tx)} {n(ty)}) scale({scale:.4f})" fill="{paint}"{stroke}/>'
                for glyph, tx, ty in placements
            ))
    layers.append("".join(
        f'<path d="{glyph["d"]}" transform="translate({n(tx)} {n(ty)}) scale({scale:.4f})" fill="{fill}"/>'
        for glyph, tx, ty in placements
    ))
    return "".join(layers)


def linear_gradient(gid, stops, x1=0, y1=0, x2=0, y2=1):
    stop_tags = "".join(f'<stop offset="{offset}" stop-color="{color}"/>' for offset, color in stops)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stop_tags}</linearGradient>'


def radial_gradient(gid, stops, cx=0.5, cy=0.5, r=0.7):
    stop_tags = "".join(f'<stop offset="{offset}" stop-color="{color}"/>' for offset, color in stops)
    return f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{stop_tags}</radialGradient>'


def dots_pattern(pid, color, opacity, spacing, radius):
    return (
        f'<pattern id="{pid}" width="{spacing}" height="{spacing}" patternUnits="userSpaceOnUse">'
        f'<circle cx="{spacing / 2}" cy="{spacing / 2}" r="{radius}" fill="{color}" fill-opacity="{opacity}"/>'
        f"</pattern>"
    )


def soft_shadow_filter(fid, blur=18, dy=14, opacity=0.28):
    return (
        f'<filter id="{fid}" x="-30%" y="-30%" width="160%" height="160%">'
        f'<feDropShadow dx="0" dy="{dy}" stdDeviation="{blur}" flood-color="#000" flood-opacity="{opacity}"/></filter>'
    )


def speckle_mask(mid, seed, x, y, w, h, count, r_min, r_max):
    """インクのかすれ（スタンプ・印）。白い四角に黒い点を散らしたマスク"""
    rnd = Random(seed)
    dots = "".join(
        f'<circle cx="{n(rnd.uniform(x, x + w))}" cy="{n(rnd.uniform(y, y + h))}" r="{n(rnd.uniform(r_min, r_max))}" fill="#000"/>'
        for _ in range(count)
    )
    return (
        f'<mask id="{mid}" maskUnits="userSpaceOnUse" x="-200" y="-200" width="1424" height="1424">'
        f'<rect x="-200" y="-200" width="1424" height="1424" fill="#fff"/>{dots}</mask>'
    )


def dot_trio(cx, cy, spacing, r, fill):
    return "".join(path(circle_d(cx + spacing * i, cy, r), fill=fill) for i in (-1, 0, 1))


# ---------------------------------------------------------------------------
# A. ポップ＆ツッコミ（01〜10）


def c01(p):
    """吹き出しの形のピンに「！」"""
    defs = radial_gradient(f"{p}bg", [(0, "#FFA040"), (1, "#FF6A00")], cy=0.4, r=0.75)
    bubble = bubble_rect_d(232, 190, 560, 480, 160, 440, 584, 512, 860)
    body = background(f"url(#{p}bg)")
    body += group(
        layered(bubble, WHITE, INK, 26, shadow=INK, shadow_offset=(22, 22))
        + glyph_run("dela", "!", 512, 430, 400, fill=ORANGE, line=INK, thickness=14),
        rotate(-6),
    )
    body += path(sparkle_d(206, 190, 62), fill=YELLOW, stroke=INK, stroke_width=12, stroke_linejoin="round")
    body += path(sparkle_d(842, 742, 46), fill=YELLOW, stroke=INK, stroke_width=10, stroke_linejoin="round")
    return defs, body


def c02(p):
    """楕円の吹き出しに「ぶ」"""
    defs = dots_pattern(f"{p}dots", "#FF8A00", 0.45, 46, 8)
    bubble = bubble_ellipse_d(520, 470, 352, 292, 112, 136, 214, 884)
    body = background(YELLOW) + f'<rect width="{SIZE}" height="{SIZE}" fill="url(#{p}dots)"/>'
    body += group(
        layered(bubble, WHITE, INK, 26)
        + glyph_run("dela", "ぶ", 528, 474, 440, fill=INK),
        rotate(-5),
    )
    return defs, body


def c03(p):
    """ステッカー風のピンと星"""
    defs = radial_gradient(f"{p}bg", [(0, "#7FDDF0"), (1, "#25AFCB")], cy=0.35, r=0.8)
    pin = pin_d(512, 420, 236, 870, 22)
    body = background(f"url(#{p}bg)")
    body += group(
        layered(pin, ORANGE, INK, 24, border=WHITE, border_width=36)
        + path(circle_d(512, 420, 94), fill=WHITE, stroke=INK, stroke_width=24)
        + path("M362 330 Q392 268 452 246", fill="none", stroke=WHITE, stroke_width=26, stroke_linecap="round",
               opacity="0.85"),
        rotate(10, 512, 560),
    )
    body += group(
        layered(star_d(792, 236, 116, 52), YELLOW, INK, 16, border=WHITE, border_width=22),
        rotate(14, 792, 236),
    )
    return defs, body


def c04(p):
    """表彰台（1・2・3）の上にピン"""
    defs = linear_gradient(f"{p}bg", [(0, "#FF9A3D"), (1, "#FF6A00")])
    body = background(f"url(#{p}bg)")
    blocks = [
        (174, 640, 222, 210, WHITE, "2"),
        (628, 700, 222, 150, "#FFB8CC", "3"),
        (396, 560, 232, 290, YELLOW, "1"),
    ]
    for x, y, w, h, color, label in blocks:
        body += layered(rect_d(x, y, w, h, 14), color, INK, 18)
        body += glyph_run("mochiy", label, x + w / 2, y + min(h, 210) / 2 + 6, 150, fill=INK)
    body += layered(pin_d(512, 318, 122, 540, 14), INK, WHITE, 14)
    body += path(circle_d(512, 318, 50), fill=YELLOW)
    body += path(sparkle_d(300, 300, 54), fill=YELLOW, stroke=INK, stroke_width=10, stroke_linejoin="round")
    body += path(sparkle_d(744, 232, 38), fill=WHITE, stroke=INK, stroke_width=9, stroke_linejoin="round")
    return defs, body


def c05(p):
    """王冠をかぶったピン（1 位）"""
    defs = radial_gradient(f"{p}bg", [(0, "#FF8FB0"), (1, "#FF4778")], cy=0.4, r=0.8)
    crown = polygon_d([(372, 372), (346, 196), (446, 268), (512, 150), (578, 268), (678, 196), (652, 372)])
    balls = [circle_d(346, 196, 26), circle_d(512, 150, 28), circle_d(678, 196, 26)]
    body = background(f"url(#{p}bg)")
    body += group(layered([crown] + balls, YELLOW, INK, 20), rotate(-10, 512, 300))
    body += layered(pin_d(512, 566, 214, 920, 20), ORANGE, INK, 24)
    body += path(circle_d(512, 566, 116), fill=WHITE, stroke=INK, stroke_width=20)
    body += glyph_run("mochiy", "1", 512, 572, 190, fill=INK)
    return defs, body


def c06(p):
    """マンガの集中線とピン"""
    body = background(WHITE)
    body += path(rays_d(512, 470, 84, 330, 900, 2.0, seed=6), fill=INK)
    body += layered(pin_d(512, 430, 196, 810, 18), INK, WHITE, 30)
    body += path(circle_d(512, 430, 80), fill=RED)
    return "", body


def c07(p):
    """「三」のステッカー"""
    defs = dots_pattern(f"{p}dots", WHITE, 0.25, 52, 9)
    body = background(ORANGE) + f'<rect width="{SIZE}" height="{SIZE}" fill="url(#{p}dots)"/>'
    body += group(
        layered(rect_d(232, 232, 560, 560, 120), YELLOW, INK, 26, border=WHITE, border_width=36, shadow="#C24E00",
                shadow_offset=(18, 24))
        + glyph_run("dela", "三", 512, 516, 400, fill=INK),
        rotate(-8),
    )
    return defs, body


def c08(p):
    """1・2・3 の 3 本のピン"""
    defs = radial_gradient(f"{p}bg", [(0, "#79DCEF"), (1, "#22ABC7")], cy=0.4, r=0.8)
    body = background(f"url(#{p}bg)")
    pins = [
        (252, 540, 132, 830, YELLOW, "2", -14),
        (772, 540, 132, 830, PINK, "3", 14),
        (512, 420, 170, 800, ORANGE, "1", 0),
    ]
    for cx, cy, r, tip, color, label, angle in pins:
        body += group(
            layered(pin_d(cx, cy, r, tip, 14), color, INK, 20, shadow=INK, shadow_offset=(14, 14))
            + path(circle_d(cx, cy, r * 0.6), fill=WHITE, stroke=INK, stroke_width=16)
            + glyph_run("mochiy", label, cx, cy + 4, r * 0.95, fill=INK),
            rotate(angle, cx, cy + r),
        )
    return defs, body


def c09(p):
    """ネオブルータリズムの極太「3」とピン"""
    grid = "".join(
        f'<path d="M{v} 0V{SIZE}M0 {v}H{SIZE}" stroke="{INK}" stroke-opacity="0.08" stroke-width="4"/>'
        for v in range(64, SIZE, 128)
    )
    body = background(YELLOW) + grid
    body += group(glyph_run("dela", "3", 470, 560, 720, fill=INK, line=INK, thickness=20), "translate(30 30)")
    body += glyph_run("dela", "3", 470, 560, 720, fill=ORANGE, line=INK, thickness=20)
    body += group(
        layered(pin_d(778, 262, 104, 440, 14), INK, WHITE, 22, shadow=INK, shadow_offset=(12, 12))
        + path(circle_d(778, 262, 42), fill=YELLOW),
        rotate(16, 778, 340),
    )
    return "", body


def c10(p):
    """叫びの吹き出しに「!?」"""
    body = background(RED)
    body += path(rays_d(512, 512, 20, 0, 900, 9, offset=4), fill="#FF6A5C", fill_opacity="0.55")
    body += layered(spiky_d(512, 506, 410, 318, 16, seed=10, sx=1.02), YELLOW, INK, 24)
    body += glyph_run("dela", "!?", 512, 512, 360, gap=6, fill=INK)
    return "", body


# ---------------------------------------------------------------------------
# B. レトロ観光パンフ（11〜20）


def c11(p):
    """切手（ミシン目）の中に山とピン"""
    x, y, w, h = 222, 182, 580, 660
    holes = []
    step = 52
    for i in range(int(w / step) + 1):
        holes.append(f'<circle cx="{n(x + i * w / int(w / step))}" cy="{y}" r="20" fill="#000"/>')
        holes.append(f'<circle cx="{n(x + i * w / int(w / step))}" cy="{y + h}" r="20" fill="#000"/>')
    for i in range(int(h / step) + 1):
        holes.append(f'<circle cx="{x}" cy="{n(y + i * h / int(h / step))}" r="20" fill="#000"/>')
        holes.append(f'<circle cx="{x + w}" cy="{n(y + i * h / int(h / step))}" r="20" fill="#000"/>')
    defs = (
        f'<mask id="{p}perf" maskUnits="userSpaceOnUse" x="0" y="0" width="{SIZE}" height="{SIZE}">'
        f'<rect width="{SIZE}" height="{SIZE}" fill="#fff"/>{"".join(holes)}</mask>'
        + f'<clipPath id="{p}frame"><rect x="{x + 52}" y="{y + 52}" width="{w - 104}" height="{h - 104}"/></clipPath>'
        + soft_shadow_filter(f"{p}shadow", 14, 10, 0.35)
    )
    inner = (
        f'<rect x="{x + 52}" y="{y + 52}" width="{w - 104}" height="{h - 104}" fill="{CREAM}"/>'
        + path(circle_d(640, 330, 70), fill=MUSTARD)
        + path(polygon_d([(250, 720), (430, 430), (520, 560), (600, 470), (800, 720)]), fill=NAVY)
        + path(polygon_d([(430, 430), (470, 494), (446, 482), (420, 506), (396, 486)]), fill=PAPER)
        + path("M274 700 Q340 670 406 700 T538 700 T670 700 T802 700V800H274Z", fill=TEAL)
        + layered(pin_d(512, 470, 112, 690, 12), VERMILION, PAPER, 10)
        + path(circle_d(512, 470, 44), fill=PAPER)
    )
    stamp = (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{PAPER}"/>'
        + group(inner, clip_path=f"url(#{p}frame)")
        + f'<rect x="{x + 52}" y="{y + 52}" width="{w - 104}" height="{h - 104}" fill="none" stroke="{VERMILION}" stroke-width="6"/>'
    )
    body = background(NAVY)
    body += group(group(stamp, mask=f"url(#{p}perf)"), rotate(-6), filter=f"url(#{p}shadow)")
    return defs, body


def c12(p):
    """観光スタンプ（二重の円）に「三大」"""
    defs = speckle_mask(f"{p}ink", 12, 140, 140, 744, 744, 260, 2, 9)
    ink = (
        path(circle_d(512, 512, 352), fill="none", stroke=NAVY, stroke_width=26)
        + path(circle_d(512, 512, 304), fill="none", stroke=NAVY, stroke_width=8)
        + glyph_run("antique", "三大", 512, 536, 236, gap=36, fill=NAVY, line=NAVY, thickness=7)
        + layered(pin_d(512, 300, 50, 382, 6), NAVY)
        + path(circle_d(512, 300, 19), fill=CREAM)
        + path(star_d(418, 326, 26, 11), fill=NAVY)
        + path(star_d(606, 326, 26, 11), fill=NAVY)
        + dot_trio(512, 716, 56, 14, NAVY)
    )
    body = background(CREAM)
    body += group(group(ink, mask=f"url(#{p}ink)", opacity="0.93"), rotate(-8))
    return defs, body


def c13(p):
    """朱の角印に「本音」"""
    defs = speckle_mask(f"{p}ink", 13, 230, 200, 564, 624, 220, 2, 8)
    seal = (
        path(rect_d(262, 222, 500, 580, 48), fill=VERMILION)
        + path(rect_d(292, 252, 440, 520, 28), fill="none", stroke=CREAM, stroke_width=12)
        + glyph_run("yuji", "本音", 512, 512, 248, gap=6, vertical=True, fill=CREAM)
    )
    body = background(CREAM)
    body += group(group(seal, mask=f"url(#{p}ink)"), rotate(-4))
    return defs, body


def c14(p):
    """ピンの頭の窓に富士山"""
    defs = (
        f'<clipPath id="{p}window"><circle cx="512" cy="430" r="196"/></clipPath>'
        + soft_shadow_filter(f"{p}shadow", 16, 14, 0.25)
    )
    scenery = (
        f'<rect x="300" y="220" width="424" height="424" fill="#F7DFA8"/>'
        + path(circle_d(600, 350, 56), fill=VERMILION)
        + path(polygon_d([(250, 640), (448, 380), (576, 380), (774, 640)]), fill=NAVY)
        + path(polygon_d([(448, 380), (576, 380), (612, 428), (578, 418), (548, 444), (512, 420), (478, 446),
                          (448, 418), (412, 428)]), fill=PAPER)
        + path("M300 580 Q350 556 400 580 T500 580 T600 580 T700 580 T800 580V660H300Z", fill=TEAL)
    )
    body = background(CREAM)
    body += path(rays_d(512, 430, 24, 0, 900, 7.5), fill=MUSTARD, fill_opacity="0.22")
    body += group(path(pin_d(512, 430, 262, 900, 22), fill=VERMILION), filter=f"url(#{p}shadow)")
    body += path(circle_d(512, 430, 212), fill=PAPER)
    body += group(scenery, clip_path=f"url(#{p}window)")
    return defs, body


def c15(p):
    """旅かばんのラベル（楕円）にピンと星"""
    defs = soft_shadow_filter(f"{p}shadow", 12, 10, 0.4)
    label = (
        path(ellipse_d(512, 512, 384, 286), fill=PAPER)
        + path(ellipse_d(512, 512, 340, 242), fill="none", stroke=VERMILION, stroke_width=34)
        + path(ellipse_d(512, 512, 306, 208), fill="none", stroke=MUSTARD, stroke_width=8)
        + path(pin_d(512, 470, 112, 650, 12), fill=NAVY)
        + path(circle_d(512, 470, 44), fill=PAPER)
        + path(star_d(372, 560, 34, 15), fill=VERMILION)
        + path(star_d(652, 560, 34, 15), fill=VERMILION)
    )
    body = background(NAVY)
    body += path(rect_d(0, 440, SIZE, 60), fill="#27426A")
    body += path(rect_d(0, 524, SIZE, 60), fill="#27426A")
    body += group(group(label, filter=f"url(#{p}shadow)"), rotate(-12))
    return defs, body


def c16(p):
    """荷札に「旅」"""
    defs = soft_shadow_filter(f"{p}shadow", 12, 10, 0.35)
    tag = polygon_d([(372, 250), (652, 250), (742, 340), (742, 880), (282, 880), (282, 340)])
    body = background(TEAL)
    body += path("M512 330 C520 230 640 140 760 40", fill="none", stroke=PAPER, stroke_width=14,
                 stroke_linecap="round", transform=rotate(12, 512, 560))
    body += group(
        group(path(tag, fill=PAPER), filter=f"url(#{p}shadow)")
        + path(circle_d(512, 330, 54), fill=MUSTARD)
        + path(circle_d(512, 330, 30), fill=TEAL)
        + glyph_run("antique", "旅", 512, 592, 300, fill=NAVY)
        + f'<path d="M332 790H692" stroke="{NAVY}" stroke-width="8" stroke-dasharray="20 14"/>'
        + group(
            path(circle_d(656, 740, 72), fill="none", stroke=VERMILION, stroke_width=10)
            + path(pin_d(656, 726, 28, 774, 4), fill=VERMILION),
            rotate(-14, 656, 740), opacity="0.9",
        ),
        rotate(12, 512, 560),
    )
    return defs, body


def c17(p):
    """切符の上に 3 つの駅とピン"""
    defs = (
        f'<mask id="{p}notch" maskUnits="userSpaceOnUse" x="0" y="0" width="{SIZE}" height="{SIZE}">'
        f'<rect width="{SIZE}" height="{SIZE}" fill="#fff"/><circle cx="152" cy="560" r="54" fill="#000"/>'
        f'<circle cx="872" cy="560" r="54" fill="#000"/><circle cx="772" cy="420" r="22" fill="#000"/></mask>'
        + soft_shadow_filter(f"{p}shadow", 12, 10, 0.35)
    )
    ticket = path(rect_d(152, 352, 720, 416, 28), fill=PAPER)
    stations = "".join(
        path(circle_d(x, 640, 40), fill=PAPER, stroke=NAVY, stroke_width=16) for x in (282, 512, 742)
    )
    body = background(VERMILION)
    body += group(
        group(group(ticket, mask=f"url(#{p}notch)"), filter=f"url(#{p}shadow)")
        + f'<path d="M282 640H742" stroke="{NAVY}" stroke-width="20"/>'
        + stations
        + f'<path d="M212 412H552" stroke="{MUSTARD}" stroke-width="24" stroke-linecap="round"/>'
        + f'<path d="M212 462H432" stroke="{MUSTARD}" stroke-width="12" stroke-linecap="round" opacity="0.7"/>'
        + path(pin_d(742, 498, 66, 600, 8), fill=VERMILION)
        + path(circle_d(742, 498, 26), fill=PAPER),
        rotate(-8),
    )
    return defs, body


def c18(p):
    """赤提灯に「三」"""
    defs = (
        radial_gradient(f"{p}glow", [(0, "#7A3328"), (0.55, "#33303F"), (1, "#1B2333")], cy=0.52, r=0.62)
        + radial_gradient(f"{p}body", [(0, "#F0694A"), (0.7, VERMILION), (1, "#A9301C")], cx=0.42, cy=0.42, r=0.7)
    )
    cy, rx, ry = 540, 262, 318
    ribs = ""
    for i in range(-4, 5):
        y = cy + i * 64
        half = rx * math.sqrt(max(0, 1 - ((y - cy) / ry) ** 2))
        ribs += f'<path d="M{n(512 - half)} {n(y)}Q512 {n(y + 26)} {n(512 + half)} {n(y)}" fill="none" stroke="#9E2E1B" stroke-width="7" opacity="0.8"/>'
    body = background(f"url(#{p}glow)")
    body += f'<path d="M512 120V200" stroke="#2A1F1A" stroke-width="14"/>'
    body += path(ellipse_d(512, cy, rx, ry), fill=f"url(#{p}body)")
    body += ribs
    body += path(rect_d(372, 196, 280, 64, 18), fill="#2A1F1A")
    body += path(rect_d(372, 820, 280, 64, 18), fill="#2A1F1A")
    body += glyph_run("antique", "三", 512, 548, 330, fill="#211A17", line="#211A17", thickness=8)
    return defs, body


def c19(p):
    """折り地図とルート（3 つの点とピン）"""
    defs = soft_shadow_filter(f"{p}shadow", 14, 12, 0.3)
    xs = [176, 400, 624, 848]
    tops = [300, 350, 300, 350]
    panels = [
        polygon_d([(xs[i], tops[i]), (xs[i + 1], tops[i + 1]), (xs[i + 1], tops[i + 1] + 430), (xs[i], tops[i] + 430)])
        for i in range(3)
    ]
    body = background(MUSTARD)
    body += group(
        path(panels[0], fill=PAPER) + path(panels[1], fill="#E9D8B4") + path(panels[2], fill=PAPER),
        filter=f"url(#{p}shadow)",
    )
    body += path("M200 470 C300 520 340 420 430 470 S600 560 640 500 S760 430 840 470", fill="none", stroke=TEAL,
                 stroke_width=22, opacity="0.45")
    body += path("M248 650 C330 560 420 690 512 600 S640 520 720 470", fill="none", stroke=VERMILION,
                 stroke_width=16, stroke_dasharray="4 26", stroke_linecap="round")
    body += path(circle_d(248, 650, 22), fill=NAVY) + path(circle_d(512, 600, 22), fill=NAVY)
    body += path(pin_d(720, 408, 74, 520, 10), fill=NAVY) + path(circle_d(720, 408, 28), fill=PAPER)
    return defs, body


def c20(p):
    """3 枚ののれんにピンの紋"""
    defs = (
        f'<clipPath id="{p}panels">'
        + "".join(f'<rect x="{x}" y="250" width="210" height="560"/>' for x in (183, 407, 631))
        + "</clipPath>"
    )
    body = background(CREAM)
    for x in (183, 407, 631):
        body += path(polygon_d([(x, 250), (x + 210, 250), (x + 214, 810), (x + 4, 810)]), fill=NAVY)
    body += group(
        path(pin_d(512, 470, 150, 700, 14), fill=PAPER) + path(circle_d(512, 470, 58), fill=NAVY),
        clip_path=f"url(#{p}panels)",
    )
    body += path(rect_d(150, 222, 724, 40, 20), fill=BROWN)
    return defs, body


# ---------------------------------------------------------------------------
# C. シンプル（今の青 #2B6CB0 × オレンジ #DD6B20）（21〜30）


def brand_background(p):
    return linear_gradient(f"{p}bg", [(0, "#3C80C6"), (1, BLUE_DARK)], 0, 0, 1, 1), background(f"url(#{p}bg)")


def c21(p):
    """白いピンの穴にオレンジの吹き出し"""
    defs, body = brand_background(p)
    defs += soft_shadow_filter(f"{p}shadow", 20, 18, 0.3)
    body += group(path(pin_d(512, 440, 252, 880, 26), fill=WHITE), filter=f"url(#{p}shadow)")
    body += path(bubble_ellipse_d(512, 432, 140, 112, 118, 142, 420, 568), fill=BRAND_ORANGE)
    body += dot_trio(512, 432, 64, 20, WHITE)
    return defs, body


def c22(p):
    """オレンジのピンに「3」"""
    defs = (
        linear_gradient(f"{p}pin", [(0, BRAND_ORANGE_LIGHT), (1, BRAND_ORANGE)])
        + soft_shadow_filter(f"{p}shadow", 20, 18, 0.25)
    )
    body = background(WHITE)
    body += group(path(pin_d(512, 430, 262, 892, 26), fill=f"url(#{p}pin)"), filter=f"url(#{p}shadow)")
    body += path(circle_d(512, 430, 158), fill=WHITE)
    body += glyph_run("mochiy", "3", 512, 438, 250, fill=BLUE)
    return defs, body


def c23(p):
    """大中小の 3 本のピン（1 位・2 位・3 位）"""
    defs, body = brand_background(p)
    pins = [
        (262, 540, 108, 760, BRAND_ORANGE),
        (772, 580, 88, 760, BLUE_LIGHT),
        (512, 420, 160, 760, WHITE),
    ]
    for cx, cy, r, tip, color in pins:
        body += path(ellipse_d(cx, tip + 6, r * 0.7, r * 0.16), fill="#000", fill_opacity="0.18")
        body += path(pin_d(cx, cy, r, tip, 12), fill=color)
        body += path(circle_d(cx, cy, r * 0.4), fill=BLUE)
    return defs, body


def airplane_d(cx, cy, scale, angle):
    """旅人の飛行機（上向きの形を angle 度だけ回す）"""
    shapes = [
        "M0 -52C6 -52 7 -44 7 -38L7 40C7 48 4 52 0 52C-4 52 -7 48 -7 40L-7 -38C-7 -44 -6 -52 0 -52Z",
        "M6 -10L54 14L54 25L6 12Z", "M-6 -10L-54 14L-54 25L-6 12Z",
        "M5 34L24 45L24 53L5 48Z", "M-5 34L-24 45L-24 53L-5 48Z",
    ]
    return "".join(
        path(shape, transform=f"translate({n(cx)} {n(cy)}) rotate({n(angle)}) scale({scale})", fill=WHITE)
        for shape in shapes
    )


def house_d(cx, cy, scale):
    """地元民の家"""
    points = [(0, -46), (48, -4), (34, -4), (34, 42), (-34, 42), (-34, -4), (-48, -4)]
    return polygon_d([(cx + x * scale, cy + y * scale) for x, y in points])


def c24(p):
    """地元民（家）と旅人（飛行機）の 2 本のピン"""
    defs = (
        linear_gradient(f"{p}bg", [(0, "#FFFFFF"), (1, "#E6EEF7")])
        + soft_shadow_filter(f"{p}shadow", 16, 14, 0.22)
    )
    body = background(f"url(#{p}bg)")
    body += group(path(pin_d(372, 450, 200, 850, 20), fill=BLUE), filter=f"url(#{p}shadow)")
    body += path(house_d(372, 452, 2.3), fill=WHITE)
    body += path(rect_d(352, 494, 40, 56, 6), fill=BLUE)
    body += group(path(pin_d(668, 380, 182, 760, 20), fill=BRAND_ORANGE), filter=f"url(#{p}shadow)")
    body += airplane_d(668, 380, 2.3, 45)
    return defs, body


def c25(p):
    """折り地図の上にオレンジのピン"""
    defs, body = brand_background(p)
    defs += soft_shadow_filter(f"{p}shadow", 16, 14, 0.3)
    xs = [196, 407, 618, 829]
    tops = [360, 410, 360, 410]
    panel_colors = [WHITE, BLUE_PALE, WHITE]
    panels = "".join(
        path(polygon_d([(xs[i], tops[i]), (xs[i + 1], tops[i + 1]), (xs[i + 1], tops[i + 1] + 400),
                        (xs[i], tops[i] + 400)]), fill=panel_colors[i])
        for i in range(3)
    )
    body += group(panels, filter=f"url(#{p}shadow)")
    body += path("M210 640 C320 600 360 700 470 660 S660 560 820 610", fill="none", stroke=BLUE_LIGHT,
                 stroke_width=20, opacity="0.6")
    body += path(ellipse_d(512, 652, 70, 16), fill="#000", fill_opacity="0.18")
    body += path(pin_d(512, 420, 150, 650, 16), fill=BRAND_ORANGE)
    body += path(circle_d(512, 420, 58), fill=WHITE)
    return defs, body


def c26(p):
    """旅人の「?」と地元民の「!」のふたつの吹き出し"""
    defs = linear_gradient(f"{p}bg", [(0, "#FFFFFF"), (1, "#EAF1F9")])
    body = background(f"url(#{p}bg)")
    body += path(bubble_ellipse_d(410, 410, 248, 200, 112, 140, 214, 700), fill=BLUE)
    body += glyph_run("dela", "?", 410, 410, 230, fill=WHITE)
    body += path(bubble_ellipse_d(624, 620, 236, 190, 40, 68, 846, 900), fill=BRAND_ORANGE, stroke=WHITE,
                 stroke_width=28, stroke_linejoin="round", paint_order="stroke")
    body += glyph_run("dela", "!", 624, 620, 240, fill=WHITE)
    return defs, body


def c27(p):
    """リボンの付いたメダルにピン（マイ三大の 1 位）"""
    defs, body = brand_background(p)
    defs += (
        linear_gradient(f"{p}medal", [(0, BRAND_ORANGE_LIGHT), (1, BRAND_ORANGE)], 0, 0, 1, 1)
        + soft_shadow_filter(f"{p}shadow", 18, 16, 0.3)
    )
    body += path(polygon_d([(332, 0), (482, 0), (602, 452), (472, 452)]), fill=BLUE_PALE)
    body += path(polygon_d([(692, 0), (542, 0), (422, 452), (552, 452)]), fill=WHITE)
    body += group(path(circle_d(512, 600, 236), fill=f"url(#{p}medal)"), filter=f"url(#{p}shadow)")
    body += path(circle_d(512, 600, 190), fill="none", stroke="#F6B183", stroke_width=14)
    body += path(pin_d(512, 566, 92, 712, 12), fill=WHITE)
    body += path(circle_d(512, 566, 36), fill=BRAND_ORANGE)
    return defs, body


def c28(p):
    """「ふ」の濁点をピン 2 本にした「ぶ」"""
    defs, body = brand_background(p)
    body += glyph_run("mochiy", "ふ", 480, 590, 660, fill=WHITE)
    for cx, cy in ((610, 286), (708, 274)):
        body += group(
            path(pin_d(cx, cy, 52, cy + 138, 8), fill=BRAND_ORANGE_LIGHT) + path(circle_d(cx, cy, 19), fill=BLUE),
            rotate(-28, cx, cy + 40),
        )
    return defs, body


def c29(p):
    """1・2・3 をたどるルートとピン"""
    defs = soft_shadow_filter(f"{p}shadow", 12, 10, 0.2)
    body = background(WHITE)
    body += path("M262 790 C420 720 820 740 744 566 S360 470 340 360", fill="none", stroke=BLUE,
                 stroke_width=26, stroke_dasharray="0 46", stroke_linecap="round")
    for cx, cy, label in ((262, 790, "1"), (744, 566, "2")):
        body += group(path(circle_d(cx, cy, 78), fill=BRAND_ORANGE), filter=f"url(#{p}shadow)")
        body += glyph_run("mochiy", label, cx, cy + 4, 120, fill=WHITE)
    body += group(path(pin_d(340, 250, 118, 410, 14), fill=BLUE), filter=f"url(#{p}shadow)")
    body += glyph_run("mochiy", "3", 340, 254, 140, fill=WHITE)
    return defs, body


def c30(p):
    """虫めがねで見つけたピン（穴場）"""
    defs = (
        linear_gradient(f"{p}bg", [(0, BLUE_LIGHT), (1, BLUE)], 0, 0, 1, 1)
        + soft_shadow_filter(f"{p}shadow", 18, 16, 0.3)
    )
    body = background(f"url(#{p}bg)")
    body += group(
        f'<path d="M626 616L812 802" stroke="{BRAND_ORANGE}" stroke-width="96" stroke-linecap="round"/>'
        + path(circle_d(452, 444, 236), fill=BLUE_PALE, stroke=WHITE, stroke_width=58),
        filter=f"url(#{p}shadow)",
    )
    body += path(pin_d(452, 412, 96, 560, 12), fill=BLUE)
    body += path(circle_d(452, 412, 38), fill=BLUE_PALE)
    body += path(sparkle_d(596, 296, 38), fill=BRAND_ORANGE_LIGHT)
    body += path(sparkle_d(318, 560, 26), fill=BRAND_ORANGE_LIGHT)
    return defs, body


# ---------------------------------------------------------------------------
# 一覧と書き出し

CANDIDATES = [
    ("01", c01, "A", "吹き出しピン「！」"),
    ("02", c02, "A", "「ぶ」の吹き出し"),
    ("03", c03, "A", "ピンのステッカー"),
    ("04", c04, "A", "表彰台とピン"),
    ("05", c05, "A", "王冠のピン「1」"),
    ("06", c06, "A", "集中線のピン"),
    ("07", c07, "A", "「三」のステッカー"),
    ("08", c08, "A", "1・2・3 のピン"),
    ("09", c09, "A", "極太の「3」とピン"),
    ("10", c10, "A", "ツッコミ「!?」"),
    ("11", c11, "B", "切手のピン"),
    ("12", c12, "B", "観光スタンプ「三大」"),
    ("13", c13, "B", "朱の印「本音」"),
    ("14", c14, "B", "富士山のピン"),
    ("15", c15, "B", "旅かばんのラベル"),
    ("16", c16, "B", "荷札「旅」"),
    ("17", c17, "B", "切符と 3 つの駅"),
    ("18", c18, "B", "赤提灯「三」"),
    ("19", c19, "B", "折り地図のルート"),
    ("20", c20, "B", "のれん（三枚）"),
    ("21", c21, "C", "白いピンと吹き出し"),
    ("22", c22, "C", "オレンジのピン「3」"),
    ("23", c23, "C", "大中小の 3 本のピン"),
    ("24", c24, "C", "地元民と旅人のピン"),
    ("25", c25, "C", "折り地図とピン"),
    ("26", c26, "C", "ふたつの吹き出し"),
    ("27", c27, "C", "メダルとピン"),
    ("28", c28, "C", "「ふ」＋ピンの濁点"),
    ("29", c29, "C", "ルートと 1・2・3"),
    ("30", c30, "C", "虫めがねとピン"),
]

GROUPS = {
    "A": "A. ポップ＆ツッコミ（01〜10）",
    "B": "B. レトロ観光パンフ（11〜20）",
    "C": "C. シンプル・今の青×オレンジ（21〜30）",
}


def icon_content(number, draw):
    defs, body = draw(f"c{number}-")
    return (f"<defs>{defs}</defs>" if defs else "") + body


def candidate_svg(number, draw):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">'
        f"{icon_content(number, draw)}</svg>\n"
    )


def placed_icon(number, draw, x, y, size):
    """ホーム画面と同じように角丸をかけた候補を (x, y) に置く（角の半径は 1 辺の 22.37%）"""
    radius = size * 0.2237
    return (
        f'<clipPath id="clip{number}"><rect x="{n(x)}" y="{n(y)}" width="{n(size)}" height="{n(size)}" rx="{n(radius)}"/></clipPath>'
        f'<rect x="{n(x)}" y="{n(y + size * 0.02)}" width="{n(size)}" height="{n(size)}" rx="{n(radius)}" fill="#000" fill-opacity="0.12"/>'
        f'<g clip-path="url(#clip{number})"><svg x="{n(x)}" y="{n(y)}" width="{n(size)}" height="{n(size)}" '
        f'viewBox="0 0 {SIZE} {SIZE}">{icon_content(number, draw)}</svg></g>'
    )


def text(x, y, content, size, fill, weight=700, anchor="middle"):
    return (
        f'<text x="{n(x)}" y="{n(y)}" font-family="Hiragino Sans, Hiragino Kaku Gothic ProN, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{content}</text>'
    )


def sheet(width, height, background_fill, content, defs=""):
    """一覧の SVG。qlmanage は正方形に切り取って書き出すので、正方形の画面の真ん中に描き、
    書き出したあとに export_png.sh が真ん中の width × height を切り出す（大きさは sheets.txt に書く）"""
    side = max(width, height)
    offset = f"translate({n((side - width) / 2)} {n((side - height) / 2)})"
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{n(side)}" height="{n(side)}" '
        f'viewBox="0 0 {n(side)} {n(side)}"><defs>{defs}</defs><g transform="{offset}">'
        f'<rect width="{n(width)}" height="{n(height)}" fill="{background_fill}"/>{content}</g></svg>\n'
    )
    return svg, (round(width), round(height), round(side))


def group_sheet(key):
    """1 つの系統の 10 案を 5 列 × 2 段で大きく並べる"""
    items = [item for item in CANDIDATES if item[2] == key]
    icon, gap_x, gap_y, margin, heading, label = 300, 64, 40, 72, 110, 110
    width = margin * 2 + icon * 5 + gap_x * 4
    height = margin + heading + (icon + label) * 2 + gap_y + margin - 30
    content = text(margin, margin + 44, GROUPS[key], 44, "#1C1C1E", anchor="start")
    for index, (number, draw, _, name) in enumerate(items):
        column, row = index % 5, index // 5
        x = margin + column * (icon + gap_x)
        y = margin + heading + row * (icon + label + gap_y)
        content += placed_icon(number, draw, x, y, icon)
        content += text(x + icon / 2, y + icon + 52, number, 34, "#1C1C1E")
        content += text(x + icon / 2, y + icon + 92, name, 24, "#5A5A60", weight=600)
    return sheet(width, height, "#F2F2F7", content)


def home_sheet():
    """30 案をホーム画面の大きさ（60pt を 3 倍の 180px）で 10 列 × 3 段に並べる"""
    icon, pitch_x, pitch_y, margin, label = 180, 236, 280, 64, 56
    width = margin * 2 + pitch_x * 9 + icon
    height = margin * 2 + pitch_y * 2 + icon + label
    defs = linear_gradient("wallpaper", [(0, "#41355F"), (0.5, "#2C5A8A"), (1, "#1D3B57")], 0, 0, 1, 1)
    content = ""
    for index, (number, draw, _, _) in enumerate(CANDIDATES):
        column, row = index % 10, index // 10
        x = margin + column * pitch_x
        y = margin + row * pitch_y
        content += placed_icon(number, draw, x, y, icon)
        content += text(x + icon / 2, y + icon + 44, number, 30, "#FFFFFF", weight=600)
    return sheet(width, height, "url(#wallpaper)", content, defs)


def main():
    os.makedirs(CANDIDATES_DIR, exist_ok=True)
    os.makedirs(SHEETS_DIR, exist_ok=True)
    for number, draw, _, _ in CANDIDATES:
        with open(os.path.join(CANDIDATES_DIR, f"{number}.svg"), "w", encoding="utf-8") as file:
            file.write(candidate_svg(number, draw))
    sheets = {f"group-{key.lower()}": group_sheet(key) for key in GROUPS}
    sheets["home"] = home_sheet()
    sizes = []
    for name, (svg, (width, height, side)) in sheets.items():
        with open(os.path.join(SHEETS_DIR, f"{name}.svg"), "w", encoding="utf-8") as file:
            file.write(svg)
        sizes.append(f"{name} {width} {height} {side}\n")
    with open(os.path.join(SHEETS_DIR, "sheets.txt"), "w", encoding="utf-8") as file:
        file.writelines(sizes)
    print(f"候補 {len(CANDIDATES)} 案を {os.path.relpath(CANDIDATES_DIR, REPO_DIR)}/ に、"
          f"一覧を {os.path.relpath(SHEETS_DIR, REPO_DIR)}/ に書き出しました")


if __name__ == "__main__":
    main()
