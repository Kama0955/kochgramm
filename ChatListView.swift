import SwiftUI

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unread: Int
    let isOnline: Bool
    let avatarColor: Color
}

struct ChatListView: View {
    @State private var searchText = ""
    
    let chats: [Chat] = [
        Chat(name: "Александр", lastMessage: "Привет! Как дела?", time: "14:23", unread: 2, isOnline: true, avatarColor: .blue),
        Chat(name: "Мария", lastMessage: "Отправила фото 📸", time: "13:45", unread: 0, isOnline: false, avatarColor: .pink),
        Chat(name: "Рабочий чат", lastMessage: "Дмитрий: Совещание в 15:00", time: "12:30", unread: 5, isOnline: false, avatarColor: .orange),
        Chat(name: "Telegram News", lastMessage: "Обновление вышло!", time: "11:00", unread: 0, isOnline: false, avatarColor: .cyan),
        Chat(name: "Иван Петров", lastMessage: "Спасибо 👍", time: "Вчера", unread: 0, isOnline: true, avatarColor: .green),
        Chat(name: "Дизайн-канал", lastMessage: "Новая подборка иконок", time: "Вчера", unread: 12, isOnline: false, avatarColor: .purple),
        Chat(name: "Ольга", lastMessage: "Договорились!", time: "Пн", unread: 0, isOnline: false, avatarColor: .red),
        Chat(name: "NEXOGRAM Chat", lastMessage: "Добро пожаловать!", time: "Пн", unread: 0, isOnline: false, avatarColor: .indigo)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ChatSectionHeader(title: "Закреплённые")
                        
                        ForEach(chats.prefix(2)) { chat in
                            ChatRowView(chat: chat)
                            Divider().background(Theme.divider).padding(.leading, 76)
                        }
                        
                        ChatSectionHeader(title: "Все чаты")
                        
                        ForEach(chats.dropFirst(2)) { chat in
                            ChatRowView(chat: chat)
                            Divider().background(Theme.divider).padding(.leading, 76)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Поиск")
        }
        .preferredColorScheme(.dark)
    }
}

struct ChatSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(chat.avatarColor.gradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(chat.name.prefix(1)))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                if chat.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(chat.time)
                        .font(.system(size: 13))
                        .foregroundColor(chat.unread > 0 ? Theme.accent : Theme.textSecondary)
                }
                
                HStack {
                    Text(chat.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    
                    if chat.unread > 0 {
                        Text("\(chat.unread)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Theme.unread)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
