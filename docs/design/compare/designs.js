// 比較シートに並べる案（並べる順）。名前・方向性・ひとことは docs/design/README.md の一覧表と同じ。
window.DESIGNS = [
  { id: 'current', name: '今のデザイン', dir: '—', note: '青×オレンジ・システムフォント' },
  { id: 'a1', name: '王道ポップ', dir: 'A', note: 'オレンジ×黄×黒の太線・ステッカー' },
  { id: 'a2', name: 'マンガのツッコミ', dir: 'A', note: '白黒の網点・集中線・赤 1 色' },
  { id: 'a3', name: '駄菓子屋のおまけシール', dir: 'A', note: 'ピンク・水色・黄とキラキラのシール' },
  { id: 'a4', name: 'ネオブルータリズム', dir: 'A', note: '原色のベタ・太枠とずらした影' },
  { id: 'a5', name: 'バラエティ番組のテロップ', dir: 'A', note: '縁取り文字・テロップ・ワイプ' },
  { id: 'b1', name: '昭和の観光パンフ', dir: 'B', note: 'クリームに朱と紺・切手と消印' },
  { id: 'b2', name: '駅のスタンプラリー', dir: 'B', note: '紺のインク・駅名標・きっぷ' },
  { id: 'b3', name: '純喫茶のメニュー', dir: 'B', note: 'こげ茶と赤・レースペーパー・明朝' },
  { id: 'b4', name: '旅かばんのラベル', dir: 'B', note: 'ホテルのラベル・荷札・エアメール' },
  { id: 'b5', name: '昭和の銭湯と看板', dir: 'B', note: '水色と朱・のれん・ペンキ絵' },
];

/**
 * iframe を並べたページで、ページ全体の load（iframe の読み込みを含む）を待ち、中の書体が読み込まれる余裕を置く。
 * file:// の iframe は別のオリジンになり中の document.fonts を読めないので、時間で待つ
 */
window.waitForFrames = function () {
  const loaded = document.readyState === 'complete' ? Promise.resolve() : new Promise(resolve => window.addEventListener('load', resolve));
  return loaded.then(() => new Promise(resolve => setTimeout(resolve, 3000)));
};
