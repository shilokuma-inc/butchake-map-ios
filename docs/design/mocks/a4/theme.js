// A-4「ネオブルータリズム」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;
  const rankColors = ['', '#FFD60A', '#3BCB7A', '#B8A9FF'];

  /** ロゴタイプ「ぶっちゃけmap」（白のブロックと青のブロック）。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 28) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span></span>`;
  };

  /** 見出しと、横の小さな札（任意） */
  parts.sectionHeader = function (title, tag = '', color = '#FFD60A') {
    return `<h2 class="section-header">${esc(title)}${tag ? `<span class="tag" style="--c:${color}">${esc(tag)}</span>` : ''}</h2>`;
  };

  /** 大きな順位の数字 */
  parts.bigRank = function (order, size = 64) {
    return `<span class="big-rank" aria-label="${order}位" style="--c:${rankColors[order]};width:${size}px;height:${size}px;font-size:${Math.round(size * 0.62)}px">${order}</span>`;
  };

  /** カルーセルのカード: 上にベタ塗りの帯（カテゴリ）と、いいねの多い投稿は件数を大きく */
  parts.carouselCard = function (post) {
    const category = data.categories[post.category];
    return `<article class="card carousel-card">
      <div class="carousel-band" style="--c:${post.likeCount >= 200 ? '#FF5A36' : '#FFD60A'}"><span>${esc(category.title)}</span><span class="likes">♥ ${post.likeCount}</span></div>
      <h3 class="carousel-title">${esc(post.title)}</h3>
      <p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p>
      <div class="carousel-card-foot">${parts.authorBadge(post)}${parts.starButton(post)}</div>
    </article>`;
  };

  /** ぶっちゃけコメント（赤い札の付いた箱） */
  parts.box = function (text) {
    return `<div class="box"><span class="box-label">${esc(data.strings.honestComment)}</span><p class="box-text">${esc(text)}</p></div>`;
  };
}());
