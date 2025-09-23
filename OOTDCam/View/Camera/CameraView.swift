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
            // カメラプレビュー
            CameraPreviewView(service: viewModel.service)
                .background(
                    Color.black
                        .overlay(
                            LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                                .blendMode(.screen)
                        )
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
                        .onTapGesture {
                            viewModel.send(.takePhoto)
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

            VStack {
                Spacer()
                // サムネイル
                HStack {
                    if let image = viewModel.lastCapturedImage {
                        Button(action: {
                            openPhotoApp()
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 4)
                                .padding(12)
                        }
                        .padding(.bottom, 12)
                        .padding(.leading, 12)
                    }
                    Spacer()
                }
            }
        }
        .alert("カメラ権限がありません", isPresented: $viewModel.cameraPermissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("カメラを使用するには設定で許可が必要です")
        }
        .alert("写真権限がありません", isPresented: $viewModel.photoLibraryPermissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を保存するには設定で許可が必要です")
        }
        .onAppear { viewModel.send(.onAppear) }
        .onDisappear { viewModel.send(.onDisappear) }
    }
    
    private func openPhotoApp() {
        // iOSの写真アプリを開くURLスキーム
        if let url = URL(string: "photos-redirect://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                print("写真アプリを開けません")
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
