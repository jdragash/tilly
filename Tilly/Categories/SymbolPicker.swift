import SwiftUI

/// Tilly's symbols as one long grid, each drawn as the category will draw it, in `colour`, at a grid
/// card's picture size. A search field rides over them and sticks at the top as they scroll. A
/// search that matches nothing offers the closest symbols by meaning instead.
struct SymbolPicker: View {
    let colour: CategoryColour?
    let selection: String?
    /// Each change scrolls the symbols back to the top.
    var scrollToTop = 0
    let onPick: (String) -> Void

    @State private var query: String
    @FocusState private var searchFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        colour: CategoryColour?, selection: String?, scrollToTop: Int = 0, query: String = "",
        onPick: @escaping (String) -> Void
    ) {
        self.colour = colour
        self.selection = selection
        self.scrollToTop = scrollToTop
        self.onPick = onPick
        _query = State(initialValue: query)
    }

    private static let top = "top"

    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// What the grid shows, and whether it's the fallback for a search that matched nothing.
    private var shown: (entries: [SymbolEntry], closest: Bool) {
        guard isSearching else { return (SymbolCatalog.all, false) }
        let results = SymbolCatalog.search(query)
        if !results.isEmpty { return (results, false) }
        let names = SymbolGuess.closest(to: query, limit: Tokens.CategorySheet.closestLimit)
        return (names.compactMap { name in SymbolCatalog.all.first { $0.name == name } }, true)
    }

    var body: some View {
        let shown = shown
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        if shown.closest && !shown.entries.isEmpty {
                            Text("No exact match. Closest")
                                .font(Tokens.Text.symbolsNote(dynamicTypeSize))
                                .tracking(Tokens.CategorySheet.noteTracking)
                                .textCase(.uppercase)
                                .foregroundStyle(Tokens.Drawn.ink2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, Tokens.CategorySheet.noteTop)
                                .padding(.bottom, Tokens.CategorySheet.noteBottom)
                                .padding(.horizontal, Tokens.CategorySheet.gutter)
                                .accessibilityAddTraits(.isHeader)
                        }
                        if shown.entries.isEmpty {
                            Text("Nothing matches")
                                .font(Tokens.Text.caption)
                                .foregroundStyle(Tokens.Drawn.ink2)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Tokens.Space.section)
                        } else {
                            grid(shown.entries)
                        }
                    } header: {
                        search
                            .id(Self.top)
                    }
                }
                .padding(.bottom, Tokens.Space.section)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollToTop) {
                withAnimation { proxy.scrollTo(Self.top, anchor: .top) }
            }
        }
    }

    /// The field on a band of the sheet's paper, so the symbols pass under it.
    private var search: some View {
        HStack(spacing: Tokens.Space.tight) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Tokens.Drawn.ink2)
                .accessibilityHidden(true)
            TextField("Search symbols", text: $query)
                .font(Tokens.Text.body)
                .focused($searchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if isSearching {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Tokens.Drawn.ink2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Tokens.Space.gap)
        .frame(minHeight: Tokens.CategorySheet.searchHeight)
        .background(Tokens.Drawn.key, in: RoundedRectangle(cornerRadius: Tokens.CategorySheet.searchRadius, style: .continuous))
        .padding(.top, Tokens.CategorySheet.searchTop)
        .padding(.bottom, Tokens.CategorySheet.searchBottom)
        .padding(.horizontal, Tokens.CategorySheet.gutter)
        .drawnPaper()
    }

    private func grid(_ entries: [SymbolEntry]) -> some View {
        let gap = Tokens.CategorySheet.symbolGap
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: Tokens.CategorySheet.symbolsAcross),
            spacing: gap
        ) {
            ForEach(entries) { entry in
                cell(entry)
            }
        }
        .padding(.horizontal, Tokens.CategorySheet.gutter)
    }

    /// A square cell, its picture centred, and a ring round the picked one.
    private func cell(_ entry: SymbolEntry) -> some View {
        let isPicked = entry.name == selection
        let picture = Tokens.CategorySheet.symbolPicture
        return Button {
            searchFocused = false
            onPick(entry.name)
        } label: {
            CategoryPictureView(picture: .symbol(entry.name), colour: colour, size: picture, round: true, place: .editor)
                .overlay {
                    if isPicked {
                        Circle()
                            .strokeBorder(Tokens.Ink.accent, lineWidth: Tokens.CategorySheet.symbolRingWidth)
                            .frame(
                                width: picture + 2 * Tokens.CategorySheet.symbolRingOutset,
                                height: picture + 2 * Tokens.CategorySheet.symbolRingOutset
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel((entry.words.first ?? entry.name).capitalized)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }
}

#Preview {
    SymbolPicker(colour: .blue, selection: "house", onPick: { _ in })
        .frame(height: Tokens.Size.symbolPicker)
        .drawnGround()
}
