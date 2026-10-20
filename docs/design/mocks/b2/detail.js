// 投稿詳細: 都市の駅名標・タイトル・作者といいね／スター。3 つのスポットを路線図の駅として並べ、行った駅にはスタンプを押す。コメントは駅の掲示板
const { data, parts, icon, esc } = Mock;
const post = data.posts[0];
const stop = (s, stamped) => `<article class="stop">${parts.rank(s.order)}
  <div class="stop-head"><div><p class="stop-name">${esc(s.name)}</p><p class="stop-address">${icon('mappin', { size: 14 })}${esc(s.address)}</p></div>
    ${stamped ? parts.stamp('10.18', '済', '金沢') : '<span class="stamp-slot" style="width:56px;height:56px">未</span>'}</div>
  ${parts.notice(s.recommendation)}
  <span class="rail-button secondary" style="align-self:flex-start">${icon('map', { size: 17 })}${esc(data.strings.openInMaps)}</span>
</article>`;
Mock.mount(Mock.screen({
  nav: { title: '', back: true, trailing: ['share'] },
  body: `<div class="detail">
    <div class="sign station"><p class="sign-name">${esc(post.city)}</p><p class="sign-en">KANAZAWA · ${esc(post.prefecture)}</p>
      <p class="sign-bar"><span>◀ ${esc(data.categories[post.category].title)}</span><span>${esc(data.authorTypes[post.authorType].title)} ▶</span></p></div>
    <h1 class="detail-title">${esc(post.title)}</h1>
    <div class="badges">${parts.categoryBadge(post)}${parts.authorBadge(post)}</div>
    <div class="detail-meta"><p class="detail-author">${esc(post.authorName)}<span>${esc(post.date)}</span></p>${parts.likeButton(post)}${parts.starButton(post)}</div>
    <div class="route">${stop(post.spots[0], true)}${stop(post.spots[1], false)}</div>
  </div>`,
}));
