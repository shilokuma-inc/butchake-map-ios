// A-5「バラエティ番組のテロップ」の部品。雛形の mock.js の後に読み込み、Mock.parts を差し替える。
(function () {
  const { data, parts, esc } = Mock;

  /** ロゴタイプ「ぶっちゃけmap」（番組のタイトルロゴ）。size は「ぶっちゃけ」の文字の大きさ（px） */
  Mock.logo = function (size = 30) {
    return `<span class="logo" style="font-size:${size}px"><span class="logo-main">ぶっちゃけ</span><span class="logo-map">map</span></span>`;
  };

  /** ワイプの顔（驚き・にっこり・ツッコミ） */
  Mock.face = function (kind = 'wow', size = 64) {
    const mouth = { wow: '<ellipse cx="32" cy="42" rx="6" ry="8" fill="#141414"/>', smile: '<path d="M22 38 q10 10 20 0" fill="none" stroke="#141414" stroke-width="3.5" stroke-linecap="round"/>',
      tsukkomi: '<path d="M22 42 h20" stroke="#141414" stroke-width="3.5" stroke-linecap="round"/>' }[kind];
    return `<span class="wipe" style="width:${size}px;height:${size}px"><svg width="${size * 0.8}" height="${size * 0.8}" viewBox="0 0 64 64" aria-hidden="true">
      <circle cx="32" cy="32" r="26" fill="#FFE600"/><circle cx="23" cy="27" r="3.5" fill="#141414"/><circle cx="41" cy="27" r="3.5" fill="#141414"/>${mouth}
      ${kind === 'tsukkomi' ? '<path d="M50 10 l6 -6 M54 16 l8 -2" stroke="#D7141E" stroke-width="3" stroke-linecap="round"/>' : ''}</svg></span>`;
  };

  /** 見出しはテロップの帯 */
  parts.sectionHeader = function (title, color = '') {
    return `<h2 class="section-header"><span class="telop ${color}">${esc(title)}</span></h2>`;
  };

  /** 「ぶっちゃけ」のハンコ */
  parts.hanko = function (text = 'ぶっ<br>ちゃけ', style = '') {
    return `<span class="hanko" style="${style}" aria-hidden="true">${text}</span>`;
  };

  /** いいねが多い投稿は、カードの角にハンコを押す */
  // カルーセルでは右上にスターがあるのでサムネイルの右に、フィードでは右上に押す
  const stampFor = (post, style) => (post.likeCount >= 200 ? parts.hanko('ぶっ<br>ちゃけ', `position:absolute;z-index:2;${style}`) : '');
  const basePostCard = parts.postCard;
  parts.postCard = post => basePostCard(post).replace('<article class="card post-card">', `<article class="card post-card">${stampFor(post, 'top:-12px;right:10px')}`);
  const baseCarouselCard = parts.carouselCard;
  parts.carouselCard = post => baseCarouselCard(post).replace('<article class="card carousel-card">', `<article class="card carousel-card">${stampFor(post, 'top:-10px;left:72px')}`);

  /** ぶっちゃけコメント（下テロップ） */
  parts.lowerThird = function (text) {
    return `<div class="lower"><span class="telop yellow lower-label">${esc(data.strings.honestComment)}</span><p class="lower-text">${esc(text)}</p></div>`;
  };
}());
