//
//  ReviewView.swift
//  OOTDCam
//

import SwiftUI

struct ReviewView: View {
    /// 編集状態を保存完了画面との往復で保持するため、所有は AppCoordinator 側
    @ObservedObject var viewModel: ReviewViewModel
    let onRetake: () -> Void
    let onDone: (SavedPhoto) -> Void

    @State private var dragStartCenter: CGPoint?

    /// 形の切り替え時に小→大のポップを出すための一時スケール
    @State private var shapePopScale: CGFloat = 1.0

    /// hasOverlay 切替時のアニメーション
    private static let overlayToggleAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.72)

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: 0) {
                ReviewHeader(
                    isSaving: viewModel.isSaving,
                    onRetake: onRetake,
                    onDone: handleDone
                )

                photoArea
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .pearlPlate()
                    .padding(.horizontal, 10)

                // 操作ブロックはプレートと画面下端の間で上下センター
                Spacer(minLength: 18)

                // 左右は実際に表示されている写真の幅に揃える。
                // 3:4 プレートは高さ制約で縮むことがあり、固定 padding では写真の幅とずれる
                controlPad
                    .frame(width: lastPhotoAreaSize.width > 0 ? lastPhotoAreaSize.width : nil)

                Spacer(minLength: 16)
            }
        }
        // 保存失敗は消えるトーストにせず、残るアラート + 再試行の導線で伝える (issue #17)
        .alert("保存に失敗", isPresented: .constant(viewModel.saveErrorMessage != nil)) {
            Button("再試行") {
                viewModel.saveErrorMessage = nil
                handleDone()
            }
            Button("閉じる", role: .cancel) { viewModel.saveErrorMessage = nil }
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
    }

    private func handleDone() {
        guard !viewModel.isSaving else { return }
        Task {
            if let saved = await viewModel.compositeAndSave(areaSize: lastPhotoAreaSize) {
                onDone(saved)
            }
        }
    }

    @State private var lastPhotoAreaSize: CGSize = .zero

    // MARK: - Photo Area

    private var photoArea: some View {
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
                        withAnimation(Self.overlayToggleAnimation) {
                            viewModel.removeOverlay()
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
            .clipped()
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: viewModel.hasOverlay)
            .onAppear {
                lastPhotoAreaSize = geo.size
                viewModel.initializePositionIfNeeded(areaSize: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                lastPhotoAreaSize = newSize
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

    /// 形の切り替え時、なし→表示と同じ小→大のポップを再生する。
    /// 0.3 は無アニメで即時反映し、次のランループで 1.0 へ弾ませる
    /// (同一トランザクション内で 2 回代入すると最後の値に合成されてアニメが出ないため)
    private func triggerShapePop() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shapePopScale = 0.3
        }
        Task { @MainActor in
            withAnimation(Self.overlayToggleAnimation) {
                shapePopScale = 1.0
            }
        }
    }

    private func overlayLayer(areaSize: CGSize) -> some View {
        let shapeSize = viewModel.displayedShapeSize(in: areaSize)
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

    // MARK: - Control Pad (左ラベル列なし・画面幅いっぱい)

    /// 間隔は「見た目の距離」基準で組む。ドットは44pt枠に上下5pt、スライダーは
    /// 44pt枠に上下約12ptの透明な当たり判定マージンがあるため、等間隔の spacing だと
    /// 見た目の間隔が下に行くほど開いてバランスが崩れる
    private var controlPad: some View {
        VStack(spacing: 0) {
            shapeRow

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
    }

    // MARK: - Shape Tiles (グミ質感)

    private var shapeRow: some View {
        HStack(spacing: 8) {
            gummyTile(isSelected: !viewModel.hasOverlay) {
                withAnimation(Self.overlayToggleAnimation) {
                    viewModel.disableOverlay()
                }
            } icon: { selected in
                Text("✕")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor(selected: selected))
            }

            ForEach(CoverShapeID.allCases) { shapeID in
                let isSelected = viewModel.hasOverlay && viewModel.selectedShape == shapeID
                gummyTile(isSelected: isSelected) {
                    // 表示中に別の形へ切り替えた場合のみポップさせる。
                    // なし→表示は hasOverlay 側の scaleEffect が同じ演出を担うので二重にしない
                    let isShapeSwitch = viewModel.hasOverlay && viewModel.selectedShape != shapeID
                    withAnimation(Self.overlayToggleAnimation) {
                        viewModel.selectShape(shapeID, areaSize: lastPhotoAreaSize)
                    }
                    if isShapeSwitch {
                        triggerShapePop()
                    }
                } icon: { selected in
                    shapeIcon(shapeID, selected: selected)
                }
            }
        }
    }

    private func iconColor(selected: Bool) -> Color {
        selected ? Color(.shapeIconSelected) : Color(.shapeIconMuted)
    }

    private func shapeIcon(_ shapeID: CoverShapeID, selected: Bool) -> some View {
        let nominal = shapeID.nominalSize
        let width: CGFloat = 22
        return CoverShape(id: shapeID)
            .fill(iconColor(selected: selected))
            .frame(width: width, height: width * nominal.height / nominal.width)
    }

    /// グミ質感タイル。光源は全要素と同じ左上固定。
    /// 面のグラデ + 内側の影(上) + 内側の光(下) + 紫寄りの外影の4層で立体にする
    private func gummyTile(
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: @escaping (Bool) -> some View
    ) -> some View {
        Button(action: action) {
            ZStack {
                icon(isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: isSelected
                                ? [.init(color: Color(.tileSelectedPink), location: 0),
                                   .init(color: Color(.tileSelectedLavender), location: 0.5),
                                   .init(color: Color(.tileSelectedSky), location: 1)]
                                : [.init(color: Color(.glassHighlight), location: 0),
                                   .init(color: Color(.glassMid), location: 0.55),
                                   .init(color: Color(.glassLow), location: 1)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .shadow(.inner(color: Color(.glassInnerShadow).opacity(0.35), radius: 4, y: 3))
                        .shadow(.inner(color: .white.opacity(0.95), radius: 4, y: -3))
                    )
                    // 艶 (左上の白いぼかし楕円)。非選択面はほぼ白でハイライトが
                    // 効かず影だけ目立つため、色が乗る選択中のみ出す
                    .overlay(alignment: .topLeading) {
                        Ellipse()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 24, height: 10)
                            .blur(radius: 2)
                            .offset(x: 12, y: 5)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(.white, lineWidth: isSelected ? 2 : 0)
                    }
                    .shadow(
                        color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.35),
                        radius: isSelected ? 8 : 4,
                        y: isSelected ? 6 : 3
                    )
            }
            .offset(y: isSelected ? -3 : 0)
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: isSelected)
    }

    // MARK: - Color Bubbles (シャボン玉)

    private var colorDots: some View {
        // 当たり判定フレームが44ptなので、見た目の間隔12pt = spacing 2pt
        HStack(spacing: 2) {
            ForEach(CoverPresets.gradients) { gradient in
                colorDot(gradient)
            }
        }
    }

    /// シャボン玉のカラードット。中心を左上にずらした放射グラデーションで球に見せ、
    /// 上下から内側に白を入れて丸みを出す
    private func colorDot(_ gradient: CoverGradient) -> some View {
        let isSelected = viewModel.selectedGradientID == gradient.id
        return Button {
            viewModel.selectGradient(id: gradient.id, areaSize: lastPhotoAreaSize)
        } label: {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: gradient.colors[0], location: 0.40),
                            .init(color: gradient.colors[2], location: 1)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.26),
                        startRadius: 0,
                        endRadius: 34
                    )
                    .shadow(.inner(color: .white.opacity(0.85), radius: 3, y: -3))
                    .shadow(.inner(color: .white.opacity(0.45), radius: 3, y: 3))
                )
                .frame(width: 34, height: 34)
                // 艶 (左上の白いぼかし楕円)。タイルと同様、選択中のみ出す
                .overlay(alignment: .topLeading) {
                    Ellipse()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 12, height: 8)
                        .blur(radius: 1.4)
                        .offset(x: 7, y: 5)
                        .opacity(isSelected ? 1 : 0)
                }
                .overlay {
                    Circle().stroke(.white.opacity(isSelected ? 1 : 0.7), lineWidth: isSelected ? 2.5 : 1)
                }
                .shadow(
                    color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.4),
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 0 : 3
                )
                .scaleEffect(isSelected ? 1.1 : 1)
                .offset(y: isSelected ? -4 : 0)
                // 見た目34ptでも当たり判定は44ptを確保
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    // MARK: - Sliders

    private func pearlSlider(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Pearl.inkSoft)
                .frame(width: 34, alignment: .leading)
            GlassSlider(value: value, range: range, step: step)
        }
    }
}

// MARK: - Header
private struct ReviewHeader: View {
    let isSaving: Bool
    let onRetake: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Wordmark()

            HStack {
                Button(action: onRetake) {
                    Text("← 撮り直す")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Pearl.inkSoft)
                }

                Spacer()

                Button(action: onDone) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Pearl.inkDeep)
                                .scaleEffect(0.7)
                        } else {
                            Text("完了")
                                .tracking(0.5)
                        }
                    }
                    .frame(minHeight: 16)
                    .irisCapsule()
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isSaving)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Pearl.topBarHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView(
            viewModel: ReviewViewModel(photo: CapturedPhoto(
                original: UIImage(systemName: "person.fill") ?? UIImage(),
                display: UIImage(systemName: "person.fill") ?? UIImage()
            )),
            onRetake: {},
            onDone: { _ in }
        )
    }
}
