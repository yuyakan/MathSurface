//
//  SplashView.swift
//  MathSurface
//
//  起動時のスプラッシュ画面
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Image("splash")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: .indigo.opacity(0.25), radius: 24, y: 8)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onFinish()
                }
            }
        }
    }
}
