// ダークモードのブランドシート: 配色とコントラスト比（palette-dark.json）・ロゴ・空の状態のイラスト・部品を、ダークの地に置いて見る
const { data, parts, icon, esc } = Mock;
const post = data.posts[0];
const pinsSample = Mock.mapIllustration([]).replace('<div class="map-illustration">', '<div class="map-illustration" style="display:none">');
Mock.mount(`<div class="sheet">
  <div class="sheet-head">${Mock.logo(50)}
    <p>B-2「駅のスタンプラリー」のダークモード（夜の駅）<br>地を夜の紺に暗くし、紺のインクと路線の緑を明るくする。インクと緑の地に載せる文字は地の色にする。</p></div>
  <div class="grid">
    <div>
      <section class="sheet-section"><h2>ロゴ</h2>
        <div class="panel logo-panel">${Mock.logo(60)}
          <div class="nav-sample">${Mock.navBar({ large: true, titleHTML: Mock.logo(24) })}</div></div></section>
      <section class="sheet-section"><h2>空の状態のイラスト</h2>
        <div class="panel empty-row">
          <div class="empty"><img src="empty-posts.svg" alt=""><strong>${esc(data.strings.noPosts)}</strong><p>${esc(data.strings.noPostsDescription)}</p></div>
          <div class="empty"><img src="empty-search.svg" alt=""><strong>${esc(data.strings.noResults)}</strong><p>${esc(data.strings.noResultsDescription)}</p></div>
        </div>
        <p class="note">イラストはライトと同じ色のまま（台紙の札として地から浮かせる）。ダークで色を変えるかは、アプリに入れるときに見て決める</p></section>
      <section class="sheet-section"><h2>スタンプ帳</h2>
        <div class="rally-card"><p>スタンプ帳<small>今月 2 こ</small></p>
          ${parts.stamp('10.12', '横浜', '')}${parts.stamp('10.18', '金沢', '')}<span class="stamp-slot">？</span></div></section>
    </div>
    <div>
      <section class="sheet-section"><h2>カラーパレット</h2>${Mock.paletteSwatches()}</section>
      <section class="sheet-section"><h2>コントラスト比（WCAG AA）</h2>${Mock.paletteTable()}</section>
    </div>
  </div>
  <section class="sheet-section"><h2>部品</h2>
    <div class="parts-grid">
      <div class="parts-col">
        ${parts.postCard(data.posts[1])}
        <div class="row">${Object.keys(data.categories).map(c => parts.categoryBadge({ category: c })).join('')}</div>
        <div class="row">${Object.keys(data.authorTypes).map(a => parts.authorBadge({ authorType: a })).join('')}
          ${parts.stamp('10.18', '済', '金沢')}${parts.stamp('10.18', '公開', '金沢')}</div>
        <div class="row"><span class="rail-button">${esc(data.strings.publish)}</span>
          <span class="rail-button secondary">${icon('map', { size: 18 })}${esc(data.strings.openInMaps)}</span>
          ${parts.likeButton(post)}${parts.starButton(data.posts[1])}</div>
        <div class="tabbar-sample">${Mock.tabBar('map')}</div>
        <div class="pins-sample">${pinsSample}
          <span class="map-pin" style="left:20%;top:50%"><span>1</span></span>
          <span class="map-pin" style="left:40%;top:50%"><span>2</span></span>
          <span class="map-pin is-selected" style="left:66%;top:50%"><span>3</span></span></div>
      </div>
      <div class="parts-col">${parts.carouselCard(data.posts[2])}${parts.sectionHeader('今週のぶっちゃけ', 'THIS WEEK', '新着', '急上昇')}${parts.notice(post.spots[1].recommendation)}</div>
    </div></section>
</div>`);
