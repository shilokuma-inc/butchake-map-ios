// マップ: 3 つのスポットを順位の順（1 → 2 → 3）に路線でつなぎ、ピンは駅の丸。選んだ駅は紺のスタンプの丸と、小さな駅名標
const { data, parts, icon, esc } = Mock;
const post = data.posts[0];
const spot = post.spots[1];
const pins = post.spots.map(s => ({ order: s.order, x: s.mapPosition.x, y: s.mapPosition.y * 0.5 + 6, selected: s === spot }));
// 3 の駅は 1 と 2 の間にあり、路線（1 → 2 → 3）が重なって見えるので、このモックでは 2 の先（右上）に置く
Object.assign(pins.find(p => p.order === 3), { x: 84, y: 20 });
// 地図の高さ（874 - 106）に対する % を、SVG の座標（402 x 768）に直して路線を引く
const pt = p => `${(p.x / 100) * 402} ${(p.y / 100) * 768}`;
const order = [...pins].sort((a, b) => a.order - b.order);
const route = `<svg class="route" viewBox="0 0 402 768" preserveAspectRatio="none" aria-hidden="true">
  <path d="M ${pt(order[0])} L ${pt(order[1])} L ${pt(order[2])}" fill="none" style="stroke: var(--rail)" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
const sel = pins.find(p => p.selected);
const sign = `<div class="pin-sign sign" style="left:${sel.x}%;top:${sel.y}%"><p class="sign-name">もりもり寿し</p>
  <p class="sign-bar"><span>◀ 1</span><span>3 ▶</span></p></div>`;
Mock.mount(Mock.screen({
  className: 'map-screen',
  nav: { title: 'マップ' },
  overlay: `${Mock.mapIllustration(pins).replace('<span class="map-pin', `${route}${sign}<span class="map-pin`)}
    <section class="sheet-panel">
      <span class="grabber"></span>
      <div class="badges">${parts.categoryBadge(post)}${parts.authorBadge(post)}</div>
      <div><h2 class="sheet-title">${esc(post.title)}</h2>
        <p class="sheet-area">${icon('mappin', { size: 14 })}${esc(post.prefecture)} ${esc(post.city)}</p></div>
      <div class="spot-line">${parts.rank(spot.order)}
        <div style="flex:1"><p class="spot-name">${esc(spot.name)}</p><p class="spot-address">${esc(spot.address)}</p></div>
        ${parts.stamp('10.18', '済', '金沢', 'width:54px;height:54px')}</div>
      ${parts.notice(spot.recommendation)}
      <div class="sheet-actions">${parts.likeButton(post)}${parts.starButton(post)}
        <span class="rail-button">${esc(data.strings.viewPost)}${icon('chevronRight', { size: 16 })}</span></div>
    </section>`,
}));
