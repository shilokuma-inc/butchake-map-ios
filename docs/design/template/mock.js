// モックの組み立てに使う関数。mock-data.js と icons.js の後に読み込む。
// 画面のページは <div id="app"></div> に Mock.screen({...}) の結果を入れて描く（例: mocks/current/home.html）。
// 部品（カードやバッジ）は Mock.parts にあり、今のアプリの見た目をトークン（tokens.css の CSS 変数）で描く。
// 案ごとに見た目を変えるときは、トークンを上書きするか、Mock.parts の関数をページで差し替える。
(function () {
  const data = window.MOCK_DATA;
  const icons = window.MOCK_ICONS;

  /** HTML に入れる文字列をエスケープする */
  function esc(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  /** アイコンの SVG。size は CSS の px */
  function icon(name, options = {}) {
    const body = Mock.icons[name];
    if (!body) {
      throw new Error(`アイコン「${name}」がありません`);
    }
    const size = options.size || 20;
    const className = options.className ? ` ${options.className}` : '';
    return `<svg class="icon${className}" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none"
      stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"
      aria-hidden="true">${body}</svg>`;
  }

  /** ステータスバー（時刻・電波・Wi-Fi・電池）とダイナミックアイランド */
  function statusBar() {
    return `<div class="status-bar">
      <span class="status-time">9:41</span>
      <span class="dynamic-island"></span>
      <span class="status-icons">${icon('signal', { size: 17 })}${icon('wifi', { size: 17 })}${icon('battery', { size: 25 })}</span>
    </div>`;
  }

  /**
   * ナビゲーションバー。large なら大きなタイトル、そうでなければ中央の小さなタイトル。
   * leading / trailing はボタンのアイコン名の配列（back を渡すと戻るボタン）
   */
  function navBar({ title = '', large = false, back = false, trailing = [], titleHTML = null } = {}) {
    const leading = back ? `<span class="nav-button nav-back">${icon('chevronLeft', { size: 22 })}</span>` : '<span></span>';
    const buttons = trailing.map(name => `<span class="nav-button">${icon(name, { size: 22 })}</span>`).join('');
    const titleContent = titleHTML || esc(title);
    if (large) {
      return `<div class="nav-bar nav-large">
        <div class="nav-row">${leading}<span class="nav-trailing">${buttons}</span></div>
        <h1 class="nav-large-title">${titleContent}</h1>
      </div>`;
    }
    return `<div class="nav-bar nav-inline">
      <div class="nav-row">${leading}<span class="nav-inline-title">${titleContent}</span><span class="nav-trailing">${buttons}</span></div>
    </div>`;
  }

  /** タブバー（ホーム・マップ・投稿・検索・マイページ）。active は選択中のタブの id */
  function tabBar(active) {
    const items = data.tabs.map(tab => `<span class="tab-item${tab.id === active ? ' is-active' : ''}">
        ${icon(tab.icon, { size: 24 })}<span class="tab-title">${esc(tab.title)}</span>
      </span>`).join('');
    return `<nav class="tab-bar">${items}</nav>`;
  }

  /** ホームインジケーター */
  function homeIndicator() {
    return '<div class="home-indicator"></div>';
  }

  /**
   * 1 画面ぶん（402x874）を組み立てる。
   * nav: navBar の引数、body: スクロールする中身の HTML、tab: 選択中のタブ（null ならタブバーを出さない）、
   * overlay: 画面の上に重ねる HTML（シートなど）、className: 画面に付けるクラス
   */
  function screen({ nav = null, body = '', tab = null, overlay = '', className = '' } = {}) {
    return `<div class="screen ${className}">
      <div class="screen-scroll">
        ${statusBar()}
        ${nav ? navBar(nav) : ''}
        <main class="screen-body">${body}</main>
      </div>
      ${overlay}
      ${tab ? tabBar(tab) : ''}
      ${homeIndicator()}
    </div>`;
  }

  /** #app に HTML を入れる */
  function mount(html, selector = '#app') {
    document.querySelector(selector).innerHTML = html;
  }

  /** WCAG 2.x のコントラスト比（Tools/check_design_contrast.py と同じ式） */
  function contrastRatio(fg, bg) {
    const luminance = hex => {
      let digits = hex.replace('#', '');
      if (digits.length === 3) {
        digits = digits.split('').map(ch => ch + ch).join('');
      }
      const channels = [0, 2, 4].map(i => parseInt(digits.slice(i, i + 2), 16) / 255)
        .map(c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
      return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
    };
    const [lighter, darker] = [luminance(fg), luminance(bg)].sort((a, b) => b - a);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /**
   * palette.json（書き出しのときに window.MOCK_PALETTE として渡される）のコントラスト比の表。
   * palette.json が無いとエラーにする（ブランドシートで表が空のまま書き出さないため）
   */
  function paletteTable() {
    const palette = window.MOCK_PALETTE;
    if (!palette || !Array.isArray(palette.pairs)) {
      throw new Error('palette.json が読み込まれていません（Tools/render_design_mocks.sh で書き出してください）');
    }
    const rows = palette.pairs.map(pair => {
      const ratio = contrastRatio(pair.fg, pair.bg);
      const required = pair.large === true ? 3 : 4.5;
      return `<tr>
        <td><span class="contrast-sample" style="color:${esc(pair.fg)};background:${esc(pair.bg)}">あA</span></td>
        <td>${esc(pair.name)}</td>
        <td><code>${esc(pair.fg.toUpperCase())}</code> / <code>${esc(pair.bg.toUpperCase())}</code></td>
        <td>${pair.large === true ? '大' : '通常'}</td>
        <td class="contrast-ratio">${ratio.toFixed(2)}:1 ${ratio >= required ? 'AA' : '× AA 未満'}</td>
      </tr>`;
    }).join('');
    return `<table class="contrast-table"><thead><tr><th></th><th>組</th><th>文字 / 背景</th><th>文字</th><th>比</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  }

  /** palette.json の colors の色見本 */
  function paletteSwatches() {
    const palette = window.MOCK_PALETTE;
    if (!palette || !Array.isArray(palette.colors)) {
      throw new Error('palette.json に colors がありません');
    }
    return `<div class="swatches">${palette.colors.map(color => `<div class="swatch">
        <span class="swatch-chip" style="background:${esc(color.hex)}"></span>
        <span class="swatch-name">${esc(color.name)}</span>
        <code class="swatch-hex">${esc(color.hex.toUpperCase())}</code>
      </div>`).join('')}</div>`;
  }

  // MARK: - 部品（今のアプリの見た目。トークンで色・書体・角丸を変えられる）

  const parts = {
    /** カテゴリのバッジ */
    categoryBadge(post) {
      const category = data.categories[post.category];
      return `<span class="badge badge-category">${icon(category.icon, { size: 13 })}${esc(category.title)}</span>`;
    },

    /** 投稿者の属性のバッジ */
    authorBadge(post) {
      const authorType = data.authorTypes[post.authorType];
      return `<span class="badge badge-author">${icon(authorType.icon, { size: 13 })}${esc(authorType.title)}</span>`;
    },

    /** いいね（件数つき） */
    likeButton(post) {
      return `<span class="count-button like-button${post.isLiked ? ' is-on' : ''}">
        ${icon(post.isLiked ? 'heartFill' : 'heart', { size: 17 })}${post.likeCount.toLocaleString('ja-JP')}</span>`;
    },

    /** スター（件数つき） */
    starButton(post) {
      return `<span class="count-button star-button${post.isStarred ? ' is-on' : ''}">
        ${icon(post.isStarred ? 'starFill' : 'star', { size: 17 })}${post.starCount.toLocaleString('ja-JP')}</span>`;
    },

    /** スポットの順位の丸数字 */
    rank(order, className = '') {
      return `<span class="rank ${className}">${order}</span>`;
    },

    /** 写真の代わりに出すカテゴリのアイコン */
    thumbnail(post, size = 56) {
      const category = data.categories[post.category];
      return `<span class="thumbnail" style="width:${size}px;height:${size}px">${icon(category.icon, { size: size * 0.42 })}</span>`;
    },

    /** フィードの投稿カード */
    postCard(post) {
      const spots = post.spots.map(spot => `<li class="spot-row">${parts.rank(spot.order)}<span>${esc(spot.name)}</span></li>`).join('');
      return `<article class="card post-card">
        <div class="post-card-head">${parts.thumbnail(post)}
          <div><h3 class="post-title">${esc(post.title)}</h3><p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p></div>
        </div>
        <div class="badges">${parts.categoryBadge(post)}${parts.authorBadge(post)}</div>
        <ol class="spot-list">${spots}</ol>
        <div class="post-card-foot"><span class="post-author">${esc(post.authorName)}</span>${parts.likeButton(post)}${parts.starButton(post)}</div>
      </article>`;
    },

    /** ホームのカルーセルの小さめのカード */
    carouselCard(post) {
      return `<article class="card carousel-card">
        <div class="carousel-card-head">${parts.thumbnail(post, 44)}${parts.starButton(post)}</div>
        <h3 class="carousel-title">${esc(post.title)}</h3>
        <p class="post-area">${esc(post.prefecture)} ${esc(post.city)}</p>
        <div class="badges">${parts.categoryBadge(post)}</div>
      </article>`;
    },

    /** 見出し */
    sectionHeader(title) {
      return `<h2 class="section-header">${esc(title)}</h2>`;
    },
  };

  /**
   * イラストの地図（実際の地図の画像は使わない）。色は CSS 変数 --map-* で変える。
   * pins: [{ order, x, y, selected }]（x, y は %）
   */
  function mapIllustration(pins = []) {
    const pinHTML = pins.map(pin => `<span class="map-pin${pin.selected ? ' is-selected' : ''}"
      style="left:${pin.x}%;top:${pin.y}%">${pin.order}</span>`).join('');
    return `<div class="map-illustration">
      <svg viewBox="0 0 402 874" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
        <rect width="402" height="874" fill="var(--map-land)"/>
        <path d="M-10 610 C 80 560, 150 640, 230 600 S 360 520, 420 560 L 420 690 C 330 660, 260 720, 170 700 S 40 690, -10 720 Z" fill="var(--map-water)"/>
        <path d="M250 120 h110 v90 h-110 z M40 300 h90 v70 h-90 z M290 380 h80 v120 h-80 z" fill="var(--map-park)"/>
        <g stroke="var(--map-road)" stroke-width="14" fill="none" stroke-linecap="round">
          <path d="M-10 250 L 420 200"/><path d="M120 -10 L 170 900"/><path d="M-10 470 C 120 430, 260 500, 420 440"/>
        </g>
        <g stroke="var(--map-road-minor)" stroke-width="6" fill="none" stroke-linecap="round">
          <path d="M-10 140 L 420 110"/><path d="M260 -10 L 230 900"/><path d="M-10 380 L 420 330"/><path d="M60 -10 L 40 900"/>
          <path d="M350 -10 L 380 900"/><path d="M-10 800 L 420 770"/>
        </g>
      </svg>
      ${pinHTML}
    </div>`;
  }

  window.Mock = {
    data,
    icons,
    esc,
    icon,
    statusBar,
    navBar,
    tabBar,
    homeIndicator,
    screen,
    mount,
    contrastRatio,
    paletteTable,
    paletteSwatches,
    parts,
    mapIllustration,
  };
}());
