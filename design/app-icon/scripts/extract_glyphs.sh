#!/bin/bash
set -euo pipefail

# 候補のアイコンに使う文字のアウトラインを、Google Fonts の OFL の書体から取り出して glyphs.json に書き出す。
#
#   design/app-icon/scripts/extract_glyphs.sh
#
# 書体のファイルは google/fonts から取得してキャッシュに置く（リポジトリには入れない）。
# 使う文字を増やしたときだけ実行する。候補の SVG は glyphs.json のパスを埋め込むので、書体が無くても描き直せる。

SCRIPTS_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
ICON_DIR="$(dirname "$SCRIPTS_DIR")"
CACHE_DIR="${APP_ICON_FONT_CACHE:-$HOME/Library/Caches/butchake-map-app-icon/fonts}"
# 上流の更新で glyphs.json（と候補の SVG）が変わらないよう、取得した時点の google/fonts のコミットに固定する
FONTS_COMMIT="47d54ca1ebb14fd864695f1d39dc734f39017c33"
FONTS_URL="https://github.com/google/fonts/raw/$FONTS_COMMIT/ofl"

# キー・google/fonts のパス・使う文字
specs=(
    "dela|delagothicone/DelaGothicOne-Regular.ttf|ぶ三3!?"
    "mochiy|mochiypopone/MochiyPopOne-Regular.ttf|ふ123"
    "antique|zenantique/ZenAntique-Regular.ttf|三大旅"
    "yuji|yujisyuku/YujiSyuku-Regular.ttf|本音"
)

mkdir -p "$CACHE_DIR"
arguments=()
for spec in "${specs[@]}"; do
    IFS='|' read -r key path characters <<<"$spec"
    font="$CACHE_DIR/$(basename "$path")"
    if [ ! -s "$font" ]; then
        echo "取得: ${path}"
        # 途中で切れたファイルを取得済みと扱わないよう、取得できてからキャッシュに移す
        curl -fsSL -o "$font.part" "$FONTS_URL/$path"
        mv "$font.part" "$font"
    fi
    arguments+=("$key=$font=$characters")
done

xcrun swift "$SCRIPTS_DIR/extract_glyphs.swift" "$ICON_DIR/glyphs.json" "${arguments[@]}"
