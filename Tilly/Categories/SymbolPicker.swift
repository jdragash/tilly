import SwiftUI

/// Tilly's symbols in the keypad's place: a search field over a grid, in sections, each symbol
/// drawn as the category will draw it, in `colour`.
struct SymbolPicker: View {
    let colour: CategoryColour?
    let selection: String?
    let onPick: (String) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [SymbolEntry] { SymbolCatalog.search(query) }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: Tokens.Space.tight) {
            search
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Tokens.Space.tight, pinnedViews: []) {
                    if isSearching {
                        if results.isEmpty {
                            Text("Nothing matches")
                                .font(Tokens.Text.caption)
                                .foregroundStyle(Tokens.Ink.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Tokens.Space.section)
                        } else {
                            grid(results)
                        }
                    } else {
                        ForEach(SymbolCatalog.sections) { section in
                            Text(section.title)
                                .font(Tokens.Text.nextHeading)
                                .textCase(.uppercase)
                                .foregroundStyle(Tokens.Ink.secondary)
                                .padding(.top, Tokens.Space.tight)
                                .accessibilityAddTraits(.isHeader)
                            grid(section.entries)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .editorSheetScroll()
        }
    }

    private var search: some View {
        HStack(spacing: Tokens.Space.tight) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Tokens.Ink.secondary)
                .accessibilityHidden(true)
            TextField("Search symbols", text: $query)
                .font(Tokens.Text.body)
                .focused($searchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if isSearching {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Tokens.Ink.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Tokens.Space.section)
        .frame(height: Tokens.Size.categoryField)
        .background(Tokens.Surface.editorButtonActive, in: Capsule())
    }

    private func grid(_ entries: [SymbolEntry]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: Tokens.Size.symbolCell), spacing: Tokens.Space.tight)],
            spacing: Tokens.Space.tight
        ) {
            ForEach(entries) { entry in
                cell(entry)
            }
        }
    }

    private func cell(_ entry: SymbolEntry) -> some View {
        let isPicked = entry.name == selection
        return Button {
            searchFocused = false
            onPick(entry.name)
        } label: {
            CategoryPictureView(picture: .symbol(entry.name), colour: colour, size: Tokens.Size.symbolCell, place: .editor)
                .padding(Tokens.Stroke.pocketRing)
                .overlay {
                    if isPicked {
                        RoundedRectangle(
                            cornerRadius: Tokens.Size.symbolCell * Tokens.Drawn.wellRadius + Tokens.Stroke.pocketRing,
                            style: .continuous
                        )
                        .strokeBorder(Tokens.Ink.accent, lineWidth: Tokens.Stroke.pocketRing)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel((entry.words.first ?? entry.name).capitalized)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }
}

#Preview {
    SymbolPicker(colour: .blue, selection: "house", onPick: { _ in })
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(height: Tokens.Size.symbolPicker)
        .drawnGround()
}
