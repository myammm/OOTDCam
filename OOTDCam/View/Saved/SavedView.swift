//
//  SavedView.swift
//  OOTDCam
//
//  保存完了画面 (issue #17)
//  保存できたことを伝え、共有と次の撮影への導線を出す。
//  バナー広告を置ける唯一の場所 (撮影・編集画面には広告を入れない)
//

import SwiftUI

struct SavedView: View {
    let photo: SavedPhoto
    /// 撮影画面で実測した写真幅 (AppCoordinator.basePhotoWidth)。ReviewView と同じ理由で上限にする
    let basePhotoWidth: CGFloat
    /// 編集画面へ。保存した状態を見てシェイプの位置を直したいとき
    let onBack: () -> Void
    /// 撮影画面へ
    let onShoot: () -> Void

    @State private var appeared = false
    @State private var showToast = false
    @State private var showShareSheet = false
    /// 実際に表示されている写真エリアの幅。ボタン列の幅をこれに揃える
    /// (3:4 プレートは高さ制約で縮むことがあり、固定 padding では写真の幅とずれる)
    @State private var photoAreaWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: 0) {
                SavedHeader(contentWidth: photoAreaWidth, onBack: onBack)
                photoPlate
                SavedActions(onShare: { showShareSheet = true }, onShoot: onShoot)
                    // 左右は実際に表示されている写真の幅に揃える (ReviewControlPad と同じ方式)
                    .frame(width: photoAreaWidth > 0 ? photoAreaWidth : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SavedAdSlot()
            }
        }
        .task { try? await runSequence() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareItem])
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    /// カメラロールに保存したものと同一の JPEG ファイルを渡す (シートが即座に開く)。
    /// ファイル化に失敗した・tmp が掃除されて消えていたときだけ表示用の 1600px を渡す
    /// (フル解像度はカメラロールに保存済み。共有だけ縮小版になるが成立はする)
    private var shareItem: Any {
        if let url = photo.fileURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return photo.display
    }

    // MARK: - 写真

    private var photoPlate: some View {
        ZStack {
            Color(.photoBackdrop)

            Image(uiImage: photo.display)
                .resizable()
                .aspectRatio(contentMode: .fit)

            GeometryReader { geo in
                Color.clear
                    .onAppear { photoAreaWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in
                        photoAreaWidth = newWidth
                    }
            }

            if !reduceMotion {
                SweepOverlay()
            }

            // トーストは ZStack 上のオーバーレイなので、消えてもレイアウトは動かない
            if showToast {
                SavedToast()
                    .transition(toastTransition)
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxWidth: basePhotoWidth > 0 ? basePhotoWidth : .infinity)
        .pearlPlate()
        .padding(.horizontal, Pearl.plateHorizontalPadding)
        .padding(.top, Pearl.plateTopGap)
        // 操作ブロックの maxHeight: .infinity と余り空間を折半して写真が縮まないよう、
        // 写真を先にレイアウトさせて撮影・編集画面と同じ幅いっぱいに揃える
        .layoutPriority(1)
        .offset(y: appeared ? 0 : 14)
        .opacity(appeared ? 1 : 0)
    }

    private var toastTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        // 出るときは縮小から、消えるときは上に数pt動きながらフェード
        return .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .offset(y: -8).combined(with: .opacity)
        )
    }

    // MARK: - 演出の順番

    /// 画面から外れると .task ごとキャンセルされ、以降の演出は打ち切られる
    private func runSequence() async throws {
        if reduceMotion {
            // 浮上と膜の演出は止め、トーストはフェードのみ
            appeared = true
            withAnimation(.easeInOut(duration: 0.3)) { showToast = true }
            try await Task.sleep(for: .seconds(2.95))
        } else {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                appeared = true
            }
            try await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showToast = true
            }
            // 出る → とどまる → 消える で計 2.6 秒 (0.35 + 2.6 = 2.95)
            try await Task.sleep(for: .seconds(2.6))
        }
        withAnimation(.easeOut(duration: 0.4)) { showToast = false }
    }
}

// MARK: - Preview

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView(
            photo: SavedPhoto(
                display: UIImage(systemName: "person.fill") ?? UIImage(),
                fileURL: nil
            ),
            basePhotoWidth: 0,
            onBack: {},
            onShoot: {}
        )
    }
}
