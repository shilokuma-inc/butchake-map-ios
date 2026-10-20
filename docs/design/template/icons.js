// モックで使うアイコン（SF Symbols に似せて自分で描いた SVG。外部のサイトから取ってこない）。
// 24x24 の viewBox に、線は currentColor で描く。線の太さは CSS 変数 --icon-stroke（既定 2）。
// 案ごとに別の絵にしたいときは、ページで Mock.icons.<名前> = '<path …/>' のように差し替える。
window.MOCK_ICONS = {
  // タブ
  house: '<path d="M3.5 11 12 4l8.5 7"/><path d="M6 9.5V20h4.5v-5.5h3V20H18V9.5"/>',
  houseFill: '<path d="M3 11.2 12 3.8l9 7.4-1.3 1.5L18.5 11.7V20.5h-5v-5.5h-3v5.5h-5v-8.8l-1.2 1z" fill="currentColor" stroke="none"/>',
  map: '<path d="M3.5 6.5 9 4.5l6 2 5.5-2v13l-5.5 2-6-2-5.5 2z"/><path d="M9 4.5v13M15 6.5v13"/>',
  plusCircle: '<circle cx="12" cy="12" r="8.5"/><path d="M12 8v8M8 12h8"/>',
  magnifyingglass: '<circle cx="10.5" cy="10.5" r="6"/><path d="m15 15 5 5"/>',
  person: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="10" r="3"/><path d="M6.5 18.2c1.3-2.2 3.2-3.2 5.5-3.2s4.2 1 5.5 3.2"/>',

  // いいね・スター
  heart: '<path d="M12 19.5s-7.5-4.6-7.5-9.7C4.5 7.3 6.4 5.5 8.6 5.5c1.5 0 2.7.8 3.4 2 .7-1.2 1.9-2 3.4-2 2.2 0 4.1 1.8 4.1 4.3 0 5.1-7.5 9.7-7.5 9.7z"/>',
  heartFill: '<path d="M12 19.5s-7.5-4.6-7.5-9.7C4.5 7.3 6.4 5.5 8.6 5.5c1.5 0 2.7.8 3.4 2 .7-1.2 1.9-2 3.4-2 2.2 0 4.1 1.8 4.1 4.3 0 5.1-7.5 9.7-7.5 9.7z" fill="currentColor"/>',
  star: '<path d="m12 4 2.4 5 5.4.6-4 3.7 1.1 5.4L12 16l-4.9 2.7 1.1-5.4-4-3.7 5.4-.6z"/>',
  starFill: '<path d="m12 4 2.4 5 5.4.6-4 3.7 1.1 5.4L12 16l-4.9 2.7 1.1-5.4-4-3.7 5.4-.6z" fill="currentColor"/>',

  // カテゴリ
  forkKnife: '<path d="M7 3.5v6.5M5 3.5v4.5a2 2 0 0 0 4 0V3.5M7 10v10.5"/><path d="M17 20.5V3.5c-2 1-3 3.5-3 6.5v3h3"/>',
  mountain: '<path d="M2.5 19.5 9 8.5l4 6.5 2.5-3.5 6 8z"/><path d="m7.4 11.2 1.6 1.3 1.5-1.4"/>',
  faceDashed: '<circle cx="12" cy="12" r="8.5" stroke-dasharray="3 2.4"/><path d="M9 10h.01M15 10h.01M9 15.5h6"/>',
  sparkleMagnifyingglass: '<circle cx="10.5" cy="10.5" r="6"/><path d="m15 15 5 5"/><path d="M10.5 7.5v6M7.5 10.5h6" stroke-width="1.5"/>',
  mappin: '<path d="M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.3"/>',

  // 投稿者の属性
  repeat: '<path d="M5 10a7 7 0 0 1 12-3.5L19 8.5"/><path d="M19 4v4.5h-4.5"/><path d="M19 14a7 7 0 0 1-12 3.5L5 15.5"/><path d="M5 20v-4.5h4.5"/>',
  airplane: '<path d="M10.5 3.5c0-.8.7-1.5 1.5-1.5s1.5.7 1.5 1.5V9l7.5 4.5v2L13.5 13v4.5l2.5 2v1.5L12 20l-4 1v-1.5l2.5-2V13L3 15.5v-2L10.5 9z" fill="currentColor" stroke="none"/>',

  // ナビゲーション・操作
  chevronLeft: '<path d="m14.5 5-7 7 7 7"/>',
  chevronRight: '<path d="m9.5 5 7 7-7 7"/>',
  share: '<path d="M12 3.5v11M8 7.5l4-4 4 4"/><path d="M8 10.5H6.5v9.5h11v-9.5H16"/>',
  ellipsis: '<circle cx="12" cy="12" r="8.5"/><path d="M8 12h.01M12 12h.01M16 12h.01" stroke-width="2.6"/>',
  mapFill: '<path d="M3.5 6.5 9 4.5l6 2 5.5-2v13l-5.5 2-6-2-5.5 2z" fill="currentColor"/>',
  tray: '<path d="M3.5 13.5 6 5.5h12l2.5 8v5h-17z"/><path d="M3.5 13.5h5a3.5 3.5 0 0 0 7 0h5"/>',
  location: '<path d="m4 11 16-7-7 16-2-7z"/>',

  // ステータスバー（塗りで描く）
  signal: '<rect x="2" y="15" width="3.4" height="5" rx="1" fill="currentColor" stroke="none"/><rect x="7.2" y="12" width="3.4" height="8" rx="1" fill="currentColor" stroke="none"/><rect x="12.4" y="8.5" width="3.4" height="11.5" rx="1" fill="currentColor" stroke="none"/><rect x="17.6" y="5" width="3.4" height="15" rx="1" fill="currentColor" stroke="none"/>',
  wifi: '<path d="M2.5 9.5a14 14 0 0 1 19 0M5.8 13a9.2 9.2 0 0 1 12.4 0M9 16.4a4.6 4.6 0 0 1 6 0" stroke-width="2.4"/><circle cx="12" cy="19.4" r="1.6" fill="currentColor" stroke="none"/>',
  battery: '<rect x="1.5" y="7" width="18" height="10" rx="3" stroke-width="1.4" opacity=".45"/><rect x="3.3" y="8.8" width="14.4" height="6.4" rx="1.6" fill="currentColor" stroke="none"/><path d="M21 10.5v3" stroke-width="1.8" opacity=".45"/>',
};
