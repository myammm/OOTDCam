//
//  ShareSheet.swift
//  OOTDCam
//

import SwiftUI

/// UIActivityViewController のラッパー。フル解像度 (保存したものと同一) を渡す
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
