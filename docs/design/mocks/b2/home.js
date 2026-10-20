// ホーム: 駅名標のロゴ・今月のスタンプ帳（押した数）・駅名標の見出し・きっぷのカルーセル・台紙の投稿カード
const { data, parts } = Mock;
const posts = data.posts;
const byLikes = [...posts].sort((a, b) => b.likeCount - a.likeCount);
Mock.mount(Mock.screen({
  nav: { large: true, titleHTML: Mock.logo(24) },
  tab: 'home',
  body: `<div class="rally-card"><p>スタンプ帳<small>今月 2 / 3 こ あつめた</small></p>
      ${parts.stamp('10.12', '横浜', '')}${parts.stamp('10.18', '金沢', '')}<span class="stamp-slot">？</span></div>
    <div class="home">
      <section>${parts.sectionHeader(data.strings.weeklyPicks, 'THIS WEEK', '', data.strings.trending)}
        <div class="carousel">${posts.slice(0, 3).map(parts.carouselCard).join('')}</div></section>
      <section>${parts.sectionHeader(data.strings.trending, 'TRENDING', data.strings.weeklyPicks, data.strings.latestPosts)}
        <div class="carousel">${byLikes.slice(0, 3).map(parts.carouselCard).join('')}</div></section>
      <section>${parts.sectionHeader(data.strings.latestPosts, 'LATEST', data.strings.trending, '')}
        <div class="feed">${posts.slice(0, 2).map(parts.postCard).join('')}</div></section>
    </div>`,
}));
