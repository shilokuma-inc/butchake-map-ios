#!/usr/bin/env python3
"""デザイン案の配色（palette.json）の文字と背景のコントラスト比を WCAG 2.x の式で計算し、AA を満たすか確かめる。

    python3 Tools/check_design_contrast.py docs/design/mocks/a1 [docs/design/mocks/b1 …]

案のディレクトリの palette.json を読み、組ごとの比を Markdown の表で出す（ブランドシートと PR 本文に載せる）。
AA の基準は、通常の文字で 4.5:1、大きな文字（18pt 以上、または 14pt 以上の太字）で 3:1。
AA 未満の組が 1 つでもあれば 0 以外で終わる。標準ライブラリだけで動く。

palette.json の形:

    {
      "colors": [{"name": "朱色", "hex": "#D94A2B"}, …],        # パレットの見本（任意。検査はしない）
      "pairs": [
        {"name": "本文", "fg": "#2A2420", "bg": "#FFF6E5", "large": false},
        …
      ]
    }
"""

import json
import re
import sys
from pathlib import Path

HEX_PATTERN = re.compile(r"^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$")
AA_NORMAL = 4.5
AA_LARGE = 3.0


def parse_hex(value):
    """#RGB / #RRGGBB を 0〜255 の (r, g, b) にする"""
    if not isinstance(value, str) or not HEX_PATTERN.match(value):
        raise ValueError(f"色「{value}」は #RGB か #RRGGBB で書いてください")
    digits = value[1:]
    if len(digits) == 3:
        digits = "".join(ch * 2 for ch in digits)
    return tuple(int(digits[i:i + 2], 16) for i in (0, 2, 4))


def relative_luminance(rgb):
    """WCAG 2.x の相対輝度"""
    def channel(value):
        c = value / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(fg, bg):
    lighter, darker = sorted((relative_luminance(parse_hex(fg)), relative_luminance(parse_hex(bg))), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def check_directory(directory):
    """1 案の palette.json を検査し、(表の行, AA 未満の件数) を返す"""
    path = Path(directory) / "palette.json"
    try:
        palette = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"{path} を読めません: {error}") from error
    pairs = palette.get("pairs")
    if not isinstance(pairs, list) or not pairs:
        raise ValueError(f"{path} に pairs（文字色と背景色の組）がありません")

    rows = []
    failures = 0
    for index, pair in enumerate(pairs, start=1):
        try:
            name, fg, bg = pair["name"], pair["fg"], pair["bg"]
        except (KeyError, TypeError) as error:
            raise ValueError(f"{path} の pairs の {index} 番目に name / fg / bg がありません") from error
        large = bool(pair.get("large", False))
        ratio = contrast_ratio(fg, bg)
        required = AA_LARGE if large else AA_NORMAL
        # 表示は小数 2 桁に丸めるので、判定も丸める前の値で行う（4.499 を 4.50 と出して合格にしない）
        passed = ratio >= required
        if not passed:
            failures += 1
        rows.append(
            f"| {name} | `{fg.upper()}` | `{bg.upper()}` | {'大' if large else '通常'} "
            f"| {ratio:.2f}:1 | {'✅ AA' if passed else f'❌ {required:g}:1 未満'} |"
        )
    return rows, failures


def main(argv):
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 2
    total_failures = 0
    for directory in argv[1:]:
        try:
            rows, failures = check_directory(directory)
        except ValueError as error:
            print(f"エラー: {error}", file=sys.stderr)
            return 1
        total_failures += failures
        print(f"### {directory}\n")
        print("| 組 | 文字 | 背景 | 文字の大きさ | コントラスト比 | 判定 |")
        print("| --- | --- | --- | --- | --- | --- |")
        print("\n".join(rows))
        print()
    if total_failures:
        print(f"AA 未満の組が {total_failures} 件あります", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
