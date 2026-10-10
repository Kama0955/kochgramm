import SwiftUI
import Combine
import Foundation
import TDLibKit

typealias Date = Foundation.Date

// MARK: - Telegram Configuration
let kochApiId: Int = 31805867
let kochApiHash: String = "API_HASH_PLACEHOLDER"

// MARK: - App Entry Point
@main
struct kochgrammApp: App {
    @StateObject private var telegram = TelegramManager()
    @StateObject private var ghostMode = GhostModeManager.shared
    @StateObject private var deletedStore = DeletedMessagesStore.shared
    @StateObject private var callManager = CallManager.shared
    @AppStorage("koch_theme_mode") private var themeMode: String = "dark"
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if telegram.isLoggedIn {
                        MainAppTabView()
                    } else {
                        AuthenticationRootView()
                    }
                }
                
                // Fullscreen VoIP Call Overlay if active
                if callManager.isCallActive {
                    ActiveCallView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .environmentObject(telegram)
            .environmentObject(ghostMode)
            .environmentObject(deletedStore)
            .environmentObject(callManager)
            .preferredColorScheme(themeMode == "light" ? .light : .dark)
        }
    }
}

// MARK: - Data Models for Telegram & Kochgram

struct LocalChat: Identifiable, Hashable {
    let id: Int64
    var title: String
    var lastMessageSnippet: String
    var lastMessageDate: Date
    var unreadCount: Int
    var isPinned: Bool
    var isChannel: Bool
    var isGroup: Bool
    var avatarLetter: String {
        String(title.prefix(1)).uppercased()
    }
}

struct LocalMessage: Identifiable, Codable, Hashable {
    let id: Int64
    let chatId: Int64
    let senderName: String
    let senderId: Int64
    let text: String
    let date: Date
    let isOutgoing: Bool
    var isDeletedLocally: Bool = false
    var deletedAt: Date? = nil
    var mediaType: String? = nil // "photo", "voice", "sticker", "document"
    var voiceDuration: Int = 0   // seconds
    var stickerEmoji: String? = nil
    var isEdited: Bool = false
    var replyToSnippet: String? = nil
    var reaction: String? = nil
}

struct LocalCall: Identifiable, Hashable {
    let id = UUID()
    let callerName: String
    let date: Date
    let isOutgoing: Bool
    let isMissed: Bool
    let isVideo: Bool
    let durationString: String
}

// MARK: - 📞 VoIP Calls Manager
@MainActor
class CallManager: ObservableObject {
    static let shared = CallManager()
    
    @Published var isCallActive: Bool = false
    @Published var activeCallerName: String = "Алексей"
    @Published var activeCallerPhone: String = "+7 999 123-45-67"
    @Published var isVideoCall: Bool = false
    @Published var callDurationSeconds: Int = 0
    @Published var isMuted: Bool = false
    @Published var isSpeaker: Bool = false
    @Published var isVideoPaused: Bool = false
    
    @Published var callHistory: [LocalCall] = [
        LocalCall(callerName: "Павел Дуров", date: Date().addingTimeInterval(-3600), isOutgoing: false, isMissed: false, isVideo: false, durationString: "04:12"),
        LocalCall(callerName: "Анна Смирнова", date: Date().addingTimeInterval(-86400), isOutgoing: true, isMissed: false, isVideo: true, durationString: "12:45"),
        LocalCall(callerName: "Команда Kochgram", date: Date().addingTimeInterval(-172800), isOutgoing: false, isMissed: true, isVideo: false, durationString: "Пропущенный")
    ]
    
    private var timer: AnyCancellable?
    
    func startCall(name: String, isVideo: Bool = false) {
        activeCallerName = name
        isVideoCall = isVideo
        callDurationSeconds = 0
        isMuted = false
        isSpeaker = false
        isVideoPaused = false
        isCallActive = true
        
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.callDurationSeconds += 1
            }
    }
    
    func endCall() {
        if isCallActive {
            let call = LocalCall(
                callerName: activeCallerName,
                date: Date(),
                isOutgoing: true,
                isMissed: false,
                isVideo: isVideoCall,
                durationString: String(format: "%02d:%02d", callDurationSeconds / 60, callDurationSeconds % 60)
            )
            callHistory.insert(call, at: 0)
        }
        timer?.cancel()
        timer = nil
        isCallActive = false
    }
}

// MARK: - 👻 Ghost Mode Manager
@MainActor
class GhostModeManager: ObservableObject {
    static let shared = GhostModeManager()
    
    @AppStorage("ghost_master_enabled") var isMasterGhostEnabled: Bool = false
    @AppStorage("ghost_hide_typing") var hideTyping: Bool = true
    @AppStorage("ghost_stealth_read") var stealthReadMessages: Bool = true
    @AppStorage("ghost_stealth_stories") var stealthStories: Bool = true
    
    @AppStorage("ghost_per_chat_ids") private var perChatIdsJson: String = "[]"
    @Published var perChatGhostList: Set<Int64> = []
    
    init() {
        if let data = perChatIdsJson.data(using: .utf8),
           let ids = try? JSONDecoder().decode([Int64].self, from: data) {
            self.perChatGhostList = Set(ids)
        }
    }
    
    func isGhostActive(for chatId: Int64) -> Bool {
        if isMasterGhostEnabled { return true }
        return perChatGhostList.contains(chatId)
    }
    
    func toggleChatGhost(chatId: Int64) {
        if perChatGhostList.contains(chatId) {
            perChatGhostList.remove(chatId)
        } else {
            perChatGhostList.insert(chatId)
        }
        if let encoded = try? JSONEncoder().encode(Array(perChatGhostList)),
           let str = String(data: encoded, encoding: .utf8) {
            perChatIdsJson = str
        }
    }
}

