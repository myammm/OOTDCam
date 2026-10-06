# fig.cam

[![Test](https://github.com/myammm/OOTDCam/actions/workflows/test.yml/badge.svg)](https://github.com/myammm/OOTDCam/actions/workflows/test.yml)

顔を隠して全身コーデを撮る OOTD カメラアプリ (iOS)。

撮影ガイドに合わせて撮り、顔の位置にハート・星などのモチーフを重ねてぼかし＋グラデーションで隠す。日付スタンプを焼き込んでカメラロールへ保存・共有できる。

[App Store](https://apps.apple.com/jp/app/fig-cam/id6816117067)

## 画面

- **撮影**: 顔から足元までの撮影ガイド付きカメラ
- **編集**: モチーフの種類・位置・サイズ・色・ぼかし・濃さを調整、日付スタンプの ON/OFF
- **保存完了**: カメラロールへ保存、共有シート

## 環境

- iOS 18.0+
- Swift 6 / SwiftUI
- AVFoundation, Core Image, Photos
- Swift Testing / XCUITest
- Google Mobile Ads, RevenueCat (SPM)
- 日本語 / 英語

## 構成

```
OOTDCam/
├── AppCoordinator.swift  # 画面遷移
├── Model/
├── Service/              # カメラ・画像合成・写真ライブラリ
└── View/
    ├── Camera/
    ├── Review/           # 編集画面
    ├── Saved/            # 保存完了画面
    └── Component/
```
