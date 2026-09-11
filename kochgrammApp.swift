import SwiftUI

@main
struct kochgrammApp: App {
    @State private var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

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
            
            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .offset(y: -280)
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)
                            .opacity(0.7)
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    VStack(spacing: 6) {
                        Text("kochgramm")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Premium Messenger")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Введите номер телефона")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            Text("+")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField("", text: $phone)
                                .keyboardType(.phonePad)
                                .foregroundColor(.white)
                                .font(.system(size: 18))
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
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .offset(y: contentOffset)
                .opacity(contentOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                contentOffset = 0
                contentOpacity = 1
            }
        }
    }
}

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatScreen()
                .tabItem { Label("Чаты", systemImage: "message.fill") }
                .tag(0)
            
            SimpleScreen(title: "Контакты", icon: "person.2.fill")
                .tabItem { Label("Контакты", systemImage: "person.2.fill") }
                .tag(1)
            
            SimpleScreen(title: "Звонки", icon: "phone.fill")
                .tabItem { Label("Звонки", systemImage: "phone.fill") }
                .tag(2)
            
            SimpleScreen(title: "AI", icon: "sparkles")
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(3)
            
            SimpleScreen(title: "Настройки", icon: "gearshape.fill")
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.blue)
        .preferredColorScheme(.dark)
    }
}

struct ChatScreen: View {
    let names = ["Александр", "Мария", "Рабочий чат", "Telegram News", "Иван", "Ольга"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(names, id: \.self) { name in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(name.prefix(1)))
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )
                        VStack(alignment: .leading) {
                            Text(name).font(.headline)
                            Text("Последнее сообщение").font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Чаты")
        }
    }
}

struct SimpleScreen: View {
    let title: String
    let icon: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text(title)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .navigationTitle(title)
        }
    }
}
