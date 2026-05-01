//
//  CoverPresets.swift
//  OOTDCam
//

import SwiftUI
import UIKit

enum CoverShapeID: String, CaseIterable, Identifiable {
    case heart, star, butterfly, cloud

    var id: String { rawValue }

    var label: String {
        switch self {
        case .heart: return "♡"
        case .star: return "★"
        case .butterfly: return "🦋"
        case .cloud: return "☁️"
        }
    }

    var name: String {
        switch self {
        case .heart: return "HEART"
        case .star: return "STAR"
        case .butterfly: return "BUTTERFLY"
        case .cloud: return "CLOUD"
        }
    }

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

struct CoverGradient: Identifiable, Equatable {
    let id: String
    let label: String
    let colors: [Color]

    var uiColors: [UIColor] {
        colors.map { UIColor($0) }
    }

    var swiftUIGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum CoverPresets {
    static let gradients: [CoverGradient] = [
        .init(id: "pink", label: "PINK", colors: [
            Color(hex: "#FF69B4"),
            Color(hex: "#FF1493"),
            Color(hex: "#C71585")
        ]),
        .init(id: "lavender", label: "LAVENDER", colors: [
            Color(hex: "#E0BBE4"),
            Color(hex: "#957DAD"),
            Color(hex: "#D291BC")
        ]),
        .init(id: "sunset", label: "SUNSET", colors: [
            Color(hex: "#FF9A9E"),
            Color(hex: "#FAD0C4"),
            Color(hex: "#FBC2EB")
        ]),
        .init(id: "cyber", label: "CYBER", colors: [
            Color(hex: "#00FFFF"),
            Color(hex: "#8B5CF6"),
            Color(hex: "#FF69B4")
        ]),
        .init(id: "mint", label: "MINT", colors: [
            Color(hex: "#A8E6CF"),
            Color(hex: "#88D8B0"),
            Color(hex: "#B8E6D0")
        ]),
    ]

    static func gradient(id: String) -> CoverGradient {
        gradients.first { $0.id == id } ?? gradients[0]
    }
}

extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xff) / 255
        let g = Double((rgb >> 8) & 0xff) / 255
        let b = Double(rgb & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
