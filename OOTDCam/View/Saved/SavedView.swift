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
                actions
                adSlot
            }
        }
        .onAppear(perform: runSequence)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [photo.full])
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
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

    // MARK: - 操作

    /// 主 CTA は撮影ループの頻度が高い「続けて撮る」(iris)。
    /// iOS の慣習 (横並びの右=推奨アクション) に合わせて右に置き、強調色もセットで揃える
    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                showShareSheet = true
            } label: {
                Text("共有する")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Pearl.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color(.glassHighlight), location: 0),
                                        .init(color: Color(.glassMid), location: 0.55),
                                        .init(color: Color(.glassLow), location: 1)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .shadow(.inner(color: Color(.glassInnerShadow).opacity(0.35), radius: 4, y: 3))
                                .shadow(.inner(color: .white.opacity(0.95), radius: 4, y: -3))
                            )
                            .shadow(color: Pearl.shadow.opacity(0.55), radius: 5, y: 5)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())

            Button(action: onShoot) {
                Text("続けて撮る")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Pearl.inkDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        // 形は編集画面の完了ボタン (irisCapsule) に合わせる
                        Capsule()
                            .fill(Pearl.iris.shadow(.inner(color: .white.opacity(0.7), radius: 3, y: -2)))
                            .shadow(color: Color(.irisButtonGlow).opacity(0.9), radius: 8, y: 7)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        // 左右は実際に表示されている写真の幅に揃える (ReviewView の controlPad と同じ方式)
        .frame(width: photoAreaWidth > 0 ? photoAreaWidth : nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 広告

    private var adSlot: some View {
        VStack(spacing: 4) {
            Text("広告")
                .font(.system(size: 9.5))
                .kerning(1)
                .foregroundStyle(Color(.adLabelText))
            BannerAdView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) { adDivider }
                .overlay(alignment: .bottom) { adDivider }
        }
        // 「続けて撮る」との間隔 20pt。ボタンに隣接させると誤タップが増え、
        // 無効トラフィックとして跳ね返るので詰めないこと
        .padding(.top, 20)
        // SE (667pt) はこの画面が縦ぴったりで、10pt だと広告が下端からはみ出す
        .padding(.bottom, 6)
    }

    private var adDivider: some View {
        Rectangle()
            .fill(Color(.adDivider).opacity(0.14))
            .frame(height: 1)
    }

    // MARK: - 演出の順番

    private func runSequence() {
        // トーストは消えるので、視覚に頼れない場合のために読み上げを別途投げる
        UIAccessibility.post(notification: .announcement, argument: "カメラロールに保存しました")

        if reduceMotion {
            // 浮上と膜の演出は止め、トーストはフェードのみ
            appeared = true
            withAnimation(.easeInOut(duration: 0.3)) { showToast = true }
        } else {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    showToast = true
                }
            }
        }

        // 出る → とどまる → 消える で計 2.6 秒 (0.35 + 2.6 = 2.95)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
            withAnimation(.easeOut(duration: 0.4)) { showToast = false }
        }
    }
}

// MARK: - Header

private struct SavedHeader: View {
    /// 実際に表示されている写真の幅。ボタン列の左右端はこれに揃える (ReviewHeader と同じ実測束縛方式)
    let contentWidth: CGFloat
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Wordmark()

            HStack {
                // 左上はアイコンだけのガラス球。「帯の ← = 1画面戻る」で編集画面と共通の文法
                Button(action: onBack) {
                    Text("←")
                }
                .buttonStyle(PearlCircleButtonStyle(size: Pearl.barButtonHeight))
                .accessibilityLabel("編集に戻る")
                Spacer()
            }
        }
        // 実測幅が取れるまでの初回フレームだけ固定 padding で近似する
        .frame(width: contentWidth > 0 ? contentWidth : nil)
        .padding(.horizontal, contentWidth > 0 ? 0 : Pearl.barHorizontalPadding)
        // 高さは撮影・編集の帯と揃える。揃えないとプレートの開始位置が
        // クロスフェード中にずれて見える (#18 と同じ理由)
        .frame(height: Pearl.topBarHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Toast

private struct SavedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("✓")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Pearl.inkDeep)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Pearl.iris))
            Text("カメラロールに保存しました")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Pearl.ink)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 18)
        .background {
            // 背面ぼかしが意味を持つ唯一の場所。帯の上では背景が不透明で効かないが、
            // ここは写真の上なので実際に写真がぼけて透ける
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().fill(
                        Color.white.opacity(0.5)
                            .shadow(.inner(color: .white.opacity(0.8), radius: 3, y: -2))
                    )
                )
                .overlay(Capsule().strokeBorder(Pearl.glassEdgeLine, lineWidth: 1.2))
                .shadow(color: Color(.toastShadow).opacity(0.7), radius: 12, y: 10)
        }
    }
}

// MARK: - Sweep

/// 保存の合図として写真の上を一度だけ左から右に走る虹色の膜。
/// 色は撮影フラッシュ (Pearl.flash) と同じにして、撮影 → 保存を同じ光の演出でつなぐ
private struct SweepOverlay: View {
    @State private var go = false

    var body: some View {
        GeometryReader { geo in
            Pearl.flash
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.30),
                            .init(color: .white.opacity(0.55), location: 0.50),
                            .init(color: .clear, location: 0.70)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 1.6)
                    .offset(x: go ? geo.size.width * 0.6 : -geo.size.width * 0.9)
                )
                .opacity(go ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1).delay(0.25)) { go = true }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Share

/// UIActivityViewController のラッパー。フル解像度 (保存したものと同一) を渡す
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView(
            photo: SavedPhoto(
                full: UIImage(systemName: "person.fill") ?? UIImage(),
                display: UIImage(systemName: "person.fill") ?? UIImage()
            ),
            basePhotoWidth: 0,
            onBack: {},
            onShoot: {}
        )
    }
}
