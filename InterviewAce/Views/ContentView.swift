import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(spacing: 0) {
            LeftView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            RightView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(Color.gray.opacity(0.3))
        
    }
}

#Preview {
    ContentView()
}
