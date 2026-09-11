import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("kochgramm")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Custom Telegram Client")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
