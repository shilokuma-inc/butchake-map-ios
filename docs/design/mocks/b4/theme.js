// B-4「旅かばんのラベル」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, icon, esc } = Mock;
  const labelColors = ['#1F6F6B', '#23395B', '#B8432F'];

  /** ロゴタイプ「ぶっちゃけmap」（楕円のホテルラベル）。size は「ぶっちゃけmap」の文字の大きさ（px） */
  Mock.logo = function (size = 26, small = false) {
    return `<span class="logo" style="font-size:${size}px">${small ? '' : '<span class="logo-top">GRAND HONNE</span>'}
      <span class="logo-main">ぶっちゃけmap</span>${small ? '' : '<span class="logo-bottom">JAPAN · 2026</span>'}</span>`;
  };

  /** 見出しと、横の楕円の英字（任意） */
  parts.sectionHeader = function (title, en = '', color = '#E0A526') {
    return `<h2 class="section-header">${esc(title)}${en ? `<span class="en" style="--c:${color}">${esc(en)}</span>` : ''}</h2>`;
  };

  /** ホテルの楕円のラベル（上の英字と、大きな文字） */
  parts.oval = function (top, main, color, style = '') {
    return `<span class="oval" style="--c:${color};${style}"><span class="top">${esc(top)}</span><span class="main">${esc(main)}</span></span>`;
  };

  /** カルーセルのカード: 荷札（行き先・タイトル・カテゴリ） */
  parts.carouselCard = function (post, i = 0) {
    return `<article class="tag carousel-card">
      <p class="tag-to">TO <span>${esc(post.prefecture)} ${esc(post.city)}</span></p>
      <h3 class="carousel-title">${esc(post.title)}</h3>
      <div class="carousel-card-foot"><div class="badges">${parts.categoryBadge(post)}</div>${parts.starButton(post)}</div>
    </article>`;
  };

  /** フィードのカード: 右上に行き先の楕円のラベルを貼る */
  const basePostCard = parts.postCard;
  parts.postCard = function (post) {
    const color = labelColors[data.posts.indexOf(post) % labelColors.length];
    return basePostCard(post).replace('<article class="card post-card">',
      `<article class="card post-card">${parts.oval('HOTEL', post.city.replace('市', ''), color, 'position:absolute;top:-10px;right:10px;transform:rotate(8deg);padding:6px 16px')}`);
  };

  /** ぶっちゃけコメント（荷札の裏の書き込み） */
  parts.note = function (text) {
    return `<div class="tag note"><p class="note-label">HONEST NOTE · ${esc(data.strings.honestComment)}</p><p class="note-text">${esc(text)}</p></div>`;
  };

  Mock.planeIcon = () => icon('airplane', { size: 16 });
}());
