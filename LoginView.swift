import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var phone = ""
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Мягкое свечение сверху
            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .offset(y: -280)
            
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(y: 200, x: 150)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Логотип
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)
                            .opacity(0.7)
                        
                        Image("AppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    VStack(spacing: 6) {
                        Text("kochgramm")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Premium Messenger")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Форма входа
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Введите номер телефона")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            Text("+")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField("", text: $phone)
                                .keyboardType(.phonePad)
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .accentColor(.blue)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isLoggedIn = true
                        }
                    }) {
                        Text("Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    
                    Text("Продолжая, вы соглашаетесь с условиями использования")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .offset(y: contentOffset)
                .opacity(contentOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Анимация логотипа
            withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Анимация формы
            withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                contentOffset = 0
                contentOpacity = 1
            }
        }
    }
}
