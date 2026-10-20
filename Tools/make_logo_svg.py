#!/usr/bin/env python3
"""B-2「駅のスタンプラリー」のロゴ（駅名標の形のロゴタイプ「ぶっちゃけmap」）を SVG に書き出す。

    $FONTTOOLS_PYTHON Tools/make_logo_svg.py

fontTools が要る（標準ライブラリだけでは動かない）。FONTTOOLS_PYTHON には fontTools を入れた Python を指定する。例:

    python3 -m venv /tmp/fonttools-venv && /tmp/fonttools-venv/bin/pip install fonttools
    FONTTOOLS_PYTHON=/tmp/fonttools-venv/bin/python
    "$FONTTOOLS_PYTHON" Tools/make_logo_svg.py

見本は docs/design/mocks/b2/theme.css の .logo・.logo-name・.logo-en・.logo-bar と theme.js の Mock.logo(size)。
CSS のレイアウト（padding・letter-spacing・line-height 1・中央寄せ・左右に寄せる帯）をここで計算し直し、
文字はアプリに同梱している書体から fontTools でアウトライン（path）にする。SVG を開く側の書体には頼らない。

- 書体: ButchakeMap/Resources/Fonts/BIZUDPGothic/BIZUDPGothic-Bold.ttf（「ぶっちゃけ」「map」と帯の文字）
        ButchakeMap/Resources/Fonts/DotGothic16/DotGothic16-Regular.ttf（「BUTCHAKE MAP」）
- 送り幅は hmtx の値。字間は CSS の letter-spacing と同じく、各文字の後ろ（最後の文字の後ろも）に足す。
  どちらの書体にもカーニング（GPOS の kern・palt）は無く、ブラウザも letter-spacing があると合字を使わないので、詰めはしない
- 縦の位置は line-height 1 のときのブラウザ（WebKit）と同じく、hhea の ascent・descent の高さを行の高さに中央寄せして基線を決める
- 基準の大きさ（CSS の font-size）は BASE_SIZE。viewBox はロゴの外形（枠の外側）にぴったり合わせる（余白なし）

出力（同じ内容）:
    docs/design/mocks/b2/logo.svg
    ButchakeMap/Assets.xcassets/Logo.imageset/logo.svg

Asset Catalog の SVG でも崩れないように、clipPath・stroke・transform は使わず、塗りの rect と path だけで描く。
"""

import sys
from pathlib import Path

try:
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
except ImportError:
    sys.exit("fontTools が読み込めません。fontTools を入れた Python で動かしてください（例: $FONTTOOLS_PYTHON Tools/make_logo_svg.py）")

ROOT = Path(__file__).resolve().parent.parent
FONT_GOTHIC = ROOT / "ButchakeMap/Resources/Fonts/BIZUDPGothic/BIZUDPGothic-Bold.ttf"
FONT_DOT = ROOT / "ButchakeMap/Resources/Fonts/DotGothic16/DotGothic16-Regular.ttf"
OUTPUTS = [
    ROOT / "docs/design/mocks/b2/logo.svg",
    ROOT / "ButchakeMap/Assets.xcassets/Logo.imageset/logo.svg",
]

# 色（theme.css のライトの値。ダークの値は別に用意する）
COLOR_TEXT = "#1B1F2A"       # --text（枠と「ぶっちゃけ」）
COLOR_INK = "#24387F"        # --ink（「map」）
COLOR_SECONDARY = "#4F566A"  # --color-text-secondary（「BUTCHAKE MAP」）
COLOR_RAIL = "#2F7A45"       # --rail（下の帯）
COLOR_SURFACE = "#FFFFFF"    # 地と帯の文字

# 寸法（theme.css の値。em は BASE_SIZE を掛ける）
BASE_SIZE = 60.0             # Mock.logo(size) の size（「ぶっちゃけ」の文字の大きさ）
BORDER = 2.5
RADIUS = 6.0

