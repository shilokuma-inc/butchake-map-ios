// デザイン案のモック（HTML）を macOS の WebKit で PNG に書き出す。Tools/render_design_mocks.sh から呼ぶ。
//
//   xcrun swift Tools/render_design_mocks.swift <出力ディレクトリ> <ページの HTML>…
//
// ページの HTML には、書き出す大きさを CSS の px で宣言する（倍率は省略すると 3）:
//
//   <meta name="mock-size" content="402x874">
//   <meta name="mock-scale" content="3">
//   <meta name="mock-fonts" content="Dela Gothic One|M PLUS Rounded 1c">
//
// 出力は <出力ディレクトリ>/<ページ名>.png で、ピクセル数は mock-size × mock-scale になる。
// 次のどれかを検出したら、そのページを失敗として扱い、最後に 0 以外で終わる（□ や代替フォントのまま添付しないため）:
//   - フォントの読み込みの失敗（status が error の FontFace がある・mock-fonts の書体が読み込まれていない）
//   - 画像の欠け（読み込めていない、または naturalWidth が 0 の img）
//   - 寸法の違い（ページの中身が mock-size からはみ出している・書き出した画像のピクセル数が違う）
//   - ページの JavaScript のエラー
//   - 読み込めなかった CSS・スクリプト・画像、Web フォントを読み込んでいるのに mock-fonts が無いページ
// ページが window.mockReady（Promise）を置いていれば、それが終わるまで待ってから検査する（iframe で別のページを並べる比較シートのため）。
// ページと同じディレクトリに palette.json があれば、読み込む前に window.MOCK_PALETTE として渡す
// （ブランドシートでコントラスト比の表を描くため）。ダークモードのブランドシートのように別の配色を描くページは、
// <meta name="mock-palette" content="palette-dark.json"> で同じディレクトリの別のファイルを指定する（無ければエラー）。

import AppKit
import Foundation
import WebKit

/// 1 ページの書き出しの設定
struct MockPage {
    let htmlURL: URL
    let outputURL: URL
    /// CSS の px で宣言した大きさ
    let size: CGSize
    /// CSS の 1px を何ピクセルで書き出すか
    let scale: CGFloat
    /// 読み込めていることを確かめる書体（CSS の font-family の名前）
    let fontFamilies: [String]
    /// palette.json の中身（無ければ nil）
    let paletteJSON: String?

    /// WebKit に読ませてよい範囲。雛形（template/）を含む docs/design まで上がる。見つからなければページのディレクトリ
    var readAccessURL: URL {
        var directory = htmlURL.deletingLastPathComponent()
        while directory.path != "/" {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("template").path) {
                return directory
            }
            directory.deleteLastPathComponent()
        }
        return htmlURL.deletingLastPathComponent()
    }

    var pixelWidth: Int { Int((size.width * scale).rounded()) }
    var pixelHeight: Int { Int((size.height * scale).rounded()) }

    init(htmlURL: URL, outputDirectory: URL) throws {
        let html = try String(contentsOf: htmlURL, encoding: .utf8)
        guard let sizeText = Self.metaContent(named: "mock-size", in: html) else {
            throw RenderError("<meta name=\"mock-size\" content=\"幅x高さ\"> がありません")
        }
        let parts = sizeText.split(separator: "x").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, parts.allSatisfy({ $0 > 0 }) else {
            throw RenderError("mock-size の値「\(sizeText)」を読めません（例: 402x874）")
        }
        let scaleText = Self.metaContent(named: "mock-scale", in: html) ?? "3"
        guard let scale = Double(scaleText), scale > 0 else {
            throw RenderError("mock-scale の値「\(scaleText)」を読めません（例: 3）")
        }
        let fonts = Self.metaContent(named: "mock-fonts", in: html) ?? ""
        let paletteName = Self.metaContent(named: "mock-palette", in: html)
        if let paletteName, paletteName.isEmpty || paletteName.contains("/") || !paletteName.hasSuffix(".json") {
            throw RenderError("mock-palette の値「\(paletteName)」は、同じディレクトリの .json のファイル名で書いてください")
        }
        let paletteURL = htmlURL.deletingLastPathComponent().appendingPathComponent(paletteName ?? "palette.json")

        self.htmlURL = htmlURL
        outputURL = outputDirectory
            .appendingPathComponent(htmlURL.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("png")
        size = CGSize(width: parts[0], height: parts[1])
        self.scale = scale
        fontFamilies = fonts.split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if paletteName != nil, !FileManager.default.fileExists(atPath: paletteURL.path) {
            throw RenderError("mock-palette で指定した \(paletteURL.path) がありません")
        }
        paletteJSON = try Self.readPalette(at: paletteURL)
    }

    /// palette.json を読む。無ければ nil。JSON として読めなければエラーにする（壊れた JSON をページに渡すと、ページの検査ごと動かなくなるため）
    private static func readPalette(at url: URL) throws -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        guard (try? JSONSerialization.jsonObject(with: data)) is [String: Any],
              let text = String(data: data, encoding: .utf8) else {
            throw RenderError("\(url.path) を JSON のオブジェクトとして読めません")
        }
        return text
    }

    /// <meta name="…" content="…"> の content を取り出す（属性の順は name → content に限る）
    private static func metaContent(named name: String, in html: String) -> String? {
        let pattern = "<meta\\s+name=\"\(NSRegularExpression.escapedPattern(for: name))\"\\s+content=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[range])
    }
}

