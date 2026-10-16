import SwiftData
import SwiftUI
import os

/// Every bill, one row each, read as what it comes to a month or a year, in a card for each
/// category, highest first. Opened from the list button at the bottom right. Tapping a bill opens
/// its next charge in the editor, over this sheet. See "All bills" in `docs/DESIGN.md`.
struct AllBillsSheet: View {
    let today: Date

    @Query private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @AppStorage("billsPeriod") private var period: BillPeriod = .month

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    /// The chip picked, by `BillCard.id`; nil is All.
    @State private var picked: String?
    @State private var showsEnded = false
    @State private var editing: EditSession?
    /// Bumped when the editor closes: a saved edit changes the instances this view already holds,
    /// which `@Query` doesn't reliably notice (see `.claude/rules/swiftui-controls.md`).
    @State private var refresh = 0

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "AllBillsSheet")

    var body: some View {
        let _ = refresh
        let infos = categories.map(CategoryInfo.init)
        let bills = AllBillsBuilder.bills(
            Expense.billInputs(expenses), categories: infos, period: period, today: today, calendar: calendar
        )
        // A picked category that no longer has a card (edited away) falls back to All.
        let pickedCard = picked.flatMap { id in bills.cards.first { $0.id == id } }
        let cards = pickedCard.map { [$0] } ?? bills.cards
        let known = Set(infos.map(\.id))
        let ended = bills.ended.filter { row in
            guard let pickedCard else { return true }
            return row.categoryID.flatMap { known.contains($0) ? $0 : nil } == pickedCard.category?.id
        }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title(pickedCard, total: pickedCard?.total ?? bills.total)
                    if !bills.cards.isEmpty {
                        chips(bills.cards, picked: pickedCard?.id)
                    }
                    if !cards.isEmpty || !ended.isEmpty {
                        VStack(spacing: Tokens.Space.cardGap) {
                            ForEach(cards) { card in
                                BillCardView(card: card, period: period, onOpen: open)
                            }
                            if !ended.isEmpty {
                                endedToggle(count: ended.count)
                                if showsEnded {
                                    EndedBillsCard(
                                        rows: ended, period: period,
                                        emoji: { emoji(for: $0, in: infos) }, onOpen: open
                                    )
                                }
                            }
                        }
                        .padding(.top, Tokens.Space.cardsTop)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Period", selection: $period) {
                        Text("Monthly").tag(BillPeriod.month)
                        Text("Yearly").tag(BillPeriod.year)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .sheet(item: $editing, onDismiss: { refresh &+= 1 }) { session in
            ExpenseEditor(today: today, session: session)
        }
    }

    // MARK: Title and chips

    private func title(_ card: BillCard?, total: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titleText(card))
                .font(Tokens.Text.calendarTitle)
                .foregroundStyle(Tokens.Ink.primary)
                .accessibilityAddTraits(.isHeader)
            Text(BillsFormatting.total(total, period: period, locale: locale))
                .font(Tokens.Text.monthTotal)
                .monospacedDigit()
                .foregroundStyle(Tokens.Ink.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.gutter)
        .accessibilityElement(children: .combine)
    }

    private func titleText(_ card: BillCard?) -> String {
        guard let card else { return "All bills" }
        guard let category = card.category else { return BillsFormatting.uncategorisedName }
        return "\(category.emoji) \(category.name)"
    }

    private func chips(_ cards: [BillCard], picked pickedID: String?) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Tokens.Space.chipGap) {
                chip("All", isPicked: pickedID == nil) { picked = nil }
                ForEach(cards) { card in
                    chip(chipText(card), isPicked: pickedID == card.id) {
                        picked = pickedID == card.id ? nil : card.id
                    }
                }
            }
            .padding(.horizontal, Tokens.Space.gutter)
        }
        .scrollIndicators(.hidden)
        .padding(.top, Tokens.Space.chipsTop)
    }

    private func chipText(_ card: BillCard) -> String {
        guard let category = card.category else { return BillsFormatting.uncategorisedName }
        return "\(category.emoji) \(category.name)"
    }

    private func chip(_ text: String, isPicked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(Tokens.Text.billsChip)
                .lineLimit(1)
                .foregroundStyle(isPicked ? Tokens.Surface.base : Tokens.Ink.primary)
                .padding(.horizontal, Tokens.Space.chipHorizontal)
                .frame(minHeight: Tokens.Size.chipHeight)
                .background(isPicked ? Tokens.Ink.primary : Tokens.Surface.chip, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }

    // MARK: Ended

    /// "2 ended bills", with Show or Hide: the bills that are over, out of the way of the ones
    /// still going.
    private func endedToggle(count: Int) -> some View {
        Button { showsEnded.toggle() } label: {
            HStack {
                Text(count == 1 ? "1 ended bill" : "\(count) ended bills")
                Spacer()
                Text(showsEnded ? "Hide" : "Show")
            }
            .font(Tokens.Text.endedToggle)
            .foregroundStyle(Tokens.Ink.secondary)
            .padding(.vertical, Tokens.Space.endedToggleVertical)
            .padding(.horizontal, Tokens.Space.cardInset + Tokens.Space.tight / 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count == 1 ? "1 ended bill" : "\(count) ended bills")
        .accessibilityHint(showsEnded ? "Hides them" : "Shows them")
    }

    private func emoji(for row: BillRow, in infos: [CategoryInfo]) -> String? {
        row.categoryID.flatMap { id in infos.first { $0.id == id }?.emoji }
    }

    // MARK: Opening

    /// A bill opens at its next charge, or its last once it's over, built fresh from the store as
    /// the timeline's rows are.
    private func open(_ row: BillRow) {
        guard let opens = row.opens else { return }
        do {
            editing = try EditSession.make(
                expenseID: opens.expenseID, scheduledDate: opens.scheduledDate,
                context: modelContext, calendar: calendar
            )
        } catch {
            Self.logger.error("Opening a bill failed: \(error)")
        }
    }
}
