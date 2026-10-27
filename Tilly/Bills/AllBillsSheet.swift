import SwiftData
import SwiftUI

/// Every bill, one row each, read as what it comes to a month or a year, in a card for each
/// category, highest first. Opened from the list button at the bottom right. Read only: nothing in
/// it opens. See "All bills" in `docs/DESIGN.md`.
struct AllBillsSheet: View {
    let today: Date

    @Query private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @AppStorage("billsPeriod") private var period: BillPeriod = .month

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showsEnded = false

    var body: some View {
        let infos = categories.map(CategoryInfo.init)
        let bills = AllBillsBuilder.bills(
            Expense.billInputs(expenses), categories: infos, period: period, today: today, calendar: calendar
        )

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title(total: bills.total)
                    VStack(spacing: Tokens.Bills.cardGap) {
                        ForEach(bills.cards) { card in
                            BillCardView(card: card, period: period, today: today)
                        }
                        if !bills.ended.isEmpty {
                            endedToggle(count: bills.ended.count)
                            if showsEnded {
                                EndedBillsCard(
                                    rows: bills.ended, period: period, today: today,
                                    picture: { picture(for: $0, in: infos) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Tokens.Bills.sheetSide)
                .padding(.bottom, Tokens.Bills.sheetBottom)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
        .drawnGround()
        .presentationDetents([.large])
    }

    // MARK: Title

    private func title(total: Decimal) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Bills.subtitleTop) {
            Text("All bills")
                .font(Tokens.Bills.titleFont(dynamicTypeSize))
                .foregroundStyle(Tokens.Ink.primary)
                .accessibilityAddTraits(.isHeader)
            Text(BillsFormatting.total(total, period: period, locale: locale))
                .font(Tokens.Bills.subtitleFont(dynamicTypeSize))
                .monospacedDigit()
                .foregroundStyle(Tokens.Drawn.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Bills.titleInset)
        .padding(.top, Tokens.Bills.titleTop)
        .padding(.bottom, Tokens.Bills.subtitleBottom)
        .accessibilityElement(children: .combine)
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
            .font(Tokens.Bills.endedToggleFont)
            .foregroundStyle(Tokens.Drawn.ink2)
            .padding(.vertical, Tokens.Bills.endedToggleVertical)
            .padding(.horizontal, Tokens.Bills.titleInset)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count == 1 ? "1 ended bill" : "\(count) ended bills")
        .accessibilityHint(showsEnded ? "Hides them" : "Shows them")
    }

    private func picture(for row: BillRow, in infos: [CategoryInfo]) -> CategoryPicture {
        row.categoryID.flatMap { id in infos.first { $0.id == id }?.picture } ?? .none
    }
}
