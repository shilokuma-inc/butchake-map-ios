//
//  TicketShapeTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreGraphics
import SwiftUI
import Testing

/// きっぷの形（左の中ほどの切り込み）
struct TicketShapeTests {
    private let rect = CGRect(x: 0, y: 0, width: 252, height: 120)

    /// 左の中ほどは切り込みで抜け、上下の左端と真ん中は残る
    @Test
    func notchIsCutOutOfLeftMiddle() {
        let path = TicketShape().path(in: rect).cgPath
        #expect(!path.contains(CGPoint(x: 2, y: rect.midY)))
        #expect(!path.contains(CGPoint(x: 8, y: rect.midY)))
        #expect(path.contains(CGPoint(x: 12, y: rect.midY)))
        #expect(path.contains(CGPoint(x: 2, y: 20)))
        #expect(path.contains(CGPoint(x: 2, y: rect.maxY - 20)))
        #expect(path.contains(CGPoint(x: rect.midX, y: rect.midY)))
    }

    /// 右の中ほどには切り込みが無い
    @Test
    func rightEdgeHasNoNotch() {
        let path = TicketShape().path(in: rect).cgPath
        #expect(path.contains(CGPoint(x: rect.maxX - 2, y: rect.midY)))
    }
}
