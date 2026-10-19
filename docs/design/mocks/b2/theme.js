// B-2「駅のスタンプラリー」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, icon, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap」（駅名標の形）。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 26) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-name">ぶっちゃけ<span class="map">map</span></span>
      <span class="logo-en">BUTCHAKE MAP</span><span class="logo-bar"><span>◀ ほんね</span><span>たび ▶</span></span></span>`;
  };

  /** 見出しは駅名標（駅名・英字・前後の駅の帯） */
  parts.sectionHeader = function (title, en = '', prev = '', next = '') {
    return `<div class="section-header"><div class="sign"><p class="sign-name">${esc(title)}</p>
      ${en ? `<p class="sign-en">${esc(en)}</p>` : ''}
      ${prev || next ? `<p class="sign-bar"><span>${prev ? `◀ ${esc(prev)}` : ''}</span><span>${next ? `${esc(next)} ▶` : ''}</span></p>` : ''}</div></div>`;
  };

  /** スタンプ（上の小さな文字・大きな文字・下の小さな文字） */
  parts.stamp = function (top, main, bottom, style = '') {
    return `<span class="stamp-mark" style="${style}"><small>${esc(top)}</small><strong>${esc(main)}</strong><small>${esc(bottom)}</small></span>`;
  };

  /** カルーセルのカードはきっぷにする */
  parts.carouselCard = function (post) {
    return `<article class="ticket carousel-card">
      <div class="ticket-top"><span>ぶっちゃけ線</span><span>${esc(post.date)}</span></div>
      <h3 class="carousel-title">${esc(post.title)}</h3>
      <p class="ticket-route">${esc(post.prefecture)} ${esc(post.city)} ゆき</p>
      <div class="carousel-card-foot"><div class="badges">${parts.categoryBadge(post)}</div>${parts.starButton(post)}</div>
    </article>`;
  };

  /** フィードのカードには、スタンプラリーの台紙のように 3 つのスタンプ欄を並べる */
  parts.postCard = function (post) {
    const spots = post.spots.map(spot => `<li class="spot-row">${parts.rank(spot.order)}<span>${esc(spot.name)}</span></li>`).join('');
    const [, month, day] = post.date.split('/');
    return `<article class="card post-card">
      <div class="post-card-head">${parts.thumbnail(post)}
        <div><h3 class="post-title">${esc(post.title)}</h3><p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p></div>
      </div>
      <div class="badges">${parts.categoryBadge(post)}${parts.authorBadge(post)}</div>
      <div class="rally"><ol class="spot-list">${spots}</ol>${parts.stamp('2026', `${Number(month)}.${Number(day)}`, post.city)}</div>
      <div class="post-card-foot"><span class="post-author">${esc(post.authorName)}</span>${parts.likeButton(post)}${parts.starButton(post)}</div>
    </article>`;
  };

  /** ぶっちゃけコメント（駅の掲示板） */
  parts.notice = function (text) {
    return `<div class="notice"><p class="notice-label">${icon('mappin', { size: 13 })}${esc(data.strings.honestComment)}</p><p class="notice-text">${esc(text)}</p></div>`;
  };
}());