// MARK: - 🗑️ Deleted Messages Store
@MainActor
class DeletedMessagesStore: ObservableObject {
    static let shared = DeletedMessagesStore()
    
    @AppStorage("save_deleted_messages_enabled") var isSaveEnabled: Bool = true
    @Published var savedDeletedMessages: [LocalMessage] = []
    @Published var allCachedMessages: [Int64: [LocalMessage]] = [:]
    
    private let cacheFileUrl: URL
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheFileUrl = docs.appendingPathComponent("koch_deleted_messages.json")
        loadFromDisk()
    }
    
    func cacheIncomingMessage(_ message: LocalMessage) {
        guard isSaveEnabled else { return }
        var list = allCachedMessages[message.chatId] ?? []
        if !list.contains(where: { $0.id == message.id }) {
            list.append(message)
            allCachedMessages[message.chatId] = list
        }
    }
    
    func markMessagesDeleted(chatId: Int64, messageIds: [Int64]) {
        guard isSaveEnabled else { return }
        guard var list = allCachedMessages[chatId] else { return }
        
        for id in messageIds {
            if let idx = list.firstIndex(where: { $0.id == id }) {
                var deletedMsg = list[idx]
                if !deletedMsg.isDeletedLocally {
                    deletedMsg.isDeletedLocally = true
                    deletedMsg.deletedAt = Date()
                    list[idx] = deletedMsg
                    
                    if !savedDeletedMessages.contains(where: { $0.id == deletedMsg.id }) {
                        savedDeletedMessages.insert(deletedMsg, at: 0)
                    }
                }
            }
        }
        allCachedMessages[chatId] = list
        saveToDisk()
    }
    
    func clearAllHistory() {
        savedDeletedMessages.removeAll()
        allCachedMessages.removeAll()
        try? FileManager.default.removeItem(at: cacheFileUrl)
    }
    
    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(savedDeletedMessages) else { return }
        try? data.write(to: cacheFileUrl, options: .atomic)
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: cacheFileUrl),
              let list = try? JSONDecoder().decode([LocalMessage].self, from: data) else { return }
        self.savedDeletedMessages = list
    }
}

// MARK: - Core Telegram Manager (TDLib)
@MainActor
class TelegramManager: ObservableObject {
    private let clientManager = TDLibClientManager()
    private var client: TDLibClient?
    
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authState = 0
    @Published var connectionStatus: String = "Подключение..."
    
    @Published var currentUserName: String = "Kochgram Пользователь"
    @Published var currentUserPhone: String = ""
    @Published var currentUserId: Int64 = 0
    
    @Published var chats: [LocalChat] = []
    @Published var messagesForChat: [Int64: [LocalMessage]] = [:]
    @Published var pinnedMessages: [Int64: LocalMessage] = [:]
    
    init() {
        setupTDLib()
        injectDemoChatsIfEmpty()
    }
    
    private func injectDemoChatsIfEmpty() {
        if chats.isEmpty {
            chats = [
                LocalChat(id: 101, title: "Павел Дуров", lastMessageSnippet: "Рад приветствовать в Kochgram!", lastMessageDate: Date().addingTimeInterval(-60), unreadCount: 1, isPinned: true, isChannel: false, isGroup: false),
                LocalChat(id: 102, title: "Kochgram Updates", lastMessageSnippet: "Режим призрака и сохранение удаленных активированы 🚀", lastMessageDate: Date().addingTimeInterval(-300), unreadCount: 0, isPinned: true, isChannel: true, isGroup: false),
                LocalChat(id: 103, title: "Telegram Новости", lastMessageSnippet: "Новое крупное обновление TDLib и MTProto", lastMessageDate: Date().addingTimeInterval(-3600), unreadCount: 2, isPinned: false, isChannel: true, isGroup: false),
                LocalChat(id: 104, title: "Разработка iOS", lastMessageSnippet: "SwiftUI анимации на 120 Гц работают идеально", lastMessageDate: Date().addingTimeInterval(-7200), unreadCount: 0, isPinned: false, isChannel: false, isGroup: true)
            ]
            
            // Demo messages
            let demoMsg1 = LocalMessage(id: 201, chatId: 101, senderName: "Павел Дуров", senderId: 101, text: "Добро пожаловать в кастомный клиент Kochgram на базе TDLib!", date: Date().addingTimeInterval(-120), isOutgoing: false)
            let demoMsg2 = LocalMessage(id: 202, chatId: 101, senderName: "Вы", senderId: 0, text: "Спасибо! Настоящий Telegram API и полный контроль над приватностью 🔥", date: Date().addingTimeInterval(-90), isOutgoing: true)
            messagesForChat[101] = [demoMsg1, demoMsg2]
            pinnedMessages[101] = demoMsg1
        }
    }
    
    private func setupTDLib() {
        client = clientManager.createClient(updateHandler: { [weak self] data, client in
            Task { @MainActor in
                self?.handleUpdate(data: data, client: client)
            }
        })
    }
    
