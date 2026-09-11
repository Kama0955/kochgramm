import SwiftUI

@main
struct kochgrammApp: App {
    @State private var screen: AppScreen = .welcome
    
    var body: some Scene {
        WindowGroup {
            switch screen {
            case .welcome:
                WelcomeView(onContinue: {
                    withAnimation { screen = .phone }
                })
            case .phone:
                PhoneEntryView(onLogin: {
                    withAnimation { screen = .chats }
                })
            case .chats:
                MainView()
            }
        }
    }
}

enum AppScreen {
    case welcome
    case phone
    case chats
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
    Country(flag: "🇨🇦", name: "Канада", code: "+1"),
    Country(flag: "🇦🇺", name: "Австралия", code: "+61"),
    Country(flag: "🇳🇱", name: "Нидерланды", code: "+31"),
    Country(flag: "🇧🇪", name: "Бельгия", code: "+32"),
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

// MARK: - Welcome Screen (первый экран)
struct WelcomeView: View {
    let onContinue: () -> Void
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Фон — картинка или градиент
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                    Color(red: 0.10, green: 0.08, blue: 0.20),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Свечение за логотипом
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(y: -100)
                .opacity(appeared ? 1 : 0)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Логотип — твоя иконка
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.white)
                    .shadow(color: .blue.opacity(0.5), radius: 30)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                
                // Название
                Text("kochgramm")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .opacity(appeared ? 1 : 0)
                
                // Подпись
                Text("The world's fastest messaging app.\nIt is free and secure.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
                
                // Кнопка
                Button(action: onContinue) {
                    Text("Start Messaging")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(appeared ? 1 : 0)
                
                // Подпись снизу
                Text("Продолжить на русском")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appeared = true
            }
        }
    }
}

// MARK: - Phone Entry Screen
struct PhoneEntryView: View {
    let onLogin: () -> Void
    @State private var phone = ""
    @State private var selectedCountry = countries[0]
    @State private var showCountryPicker = false
    @State private var showConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 40)
                        
                        Text("☎️")
                            .font(.system(size: 70))
                            .padding(.bottom, 20)
                        
                        Text("Телефон")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 16)
                        
                        VStack(spacing: 4) {
                            Text("Введите свой номер телефона")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            
                            Text("или используйте ключ доступа >")
                                .font(.system(size: 15))
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 40)
                        
                        Button(action: {
                            showCountryPicker = true
                        }) {
                            HStack {
                                Text(selectedCountry.flag).font(.system(size: 22))
                                Text(selectedCountry.name)
                                    .font(.system(size: 17))
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack(spacing: 12) {
                            Text(selectedCountry.code)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(minWidth: 50, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1, height: 24)
                            
                            TextField("Номер телефона", text: $phone)
                                .keyboardType(.phonePad)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Button(action: { showConfirm = true }) {
                            Text("Продолжить")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(phone.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(phone.isEmpty)
                        .padding(.horizontal, 16)
                        .padding(.top, 30)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(selected: $selectedCountry)
            }
            .alert("Правильно ли указан номер?", isPresented: $showConfirm) {
                Button("Изменить", role: .cancel) { }
                Button("Продолжить") { onLogin() }
            } message: {
                Text("\(selectedCountry.code) \(phone)")
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Country Picker
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
                            if country.id == selected.id {
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

// MARK: - Main
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