NAME_PADDING = (0.22, 0.5, 0.08)  # 上・左右・下（em）
NAME_LETTER_SPACING = 0.08        # em

EN_SIZE = 0.32                    # em
EN_LETTER_SPACING = 0.3           # .logo-en の文字の大きさに対する em
EN_PADDING_BOTTOM = 0.2           # .logo-en の文字の大きさに対する em

BAR_SIZE = 0.34                   # em
BAR_PADDING = (0.12, 0.5)         # 上下・左右（帯の文字の大きさに対する em）
BAR_GAP = 1.2                     # 帯の文字の大きさに対する em
BAR_LEFT = "◀ ほんね"
BAR_RIGHT = "たび ▶"


def number(value):
    """座標を小数 2 桁までの短い文字列にする"""
    text = f"{value:.2f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


class Face:
    """1 つの書体のグリフ・送り幅・縦の寸法"""

    def __init__(self, path):
        self.font = TTFont(path)
        self.glyph_set = self.font.getGlyphSet()
        self.cmap = self.font.getBestCmap()
        self.upm = self.font["head"].unitsPerEm
        hhea = self.font["hhea"]
        self.ascent = hhea.ascent
        self.descent = -hhea.descent

    def glyph_name(self, char):
        name = self.cmap.get(ord(char))
        if name is None:
            sys.exit(f"{char!r} が書体にありません")
        return name

    def advance(self, char, size):
        return self.font["hmtx"][self.glyph_name(char)][0] * size / self.upm

    def text_width(self, text, size, letter_spacing):
        """CSS と同じく、各文字の後ろに letter-spacing を足した幅"""
        return sum(self.advance(char, size) + letter_spacing for char in text)

    def baseline(self, size):
        """line-height 1 の行の上端から基線までの距離（ascent + descent を行の高さに中央寄せする）"""
        half_leading = (self.upm - (self.ascent + self.descent)) / 2
        return (half_leading + self.ascent) * size / self.upm

    def outline(self, text, x, baseline, size, letter_spacing):
        """文字列を左端 x・基線 baseline に置いたアウトラインの path データ"""
        scale = size / self.upm
        commands = []
        for char in text:
            pen = SVGPathPen(self.glyph_set, ntos=number)
            self.glyph_set[self.glyph_name(char)].draw(TransformPen(pen, (scale, 0, 0, -scale, x, baseline)))
            commands.append(pen.getCommands())
            x += self.advance(char, size) + letter_spacing
        return "".join(command for command in commands if command)


def rounded_rect_path(x, y, width, height, top_radius, bottom_radius):
    """角丸（上と下で半径を変えられる）の長方形の path データ"""
    right, bottom = x + width, y + height
    t, b = top_radius, bottom_radius
    parts = [f"M{number(x + t)} {number(y)}", f"H{number(right - t)}"]
    if t:
        parts.append(f"A{number(t)} {number(t)} 0 0 1 {number(right)} {number(y + t)}")
    parts.append(f"V{number(bottom - b)}")
    if b:
        parts.append(f"A{number(b)} {number(b)} 0 0 1 {number(right - b)} {number(bottom)}")
    parts.append(f"H{number(x + b)}")
    if b:
        parts.append(f"A{number(b)} {number(b)} 0 0 1 {number(x)} {number(bottom - b)}")
    parts.append(f"V{number(y + t)}")
    if t:
        parts.append(f"A{number(t)} {number(t)} 0 0 1 {number(x + t)} {number(y)}")
    return "".join(parts) + "Z"


