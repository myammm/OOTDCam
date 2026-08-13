//
//  GlassSlider.swift
//  OOTDCam
//
//  編集画面の「濃さ」「ぼかし」用の自作スライダー。
//  凹んだパールのトラックにガラス玉のつまみを載せる。標準 Slider では再現できない見た目のみの差し替えで、
//  値の範囲・ステップ・反映タイミングは標準 Slider と同等
//

import SwiftUI

struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let usable = max(geo.size.width - thumbSize, 1)
            let ratio = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let x = usable * CGFloat(ratio) + thumbSize / 2

            ZStack(alignment: .leading) {
                // トラック (上から内側に影を落として凹んで見せる)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(.sliderTrackLight), Color(.sliderTrackDark)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: trackHeight)
                    .overlay(
                        Capsule()
                            .stroke(Color(.sliderTrackShadow).opacity(0.25), lineWidth: 1)
                            .blur(radius: 1)
                            .offset(y: 1)
                            .mask(Capsule())
                    )

                // ガラス玉のつまみ。フラットな円にすると他のパステルUIに埋もれるので影は必須
                Circle()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: Color(.sliderThumbMid), location: 0.45),
                            .init(color: Color(.sliderThumbEdge), location: 1)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.26),
                        startRadius: 0,
                        endRadius: thumbSize
                    ))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color(.sliderThumbShadow).opacity(0.45), radius: 3, y: 2)
                    .position(x: x, y: geo.size.height / 2)
            }
            // 見た目は6ptでも当たり判定は全高44pt。トラックのどこをタップしてもその位置に移動する
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let p = (gesture.location.x - thumbSize / 2) / usable
                        let clamped = min(max(p, 0), 1)
                        var newValue = range.lowerBound
                            + Double(clamped) * (range.upperBound - range.lowerBound)
                        if let step, step > 0 {
                            newValue = range.lowerBound
                                + (((newValue - range.lowerBound) / step).rounded()) * step
                            newValue = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        value = newValue
                    }
            )
        }
        .frame(height: 44)
    }
}

struct GlassSlider_Previews: PreviewProvider {
    struct Wrapper: View {
        @State private var value = 0.55
        var body: some View {
            HStack(spacing: 10) {
                Text("濃さ")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Pearl.inkSoft)
                    .frame(width: 34, alignment: .leading)
                GlassSlider(value: $value, range: 0.15...0.85, step: 0.05)
            }
            .padding()
            .background(PearlBackground())
        }
    }

    static var previews: some View {
        Wrapper()
    }
}
