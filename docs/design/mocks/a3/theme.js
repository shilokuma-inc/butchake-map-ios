// A-3「駄菓子屋のおまけシール」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;
  const colors = ['#FF5FA2', '#5BD0F0', '#FFE14D', '#FF5FA2', '#5BD0F0'];

  /** ロゴタイプ「ぶっちゃけmap」（1 文字ずつ丸いシール、map はキラキラのシール）。size は 1 文字の大きさ（px） */
  Mock.logo = function (size = 26) {
    const chars = 'ぶっちゃけ'.split('').map((ch, i) =>
      `<span class="logo-ch" style="--c:${colors[i]};transform:rotate(${[-6, 4, -3, 5, -4][i]}deg)">${ch}</span>`).join('');
    return `<span class="logo" style="font-size:${size}px">${chars}<span class="logo-map">map</span></span>`;
  };

  /** キラキラの星（SVG） */
  Mock.sparkle = function (style = '', color = '#FFE14D') {
    return `<svg class="sparkle" style="${style}" viewBox="0 0 20 20" aria-hidden="true"><path d="M10 0 L12.4 7.6 L20 10 L12.4 12.4 L10 20 L7.6 12.4 L0 10 L7.6 7.6 Z" fill="${color}" stroke="#FFFFFF" stroke-width="1.2"/></svg>`;
  };

  /** 見出し。横に小さなシールを添える（任意） */
  parts.sectionHeader = function (title, sticker = '', color = '#FFE14D') {
    return `<h2 class="section-header">${esc(title)}${sticker ? `<span class="sticker" style="--c:${color};transform:rotate(-6deg)">${esc(sticker)}</span>` : ''}</h2>`;
  };

  /** いいねが多い投稿に貼るキラキラシール */
  parts.holoSticker = function (post) {
    if (post.likeCount >= 300) {
      return '<span class="sticker holo card-sticker">レア！</span>';
    }
    if (post.likeCount >= 200) {
      return '<span class="sticker card-sticker" style="--c:#5BD0F0">人気</span>';
    }
    return '';
  };

  const basePostCard = parts.postCard;
  parts.postCard = function (post) {
    return basePostCard(post).replace('<article class="card post-card">', `<article class="card post-card">${parts.holoSticker(post)}`);
  };

  const baseCarouselCard = parts.carouselCard;
  parts.carouselCard = function (post) {
    return baseCarouselCard(post).replace('<article class="card carousel-card">', `<article class="card carousel-card">${parts.holoSticker(post)}`);
  };

  /** ぶっちゃけコメント（メモ帳のシール） */
  parts.memo = function (text) {
    return `<div class="memo"><span class="memo-label">${esc(data.strings.honestComment)}</span><p class="memo-text">${esc(text)}</p></div>`;
  };
}());
