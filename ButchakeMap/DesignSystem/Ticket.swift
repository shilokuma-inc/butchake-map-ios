//
//  Ticket.swift
//  ButchakeMap
//

import SwiftUI

/// きっぷの形（角丸 4 の四角の左の中ほどに、改札のはさみの切り込み）
struct TicketShape: Shape {
    /// 切り込みの深さと高さ（モックの 10x18）
    var notchDepth: CGFloat = 10
    var notchHeight: CGFloat = 18
    var cornerRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let notch = CGRect(
            x: rect.minX - (notchHeight - notchDepth),
            y: rect.midY - notchHeight / 2,
            width: notchHeight,
            height: notchHeight
        )
        return RoundedRectangle(cornerRadius: cornerRadius)
            .path(in: rect)
            .subtracting(Path(ellipseIn: notch))
    }
}

/// きっぷの地の薄い緑の斜線（モックの repeating-linear-gradient(135deg, rgba(47, 122, 69, .07) 0 6px, transparent 6px 12px)）
struct TicketStripes: View {
    var body: some View {
        Canvas { context, size in
            let period: CGFloat = 12
            let stripe = Color.brandAccent.opacity(0.07)
            // 45 度に回し、回した後の横の向きに 12pt ごとに 6pt の帯を並べる
            let diagonal = size.width + size.height
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(45))
            var x = -diagonal
            while x < diagonal {
                context.fill(Path(CGRect(x: x, y: -diagonal, width: period / 2, height: diagonal * 2)), with: .color(stripe))
                x += period
            }
        }
        .accessibilityHidden(true)
    }
}

/// きっぷ（白の地に薄い緑の斜線・きっぷの枠・左の切り込み）。中身はそのまま並べる
struct Ticket<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.top, 12)
            .padding(.bottom, 12)
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    Color.surface
                    TicketStripes()
                }
                .clipShape(TicketShape())
            }
            .overlay {
                TicketShape()
                    .stroke(Color.ticketBorder, lineWidth: 1)
            }
            .contentShape(TicketShape())
    }
}

extension View {
    /// きっぷの上の行（路線名・日付）の書体と色（DotGothic16 13pt・インク）
    func ticketCaption() -> some View {
        font(.b2Ticket(size: 13, relativeTo: .footnote))
            .foregroundStyle(Color.brandPrimary)
    }

    /// きっぷの行き先（「〇〇 ゆき」）の書体と色（DotGothic16 14pt・補足の文字）
    func ticketRoute() -> some View {
        font(.b2Ticket(size: 14, relativeTo: .subheadline))
            .foregroundStyle(Color.textSecondary)
    }
}

#Preview("きっぷ") {
    Ticket {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: "ぶっちゃけ線")
                Spacer()
                Text(verbatim: "2026/10/18")
            }
            .ticketCaption()
            Text(verbatim: "金沢市民が本気で教える三大回転寿司")
                .font(.b2Heading(size: 17, relativeTo: .headline))
                .foregroundStyle(Color.textPrimary)
            Text(verbatim: "石川県 金沢市 ゆき")
                .ticketRoute()
            CategoryBadge(category: .gourmet)
        }
    }
    .frame(width: 252)
    .padding()
    .background(Color.paper)
}

#Preview("きっぷ（大きな文字）") {
    Ticket {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "ぶっちゃけ線 2026/10/18")
                .ticketCaption()
            Text(verbatim: "金沢市民が本気で教える三大回転寿司")
                .font(.b2Heading(size: 17, relativeTo: .headline))
            Text(verbatim: "石川県 金沢市 ゆき")
                .ticketRoute()
        }
    }
    .padding()
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
