#!/bin/bash
set -euo pipefail

# スタンプの書体（Kaisei Decol Bold）を、スタンプに出す文字だけにサブセット化してアプリに同梱する。
#
#   PYFTSUBSET=/path/to/pyftsubset Tools/subset_stamp_font.sh <KaiseiDecol-Bold.ttf>
#
# 元の書体は Google Fonts の GitHub（https://raw.githubusercontent.com/google/fonts/main/ofl/kaiseidecol/KaiseiDecol-Bold.ttf）から取る。
# 元の書体のファイルはコミットしない。サブセットにした書体（ButchakeMap/Resources/Fonts/KaiseiDecol/KaiseiDecol-Bold.ttf）をコミットする。
# 出す文字は Tools/stamp_font_glyphs.txt（改行を入れずに文字だけを並べる。ファイルの中の文字はすべてサブセットに入る。先頭の半角スペースも、スタンプの文字列の区切りに使うので消さない）。
# スタンプに出す文字を増やしたら、このファイルに足して流し直す（ButchakeMapTests の B2FontTests が、足し忘れを見つける）。
# pyftsubset は fonttools のもの（pip install fonttools）。場所は環境変数 PYFTSUBSET で渡す（無ければ PATH の pyftsubset）。
# 書体の名前（name テーブル）は元のまま残す。Kaisei Decol の OFL には予約フォント名が無いので、サブセットにも同じ名前を使える。

TOOLS_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "$TOOLS_DIR/.." && pwd)"
GLYPHS="$TOOLS_DIR/stamp_font_glyphs.txt"
OUTPUT="$ROOT_DIR/ButchakeMap/Resources/Fonts/KaiseiDecol/KaiseiDecol-Bold.ttf"
PYFTSUBSET="${PYFTSUBSET:-pyftsubset}"

if [ "$#" -ne 1 ]; then
    echo "使い方: PYFTSUBSET=/path/to/pyftsubset Tools/subset_stamp_font.sh <KaiseiDecol-Bold.ttf>" >&2
    exit 2
fi
source_font="$1"
if [ ! -f "$source_font" ]; then
    echo "${source_font} がありません" >&2
    exit 1
fi
if ! command -v "$PYFTSUBSET" >/dev/null 2>&1; then
    echo "pyftsubset が見つかりません。fonttools を入れ、PYFTSUBSET に場所を渡してください" >&2
    exit 1
fi
if [ ! -s "$GLYPHS" ]; then
    echo "${GLYPHS} が空か、ありません" >&2
    exit 1
fi

"$PYFTSUBSET" "$source_font" \
    --text-file="$GLYPHS" \
    --output-file="$OUTPUT" \
    --layout-features='*' \
    --name-IDs='*' \
    --name-legacy \
    --name-languages='*' \
    --notdef-outline

before=$(wc -c < "$source_font" | tr -d ' ')
after=$(wc -c < "$OUTPUT" | tr -d ' ')
echo "書き出しました: ${OUTPUT}（${before} バイト → ${after} バイト）"
