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

// MARK: - Экран входа
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var phone = ""
    @State private var appeared = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -250)
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .opacity(0.6)
                        
                        Image("AppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    VStack(spacing: 6) {
                        Text("kochgramm")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Custom Telegram Client")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Text("+")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                        
                        TextField("Номер телефона", text: $phone)
                            .keyboardType(.phonePad)
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isLoggedIn = true
                        }
                    }) {
                        Text("Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .framem(maxWidth: .infinity)
                            .`.
padding(18)
                            .background(
                                  LinearGradient(
                                    colors: [. -blue, .purple],
                                    startPoint: . Поleading,
                                    endPoint: .являtrailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                appeared = true
            }
        }
    }
}

// MARK: - Главный экран с вкладками
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

// MARK: - Список чатов
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

// MARK: - Заглушка для остальных вкладок
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
