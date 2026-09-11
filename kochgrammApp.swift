
import SwiftUI
import TDLibKit

let kochApiId: Int32 = 31805867
let kochApiHash: String = "API_HASH_PLACEHOLDER"

@main
struct kochgrammApp: App {
    @StateObject private var telegram = TelegramManager()
    
    var body: some Scene {
        WindowGroup {
            if telegram.isLoggedIn {
                MainView()
                    .environmentObject(telegram)
            } else {
                PhoneEntryView(telegram: telegram)
            }
        }
    }
}

// MARK: - Telegram Manager (настоящий TDLib)
@MainActor
class TelegramManager: ObservableObject {
    private var client: TDLibClient?
    private let manager = TDLibClientManager()
    
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authState = 0 // 0 - телефон, 1 - код, 2 - пароль
    
    init() {
        client = manager.createClient(updateHandler: { [weak self] data, client in
            Task { @MainActor in
                self?.handleUpdate(data: data, client: client)
            }
        })
    }
    
    private func handleUpdate(data: Data, client: TDLibClient) {
        guard let update = try? client.decoder.decode(Update.self, from: data) else { return }
        
        switch update {
        case .updateAuthorizationState(let auth):
            switch auth.authorizationState {
            case .authorizationStateWaitTdlibParameters:
                let params = TDLibParameters(
                    apiId: kochApiId,
                    apiHash: kochApiHash,
                    systemLanguageCode: "ru",
                    deviceModel: "iPhone",
                    systemVersion: "iOS",
                    applicationVersion: "1.0",
                    databaseDirectory: "tdlib",
                    filesDirectory: "tdlib_files",
                    useMessageDatabase: true,
                    useSecretChats: false,
                    useTestDc: false,
                    enableStorageOptimizer: true
                )
                Task {
                    try? await client.setTdlibParameters(params: params)
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
            default:
                break
            }
        default:
            break
        }
    }
    
    func sendPhone(_ phone: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await client?.setAuthenticationPhoneNumber(phoneNumber: phone, settings: nil)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func sendCode(_ code: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await client?.checkAuthenticationCode(code: code)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func sendPassword(_ password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await client?.checkAuthenticationPassword(password: password)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Модель страны
struct Country: Identifiable {
    let id = UUID()
    let flag: String
    let name: String
    let code: String
}

let countries: [Country] = [
    Country(flag: "🇩🇪", name: "Германия", code: "+49"),
    Country(flag: "🇷🇺", name: "Россия", code: "+7"),
    Country(flag: "🇺🇦", name: "Украина", code: "+380"),
    Country(flag: "🇧🇾", name: "Беларусь", code: "+375"),
    Country(flag: "🇰🇿", name: "Казахстан", code: "+7"),
    Country(flag: "🇺🇸", name: "США", code: "+1"),
    Country(flag: "🇬🇧", name: "Великобритания", code: "+44"),
    Country(flag: "🇫🇷", name: "Франция", code: "+33"),
    Country(flag: "🇮🇹", name: "Италия", code: "+39"),
    Country(flag: "🇪🇸", name: "Испания", code: "+34"),
    Country(flag: "🇵🇱", name: "Польша", code: "+48"),
    Country(flag: "🇹🇷", name: "Турция", code: "+90"),
    Country(flag: "🇨🇳", name: "Китай", code: "+86"),
    Country(flag: "🇯🇵", name: "Япония", code: "+81"),
    Country(flag: "🇰🇷", name: "Корея", code: "+82"),
    Country(flag: "🇮🇳", name: "Индия", code: "+91"),
    Country(flag: "🇧🇷", name: "Бразилия", code: "+55"),
    Country(flag: "🇨🇦", name: "Канада", code: "+1 "),
    Country(flag: "🇦🇺", name: "20Австралия", code: "+61"),
   )
 Country(flag: "🇳🇱", name: "Ни                       дерланды", code: "+ .31"),
    Country(flag: "🇧🇪",padding name: "Бельгия", code: "+32"),
    Country(flag: "🇨🇭", name: "Швейцария", code: "+41"),
    Country(flag: "🇦🇹", name: "Австрия", code: "+43"),
    Country(flag: "🇸🇪", name: "Швеция", code: "+46"),
    Country(flag: "🇳🇴", name: "Норвегия", code: "+47"),
    Country(flag: "🇩🇰", name: "Дания", code: "+45"),
    Country(flag: "🇫🇮", name: "Финляндия", code: "+358"),
    Country(flag: "🇵🇹", name: "Португалия", code: "+351"),
    Country(flag: "🇬🇷", name: "Греция", code: "+30"),
    Country(flag: "🇨🇿", name: "Чехия", code: "+420"),
    Country(flag: "🇷🇴", name: "Румыния", code: "+40"),
    Country(flag: "🇭🇺", name: "Венгрия", code: "+36"),
    Country(flag: "🇧🇬", name: "Болгария", code: "+359"),
    Country(flag: "🇷🇸", name: "Сербия", code: "+381"),
    Country(flag: "🇭🇷", name: "Хорватия", code: "+385"),
    Country(flag: "🇮🇱", name: "Израиль", code: "+972"),
    Country(flag: "🇦🇪", name: "ОАЭ", code: "+971"),
    Country(flag: "🇸🇦", name: "Саудовская Аравия", code: "+966"),
    Country(flag: "🇪🇬", name: "Египет", code: "+20"),
    Country(flag: "🇿🇦", name: "ЮАР", code: "+27"),
    Country(flag: "🇦🇷", name: "Аргентина", code: "+54"),
    Country(flag: "🇲🇽", name: "Мексика", code: "+52"),
    Country(flag: "🇲🇩", name: "Молдова", code: "+373"),
    Country(flag: "🇬🇪", name: "Грузия", code: "+995"),
    Country(flag: "🇦🇲", name: "Армения", code: "+374"),
    Country(flag: "🇦🇿", name: "Азербайджан", code: "+994"),
    Country(flag: "🇺🇿", name: "Узбекистан", code: "+998"),
    Country(flag: "🇰🇬", name: "Киргизия", code: "+996"),
    Country(flag: "🇹🇯", name: "Таджикистан", code: "+992"),
    Country(flag: "🇹🇲", name: "Туркменистан", code: "+993"),
    Country(flag: "🇱🇹", name: "Литва", code: "+370"),
    Country(flag: "🇱🇻", name: "Латвия", code: "+371"),
    Country(flag: "🇪🇪", name: "Эстония", code: "+372")
]

// MARK: - Экран входа
struct PhoneEntryView: View {
    @ObservedObject var telegram: TelegramManager
    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var selectedCountry = countries[0]
    @State private var showCountryPicker = false
    @FocusState private var isPhoneFocused: Bool
    @FocusState private var isCodeFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                
                Text(telegram.authState == 0 ? "☎️" : telegram.authState == 1 ? "📩" : "🔐")
                    .font(.system(size: 75))
                    .padding(.bottom, 24)
                
                Text(telegram.authState == 0 ? "Телефон" : telegram.authState == 1 ? "Код" : "Пароль")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                if telegram.authState == 0 {
                    VStack(spacing: 6) {
                        Text("Введите свой номер телефона")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Text("или используйте ключ доступа >")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 50)
                    
                    Button(action: { showCountryPicker = true }) {
                        HStack(spacing: 10) {
                            Text(selectedCountry.flag).font(.system(size: 22))
                            Text(selectedCountry.name)
                                .font(.system(size: 17))
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal,(.vertical, 14)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 0) {
                        Text(selectedCountry.code)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                            .padding(.trailing, 12)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 28)
                        
                        TextField("", text: $phone)
                            .keyboardType(.phonePad)
                            .focused($isPhoneFocused)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(.leading, 12)
                    }
                    .padding(.vertical, 18)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Button(action: {
                        let fullPhone = selectedCountry.code + phone
                        Task { await telegram.sendPhone(fullPhone) }
                    }) {
                        Text(telegram.isLoading ? "Отправка..." : "Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(phone.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .cornerRadius(28)
                    }
                    .disabled(phone.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                } else if telegram.authState == 1 {
                    Text("Мы отправили код в Telegram")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.bottom, 50)
                    
                    TextField("", text: $code)
                        .keyboardType(.numberPad)
                        .focused($isCodeFocused)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 40)
                    
                    Divider().background(Color.white.opacity(0.1))
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        Task { await telegram.sendCode(code) }
                    }) {
                        Text(telegram.isLoading ? "Проверка..." : "Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(code.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .cornerRadius(28)
                    }
                    .disabled(code.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                } else if telegram.authState == 2 {
                    Text("Введите пароль двухфакторной аутентификации")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                    
                    SecureField("", text: $password)
                        .focused($isPasswordFocused)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 40)
                    
                    Divider().background(Color.white.opacity(0.1))
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        Task { await telegram.sendPassword(password) }
                    }) {
                        Text(telegram.isLoading ? "Проверка..." : "Войти")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(password.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .cornerRadius(28)
                    }
                    .disabled(password.isEmpty || telegram.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                }
                
                if let error = telegram.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 20)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if telegram.authState == 0 { isPhoneFocused = true }
            }
        }
        .onChange(of: telegram.authState) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if newValue == 1 { isCodeFocused = true }
                if newValue == 2 { isPasswordFocused = true }
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selected: $selectedCountry)
        }
    }
}

struct CountryPickerView: View {
    @Binding var selected: Country
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    
    var filtered: [Country] {
        if search.isEmpty { return countries }
        return countries.filter { $0.name.lowercased().contains(search.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { country in
                    Button(action: {
                        selected = country
                        dismiss()
                    }) {
                        HStack {
                            Text(country.flag).font(.system(size: 22))
                            Text(country.name).foregroundColor(.white)
                            Spacer()
                            Text(country.code).foregroundColor(.gray)
                            if country.name == selected.name {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Поиск страны")
            .navigationTitle("Страна")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var telegram: TelegramManager
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Вход выполнен")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Список чатов появится после подключения TDLib")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("kochgramm")
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
