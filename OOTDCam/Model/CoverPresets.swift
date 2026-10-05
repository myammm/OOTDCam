//
//  CoverPresets.swift
//  OOTDCam
//

import SwiftUI
import UIKit

enum CoverShapeID: String, CaseIterable, Identifiable {
    case heart, star, butterfly, cloud

    var id: String { rawValue }

    /// JSX viewBox の名目サイズ。スケール基準
    var nominalSize: CGSize {
        switch self {
        case .heart: return CGSize(width: 200, height: 170)
        case .star: return CGSize(width: 200, height: 200)
        case .butterfly: return CGSize(width: 200, height: 200)
        case .cloud: return CGSize(width: 210, height: 160)
        }
    }
}

enum CoverGradientID: String, CaseIterable, Identifiable {
    case pink, lavender, sunset, cyber, mint

    var id: String { rawValue }
}

struct CoverGradient: Identifiable, Equatable {
    let id: CoverGradientID
    let colors: [Color]

    var uiColors: [UIColor] {
        colors.map { UIColor($0) }
    }

    var swiftUIGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum CoverPresets {
    /// 各色 [中間 (Light) → 適用値 (Base) → 外周 (Deep)] のパステル族。
    /// カラードットの泡色 (白 + Light + Deep) とシェイプの塗りが同じ定義を共有する
    static let gradients: [CoverGradient] = [
        .init(id: .pink, colors: [
            Color(.coverPinkLight),
            Color(.coverPinkBase),
            Color(.coverPinkDeep)
        ]),
        .init(id: .lavender, colors: [
            Color(.coverLavenderLight),
            Color(.coverLavenderBase),
            Color(.coverLavenderDeep)
        ]),
        .init(id: .sunset, colors: [
            Color(.coverSunsetLight),
            Color(.coverSunsetBase),
            Color(.coverSunsetDeep)
        ]),
        .init(id: .cyber, colors: [
            Color(.coverCyberLight),
            Color(.coverCyberBase),
            Color(.coverCyberDeep)
        ]),
        .init(id: .mint, colors: [
            Color(.coverMintLight),
            Color(.coverMintBase),
            Color(.coverMintDeep)
        ]),
    ]

    static func gradient(id: CoverGradientID) -> CoverGradient {
        gradients.first { $0.id == id } ?? gradients[0]
    }
}
