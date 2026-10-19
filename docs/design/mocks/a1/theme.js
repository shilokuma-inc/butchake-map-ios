// A-1「王道ポップ」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap」。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 30) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span></span>`;
  };

  /** 見出し。蛍光ペンの下線と、横に添えるステッカー（任意） */
  parts.sectionHeader = function (title, sticker = '') {
    return `<h2 class="section-header"><span class="marker">${esc(title)}</span>${sticker ? `<span class="sticker">${esc(sticker)}</span>` : ''}</h2>`;
  };

  /** スポットの順位（黒丸に黄色の数字） */
  parts.rank = function (order, className = '') {
    return `<span class="rank ${className}">${order}</span>`;
  };

  /** いいねが多い投稿に貼るステッカー（にぎやかさを出す） */
  parts.hotSticker = function (post) {
    if (post.likeCount >= 300) {
      return '<span class="sticker card-sticker" style="background:var(--orange)">バズり中！</span>';
    }
    if (post.likeCount >= 200) {
      return '<span class="sticker card-sticker">みんな推し</span>';
    }
    return '';
  };

  const basePostCard = parts.postCard;
  parts.postCard = function (post) {
    return basePostCard(post).replace('<article class="card post-card">',
      `<article class="card post-card">${parts.hotSticker(post)}`);
  };

  const baseCarouselCard = parts.carouselCard;
  parts.carouselCard = function (post) {
    return baseCarouselCard(post).replace('<article class="card carousel-card">',
      `<article class="card carousel-card">${parts.hotSticker(post)}`);
  };

  /** ぶっちゃけコメントの吹き出し */
  parts.commentBubble = function (text) {
    return `<div class="bubble"><span class="bubble-label">${esc(data.strings.honestComment)}</span><p class="bubble-text">${esc(text)}</p></div>`;
  };
}());
