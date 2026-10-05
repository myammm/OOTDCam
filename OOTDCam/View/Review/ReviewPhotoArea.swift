//
//  ReviewPhotoArea.swift
//  OOTDCam
//
//  編集画面の写真エリア。写真の上にモチーフ (ドラッグで移動)・右上の操作・日付スタンプを重ねる
//

import SwiftUI

struct ReviewPhotoArea: View {
    @ObservedObject var viewModel: ReviewViewModel
    /// 形の切り替え時のポップ用スケール (ReviewView 側で再生する)
    let shapePopScale: CGFloat
    /// 実測した写真エリアのサイズ。保存時の合成やコントロール幅の基準になる
    @Binding var areaSize: CGSize

    @State private var dragStartCenter: CGPoint?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.photoBackdrop)

                Image(uiImage: viewModel.displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                // ハートなどのオーバーレイ。conditional 削除＋常に存在＋modifier で見せ消し
                overlayLayer(areaSize: geo.size)
                    .scaleEffect(
                        viewModel.hasOverlay ? shapePopScale : 0.3,
                        anchor: overlayAnchor(in: geo.size)
                    )
                    .opacity(viewModel.hasOverlay ? 1.0 : 0.0)
                    .allowsHitTesting(viewModel.hasOverlay)

                // 右上のコントロール (+/−/✕)
                HStack(spacing: 6) {
                    circleControl(label: "−", isEnabled: viewModel.canScaleDown) {
                        viewModel.stepScale(-1)
                    }
                    circleControl(label: "+", isEnabled: viewModel.canScaleUp) {
                        viewModel.stepScale(+1)
                    }
                    circleControl(label: "✕") {
                        withAnimation(ReviewView.overlayToggleAnimation) {
                            viewModel.disableOverlay()
                        }
                    }
                }
                .offset(y: viewModel.hasOverlay ? 0 : -60)
                .opacity(viewModel.hasOverlay ? 1.0 : 0.0)
                .allowsHitTesting(viewModel.hasOverlay)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)

                // 日付スタンプ: タップで保存時の焼き込み ON/OFF。OFF時は半透明で表示
                // 位置は撮影画面・保存時の焼き込みと揃える (右12pt / 下10pt)
                // スクショモードのサンプル写真はスタンプ焼き込み済みなのでライブ表示しない
                if !ScreenshotMode.isActive {
                    DateStamp(date: viewModel.capturedDate)
                        .opacity(viewModel.includeDateStamp ? 1.0 : 0.3)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.includeDateStamp.toggle()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 10)
                        .padding(.trailing, 12)
                }
            }
            .clipped()
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: viewModel.hasOverlay)
            .onAppear {
                areaSize = geo.size
                viewModel.initializePositionIfNeeded(areaSize: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                areaSize = newSize
            }
        }
    }

    /// モチーフ中心を基準にスケールさせるためのアンカー
    private func overlayAnchor(in areaSize: CGSize) -> UnitPoint {
        UnitPoint(
            x: areaSize.width > 0 ? viewModel.overlayCenter.x / areaSize.width : 0.5,
            y: areaSize.height > 0 ? viewModel.overlayCenter.y / areaSize.height : 0.5
        )
    }

    private func overlayLayer(areaSize: CGSize) -> some View {
        let shapeSize = viewModel.displayedShapeSize
        let shape = CoverShape(id: viewModel.selectedShape)

        return ZStack {
            // ぼかしレイヤー: 写真をぼかしてシェイプでマスク
            Image(uiImage: viewModel.displayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blur(radius: viewModel.blur)
                .frame(width: areaSize.width, height: areaSize.height)
                .mask(
                    shape
                        .frame(width: shapeSize.width, height: shapeSize.height)
                        .position(viewModel.overlayCenter)
                        .frame(width: areaSize.width, height: areaSize.height)
                )
                .allowsHitTesting(false)

            // グラデレイヤー (shadow は外側に halo を出して「2つ目のハート」に見えがちなので除去)
            shape
                .fill(viewModel.selectedGradient.swiftUIGradient)
                .frame(width: shapeSize.width, height: shapeSize.height)
                .opacity(viewModel.sheer)
                .contentShape(Rectangle())
                // coordinateSpace は必ず .global にする。デフォルトの .local だと
                // .position() で動いたハート自身に座標系が追従して translation が振動し、
                // ハートが左右にガクガク動く feedback loop が発生する
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if dragStartCenter == nil {
                                dragStartCenter = viewModel.overlayCenter
                            }
                            if let start = dragStartCenter {
                                viewModel.translate(to: CGPoint(
                                    x: start.x + value.translation.width,
                                    y: start.y + value.translation.height
                                ))
                            }
                        }
                        .onEnded { _ in
                            dragStartCenter = nil
                        }
                )
                .position(viewModel.overlayCenter)
        }
        .frame(width: areaSize.width, height: areaSize.height)
    }

    private func circleControl(label: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
        }
        .buttonStyle(PearlCircleButtonStyle(size: 30))
        .disabled(!isEnabled)
    }
}
