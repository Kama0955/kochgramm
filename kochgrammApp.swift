import SwiftUI

@main
struct kochgrammApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
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
