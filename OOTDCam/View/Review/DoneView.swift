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
            RadialGradient(
                colors: [
                    Color(red: 0.541, green: 0.361, blue: 0.965).opacity(0.15),
                    Color(red: 0.03, green: 0.03, blue: 0.06)
                ],
                center: .init(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("✨")
                    .font(.system(size: 64))

                Text("SAVED!")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(Color.pink)
                    .shadow(color: .pink.opacity(0.4), radius: 8)

                Button(action: onShootAgain) {
                    Text("SHOOT AGAIN ★")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pink, Color(red: 0.541, green: 0.361, blue: 0.965)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .pink.opacity(0.27), radius: 16)
                        )
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
