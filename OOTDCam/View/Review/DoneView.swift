//
//  DoneView.swift
//  OOTDCam
//

import SwiftUI

struct DoneView: View {
    let onShootAgain: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: 24) {
                Text("✨")
                    .font(.system(size: 64))

                Text("保存しました！")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Pearl.ink)

                Button(action: onShootAgain) {
                    Text("もう一度撮る")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(Pearl.inkDeep)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(Pearl.iris)
                                .shadow(color: Color(.irisButtonGlow).opacity(0.8), radius: 12, y: 5)
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                }
                .padding(.top, 20)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

struct DoneView_Previews: PreviewProvider {
    static var previews: some View {
        DoneView(onShootAgain: {})
    }
}
