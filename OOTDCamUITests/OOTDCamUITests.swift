//
//  OOTDCamUITests.swift
//  OOTDCamUITests
//
//  シミュレータではスクショモード (ScreenshotMode) が有効になり、
//  カメラの代わりにサンプル写真で撮影できる。それを使って
//  撮影 → 編集 → 保存の一連の流れを通す
//

import XCTest

final class OOTDCamUITests: XCTestCase {
    /// CI や並列実行中のシミュレータは遅く、撮影後の編集画面が数秒で出ないことがあるため長めに待つ
    private let timeout: TimeInterval = 30

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test撮影して編集して保存すると保存完了画面に進む() throws {
        let app = XCUIApplication()
        // 写真ライブラリの権限を未決定に戻し、毎回同じ経路 (許可ダイアログあり) を通す
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        // 撮影
        let shutter = app.buttons["shutterButton"]
        XCTAssertTrue(shutter.waitForExistence(timeout: timeout))
        shutter.tap()

        // 編集: モチーフを選んで完了
        let heartTile = app.buttons["shapeTile.heart"]
        XCTAssertTrue(heartTile.waitForExistence(timeout: timeout))
        heartTile.tap()
        app.buttons["doneButton"].tap()

        // 初回保存時の写真ライブラリ (追加のみ) の許可ダイアログ。
        // シミュレータの言語によらず押せるよう、右端 (許可) のボタンを位置で選ぶ
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permissionAlert = springboard.alerts.firstMatch
        XCTAssertTrue(permissionAlert.waitForExistence(timeout: timeout))
        permissionAlert.buttons.element(boundBy: permissionAlert.buttons.count - 1).tap()

        // 保存完了画面
        XCTAssertTrue(app.buttons["shootAgainButton"].waitForExistence(timeout: timeout))
    }
}
