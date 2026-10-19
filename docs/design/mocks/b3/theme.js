// B-3「純喫茶のメニュー」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap」（喫茶店の看板）。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 26, sub = true) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-en">Kissa Butchake</span>
      <span class="logo-main">ぶっちゃけmap</span>${sub ? '<span class="logo-rule">since 2026</span>' : ''}</span>`;
  };

  /** 見出し（明朝と英字の筆記体、右に金の二重罫） */
  parts.sectionHeader = function (title, en = '') {
    return `<h2 class="section-header">${esc(title)}${en ? `<span class="en">${esc(en)}</span>` : ''}</h2>`;
  };

  /** メニュー表の 1 行（名前……右の小さな文字） */
  parts.menuRow = function (name, right, lead = '') {
    return `<li class="menu-row">${lead}<span class="name">${esc(name)}</span><span class="leader"></span><span class="price">${esc(right)}</span></li>`;
  };

  /** カルーセルのカードはメニュー表（スポットを品書きのように並べる） */
  parts.carouselCard = function (post) {
    return `<article class="menu carousel-card">
      <p class="menu-kicker">${esc(data.categories[post.category].title)} · ${esc(post.prefecture)}</p>
      <h3 class="carousel-title">${esc(post.title)}</h3>
      <ol class="menu-list">${post.spots.map(s => parts.menuRow(s.name, `No.${s.order}`)).join('')}</ol>
      <div class="carousel-card-foot"><span class="post-area" style="margin:0">${esc(post.city)}</span>${parts.starButton(post)}</div>
    </article>`;
  };

  /** フィードのカード: スポットをメニュー表の行で並べる */
  parts.postCard = function (post) {
    return `<article class="card post-card">
      <div class="post-card-head">${parts.thumbnail(post)}
        <div><h3 class="post-title">${esc(post.title)}</h3><p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p></div>
      </div>
      <div class="badges">${parts.categoryBadge(post)}${parts.authorBadge(post)}</div>
      <ol class="menu-list">${post.spots.map(s => parts.menuRow(s.name, `${s.order}位`, parts.rank(s.order))).join('')}</ol>
      <div class="post-card-foot"><span class="post-author">${esc(post.authorName)}</span>${parts.likeButton(post)}${parts.starButton(post)}</div>
    </article>`;
  };

  /** ぶっちゃけコメント（伝票） */
  parts.slip = function (text) {
    return `<div class="slip"><p class="slip-label">${esc(data.strings.honestComment)}</p><p class="slip-text">${esc(text)}</p></div>`;
  };
}());
