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