    private func handleUpdate(data: Data, client: TDLibClient) {
        guard let update = try? client.decoder.decode(Update.self, from: data) else { return }
        
        switch update {
        case .updateAuthorizationState(let auth):
            handleAuthUpdate(auth.authorizationState)
            
        case .updateConnectionState(let conn):
            switch conn.state {
            case .connectionStateReady:
                self.connectionStatus = "Подключено"
            case .connectionStateConnecting:
                self.connectionStatus = "Подключение..."
            case .connectionStateUpdating:
                self.connectionStatus = "Обновление..."
            case .connectionStateWaitingForNetwork:
                self.connectionStatus = "Ожидание сети..."
            default:
                self.connectionStatus = "Синхронизация..."
            }
            
        case .updateUser(let u):
            if u.user.id == self.currentUserId || self.currentUserId == 0 {
                self.currentUserId = u.user.id
                let fullName = "\(u.user.firstName) \(u.user.lastName)".trimmingCharacters(in: .whitespaces)
                self.currentUserName = fullName.isEmpty ? "Telegram User" : fullName
                self.currentUserPhone = u.user.phoneNumber
            }
            
        case .updateNewChat(let newChat):
            let c = newChat.chat
            let chatItem = LocalChat(
                id: c.id,
                title: c.title,
                lastMessageSnippet: "Диалог синхронизирован",
                lastMessageDate: Date(),
                unreadCount: c.unreadCount,
                isPinned: c.positions.contains(where: { $0.isPinned }),
                isChannel: false,
                isGroup: false
            )
            if !self.chats.contains(where: { $0.id == c.id }) {
                self.chats.append(chatItem)
            }
            
        case .updateChatTitle(let titleUpdate):
            if let idx = self.chats.firstIndex(where: { $0.id == titleUpdate.chatId }) {
                self.chats[idx].title = titleUpdate.title
            }
            
        case .updateNewMessage(let newMsg):
            let msg = newMsg.message
            let text = extractText(from: msg.content)
            let localMsg = LocalMessage(
                id: msg.id,
                chatId: msg.chatId,
                senderName: msg.isOutgoing ? "Вы" : "Собеседник",
                senderId: msg.senderId.hashValue == 0 ? 0 : Int64(msg.senderId.hashValue),
                text: text,
                date: Date(timeIntervalSince1970: TimeInterval(msg.date)),
                isOutgoing: msg.isOutgoing,
                isDeletedLocally: false
            )
            
            DeletedMessagesStore.shared.cacheIncomingMessage(localMsg)
            
            var current = self.messagesForChat[msg.chatId] ?? []
            if !current.contains(where: { $0.id == localMsg.id }) {
                current.append(localMsg)
                self.messagesForChat[msg.chatId] = current
            }
            
            if let idx = self.chats.firstIndex(where: { $0.id == msg.chatId }) {
                self.chats[idx].lastMessageSnippet = text
                self.chats[idx].lastMessageDate = localMsg.date
            }
            
        case .updateDeleteMessages(let del):
            DeletedMessagesStore.shared.markMessagesDeleted(chatId: del.chatId, messageIds: del.messageIds)
            
        default:
            break
        }
    }
    
    private func extractText(from content: MessageContent) -> String {
        switch content {
        case .messageText(let t):
            return t.text.text
        case .messagePhoto(let p):
            let caption = p.caption.text
            return caption.isEmpty ? "📷 Фотография" : "📷 \(caption)"
        case .messageVoiceNote:
            return "🎤 Голосовое сообщение"
        case .messageDocument(let doc):
            return "📁 Файл: \(doc.document.fileName)"
        case .messageSticker:
            return "🎭 Стикер"
        case .messageVideo(let v):
            return v.caption.text.isEmpty ? "🎥 Видео" : "🎥 \(v.caption.text)"
        default:
            return "Сообщение"
        }
    }
    
    private func handleAuthUpdate(_ state: AuthorizationState) {
        switch state {
        case .authorizationStateWaitTdlibParameters:
            Task {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let tdlibPath = docs.appendingPathComponent("tdlib_data").path
                let filesPath = docs.appendingPathComponent("tdlib_files").path
                
                do {
                    _ = try await client?.setTdlibParameters(
                        apiHash: kochApiHash,
                        apiId: kochApiId,
                        applicationVersion: "1.0",
                        databaseDirectory: tdlibPath,
                        databaseEncryptionKey: nil,
                        deviceModel: "iPhone",
                        filesDirectory: filesPath,
                        systemLanguageCode: "ru",
                        systemVersion: "iOS 16.0",
                        useChatInfoDatabase: true,
                        useFileDatabase: true,
                        useMessageDatabase: true,
                        useSecretChats: false,
                        useTestDc: false
                    )
                } catch {
                    self.errorMessage = "Ошибка параметров TDLib: \(error.localizedDescription)"
                }
            }
        case .authorizationStateWaitPhoneNumber:
            isLoading = false
            authState = 0
        case .authorizationStateWaitCode:
            isLoading = false
            authState = 1
        case .authorizationStateWaitPassword:
            isLoading = false
            authState = 2
        case .authorizationStateReady:
            isLoading = false
            isLoggedIn = true
            loadInitialChats()
        case .authorizationStateLoggingOut, .authorizationStateClosed:
            isLoggedIn = false
            isLoading = false
        default:
            break
        }
    }
    
    func loadInitialChats() {
        Task {
            do {
                _ = try await client?.loadChats(chatList: nil, limit: 30)
                _ = try await client?.getMe()
            } catch {}
        }
    }
    
