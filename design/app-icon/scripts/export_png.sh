#!/bin/bash
set -euo pipefail

# 候補と一覧の SVG を作り直し、PNG に書き出す。
#
#   design/app-icon/scripts/export_png.sh
#
# 出力先: build/app-icon/（build/ は gitignore 済み。画像はコミットせず PR に添付する）
#   candidates/NN.png  候補（1024×1024）
#   group-a.png など   系統ごとの 10 案（ホーム画面の角丸をかけたもの）
#   home.png           30 案をホーム画面の大きさ（60pt を 3 倍の 180px）で並べたもの
#
# rsvg-convert などは使わず、macOS 標準の QuickLook（qlmanage）で描く。
# qlmanage は正方形のサムネイルしか作らないので、一覧は正方形の真ん中に描いてから sips で切り出す。

SCRIPTS_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
ICON_DIR="$(dirname "$SCRIPTS_DIR")"
REPO_DIR="$(dirname "$(dirname "$ICON_DIR")")"
OUTPUT_DIR="$REPO_DIR/build/app-icon"
SHEETS_DIR="$OUTPUT_DIR/sheets"

python3 "$SCRIPTS_DIR/make_candidates.py"

# qlmanage は出力先のディレクトリが無いと、何も書かずに成功で終わる。先に作っておく
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# <SVG> <1 辺のピクセル数> <出力の PNG>
render() {
    local svg="$1" side="$2" output="$3"
    qlmanage -t -s "$side" -o "$work_dir" "$svg" >/dev/null 2>&1
    local thumbnail
    thumbnail="$work_dir/$(basename "$svg").png"
    if [ ! -s "$thumbnail" ]; then
        echo "書き出せませんでした: ${svg}" >&2
        return 1
    fi
    mv "$thumbnail" "$output"
}

mkdir -p "$OUTPUT_DIR/candidates"
for svg in "$ICON_DIR"/candidates/*.svg; do
    render "$svg" 1024 "$OUTPUT_DIR/candidates/$(basename "${svg%.svg}").png"
done

while read -r name width height side; do
    output="$OUTPUT_DIR/$name.png"
    render "$SHEETS_DIR/$name.svg" "$side" "$output"
    # sips の切り出しは画像の真ん中が基準（--cropOffset は効かなかった）
    sips --cropToHeightWidth "$height" "$width" "$output" >/dev/null
done <"$SHEETS_DIR/sheets.txt"

echo "${OUTPUT_DIR#"$REPO_DIR"/}/ に書き出しました"
