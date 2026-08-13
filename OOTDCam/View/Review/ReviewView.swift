//
//  ReviewView.swift
//  OOTDCam
//

import SwiftUI

struct ReviewView: View {
    let photo: CapturedPhoto
    let onRetake: () -> Void
    let onDone: () -> Void

    @StateObject private var viewModel: ReviewViewModel
    @State private var dragStartCenter: CGPoint?

    /// hasOverlay 切替時のアニメーション
    private static let overlayToggleAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.72)

    init(photo: CapturedPhoto, onRetake: @escaping () -> Void, onDone: @escaping () -> Void) {
        self.photo = photo
        self.onRetake = onRetake
        self.onDone = onDone
        _viewModel = StateObject(wrappedValue: ReviewViewModel(photo: photo))
    }

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

                controlPad

                Spacer(minLength: 0)

                Text("シェイプを選んで顔にかぶせてね・ドラッグで移動")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Pearl.inkSoft.opacity(0.8))
                    .padding(.bottom, 10)
            }
        }
        .alert("保存に失敗", isPresented: .constant(viewModel.saveErrorMessage != nil)) {
            Button("OK") { viewModel.saveErrorMessage = nil }
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
    }

    private func handleDone() {
        guard !viewModel.isSaving else { return }
        Task {
            let success = await viewModel.compositeAndSave(areaSize: lastPhotoAreaSize)
            if success {
                onDone()
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
                        viewModel.hasOverlay ? 1.0 : 0.3,
                        anchor: UnitPoint(
                            x: geo.size.width > 0 ? viewModel.overlayCenter.x / geo.size.width : 0.5,
                            y: geo.size.height > 0 ? viewModel.overlayCenter.y / geo.size.height : 0.5
                        )
                    )
                    .opacity(viewModel.hasOverlay ? 1.0 : 0.0)
                    .allowsHitTesting(viewModel.hasOverlay)

                // 右上のコントロール (+/−/✕)
                HStack(spacing: 6) {
                    circleControl(label: "−") {
                        viewModel.adjustScale(by: -0.15)
                    }
                    circleControl(label: "+") {
                        viewModel.adjustScale(by: 0.15)
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
                DateStamp(date: viewModel.capturedDate)
                    .opacity(viewModel.includeDateStamp ? 1.0 : 0.3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.includeDateStamp.toggle()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(14)
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

    private func circleControl(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
        }
        .buttonStyle(PearlCircleButtonStyle(size: 30))
    }

    // MARK: - Control Pad (左ラベル列なし・画面幅いっぱい)

    private var controlPad: some View {
        VStack(spacing: 12) {
            shapeRow
            colorDots
            VStack(spacing: 9) {
                pearlSlider("濃さ", value: $viewModel.sheer, in: 0.15...0.85, step: 0.05)
                pearlSlider("ぼかし", value: $viewModel.blur, in: 0...30, step: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
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
                    withAnimation(Self.overlayToggleAnimation) {
                        viewModel.selectShape(shapeID, areaSize: lastPhotoAreaSize)
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
        let width: CGFloat = 24
        return CoverShape(id: shapeID)
            .fill(iconColor(selected: selected))
            .frame(width: width, height: width * nominal.height / nominal.width)
    }

    private func gummyTile(
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: @escaping (Bool) -> some View
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(isSelected
                        ? LinearGradient(
                            colors: [Color(.tileSelectedPink), Color(.tileSelectedLavender), Color(.tileSelectedSky)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [Color(.glassHighlight), Color(.glassMid), Color(.glassLow)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))

                // 上面のグロス
                Ellipse()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 22, height: 10)
                    .blur(radius: 2)
                    .offset(x: -8, y: -14)

                icon(isSelected)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.95 : 0.7), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.35),
                radius: isSelected ? 8 : 5,
                y: isSelected ? 2 : 3
            )
            .offset(y: isSelected ? -3 : 0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Bubbles (シャボン玉)

    private var colorDots: some View {
        HStack(spacing: 12) {
            ForEach(CoverPresets.gradients) { gradient in
                colorDot(gradient)
            }
        }
    }

    private func colorDot(_ gradient: CoverGradient) -> some View {
        let isSelected = viewModel.selectedGradientID == gradient.id
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                viewModel.selectGradient(id: gradient.id, areaSize: lastPhotoAreaSize)
            }
        } label: {
            Circle()
                .fill(gradient.swiftUIGradient)
                .overlay(
                    // シャボン玉の照り返し
                    Circle().fill(RadialGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0)],
                        center: UnitPoint(x: 0.32, y: 0.24),
                        startRadius: 0,
                        endRadius: 15
                    ))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(isSelected ? 1.0 : 0.7), lineWidth: isSelected ? 2.5 : 1)
                )
                .frame(width: 34, height: 34)
                .shadow(
                    color: isSelected ? Pearl.glowPink.opacity(0.7) : Pearl.shadow.opacity(0.4),
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 1 : 3
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .offset(y: isSelected ? -4 : 0)
        }
        .buttonStyle(.plain)
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
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .tracking(0.5)
                        }
                    }
                    .foregroundStyle(Pearl.inkDeep)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(minHeight: 32)
                    .background(
                        Capsule()
                            .fill(Pearl.iris)
                            .shadow(color: Color(.irisButtonGlow).opacity(0.9), radius: 8, y: 4)
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                }
                .disabled(isSaving)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView(
            photo: CapturedPhoto(
                original: UIImage(systemName: "person.fill") ?? UIImage(),
                display: UIImage(systemName: "person.fill") ?? UIImage()
            ),
            onRetake: {},
            onDone: {}
        )
    }
}
