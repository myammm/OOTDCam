//
//  ReviewView.swift
//  OOTDCam
//

import SwiftUI

struct ReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onDone: () -> Void

    @StateObject private var viewModel: ReviewViewModel
    @State private var dragStartCenter: CGPoint?

    init(image: UIImage, onRetake: @escaping () -> Void, onDone: @escaping () -> Void) {
        self.image = image
        self.onRetake = onRetake
        self.onDone = onDone
        _viewModel = StateObject(wrappedValue: ReviewViewModel(image: image))
    }

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {
                ReviewHeader(
                    isSaving: viewModel.isSaving,
                    onRetake: onRetake,
                    onDone: handleDone
                )

                photoArea

                bottomControls

                Text("シェイプを選んで顔にかぶせてね・ドラッグで移動")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(Color(red: 0.055, green: 0.055, blue: 0.102))

                Color(red: 0.03, green: 0.03, blue: 0.06).frame(height: 16)
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
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.06, blue: 0.16),
                        Color(red: 0.05, green: 0.09, blue: 0.13),
                        Color(red: 0.09, green: 0.06, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(uiImage: viewModel.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                if viewModel.hasOverlay {
                    overlayLayer(areaSize: geo.size)
                }

                if viewModel.hasOverlay {
                    HStack(spacing: 5) {
                        circleControl(label: "−", color: .cyan) {
                            viewModel.adjustScale(by: -0.15)
                        }
                        circleControl(label: "+", color: .cyan) {
                            viewModel.adjustScale(by: 0.15)
                        }
                        circleControl(label: "✕", color: Color(red: 1, green: 0, blue: 0.25)) {
                            viewModel.removeOverlay()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
                }

                DateStamp()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(14)
            }
            .clipped()
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
            Image(uiImage: viewModel.originalImage)
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
                .frame(width: areaSize.width, height: areaSize.height)
                .allowsHitTesting(false)

            // グラデレイヤー
            shape
                .fill(viewModel.selectedGradient.swiftUIGradient)
                .frame(width: shapeSize.width, height: shapeSize.height)
                .opacity(viewModel.sheer)
                .shadow(color: viewModel.selectedGradient.colors.first?.opacity(0.2) ?? .clear, radius: 16)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
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

    private func circleControl(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.4), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 7) {
            shapeRow
            colorRow
            sliderRow(label: "SHEER", labelColor: .pink, leftHint: "透", rightHint: "濃") {
                AnyView(
                    Slider(value: $viewModel.sheer, in: 0.15...0.85, step: 0.05)
                        .tint(Color(red: 0.541, green: 0.361, blue: 0.965))
                )
            }
            sliderRow(label: "BLUR", labelColor: .cyan, leftHint: "弱", rightHint: "強") {
                AnyView(
                    Slider(value: $viewModel.blur, in: 0...30, step: 1)
                        .tint(.cyan)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(red: 0.055, green: 0.055, blue: 0.102))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                .frame(height: 1)
        }
    }

    private var shapeRow: some View {
        HStack(spacing: 6) {
            sectionLabel("SHAPE", color: .pink)
            HStack(spacing: 5) {
                ForEach(CoverShapeID.allCases) { shapeID in
                    shapeButton(shapeID)
                }
            }
        }
    }

    private func shapeButton(_ shapeID: CoverShapeID) -> some View {
        let isSelected = viewModel.selectedShape == shapeID
        return Button {
            viewModel.selectShape(shapeID, areaSize: lastPhotoAreaSize)
        } label: {
            VStack(spacing: 1) {
                Text(shapeID.label)
                    .font(.system(size: 15))
                Text(shapeID.name)
                    .font(.system(size: 7, weight: .regular, design: .monospaced))
                    .tracking(0.5)
            }
            .foregroundStyle(isSelected ? Color.pink : Color(white: 0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.pink.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color.pink.opacity(0.53) : Color.white.opacity(0.08),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: isSelected ? Color.pink.opacity(0.13) : .clear, radius: 6)
        }
    }

    private var colorRow: some View {
        HStack(spacing: 6) {
            sectionLabel("COLOR", color: .cyan)
            HStack(spacing: 5) {
                ForEach(CoverPresets.gradients) { gradient in
                    colorButton(gradient)
                }
            }
        }
    }

    private func colorButton(_ gradient: CoverGradient) -> some View {
        let isSelected = viewModel.selectedGradientID == gradient.id
        return Button {
            viewModel.selectGradient(id: gradient.id, areaSize: lastPhotoAreaSize)
        } label: {
            ZStack(alignment: .bottom) {
                gradient.swiftUIGradient
                Text(gradient.label)
                    .font(.system(size: 7, weight: .regular, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 1)
                    .padding(.bottom, 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.white : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: isSelected ? Color.white.opacity(0.3) : .clear, radius: 4)
        }
    }

    private func sliderRow<Content: View>(label: String, labelColor: Color, leftHint: String, rightHint: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            sectionLabel(label, color: labelColor)
            HStack(spacing: 6) {
                Text(leftHint)
                    .font(.system(size: 8))
                    .foregroundStyle(Color(white: 0.4))
                content()
                Text(rightHint)
                    .font(.system(size: 8))
                    .foregroundStyle(Color(white: 0.4))
            }
        }
    }

    private func sectionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.27), radius: 3)
            .frame(width: 44, alignment: .leading)
    }
}

// MARK: - Header
private struct ReviewHeader: View {
    let isSaving: Bool
    let onRetake: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack {
            Button(action: onRetake) {
                Text("← RETAKE")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(Color.cyan)
                    .shadow(color: .cyan.opacity(0.4), radius: 3)
            }

            Spacer()

            Text("✦ COVER ✦")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color.pink)
                .shadow(color: .pink.opacity(0.4), radius: 3)

            Spacer()

            Button(action: onDone) {
                Group {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Text("DONE ✓")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .frame(minHeight: 24)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink, Color(red: 0.541, green: 0.361, blue: 0.965)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .pink.opacity(0.27), radius: 6)
                )
            }
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.047, green: 0.047, blue: 0.094),
                    Color(red: 0.055, green: 0.055, blue: 0.102)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 0.541, green: 0.169, blue: 0.886).opacity(0.25))
                .frame(height: 1)
        }
    }
}

// MARK: - Preview
struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView(
            image: UIImage(systemName: "person.fill") ?? UIImage(),
            onRetake: {},
            onDone: {}
        )
    }
}
