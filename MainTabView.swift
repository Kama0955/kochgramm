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
            
            PlaceholderTabView(title: "Контакты", icon: "person.2.fill", subtitle: "Скоро здесь появятся ваши контакты")
                .tabItem {
                    Label("Контакты", systemImage: "person.2.fill")
                }
                .tag(1)
            
            PlaceholderTabView(title: "Звонки", icon: "phone.fill", subtitle: "История звонков появится здесь")
                .tabItem {
                    Label("Звонки", systemImage: "phone.fill")
                }
                .tag(2)
            
            PlaceholderTabView(title: "NEXORA AI", icon: "sparkles", subtitle: "Умный помощник скоро будет здесь")
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(3)
            
            PlaceholderTabView(title: "Настройки", icon: "gearshape.fill", subtitle: "Раздел настроек в разработке")
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Theme.accent)
    }
}

struct PlaceholderTabView: View {
    let title: String
    let icon: String
    let subtitle: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(Theme.accent)
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(subtitle)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle(title)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
