//
//  CoverShapes.swift
//  OOTDCam
//

import SwiftUI

// MARK: - Heart (viewBox 200x170、ガイド・カバー共通)
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let viewBox = CGSize(width: 200, height: 170)
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(100, 160))
        path.addCurve(to: p(10, 55), control1: p(100, 160), control2: p(10, 105))
        path.addCurve(to: p(65, 4), control1: p(10, 25), control2: p(35, 4))
        path.addCurve(to: p(100, 25), control1: p(80, 4), control2: p(90, 12))
        path.addCurve(to: p(135, 4), control1: p(110, 12), control2: p(120, 4))
        path.addCurve(to: p(190, 55), control1: p(165, 4), control2: p(190, 25))
        path.addCurve(to: p(100, 160), control1: p(190, 105), control2: p(100, 160))
        path.closeSubpath()
        return path
    }
}

// MARK: - Star (10-point polygon, viewBox 200x200)
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [
            (100, 8), (123, 70), (190, 78), (140, 124), (155, 190),
            (100, 158), (45, 190), (60, 124), (10, 78), (77, 70)
        ]
        let viewBox = CGSize(width: 200, height: 200)
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        var path = Path()
        for (i, pt) in pts.enumerated() {
            let scaled = CGPoint(x: rect.minX + pt.0 * sx, y: rect.minY + pt.1 * sy)
            if i == 0 { path.move(to: scaled) } else { path.addLine(to: scaled) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Butterfly (4 wing ellipses + 1 body, viewBox 200x200)
struct ButterflyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let viewBox = CGSize(width: 200, height: 200)
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        let ellipses: [(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat)] = [
            (60, 70, 55, 60),
            (140, 70, 55, 60),
            (65, 145, 40, 45),
            (135, 145, 40, 45),
            (100, 100, 8, 60)
        ]
        var path = Path()
        for e in ellipses {
            let r = CGRect(
                x: rect.minX + (e.cx - e.rx) * sx,
                y: rect.minY + (e.cy - e.ry) * sy,
                width: 2 * e.rx * sx,
                height: 2 * e.ry * sy
            )
            path.addEllipse(in: r)
        }
        return path
    }
}

// MARK: - Cloud (Apple絵文字風に左右非対称、viewBox 210x160)
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let viewBox = CGSize(width: 210, height: 160)
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        // 右上に大きなコブ、左に小さめ、右下に小さい突起
        let circles: [(cx: CGFloat, cy: CGFloat, r: CGFloat)] = [
            (58, 82, 38),     // 左 (小)
            (100, 60, 46),    // 中央上 (中)
            (152, 56, 56),    // 右上 (大、最大)
            (188, 88, 28),    // 右端 (小)
            (90, 112, 32),    // 左下 (小)
            (140, 115, 36)    // 右下 (中)
        ]
        var path = Path()
        for c in circles {
            let r = CGRect(
                x: rect.minX + (c.cx - c.r) * sx,
                y: rect.minY + (c.cy - c.r) * sy,
                width: 2 * c.r * sx,
                height: 2 * c.r * sy
            )
            path.addEllipse(in: r)
        }
        // 下部のボディ (角丸長方形)
        let bodyRect = CGRect(
            x: rect.minX + 32 * sx,
            y: rect.minY + 80 * sy,
            width: 160 * sx,
            height: 56 * sy
        )
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 18 * sx, height: 18 * sy))
        return path
    }
}

// MARK: - Type-erased cover shape
struct CoverShape: Shape {
    let id: CoverShapeID

    func path(in rect: CGRect) -> Path {
        switch id {
        case .heart: return HeartShape().path(in: rect)
        case .star: return StarShape().path(in: rect)
        case .butterfly: return ButterflyShape().path(in: rect)
        case .cloud: return CloudShape().path(in: rect)
        }
    }
}
