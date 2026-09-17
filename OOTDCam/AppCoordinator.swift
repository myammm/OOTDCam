//
//  AppCoordinator.swift
//  OOTDCam
//

import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    enum Screen {
        case camera
        case review
        case saved
    }

    @Published var screen: Screen = .camera
    @Published var capturedPhoto: CapturedPhoto?
    /// 撮影画面で実測したプレビュー (写真) の幅。全画面の写真幅の基準。
    /// 縦が短い端末 (SE など) では撮影画面の写真が一番狭くなるため、
    /// 編集・保存完了はこれを上限にして3画面の写真幅を揃える (固定値の計算式は持たない)
    @Published var basePhotoWidth: CGFloat = 0
    /// 編集状態 (シェイプ位置・保存済みフラグ) は Coordinator が保持する。
    /// View 側の @StateObject にすると、保存完了画面から「戻る」で編集画面を
    /// 再表示したときに編集内容が初期化されてしまう
    @Published var reviewViewModel: ReviewViewModel?
    @Published var savedPhoto: SavedPhoto?

    func didCapture(_ photo: CapturedPhoto) {
        capturedPhoto = photo
        reviewViewModel = ReviewViewModel(photo: photo)
        screen = .review
    }

    func retake() {
        capturedPhoto = nil
        reviewViewModel = nil
        screen = .camera
    }

    func didFinishSaving(_ saved: SavedPhoto) {
        savedPhoto = saved
        screen = .saved
    }

    /// 保存完了画面 → 編集画面。編集状態は reviewViewModel がそのまま持っている
    func backToEdit() {
        screen = .review
    }

    func shootAgain() {
        capturedPhoto = nil
        reviewViewModel = nil
        savedPhoto = nil
        screen = .camera
    }
}
