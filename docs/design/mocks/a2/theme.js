// A-2「マンガのツッコミ」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, icon, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap!?」。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 30) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span><span class="logo-mark">!?</span></span>`;
  };

  /** 見出し（描き文字）と、横に添える効果音（任意） */
  parts.sectionHeader = function (title, sfx = '') {
    return `<h2 class="section-header">${esc(title)}${sfx ? `<span class="sfx">${esc(sfx)}</span>` : ''}</h2>`;
  };

  /** 写真の代わりのサムネイル（網点の上にカテゴリのアイコン） */
  parts.thumbnail = function (post, size = 56) {
    const category = data.categories[post.category];
    return `<span class="thumbnail tone" style="width:${size}px;height:${size}px">${icon(category.icon, { size: size * 0.46 })}</span>`;
  };

  /** スポットの順位（黒地に白の数字を斜めに） */
  parts.rank = function (order, className = '') {
    return `<span class="rank ${className}"><span style="display:inline-block;transform:skewX(8deg)">${order}</span></span>`;
  };

  /** ぶっちゃけコメントのフキダシ */
  parts.balloon = function (text, label = data.strings.honestComment) {
    return `<div class="balloon">${label ? `<span class="balloon-label">${esc(label)}</span>` : ''}${esc(text)}</div>`;
  };

  /** いいねが多い投稿に添える効果音 */
  parts.sfxFor = function (post) {
    if (post.likeCount >= 300) {
      return '<span class="sfx card-sfx">ドーン!!</span>';
    }
    if (post.likeCount >= 200) {
      return '<span class="sfx card-sfx">ザワ…</span>';
    }
    return '';
  };

  const basePostCard = parts.postCard;
  parts.postCard = function (post) {
    return basePostCard(post).replace('<article class="card post-card">', `<article class="card post-card">${parts.sfxFor(post)}`);
  };

  const baseCarouselCard = parts.carouselCard;
  parts.carouselCard = function (post) {
    return baseCarouselCard(post).replace('<article class="card carousel-card">', `<article class="card carousel-card">${parts.sfxFor(post)}`);
  };
}());