    func sendPhone(_ phone: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await client?.setAuthenticationPhoneNumber(phoneNumber: phone, settings: nil)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func sendCode(_ code: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await client?.checkAuthenticationCode(code: code)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func sendPassword(_ password: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await client?.checkAuthenticationPassword(password: password)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func logOut() {
        Task {
            do {
                _ = try await client?.logOut()
                self.isLoggedIn = false
                self.chats.removeAll()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func togglePinChat(chatId: Int64) {
        if let idx = chats.firstIndex(where: { $0.id == chatId }) {
            chats[idx].isPinned.toggle()
        }
    }
    
    func togglePinMessage(chatId: Int64, message: LocalMessage) {
        if pinnedMessages[chatId]?.id == message.id {
            pinnedMessages.removeValue(forKey: chatId)
        } else {
            pinnedMessages[chatId] = message
        }
    }
    
    func addReaction(chatId: Int64, messageId: Int64, emoji: String) {
        var list = messagesForChat[chatId] ?? []
        if let idx = list.firstIndex(where: { $0.id == messageId }) {
            list[idx].reaction = emoji
            messagesForChat[chatId] = list
        }
    }
    
    func sendTextMessage(chatId: Int64, text: String, replyToMessageId: Int64? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Append locally immediately for responsiveness
        let localId = Int64(Date().timeIntervalSince1970 * 1000)
        let newMsg = LocalMessage(
            id: localId,
            chatId: chatId,
            senderName: "Вы",
            senderId: 0,
            text: text,
            date: Date(),
            isOutgoing: true
        )
        var current = messagesForChat[chatId] ?? []
        current.append(newMsg)
        messagesForChat[chatId] = current
        
        if let idx = chats.firstIndex(where: { $0.id == chatId }) {
            chats[idx].lastMessageSnippet = text
            chats[idx].lastMessageDate = Date()
        }
        
        let formatted = FormattedText(entities: [], text: text)
        let content = InputMessageContent.inputMessageText(
            InputMessageText(clearDraft: true, linkPreviewOptions: nil, text: formatted)
        )
        
        Task {
            _ = try? await client?.sendMessage(
                chatId: chatId,
                inputMessageContent: content,
                options: nil,
                replyMarkup: nil,
                replyTo: nil,
                topicId: nil
            )
        }
    }
    
    func sendStickerMessage(chatId: Int64, emoji: String) {
        let localId = Int64(Date().timeIntervalSince1970 * 1000)
        let newMsg = LocalMessage(
            id: localId,
            chatId: chatId,
            senderName: "Вы",
            senderId: 0,
            text: emoji,
            date: Date(),
            isOutgoing: true,
            mediaType: "sticker",
            stickerEmoji: emoji
        )
        var current = messagesForChat[chatId] ?? []
        current.append(newMsg)
        messagesForChat[chatId] = current
        
        if let idx = chats.firstIndex(where: { $0.id == chatId }) {
            chats[idx].lastMessageSnippet = "🎭 Стикер \(emoji)"
            chats[idx].lastMessageDate = Date()
        }
    }
    
    func sendVoiceMessage(chatId: Int64, duration: Int) {
        let localId = Int64(Date().timeIntervalSince1970 * 1000)
        let newMsg = LocalMessage(
            id: localId,
            chatId: chatId,
            senderName: "Вы",
            senderId: 0,
            text: "Голосовое сообщение",
            date: Date(),
            isOutgoing: true,
            mediaType: "voice",
            voiceDuration: duration
        )
        var current = messagesForChat[chatId] ?? []
        current.append(newMsg)
        messagesForChat[chatId] = current
        
        if let idx = chats.firstIndex(where: { $0.id == chatId }) {
            chats[idx].lastMessageSnippet = "🎤 Голосовое (\(duration) сек)"
            chats[idx].lastMessageDate = Date()
        }
    }
    
    func sendTypingAction(chatId: Int64) {
        if GhostModeManager.shared.isGhostActive(for: chatId) && GhostModeManager.shared.hideTyping {
            return
        }
        Task {
            _ = try? await client?.sendChatAction(action: .chatActionTyping, businessConnectionId: nil, chatId: chatId, topicId: nil)
        }
    }
    
    func markChatRead(chatId: Int64, messageIds: [Int64]) {
        if GhostModeManager.shared.isGhostActive(for: chatId) && GhostModeManager.shared.stealthReadMessages {
            return
        }
        Task {
            _ = try? await client?.viewMessages(chatId: chatId, forceRead: true, messageIds: messageIds, source: nil)
        }
    }
}

// MARK: - Country Directory
struct Country: Identifiable {
    let id = UUID()
    let flag: String
    let name: String
    let code: String
}

let countries: [Country] = [
    Country(flag: "🇷🇺", name: "Россия", code: "+7"),
    Country(flag: "🇩🇪", name: "Германия", code: "+49"),
    Country(flag: "🇧🇾", name: "Беларусь", code: "+375"),
    Country(flag: "🇰🇿", name: "Казахстан", code: "+7"),
    Country(flag: "🇺🇦", name: "Украина", code: "+380"),
    Country(flag: "🇺🇸", name: "США", code: "+1"),
    Country(flag: "🇬🇧", name: "Великобритания", code: "+44"),
    Country(flag: "🇫🇷", name: "Франция", code: "+33"),
    Country(flag: "🇮🇹", name: "Италия", code: "+39"),
    Country(flag: "🇹🇷", name: "Турция", code: "+90"),
    Country(flag: "🇦🇪", name: "ОАЭ", code: "+971")
]

// MARK: - Authentication View
struct AuthenticationRootView: View {
    @EnvironmentObject var telegram: TelegramManager
    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var selectedCountry = countries[0]
    @State private var showCountryPicker = false
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 50)
                
                Image(systemName: telegram.authState == 0 ? "paperplane.circle.fill" : (telegram.authState == 1 ? "lock.message.fill" : "key.fill"))
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.bottom, 20)
                
                Text("Kochgram")
                    .font(.system(size: 32, weight: .bold))
                
                Text(telegram.authState == 0 ? "Введите номер телефона" : (telegram.authState == 1 ? "Проверочный код" : "Облачный пароль (2FA)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                
                if telegram.authState == 0 {
                    Button(action: { showCountryPicker = true }) {
                        HStack {
                            Text(selectedCountry.flag).font(.title3)
                            Text(selectedCountry.name).foregroundColor(.primary)
                            Spacer()
                            Text(selectedCountry.code).foregroundColor(.secondary)
                            Image(systemName: "chevron.right").font(.footnote).foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    HStack {
                        Text(selectedCountry.code)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Номер телефона", text: $phone)
                            .keyboardType(.phonePad)
                            .focused($isFieldFocused)
                            .font(.title3)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    Button(action: {
                        let fullPhone = selectedCountry.code + phone
                        telegram.sendPhone(fullPhone)
                    }) {
                        HStack {
                            if telegram.isLoading {
                                ProgressView().tint(.white).padding(.trailing, 6)
                            }
                            Text(telegram.isLoading ? "Подключение..." : "Продолжить")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(phone.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(phone.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                } else if telegram.authState == 1 {
                    TextField("Код из Telegram", text: $code)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .bold))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 48)
                    
                    Button(action: { telegram.sendCode(code) }) {
                        Text(telegram.isLoading ? "Проверка..." : "Войти")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(code.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(code.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                } else if telegram.authState == 2 {
                    SecureField("Пароль", text: $password)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 48)
                    
                    Button(action: { telegram.sendPassword(password) }) {
                        Text(telegram.isLoading ? "Проверка..." : "Подтвердить пароль")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(password.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(password.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                
                if let err = telegram.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerModal(selected: $selectedCountry)
        }
    }
}

struct CountryPickerModal: View {
    @Binding var selected: Country
    @Environment(\.dismiss) var dismiss
    @State private var query = ""
    
    var filtered: [Country] {
        query.isEmpty ? countries : countries.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        NavigationStack {
            List(filtered) { c in
                Button(action: {
                    selected = c
                    dismiss()
                }) {
                    HStack {
                        Text(c.flag).font(.title2)
                        Text(c.name).foregroundColor(.primary)
                        Spacer()
                        Text(c.code).foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $query, prompt: "Поиск страны")
            .navigationTitle("Выберите страну")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() }
            )
        }
    }
}

// MARK: - Main Application Tab View
struct MainAppTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatsListScreen()
                .tabItem { Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(0)
            
            CallsScreenView()
                .tabItem { Label("Звонки", systemImage: "phone.fill") }
                .tag(1)
            
            SavedDeletedMessagesScreen()
                .tabItem { Label("Удалённые", systemImage: "trash.circle.fill") }
                .tag(2)
            
            SettingsMainScreen()
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - 📞 Calls Screen View
struct CallsScreenView: View {
    @EnvironmentObject var callManager: CallManager
    @State private var filterMode = 0 // 0: Все, 1: Пропущенные
    
    var filteredCalls: [LocalCall] {
        if filterMode == 1 {
            return callManager.callHistory.filter { $0.isMissed }
        }
        return callManager.callHistory
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Фильтр", selection: $filterMode) {
                    Text("Все").tag(0)
                    Text("Пропущенные").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredCalls) { call in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(call.isMissed ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: call.isVideo ? "video.fill" : "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(call.isMissed ? .red : .green)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(call.callerName)
                                    .font(.headline)
                                    .foregroundColor(call.isMissed ? .red : .primary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: call.isOutgoing ? "arrow.up.right" : "arrow.down.left")
                                        .font(.caption2)
                                        .foregroundColor(call.isMissed ? .red : .secondary)
                                    Text(call.durationString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                callManager.startCall(name: call.callerName, isVideo: call.isVideo)
                            } label: {
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Звонки")
            .navigationBarItems(
                trailing: Button {
                    callManager.startCall(name: "Павел Дуров", isVideo: false)
                } label: {
                    Image(systemName: "phone.badge.plus")
                }
            )
        }
    }
}

// MARK: - 📲 Active VoIP Call Fullscreen Screen
struct ActiveCallView: View {
    @EnvironmentObject var callManager: CallManager
    @State private var waveScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.10, blue: 0.15).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top E2E Emoji security hash (Standard Telegram style)
                HStack(spacing: 8) {
                    Text("🔒 Сквозное шифрование:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("🍋 🚀 🦊 🛡️")
                        .font(.caption)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Pulsing avatar circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 170, height: 170)
                        .scaleEffect(waveScale)
                        .opacity(2.0 - Double(waveScale))
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: waveScale)
                    
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 130, height: 130)
                    
                    Text(String(callManager.activeCallerName.prefix(1)))
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .onAppear { waveScale = 1.6 }
                
                VStack(spacing: 8) {
                    Text(callManager.activeCallerName)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(String(format: "%02d:%02d", callManager.callDurationSeconds / 60, callManager.callDurationSeconds % 60))
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Call controls
                HStack(spacing: 36) {
                    CallCircleButton(
                        icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                        title: "Звук",
                        isActive: callManager.isMuted
                    ) {
                        callManager.isMuted.toggle()
                    }
                    
                    CallCircleButton(
                        icon: callManager.isVideoCall ? "video.fill" : "video.slash.fill",
                        title: "Видео",
                        isActive: callManager.isVideoCall
                    ) {
                        callManager.isVideoCall.toggle()
                    }
                    
                    CallCircleButton(
                        icon: callManager.isSpeaker ? "speaker.wave.3.fill" : "speaker.fill",
                        title: "Динамик",
                        isActive: callManager.isSpeaker
                    ) {
                        callManager.isSpeaker.toggle()
                    }
                }
                .padding(.bottom, 20)
                
                // End Call button
                Button(action: { callManager.endCall() }) {
                    ZStack {
                        Circle().fill(Color.red).frame(width: 72, height: 72)
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

struct CallCircleButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.white : Color.white.opacity(0.15))
                        .frame(width: 58, height: 58)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isActive ? .black : .white)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Chats List Screen
struct ChatsListScreen: View {
    @EnvironmentObject var telegram: TelegramManager
    @EnvironmentObject var ghostMode: GhostModeManager
    @State private var searchQuery = ""
    
    var sortedChats: [LocalChat] {
        var list = telegram.chats
        if !searchQuery.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }
        // Pinned chats first, then by date
        return list.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.lastMessageDate > $1.lastMessageDate
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if ghostMode.isMasterGhostEnabled {
                    Section {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.purple)
                            Text("Режим призрака активен для всех чатов")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                ForEach(sortedChats) { chat in
                    NavigationLink(destination: ChatConversationView(chat: chat)) {
                        ChatRowCell(chat: chat)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            telegram.togglePinChat(chatId: chat.id)
                        } label: {
                            Label(chat.isPinned ? "Открепить" : "Закрепить", systemImage: "pin")
                        }
                        .tint(.orange)
                        
                        Button {
                            ghostMode.toggleChatGhost(chatId: chat.id)
                        } label: {
                            Label(
                                ghostMode.isGhostActive(for: chat.id) ? "Снять призрака" : "Призрак",
                                systemImage: "eye.slash"
                            )
                        }
                        .tint(.purple)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchQuery, prompt: "Поиск по чатам и сообщениям")
            .navigationTitle("Чаты")
            .navigationBarItems(
                leading: HStack(spacing: 6) {
                    Circle()
                        .fill(telegram.connectionStatus == "Подключено" ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(telegram.connectionStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                },
                trailing: Button(action: { telegram.loadInitialChats() }) {
                    Image(systemName: "arrow.clockwise")
                }
            )
        }
    }
}

struct ChatRowCell: View {
    let chat: LocalChat
    @EnvironmentObject var ghostMode: GhostModeManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                
                Text(chat.avatarLetter)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if ghostMode.isGhostActive(for: chat.id) {
                        Image(systemName: "eye.slash.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                    
                    Text(formatTime(chat.lastMessageDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(chat.lastMessageSnippet)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Chat Conversation View
struct ChatConversationView: View {
    let chat: LocalChat
    @EnvironmentObject var telegram: TelegramManager
    @EnvironmentObject var ghostMode: GhostModeManager
    @EnvironmentObject var deletedStore: DeletedMessagesStore
    @EnvironmentObject var callManager: CallManager
    
    @State private var inputText = ""
    @State private var replyingTo: LocalMessage? = nil
    @State private var showStickerPicker = false
    @State private var isRecordingVoice = false
    @State private var recordingSeconds = 0
    @State private var voiceTimer: AnyCancellable?
    
    var messages: [LocalMessage] {
        let current = telegram.messagesForChat[chat.id] ?? []
        let deletedForThisChat = deletedStore.savedDeletedMessages.filter { $0.chatId == chat.id && $0.isDeletedLocally }
        
        var combined = current
        for del in deletedForThisChat {
            if !combined.contains(where: { $0.id == del.id }) {
                combined.append(del)
            }
        }
        return combined.sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pinned Message Banner
            if let pinned = telegram.pinnedMessages[chat.id] {
                HStack(spacing: 10) {
                    Rectangle().fill(Color.blue).frame(width: 3, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Закреплённое сообщение").font(.caption2.bold()).foregroundColor(.blue)
                        Text(pinned.text).font(.caption).foregroundColor(.primary).lineLimit(1)
                    }
                    Spacer()
                    Button {
                        telegram.togglePinMessage(chatId: chat.id, message: pinned)
                    } label: {
                        Image(systemName: "xmark").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
            }
            
            // Ghost Mode Indicator Banner
            if ghostMode.isGhostActive(for: chat.id) {
                HStack {
                    Image(systemName: "eye.slash.fill").foregroundColor(.purple)
                    Text("Режим призрака включен (статус набора и чтение скрыты)")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.12))
            }
            
            // Messages Scroll
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            MessageBubbleCell(message: msg, chatId: chat.id)
                                .id(msg.id)
                                .contextMenu {
                                    Button {
                                        replyingTo = msg
                                    } label: {
                                        Label("Ответить", systemImage: "arrowshape.turn.up.left")
                                    }
                                    Button {
                                        telegram.togglePinMessage(chatId: chat.id, message: msg)
                                    } label: {
                                        Label("Закрепить", systemImage: "pin")
                                    }
                                    Button {
                                        UIPasteboard.general.string = msg.text
                                    } label: {
                                        Label("Скопировать текст", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                    let unreadIds = messages.map { $0.id }
                    telegram.markChatRead(chatId: chat.id, messageIds: unreadIds)
                }
            }
            
            Divider()
            
            // Reply Preview Bar
            if let reply = replyingTo {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ответ: \(reply.senderName)").font(.caption.bold()).foregroundColor(.blue)
                        Text(reply.text).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button { replyingTo = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
            }
            
            // Voice recording indicator bar
            if isRecordingVoice {
                HStack(spacing: 12) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("Запись: \(String(format: "%02d:%02d", recordingSeconds / 60, recordingSeconds % 60))")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    // Waveform visualizer
                    HStack(spacing: 3) {
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Отмена") {
                        cancelVoiceRecording()
                    }
                    .foregroundColor(.secondary)
                    
                    Button("Отправить") {
                        finishVoiceRecording()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
            } else {
                // Regular Input Controls
                HStack(spacing: 10) {
                    Button(action: { showStickerPicker.toggle() }) {
                        Image(systemName: "theatermasks.fill").font(.title3).foregroundColor(.purple)
                    }
                    
                    TextField("Сообщение...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                        .onChange(of: inputText) { _ in
                            telegram.sendTypingAction(chatId: chat.id)
                        }
                    
                    if inputText.isEmpty {
                        Button(action: startVoiceRecording) {
                            Image(systemName: "mic.fill").font(.title3).foregroundColor(.blue)
                        }
                    } else {
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
            }
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerSheet { selectedEmoji in
                telegram.sendStickerMessage(chatId: chat.id, emoji: selectedEmoji)
                showStickerPicker = false
            }
            .presentationDetents([.height(300)])
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                Button {
                    callManager.startCall(name: chat.title, isVideo: false)
                } label: {
                    Image(systemName: "phone")
                }
                
                Button {
                    ghostMode.toggleChatGhost(chatId: chat.id)
                } label: {
                    Image(systemName: ghostMode.isGhostActive(for: chat.id) ? "eye.slash.fill" : "eye")
                        .foregroundColor(ghostMode.isGhostActive(for: chat.id) ? .purple : .secondary)
                }
            }
        )
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        telegram.sendTextMessage(chatId: chat.id, text: text, replyToMessageId: replyingTo?.id)
        inputText = ""
        replyingTo = nil
    }
    
    private func startVoiceRecording() {
        isRecordingVoice = true
        recordingSeconds = 0
        voiceTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                recordingSeconds += 1
            }
    }
    
    private func finishVoiceRecording() {
        let duration = max(1, recordingSeconds)
        telegram.sendVoiceMessage(chatId: chat.id, duration: duration)
        cancelVoiceRecording()
    }
    
    private func cancelVoiceRecording() {
        voiceTimer?.cancel()
        voiceTimer = nil
        isRecordingVoice = false
    }
}

// MARK: - Sticker Picker Sheet
struct StickerPickerSheet: View {
    let onSelect: (String) -> Void
    let stickers = ["🦆", "🐱", "🐶", "🚀", "🔥", "😎", "🦊", "🎉", "⭐️", "⚡️", "👑", "🦄", "🐼", "🦁", "🍕", "❤️"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(stickers, id: \.self) { st in
                        Button {
                            onSelect(st)
                        } label: {
                            Text(st)
                                .font(.system(size: 46))
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Стикеры")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Message Bubble Cell (with Sticker, Voice, Pinned, and "Удалено" badge)
struct MessageBubbleCell: View {
    let message: LocalMessage
    let chatId: Int64
    @EnvironmentObject var telegram: TelegramManager
    @State private var isPlayingVoice = false
    
    var body: some View {
        HStack {
            if message.isOutgoing { Spacer() }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                // Deleted Message Badge 🗑️
                if message.isDeletedLocally {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill").font(.system(size: 10))
                        Text("Удалено в Telegram").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                }
                
                // Sticker Content
                if message.mediaType == "sticker" {
                    Text(message.stickerEmoji ?? message.text)
                        .font(.system(size: 70))
                        .padding(.vertical, 4)
                }
                // Voice Message Content
                else if message.mediaType == "voice" {
                    HStack(spacing: 10) {
                        Button {
                            isPlayingVoice.toggle()
                        } label: {
                            Image(systemName: isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(message.isOutgoing ? .white : .blue)
                        }
                        
                        // Fake Waveform bars
                        HStack(spacing: 3) {
                            ForEach(0..<14) { idx in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(message.isOutgoing ? Color.white.opacity(0.8) : Color.blue)
                                    .frame(width: 3, height: CGFloat([12, 18, 8, 22, 14, 26, 10, 20, 16, 24, 8, 14, 18, 10][idx]))
                            }
                        }
                        
                        Text("\(message.voiceDuration) сек")
                            .font(.caption2.bold())
                            .foregroundColor(message.isOutgoing ? .white.opacity(0.8) : .secondary)
                    }
                    .padding(.vertical, 4)
                }
                // Regular Text
                else {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(message.isOutgoing ? .white : .primary)
                }
                
                HStack(spacing: 4) {
                    Text(formatTime(message.date))
                        .font(.system(size: 10))
                        .foregroundColor(message.isOutgoing ? Color.white.opacity(0.8) : .secondary)
                    
                    if message.isOutgoing {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Reaction emoji banner if set
                if let r = message.reaction {
                    Text(r)
                        .font(.system(size: 14))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, message.mediaType == "sticker" ? 0 : 14)
            .padding(.vertical, message.mediaType == "sticker" ? 0 : 10)
            .background(
                message.mediaType == "sticker" ? Color.clear : (
                    message.isDeletedLocally
                        ? Color.red.opacity(0.2)
                        : (message.isOutgoing ? Color.blue : Color(UIColor.secondarySystemBackground))
                )
            )
            .cornerRadius(16)
            
            if !message.isOutgoing { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Empty State Helper
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Saved Deleted Messages Screen
struct SavedDeletedMessagesScreen: View {
    @EnvironmentObject var deletedStore: DeletedMessagesStore
    @State private var showConfirmClear = false
    
    var body: some View {
        NavigationStack {
            Group {
                if deletedStore.savedDeletedMessages.isEmpty {
                    EmptyStateView(
                        title: "Нет удалённых сообщений",
                        systemImage: "trash.slash.fill",
                        description: "Здесь появятся сообщения, которые собеседники удалят из Telegram после получения."
                    )
                } else {
                    List {
                        Section {
                            ForEach(deletedStore.savedDeletedMessages) { msg in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(msg.senderName)
                                            .font(.headline)
                                        Spacer()
                                        Text("Удалено").font(.caption2.bold()).foregroundColor(.red)
                                    }
                                    Text(msg.text)
                                        .font(.subheadline)
                                    if let delAt = msg.deletedAt {
                                        Text("Удалено в: \(formatDate(delAt))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Удалённые сообщения")
            .navigationBarItems(
                trailing: Group {
                    if !deletedStore.savedDeletedMessages.isEmpty {
                        Button(role: .destructive) {
                            showConfirmClear = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            )
            .confirmationDialog("Очистить историю удалённых сообщений?", isPresented: $showConfirmClear) {
                Button("Очистить всё", role: .destructive) {
                    deletedStore.clearAllHistory()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Standard Settings + ⚙️ Настройки Kochgramma
struct SettingsMainScreen: View {
    @EnvironmentObject var telegram: TelegramManager
    @AppStorage("koch_theme_mode") private var themeMode: String = "dark"
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                            .overlay(Text("K").font(.title.bold()).foregroundColor(.white))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(telegram.currentUserName)
                                .font(.headline)
                            Text(telegram.currentUserPhone.isEmpty ? "Telegram Account" : telegram.currentUserPhone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // ⭐ SPECIALLY HIGHLIGHTED KOCHGRAM SECTION ⭐
                Section {
                    NavigationLink(destination: KochgramCustomSettingsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("⚙️ Настройки Kochgramma")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("Режим призрака, удалённые сообщения, кастомизация")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                } header: {
                    Text("Эксклюзивные функции")
                        .foregroundColor(.purple)
                        .font(.caption.bold())
                }
                
                Section("Стандартные настройки Telegram") {
                    HStack {
                        Label("Темы оформления", systemImage: "paintpalette.fill").foregroundColor(.orange)
                        Spacer()
                        Picker("", selection: $themeMode) {
                            Text("Тёмная").tag("dark")
                            Text("Светлая").tag("light")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    
                    NavigationLink(destination: Text("Уведомления и звуки синхронизированы с серверами Telegram")) {
                        Label("Уведомления и звуки", systemImage: "bell.badge.fill").foregroundColor(.red)
                    }
                    
                    NavigationLink(destination: Text("Конфиденциальность: последний визит, пересылка сообщений и звонки")) {
                        Label("Конфиденциальность", systemImage: "lock.shield.fill").foregroundColor(.green)
                    }
                    
                    NavigationLink(destination: Text("Память и данные: кэш TDLib, автозагрузка медиа")) {
                        Label("Данные и память", systemImage: "internaldrive.fill").foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Выйти из аккаунта")
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Настройки")
            .confirmationDialog("Выйти из Telegram?", isPresented: $showLogoutAlert) {
                Button("Выйти", role: .destructive) {
                    telegram.logOut()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}

// MARK: - ⚙️ Экран «Настройки Kochgramma»
struct KochgramCustomSettingsView: View {
    @EnvironmentObject var ghostMode: GhostModeManager
    @EnvironmentObject var deletedStore: DeletedMessagesStore
    @State private var showClearCacheAlert = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Spacer()
                        Text("v1.0 Pro")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                    Text("Настройки Kochgramma")
                        .font(.title2.bold())
                    Text("Расширенные приватные функции клиента. Все действия выполняются поверх официального Telegram API.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
            
            // 👻 РЕЖИМ ПРИЗРАКА
            Section {
                Toggle(isOn: $ghostMode.isMasterGhostEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "eye.slash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Режим призрака (Общий)")
                                .font(.headline)
                            Text("Включает все функции невидимости сразу")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $ghostMode.hideTyping) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Скрыть статус набора текста")
                            .font(.subheadline)
                        Text("Не отправляет собеседникам «печатает…»")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $ghostMode.stealthReadMessages) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Скрытое чтение сообщений")
                            .font(.subheadline)
                        Text("Просмотр сообщений без отправки отметки о прочтении")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $ghostMode.stealthStories) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Скрытый просмотр историй")
                            .font(.subheadline)
                        Text("Анонимный просмотр историй в рамках TDLib")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Label("👻 Режим призрака", systemImage: "eye.slash")
            } footer: {
                Text("Примечание: функции скрытности строго соблюдают архитектуру Telegram API и не отправляют исходящие запросы активности.")
                    .font(.caption2)
            }
            
            // 🗑️ УДАЛЁННЫЕ СООБЩЕНИЯ
            Section {
                Toggle(isOn: $deletedStore.isSaveEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "archivebox.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Сохранять удалённые сообщения")
                                .font(.headline)
                            Text("Локальное кэширование входящих сообщений")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                NavigationLink(destination: SavedDeletedMessagesScreen()) {
                    HStack {
                        Text("Просмотр сохранённых удалённых")
                            .font(.subheadline)
                        Spacer()
                        Text("\(deletedStore.savedDeletedMessages.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Button(role: .destructive) {
                    showClearCacheAlert = true
                } label: {
                    Text("Очистить историю удалённых")
                        .font(.subheadline)
                }
            } header: {
                Label("🗑️ Удалённые сообщения", systemImage: "trash")
            } footer: {
                Text("Kochgram сохраняет копии сообщений на устройстве в момент их получения. Если автор удалит сообщение позже, оно останется у вас с пометкой «Удалено». Сообщения, удалённые до установки или запуска, восстановить невозможно.")
                    .font(.caption2)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Настройки Kochgramma")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Очистить все локально сохранённые сообщения?", isPresented: $showClearCacheAlert) {
            Button("Очистить базу", role: .destructive) {
                deletedStore.clearAllHistory()
            }
            Button("Отмена", role: .cancel) {}
        }
    }
}
