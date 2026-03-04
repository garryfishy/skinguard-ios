//
//  RootAndSplashView.swift
//  SkinGuard
//

import SwiftUI

let primaryColor = Color(red: 123/255, green: 164/255, blue: 1.0) // #7ba4ff

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    primaryColor,
                    primaryColor.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Image("splash_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 10)

                Text("Cek keamanan skincare & makeup kamu")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    RootView()
}