def build_svg():
    gothic = Face(FONT_GOTHIC)
    dot = Face(FONT_DOT)

    # 上の行「ぶっちゃけ」＋「map」
    name_size = BASE_SIZE
    name_spacing = NAME_LETTER_SPACING * name_size
    name_pad_top, name_pad_x, name_pad_bottom = (value * name_size for value in NAME_PADDING)
    name_main, name_map = "ぶっちゃけ", "map"
    name_width = gothic.text_width(name_main + name_map, name_size, name_spacing)
    name_row_width = name_width + 2 * name_pad_x
    name_row_height = name_pad_top + name_size + name_pad_bottom

    # 中の行「BUTCHAKE MAP」
    en_size = EN_SIZE * BASE_SIZE
    en_spacing = EN_LETTER_SPACING * en_size
    en_text = "BUTCHAKE MAP"
    en_width = dot.text_width(en_text, en_size, en_spacing)
    en_row_height = en_size + EN_PADDING_BOTTOM * en_size

    # 下の帯「◀ ほんね」「たび ▶」
    bar_size = BAR_SIZE * BASE_SIZE
    bar_pad_y, bar_pad_x = (value * bar_size for value in BAR_PADDING)
    bar_left_width = gothic.text_width(BAR_LEFT, bar_size, 0)
    bar_right_width = gothic.text_width(BAR_RIGHT, bar_size, 0)
    bar_row_width = bar_left_width + BAR_GAP * bar_size + bar_right_width + 2 * bar_pad_x
    bar_row_height = bar_size + 2 * bar_pad_y

    # 外形（inline-flex の縦並びなので、いちばん広い行の幅になる）
    content_width = max(name_row_width, en_width, bar_row_width)
    content_height = name_row_height + en_row_height + bar_row_height
    width = round(content_width + 2 * BORDER, 2)
    height = round(content_height + 2 * BORDER, 2)
    left = BORDER
    inner_right = width - BORDER
    inner_radius = RADIUS - BORDER

    # 各行の位置（行の中の文字は text-align: center）
    name_top = BORDER
    name_x = left + (content_width - name_width) / 2
    name_baseline = name_top + name_pad_top + gothic.baseline(name_size)
    map_x = name_x + gothic.text_width(name_main, name_size, name_spacing)

    en_top = name_top + name_row_height
    en_x = left + (content_width - en_width) / 2
    en_baseline = en_top + dot.baseline(en_size)

    bar_top = en_top + en_row_height
    bar_bottom = height - BORDER
    bar_baseline = bar_top + bar_pad_y + gothic.baseline(bar_size)
    bar_left_x = left + bar_pad_x
    bar_right_x = inner_right - bar_pad_x - bar_right_width

    paths = [
        ("枠", COLOR_TEXT, rounded_rect_path(0, 0, width, height, RADIUS, RADIUS)),
        ("地", COLOR_SURFACE, rounded_rect_path(left, BORDER, content_width, content_height, inner_radius, inner_radius)),
        ("帯", COLOR_RAIL, rounded_rect_path(left, bar_top, content_width, bar_bottom - bar_top, 0, inner_radius)),
        ("ぶっちゃけ", COLOR_TEXT, gothic.outline(name_main, name_x, name_baseline, name_size, name_spacing)),
        ("map", COLOR_INK, gothic.outline(name_map, map_x, name_baseline, name_size, name_spacing)),
        ("BUTCHAKE MAP", COLOR_SECONDARY, dot.outline(en_text, en_x, en_baseline, en_size, en_spacing)),
        (BAR_LEFT + " / " + BAR_RIGHT, COLOR_SURFACE,
         gothic.outline(BAR_LEFT, bar_left_x, bar_baseline, bar_size, 0)
         + gothic.outline(BAR_RIGHT, bar_right_x, bar_baseline, bar_size, 0)),
    ]

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {number(width)} {number(height)}" '
        f'width="{number(width)}" height="{number(height)}">',
        "  <!-- B-2 のロゴ「ぶっちゃけmap」（駅名標の形）。Tools/make_logo_svg.py で書き出す。手で直さない -->",
    ]
    for label, color, data in paths:
        lines.append(f"  <!-- {label} -->")
        lines.append(f'  <path fill="{color}" d="{data}"/>')
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def main():
    svg = build_svg()
    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(svg, encoding="utf-8")
        print(f"書き出しました: {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
