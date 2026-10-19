// B-1「昭和の観光パンフ」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;
  const kanji = ['〇', '一', '二', '三'];

  /** ロゴタイプ「ぶっちゃけmap」と、明朝の添え書き「全国本音観光案内」。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 30, withSub = true) {
    return `<span class="logo" style="font-size:${size}px">
      <span class="logo-row"><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span></span>
      ${withSub ? '<span class="logo-sub">全国本音観光案内</span>' : ''}</span>`;
  };

  /** 見出し。朱の丸と、明朝の小さな添え書き */
  parts.sectionHeader = function (title, sub = '') {
    return `<h2 class="section-header">${esc(title)}${sub ? `<span class="section-sub">${esc(sub)}</span>` : ''}</h2>`;
  };

  /** 順位は漢数字（一・二・三）の朱の角印 */
  parts.rank = function (order, className = '') {
    return `<span class="rank ${className}" aria-label="${order}位">${kanji[order] || order}</span>`;
  };

  /** 消印風のスタンプ（上の小さな文字・大きな文字・下の小さな文字） */
  parts.postmark = function (top, main, bottom, style = '') {
    return `<span class="postmark" style="${style}"><small>${esc(top)}</small><strong>${esc(main)}</strong><small>${esc(bottom)}</small></span>`;
  };

  /** カルーセルのカードは切手にする（右上に額面の代わりの「三大」） */
  parts.carouselCard = function (post) {
    return `<article class="stamp carousel-card"><div class="stamp-inner">
      <div class="carousel-card-head">${parts.thumbnail(post, 44)}<span class="denomination">三大</span></div>
      <h3 class="carousel-title">${esc(post.title)}</h3>
      <p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p>
      <div class="carousel-card-foot"><div class="badges">${parts.categoryBadge(post)}</div>${parts.starButton(post)}</div>
    </div></article>`;
  };

  /** フィードのカードには、投稿日の消印を押す */
  const basePostCard = parts.postCard;
  parts.postCard = function (post) {
    const [year, month, day] = post.date.split('/');
    return basePostCard(post).replace('<article class="card post-card">',
      `<article class="card post-card">${parts.postmark(year, `${Number(month)}.${Number(day)}`, post.prefecture, 'position:absolute;top:10px;right:12px')}`);
  };

  /** ぶっちゃけコメント（便せんの罫線） */
  parts.comment = function (text) {
    return `<div class="letter"><p class="letter-label">${esc(data.strings.honestComment)}</p><p class="letter-text">${esc(text)}</p></div>`;
  };
}());