struct RenderError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// 読み込みが終わったページで、フォント・画像・寸法を確かめる JavaScript（エラーの文言の配列を返す）
private let inspectionScript = """
await document.fonts.ready;
if (window.mockReady) {
  await window.mockReady;
}
await new Promise(resolve => setTimeout(resolve, 300));
await document.fonts.ready;
const errors = [...(window.__mockErrors || [])];
const faces = [...document.fonts];
for (const face of faces) {
  if (face.status === 'error') {
    errors.push(`フォント「${face.family}」(${face.weight}) の読み込みに失敗しました`);
  }
}
const normalize = name => name.replace(/^["']|["']$/g, '');
for (const family of fontFamilies) {
  const loaded = faces.some(face => normalize(face.family) === family && face.status === 'loaded');
  if (!loaded) {
    errors.push(`フォント「${family}」が読み込まれていません（名前の誤り・ネットワーク・ページで使っていない など）`);
  }
}
const webFontLinks = [...document.querySelectorAll('link[rel="stylesheet"]')]
  .filter(link => link.href.includes("fonts.googleapis.com"));
if (webFontLinks.length > 0 && fontFamilies.length === 0) {
  errors.push('Web フォントを読み込んでいるのに <meta name="mock-fonts"> がありません（読み込みを確かめられません）');
}
for (const image of document.images) {
  if (!image.complete || image.naturalWidth === 0) {
    errors.push(`画像「${image.getAttribute('src')}」を読み込めませんでした`);
  }
}
const root = document.documentElement;
if (root.scrollWidth > width || root.scrollHeight > height) {
  errors.push(`ページの中身 ${root.scrollWidth}x${root.scrollHeight} が mock-size ${width}x${height} からはみ出しています`);
}
return errors;
"""

@MainActor
final class MockRenderer: NSObject, WKNavigationDelegate {
    private let pages: [MockPage]
    private var index = 0
    private var failures: [String] = []
    private let window: NSWindow
    private var webView: WKWebView?
    private var timeoutTask: Task<Void, Never>?

    init(pages: [MockPage]) {
        self.pages = pages
        window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        super.init()
    }

    func start() {
        renderNext()
    }

