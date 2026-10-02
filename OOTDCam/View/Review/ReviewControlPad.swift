//
//  ReviewControlPad.swift
//  OOTDCam
//
//  編集画面の写真下の操作ブロック (形・色・濃さ・ぼかし)。左ラベル列なし・写真幅いっぱい
//

import SwiftUI

struct ReviewControlPad: View {
    @ObservedObject var viewModel: ReviewViewModel
    /// 実測した写真エリアのサイズ。形・色の選択時にモチーフ位置の補正に使う
    let areaSize: CGSize
    /// 表示中に別の形へ切り替えたとき (ポップ演出の再生用)
    let onShapeSwitch: () -> Void

    /// 沈んだコントロールをタップしたときの「まず形を選んでね」ヒント。
    /// 消滅タイマーは再タップで巻き戻すため Task で持つ
    @State private var showLockedHint = false
    @State private var lockedHintDismissTask: Task<Void, Never>?

    /// ヒント表示と同時に shapeRow を軽く弾ませて視線誘導するための一時スケール
    @State private var shapeRowPulse: CGFloat = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 間隔は「見た目の距離」基準で組む。ドットは44pt枠に上下5pt、スライダーは
    /// 44pt枠に上下約12ptの透明な当たり判定マージンがあるため、等間隔の spacing だと
    /// 見た目の間隔が下に行くほど開いてバランスが崩れる
    var body: some View {
        VStack(spacing: 0) {
            shapeRow
                .scaleEffect(shapeRowPulse)

            // モチーフ非表示の間、色とスライダーは写真に何も起きないデッドUIになるため
            // まとめて無効化して沈ませ、「まず形を選ぶ」導線にする。
            // 沈む見た目 (彩度0 + 0.45) は PearlCircleButtonStyle の無効時と同じレシピ
            VStack(spacing: 0) {
                // 見た目の間隔 18pt (= 13 + ドットの透明マージン5)
                colorDots
                    .padding(.top, 13)

                // 見た目の間隔 18pt (= 1 + ドット5 + スライダー12)
                // スライダー同士は 16pt (= 12 + 12 - 8)
                VStack(spacing: -8) {
                    pearlSlider("濃さ", value: $viewModel.sheer, in: 0.15...0.85, step: 0.05)
                    pearlSlider("ぼかし", value: $viewModel.blur, in: 0...30, step: 1)
                }
                .padding(.top, 1)
            }
            .disabled(!viewModel.hasOverlay)
            .saturation(viewModel.hasOverlay ? 1.0 : 0)
            .opacity(viewModel.hasOverlay ? 1.0 : 0.45)
            .animation(ReviewView.overlayToggleAnimation, value: viewModel.hasOverlay)
            // 沈んでいる間は .disabled + allowsHitTesting でタップが素通りし
            // 「壊れてる？」に見えるため、透明な受け皿で拾ってヒントを出す
            .overlay {
                if !viewModel.hasOverlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { triggerLockedHint() }
                }
            }
            // ヒントはレイアウトを動かさないオーバーレイ (SavedToast と同じ考え方)。
            // タップは下の受け皿に通し、連打で表示時間が延びるだけにする
            .overlay {
                if showLockedHint {
                    lockedHint
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: viewModel.hasOverlay) { _, hasOverlay in
                // ヒント表示中に形が選ばれたら、案内は役目を終えたので即引っ込める
                if hasOverlay {
                    lockedHintDismissTask?.cancel()
                    withAnimation(.easeOut(duration: 0.2)) { showLockedHint = false }
                }
            }
        }
    }

    // MARK: - Locked Hint (モチーフ未選択の案内)

    /// 容器なし方針 (PR #24) に合わせ、板に載せず白いにじみで地から浮かせる
    private var lockedHint: some View {
        Text("まずは形を選んでね")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Pearl.inkDeep)
            .shadow(color: .white.opacity(0.95), radius: 2)
            .shadow(color: .white.opacity(0.9), radius: 6)
            .shadow(color: .white.opacity(0.8), radius: 14)
    }

    private func triggerLockedHint() {
        lockedHintDismissTask?.cancel()

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.25)) { showLockedHint = true }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showLockedHint = true }
            triggerShapeRowPulse()
        }

        lockedHintDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { showLockedHint = false }
        }
    }

    /// shapeRow を一拍だけ膨らませて「押すのはこっち」と視線を誘導する (案2)。
    /// 不要になったらこの呼び出しを消すだけで案1のみに戻せる
    private func triggerShapeRowPulse() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
            shapeRowPulse = 1.05
        }
        Task {
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                shapeRowPulse = 1.0
            }
        }
    }

    // MARK: - Shape Tiles

    private var shapeRow: some View {
        HStack(spacing: 8) {
            GummyTile(isSelected: !viewModel.hasOverlay) {
                withAnimation(ReviewView.overlayToggleAnimation) {
                    viewModel.disableOverlay()
                }
            } icon: { selected in
                ShapeTileIcon(shapeID: nil, selected: selected)
            }

            ForEach(CoverShapeID.allCases) { shapeID in
                let isSelected = viewModel.hasOverlay && viewModel.selectedShape == shapeID
                GummyTile(isSelected: isSelected) {
                    // 表示中に別の形へ切り替えた場合のみポップさせる。
                    // なし→表示は hasOverlay 側の scaleEffect が同じ演出を担うので二重にしない
                    let isShapeSwitch = viewModel.hasOverlay && viewModel.selectedShape != shapeID
                    withAnimation(ReviewView.overlayToggleAnimation) {
                        viewModel.selectShape(shapeID, areaSize: areaSize)
                    }
                    if isShapeSwitch {
                        onShapeSwitch()
                    }
                } icon: { selected in
                    ShapeTileIcon(shapeID: shapeID, selected: selected)
                }
            }
        }
    }

    // MARK: - Color Bubbles

    private var colorDots: some View {
        // 当たり判定フレームが44ptなので、見た目の間隔12pt = spacing 2pt
        HStack(spacing: 2) {
            ForEach(CoverPresets.gradients) { gradient in
                ColorBubble(
                    gradient: gradient,
                    isSelected: viewModel.selectedGradientID == gradient.id
                ) {
                    viewModel.selectGradient(id: gradient.id, areaSize: areaSize)
                }
            }
        }
    }

    // MARK: - Sliders

    private func pearlSlider(
        _ label: LocalizedStringKey, // String だとカタログを引かず原文のまま表示される
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Pearl.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8) // 英語ラベルが34pt枠をわずかに超えた場合の保険
                .frame(width: 34, alignment: .leading)
            GlassSlider(value: value, range: range, step: step)
        }
    }
}
