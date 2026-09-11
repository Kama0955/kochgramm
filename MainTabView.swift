import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Label("Чаты", systemImage: "message.fill")
                }
                .tag(0)
            
            ContactsPlaceholderView()
                .tabItem {
                    Label("Контакты", systemImage: "person.2.fill")
                }
                .tag(1)
            
            CallsPlaceholderView()
                .tabItem {
                    Label("Звонки", systemImage: "phone.fill")
                }
                .tag(2)
            
            AIView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Theme.accent)
    }
}

struct ContactsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.textSecondary)
                    Text("Контакты")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Скоро здесь появятся ваши контакты")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .navigationTitle("Контакты")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct CallsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.textSecondary)
                    Text("Звонки")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("История звонков появится здесь")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .navigationTitle("Звонки")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct AIView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.accent)
                    Text("NEXORA AI")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Умный помощник скоро будет здесь")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .navigationTitle("AI")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