    private func renderNext() {
        guard index < pages.count else {
            finish()
            return
        }
        let page = pages[index]
        // 画面の外に動かしてから倍率を読む（動かした先のディスプレイの倍率で描かれるため）
        window.setFrameOrigin(CGPoint(x: -20_000, y: 0))
        let backingScale = window.backingScaleFactor
        // CSS の 1px を page.scale ピクセルにするため、ポイントでは scale / backingScale 倍で描く
        let zoom = page.scale / backingScale
        let frame = CGRect(x: 0, y: 0, width: page.size.width * zoom, height: page.size.height * zoom)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(
            source: Self.errorCollector,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        configuration.userContentController.addUserScript(WKUserScript(
            source: "window.MOCK_PALETTE = \(page.paletteJSON ?? "null");",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.pageZoom = zoom
        webView.navigationDelegate = self
        window.setContentSize(frame.size)
        window.contentView = webView
        window.orderFrontRegardless()
        self.webView = webView

        let pageIndex = index
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled, self?.index == pageIndex else {
                return
            }
            self?.fail(page, "60 秒以内に読み込みが終わりませんでした")
        }
        webView.loadFileURL(page.htmlURL, allowingReadAccessTo: page.readAccessURL)
    }

    /// ページの読み込み前に流す JavaScript。JavaScript のエラーと、読み込めなかった CSS・スクリプト・画像を集める。
    /// リソースの error は window まで伝わらないので、capture で拾う
    private static let errorCollector = """
        window.__mockErrors = [];
        window.addEventListener('error', event => {
          const target = event.target;
          if (target && target !== window && (target.src || target.href)) {
            window.__mockErrors.push(`読み込めませんでした: ${target.src || target.href}`);
          } else {
            window.__mockErrors.push(`JavaScript のエラー: ${event.message}（${event.filename}:${event.lineno}）`);
          }
        }, true);
        window.addEventListener('unhandledrejection', event => {
          window.__mockErrors.push(`Promise のエラー: ${event.reason}`);
        });
        """

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        Task { @MainActor in
            guard webView === self.webView else {
                return
            }
            await self.inspectAndSnapshot()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
        Task { @MainActor in
            guard webView === self.webView else {
                return
            }
            self.fail(self.pages[self.index], "読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: any Error
    ) {
        Task { @MainActor in
            guard webView === self.webView else {
                return
            }
            self.fail(self.pages[self.index], "読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    private func inspectAndSnapshot() async {
        guard let webView else {
            return
        }
        let page = pages[index]
        // 待っている間にタイムアウトで次のページへ進んでいたら、結果を捨てる（同じページを二重に数えないため）
        let isCurrent = { [weak self] in self?.webView === webView }
        do {
            let result = try await webView.callAsyncJavaScript(
                inspectionScript,
                arguments: ["fontFamilies": page.fontFamilies, "width": page.size.width, "height": page.size.height],
                contentWorld: .page
            )
            guard isCurrent() else {
                return
            }
            let errors = result as? [String] ?? ["ページの検査の結果を読めませんでした"]
            guard errors.isEmpty else {
                fail(page, errors.joined(separator: "\n    "))
                return
            }
            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = true
            let image = try await webView.takeSnapshot(configuration: configuration)
            guard isCurrent() else {
                return
            }
            try save(image, for: page)
            print("書き出しました: \(page.outputURL.path) (\(page.pixelWidth)x\(page.pixelHeight))")
            next()
        } catch {
            if isCurrent() {
                fail(page, "\(error)")
            }
        }
    }

    private func save(_ image: NSImage, for page: MockPage) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw RenderError("スナップショットを画像にできませんでした")
        }
        guard cgImage.width == page.pixelWidth, cgImage.height == page.pixelHeight else {
            throw RenderError("書き出した画像が \(cgImage.width)x\(cgImage.height) で、期待した \(page.pixelWidth)x\(page.pixelHeight) と違います")
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw RenderError("PNG にできませんでした")
        }
        try FileManager.default.createDirectory(
            at: page.outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: page.outputURL)
    }

    private func fail(_ page: MockPage, _ message: String) {
        let text = "\(page.htmlURL.path):\n    \(message)"
        FileHandle.standardError.write(Data("失敗しました: \(text)\n".utf8))
        failures.append(text)
        next()
    }

    private func next() {
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.navigationDelegate = nil
        webView = nil
        index += 1
        renderNext()
    }

    private func finish() {
        if failures.isEmpty {
            print("\(pages.count) ページを書き出しました")
            exit(0)
        }
        FileHandle.standardError.write(Data("\(failures.count) / \(pages.count) ページが失敗しました\n".utf8))
        exit(1)
    }
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count >= 2, let outputPath = arguments.first else {
    FileHandle.standardError.write(Data("使い方: xcrun swift Tools/render_design_mocks.swift <出力ディレクトリ> <ページの HTML>…\n".utf8))
    exit(2)
}
let outputDirectory = URL(fileURLWithPath: outputPath, isDirectory: true)
var pages: [MockPage] = []
for path in arguments.dropFirst() {
    do {
        pages.append(try MockPage(htmlURL: URL(fileURLWithPath: path).standardizedFileURL, outputDirectory: outputDirectory))
    } catch {
        FileHandle.standardError.write(Data("\(path): \(error)\n".utf8))
        exit(1)
    }
}

let application = NSApplication.shared
application.setActivationPolicy(.prohibited)
// スクリプトの最上位はメインスレッドで動くので、MainActor の型をそのまま使う
let renderer = MainActor.assumeIsolated {
    let renderer = MockRenderer(pages: pages)
    renderer.start()
    return renderer
}
application.run()
