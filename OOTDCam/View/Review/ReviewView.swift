//
//  ReviewView.swift
//  OOTDCam
//

import SwiftUI

struct ReviewView: View {
    /// 編集状態を保存完了画面との往復で保持するため、所有は AppCoordinator 側
    @ObservedObject var viewModel: ReviewViewModel
    /// 撮影画面で実測した写真幅 (AppCoordinator.basePhotoWidth)。
    /// 縦が短い端末でもこの幅を上限にして撮影画面と写真の大きさを揃え、遷移時に跳ねないようにする
    let basePhotoWidth: CGFloat
    let onRetake: () -> Void
    let onDone: (SavedPhoto) -> Void

    /// 形の切り替え時に小→大のポップを出すための一時スケール
    @State private var shapePopScale: CGFloat = 1.0

    @State private var lastPhotoAreaSize: CGSize = .zero

    /// hasOverlay 切替時のアニメーション
    static let overlayToggleAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.72)

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: 0) {
                ReviewHeader(
                    isSaving: viewModel.isSaving,
                    contentWidth: lastPhotoAreaSize.width,
                    onRetake: onRetake,
                    onDone: handleDone
                )

                ReviewPhotoArea(
                    viewModel: viewModel,
                    shapePopScale: shapePopScale,
                    areaSize: $lastPhotoAreaSize
                )
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxWidth: basePhotoWidth > 0 ? basePhotoWidth : .infinity)
                .pearlPlate()
                .padding(.horizontal, Pearl.plateHorizontalPadding)
                .padding(.top, Pearl.plateTopGap)
                // 写真は全端末でフル幅を保つ。縦が足りない端末では
                // 写真を縮めるのではなく、下の操作ブロック側をスクロールで逃がす
                .layoutPriority(1)

                // 操作ブロックはプレートと画面下端の間で上下センター。
                // ガラスの容器には載せない: 縦予算を食って写真が痩せる上、
                // グミ質感の部品はパール地に直接並べて成立する (検討の経緯は PR #24 参照)。
                // 縦に収まらない端末 (SE 等) ではスクロールに切り替えて全コントロールに届かせる
                // コントロールはプレート直下に付け、端末の縦の余りは画面下端に集める。
                // 上12/下10 は「iPhone mini 級まで非スクロールが成立する」値。
                // これより増やすと標準サイズ端末でもスクロール枠に切り替わってしまう
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 0) {
                        boundControlPad
                            .padding(.top, 12)
                        Spacer(minLength: 10)
                    }
                    ScrollView(.vertical) {
                        boundControlPad
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                            .padding(.bottom, 10)
                    }
                    // 表示時にインジケータを一瞬光らせ、下に続きがあることを伝える
                    // (見切れたドット列と合わせた二重の合図)
                    .scrollIndicatorsFlash(onAppear: true)
                    // 中身が収まっているときはバウンスさせない (境界サイズで無意味に動くのを防ぐ)
                    .scrollBounceBehavior(.basedOnSize)
                }
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

    /// 左右は実際に表示されている写真の幅に揃える
    /// (固定 padding ではなく実測束縛。ヘッダーのボタン列と同じ方式)
    private var boundControlPad: some View {
        ReviewControlPad(
            viewModel: viewModel,
            areaSize: lastPhotoAreaSize,
            onShapeSwitch: triggerShapePop
        )
        .frame(width: lastPhotoAreaSize.width > 0 ? lastPhotoAreaSize.width : nil)
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
        Task {
            withAnimation(Self.overlayToggleAnimation) {
                shapePopScale = 1.0
            }
        }
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
            basePhotoWidth: 0,
            onRetake: {},
            onDone: { _ in }
        )
    }
}
