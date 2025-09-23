//
//  CameraView.swift
//  OOTDCam
//
//  Created by maya yamada on 2025/09/23.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            // 背景: 仮のカメラプレビュー領域
            Color.black
                .overlay(
                    LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                        .blendMode(.screen)
                )
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // シャッターボタン
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.cyan, .purple, .pink, .cyan]),
                                        center: .center
                                    ),
                                    lineWidth: 2
                                )
                                .blur(radius: viewModel.isShutterAnimating ? 8 : 2)
                                .opacity(viewModel.isShutterAnimating ? 1 : 0.6)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 12, x: 0, y: 0)
                        .scaleEffect(viewModel.isShutterAnimating ? 0.85 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isShutterAnimating)
                        .onTapGesture {
                            viewModel.takePhoto()
                        }
                    
                    // キラキラ演出
                    if viewModel.showSparkles {
                        SparkleOverlay()
                            .frame(width: 120, height: 120)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Sparkle Effect
struct SparkleOverlay: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Circle()
                    .fill(LinearGradient(colors: [.white, .yellow.opacity(0.6), .clear],
                                         startPoint: .center, endPoint: .bottom))
                    .frame(width: 8, height: 20)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
