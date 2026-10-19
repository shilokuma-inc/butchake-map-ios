#!/bin/bash
set -euo pipefail

# デザイン案のモック（docs/design/mocks/<案 ID>/*.html）を PNG に書き出す。
#
#   Tools/render_design_mocks.sh a1 b1      # 案を指定する
#   Tools/render_design_mocks.sh --all      # docs/design/mocks/ の全案と docs/design/compare/
#
# 出力先: build/design/<案 ID>/<ページ名>.png（build/ は gitignore 済み。画像はコミットせず PR に添付する）
# 書き出しは macOS の WebKit で行う（Tools/render_design_mocks.swift）。Google Chrome は使わない。
# フォントの読み込みの失敗・画像の欠け・寸法の違いが 1 ページでもあれば 0 以外で終わる。
# 案 ID の代わりに compare を渡すと docs/design/compare/ を書き出す（10 案の比較シート）。

TOOLS_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
cd "$TOOLS_DIR/.."
MOCKS_DIR="docs/design/mocks"
OUTPUT_ROOT="${DESIGN_OUTPUT_DIR:-$PWD/build/design}"

if [ "$#" -eq 0 ]; then
    echo "使い方: Tools/render_design_mocks.sh <案 ID>… | --all" >&2
    exit 2
fi

ids=()
if [ "$1" = "--all" ]; then
    for dir in "$MOCKS_DIR"/*/; do
        ids+=("$(basename "$dir")")
    done
    if [ -d docs/design/compare ]; then
        ids+=("compare")
    fi
else
    ids=("$@")
fi

# 書き出す HTML を「出力ディレクトリ ページ…」の組にまとめ、WebKit の起動（20 秒ほど）を案ごとに 1 回にする
status=0
for id in "${ids[@]}"; do
    if [ "$id" = "compare" ]; then
        source_dir="docs/design/compare"
    else
        source_dir="$MOCKS_DIR/$id"
    fi
    if [ ! -d "$source_dir" ]; then
        echo "${source_dir} がありません" >&2
        status=1
        continue
    fi
    pages=()
    for page in "$source_dir"/*.html; do
        [ -e "$page" ] && pages+=("$page")
    done
    if [ "${#pages[@]}" -eq 0 ]; then
        echo "${source_dir} に HTML がありません" >&2
        status=1
        continue
    fi
    output_dir="$OUTPUT_ROOT/$id"
    rm -rf "$output_dir"
    echo "== ${id}（${#pages[@]} ページ）"
    if ! xcrun swift "$TOOLS_DIR/render_design_mocks.swift" "$output_dir" "${pages[@]}"; then
        status=1
    fi
done
exit "$status"
