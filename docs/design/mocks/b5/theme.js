// B-5「昭和の銭湯と看板」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap」（朱の「ゆ」の札と、立体文字の看板）。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 28) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-yu" aria-hidden="true">ゆ</span><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span></span>`;
  };

  /** 富士山のペンキ絵（自分で描いた SVG）。width と height は px */
  Mock.fuji = function (width = 370, height = 110) {
    return `<svg width="${width}" height="${height}" viewBox="0 0 370 110" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
      <rect width="370" height="110" fill="#7CC6D6"/>
      <circle cx="300" cy="30" r="14" fill="#F2D28A"/>
      <path d="M60 110 L170 22 L280 110 Z" fill="#3E7FA6"/>
      <path d="M140 46 L170 22 L200 46 L188 52 L178 44 L168 54 L156 46 L148 52 Z" fill="#FFFFFF"/>
      <path d="M-10 110 L40 76 L90 110 Z M250 110 L320 70 L390 110 Z" fill="#5E9DBA"/>
      <path d="M0 96 q15 -10 30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0 t30 0" fill="none" stroke="#FFFFFF" stroke-width="3" opacity=".8"/>
      <rect y="100" width="370" height="10" fill="#1E6E80"/></svg>`;
  };

  /** 見出し（木札） */
  parts.sectionHeader = function (title) {
    return `<h2 class="section-header"><span class="fuda">${esc(title)}</span></h2>`;
  };

  /** カルーセルのカード: 下足箱の木札の番号と、ホーロー看板の色の帯 */
  parts.carouselCard = function (post) {
    const category = data.categories[post.category];
    return `<article class="card carousel-card">
      <div class="carousel-card-head"><span class="fuda vertical small">${esc(post.prefecture)}</span>
        <div style="flex:1"><h3 class="carousel-title">${esc(post.title)}</h3><p class="post-area">${esc(post.city)}</p></div></div>
      <div class="carousel-card-foot"><span class="badge badge-category">${Mock.icon(category.icon, { size: 13 })}${esc(category.title)}</span>${parts.starButton(post)}</div>
    </article>`;
  };

  /** ぶっちゃけコメント（脱衣所の貼り紙） */
  parts.notice = function (text) {
    return `<div class="notice"><p class="notice-label">${esc(data.strings.honestComment)}</p><p class="notice-text">${esc(text)}</p></div>`;
  };
}());
