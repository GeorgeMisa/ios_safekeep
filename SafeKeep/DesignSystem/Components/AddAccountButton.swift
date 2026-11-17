import SwiftUI

struct AddAccountButton: View {
    let action: () -> Void

    @Environment(\.isSearching) private var isSearching

    // Hidden while searching so it never floats over results above the keyboard.
    var body: some View {
        if !isSearching {
            button
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Palette.brand))
                .shadow(color: Palette.brand.opacity(0.35), radius: 10, y: 4)
        }
        .accessibilityLabel("Add Account")
    }
}
