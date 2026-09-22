import Foundation
import SwiftData
import TillyCore

/// Every write phase 2 makes to a bill, on a `ModelContext`. Kept apart from the views so the
/// rules — this charge, future charges, the whole bill, and the two deletes — are tested
/// against an in-memory store rather than a screen. See `docs/DECISIONS.md`, "A bill is a
/// series of rules, and 'future charges' starts the next one".
@MainActor
enum BillEditor {
    // MARK: Reading a series

    /// The records sharing `expense.seriesKey`, ascending by anchor.
    static func series(of expense: Expense, in context: ModelContext) throws -> [Expense] {
        let key = expense.seriesKey
        let all = try context.fetch(FetchDescriptor<Expense>())
        return all.filter { $0.seriesKey == key }.sorted { $0.anchorDate < $1.anchorDate }
    }

    /// How many charges a record generates; nil when it runs on.
    static func paymentCount(of expense: Expense, calendar: Calendar) -> Int? {
        guard let endDate = expense.endDate else { return nil }
        let anchor = calendar.startOfDay(for: expense.anchorDate)
        let end = calendar.startOfDay(for: endDate)
        guard end >= anchor else { return 0 }
        return RecurrenceEngine.dates(for: expense.rule, in: DateInterval(start: anchor, end: end), calendar: calendar).count
    }

    /// Whether the series has any charge, in this record or a later one, strictly after
    /// `scheduledDate`. A record that runs on always does.
    static func hasLaterCharge(than scheduledDate: Date, in series: [Expense], calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: scheduledDate)
        for record in series {
            if record.endDate == nil { return true }
            if let count = paymentCount(of: record, calendar: calendar), count > 0 {
                let last = RecurrenceEngine.date(ofPayment: count - 1, for: record.rule, calendar: calendar)
                if calendar.startOfDay(for: last) > day { return true }
            }
        }
        return false
    }

    /// Whether `scheduledDate` is the bill's very first charge — the earliest record's own
    /// anchor. The first charge of a later, split-off record is not the bill's first.
    static func isFirstCharge(_ scheduledDate: Date, of expense: Expense, in series: [Expense], calendar: Calendar) -> Bool {
        guard let earliest = series.min(by: { $0.anchorDate < $1.anchorDate }) else { return false }
        return calendar.startOfDay(for: scheduledDate) == calendar.startOfDay(for: earliest.anchorDate)
    }

    // MARK: Saving

    /// One charge alone: writes or updates an `OverrideRecord` keyed on `scheduledDate`, and
    /// still applies the draft's name, category and whole-bill count, which never ask.
    static func saveThisCharge(
        _ draft: ExpenseDraft, expense: Expense, scheduledDate: Date,
        category: ExpenseCategory, context: ModelContext, calendar: Calendar
    ) throws {
        let seriesRecords = try series(of: expense, in: context)
        let day = calendar.startOfDay(for: scheduledDate)
        let amount = storedAmount(draft)
        let movedDay = calendar.startOfDay(for: draft.date)

        let override = existingOverride(on: day, of: expense, calendar: calendar) ?? {
            let created = OverrideRecord(scheduledDate: day, expense: expense)
            context.insert(created)
            return created
        }()
        override.actualAmount = amount == expense.amount ? nil : amount
        override.movedDate = movedDay == day ? nil : movedDay
        override.isSkipped = false

        if override.actualAmount == nil, override.movedDate == nil, !override.isSkipped {
            context.delete(override)
        }

        applyWholeSeries(draft: draft, series: seriesRecords, category: category, context: context, calendar: calendar)
        try context.save()
    }

    /// This charge and every one after it, never one before. Editing the record's own first
    /// charge changes that record in place; editing a later charge ends the record the charge
    /// before it and starts a new one sharing the series, moving forward any later one-off
    /// override whose date the new rule still generates.
    static func saveFutureCharges(
        _ draft: ExpenseDraft, expense: Expense, scheduledDate: Date,
        category: ExpenseCategory, context: ModelContext, calendar: Calendar
    ) throws {
        let seriesRecords = try series(of: expense, in: context)
        let day = calendar.startOfDay(for: scheduledDate)
        let amount = storedAmount(draft)
        let originalRule = expense.rule
        let originalAnchor = calendar.startOfDay(for: expense.anchorDate)
        let chargeIdx = chargeIndex(
            of: day, anchoredAt: expense.anchorDate, interval: expense.recurrenceInterval,
            unit: expense.recurrenceUnit, calendar: calendar
        )
        let laterRecords = seriesRecords.filter { $0 !== expense && $0.anchorDate > originalAnchor }

        let newRuleRecord: Expense
        if chargeIdx == 0 {
            expense.amount = amount
            expense.recurrenceInterval = draft.interval
            expense.recurrenceUnitRaw = draft.unit.rawValue
            expense.anchorDate = calendar.startOfDay(for: draft.date)
            newRuleRecord = expense
        } else {
            let endDate = RecurrenceEngine.date(ofPayment: chargeIdx - 1, for: originalRule, calendar: calendar)
            expense.endDate = calendar.startOfDay(for: endDate)
            let created = Expense(
                name: expense.name, amount: amount, isEstimate: false, isArchived: false,
                recurrenceInterval: draft.interval, recurrenceUnit: draft.unit,
                anchorDate: calendar.startOfDay(for: draft.date), endDate: nil,
                category: category, seriesID: expense.seriesKey
            )
            context.insert(created)
            newRuleRecord = created
        }

        // Every override scheduled after the open charge, whether it sat on the open record
        // or on a record about to be deleted, moves forward if the new rule still generates
        // its date, and is dropped otherwise.
        var candidateOverrides = (expense.overrides ?? []).filter { calendar.startOfDay(for: $0.scheduledDate) > day }
        for later in laterRecords {
            candidateOverrides.append(contentsOf: later.overrides ?? [])
        }
        for override in candidateOverrides {
            if generates(override.scheduledDate, rule: newRuleRecord.rule, calendar: calendar) {
                override.expense = newRuleRecord
            } else {
                context.delete(override)
            }
        }

        // The open charge's own override never survives a future-charges save: its amount
        // and date are now the rule's own.
        if let ownOverride = existingOverride(on: day, of: expense, calendar: calendar) {
            context.delete(ownOverride)
        }

        for later in laterRecords {
            context.delete(later)
        }

        let updatedSeries = try series(of: expense, in: context)
        applyWholeSeries(draft: draft, series: updatedSeries, category: category, context: context, calendar: calendar)
        try context.save()
    }

    /// Name, category and payment count alone: every record in the series, without touching
    /// any one charge.
    static func saveWholeBill(
        _ draft: ExpenseDraft, expense: Expense, category: ExpenseCategory, context: ModelContext, calendar: Calendar
    ) throws {
        let seriesRecords = try series(of: expense, in: context)
        applyWholeSeries(draft: draft, series: seriesRecords, category: category, context: context, calendar: calendar)
        try context.save()
    }

    // MARK: Deleting

    /// Ends the bill at the charge before this one — or, from a record's own first charge,
    /// removes that record outright — and always removes every later record.
    static func deleteFutureCharges(
        from scheduledDate: Date, of expense: Expense, context: ModelContext, calendar: Calendar
    ) throws {
        let seriesRecords = try series(of: expense, in: context)
        let day = calendar.startOfDay(for: scheduledDate)
        let originalAnchor = calendar.startOfDay(for: expense.anchorDate)
        let chargeIdx = chargeIndex(
            of: day, anchoredAt: expense.anchorDate, interval: expense.recurrenceInterval,
            unit: expense.recurrenceUnit, calendar: calendar
        )
        let laterRecords = seriesRecords.filter { $0 !== expense && $0.anchorDate > originalAnchor }

        if chargeIdx == 0 {
            context.delete(expense) // cascades to its overrides
        } else {
            let endDate = RecurrenceEngine.date(ofPayment: chargeIdx - 1, for: expense.rule, calendar: calendar)
            expense.endDate = calendar.startOfDay(for: endDate)
            for override in expense.overrides ?? [] where calendar.startOfDay(for: override.scheduledDate) >= day {
                context.delete(override)
            }
        }

        for later in laterRecords {
            context.delete(later)
        }

        try context.save()
    }

    /// Every record in the series. Overrides cascade.
    static func deleteAllCharges(of expense: Expense, context: ModelContext) throws {
        for record in try series(of: expense, in: context) {
            context.delete(record)
        }
        try context.save()
    }

    // MARK: Shared writes

    /// Name and category always reach the whole series; the count is applied last since it
    /// can delete records past where it lands.
    private static func applyWholeSeries(
        draft: ExpenseDraft, series: [Expense], category: ExpenseCategory, context: ModelContext, calendar: Calendar
    ) {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        for record in series {
            record.name = name
            record.category = category
        }
        applyPaymentCount(draft.paymentCount, to: series, context: context, calendar: calendar)
    }

    /// nil reopens the last record. A count walks the series, adding up each ended record's
    /// charges until it finds the record charge N falls in — the last record if N runs past
    /// every one of them, extending it — sets that record's end there, and drops every record
    /// after it.
    private static func applyPaymentCount(
        _ wholeBillCount: Int?, to series: [Expense], context: ModelContext, calendar: Calendar
    ) {
        guard let last = series.last else { return }
        guard let wholeBillCount else {
            last.endDate = nil
            return
        }

        var chargesBefore = 0
        for (index, record) in series.enumerated() {
            let isLast = index == series.count - 1
            let recordCount = paymentCount(of: record, calendar: calendar)
            let fallsHere = isLast || (recordCount.map { chargesBefore + $0 >= wholeBillCount } ?? true)
            if fallsHere {
                let localIndex = max(0, wholeBillCount - chargesBefore - 1)
                let chargeDate = RecurrenceEngine.date(ofPayment: localIndex, for: record.rule, calendar: calendar)
                record.endDate = calendar.startOfDay(for: chargeDate)
                for later in series[(index + 1)...] {
                    context.delete(later)
                }
                return
            }
            chargesBefore += recordCount ?? 0
        }
    }

    // MARK: Helpers

    /// The draft's amount including zero, which `ExpenseDraft.amount` deliberately excludes.
    /// Only meaningful once the draft has passed `isValid`.
    private static func storedAmount(_ draft: ExpenseDraft) -> Decimal {
        draft.isZero ? 0 : (draft.amount ?? 0)
    }

    private static func existingOverride(on day: Date, of expense: Expense, calendar: Calendar) -> OverrideRecord? {
        (expense.overrides ?? []).first { calendar.startOfDay(for: $0.scheduledDate) == day }
    }

    /// This charge's 0-based position among the dates its own record generates from `anchor`,
    /// the same reckoning `EditSession` uses.
    private static func chargeIndex(
        of scheduledDate: Date, anchoredAt anchor: Date, interval: Int, unit: RecurrenceUnit, calendar: Calendar
    ) -> Int {
        let rule = RecurrenceRule(interval: interval, unit: unit, anchorDate: anchor)
        let anchorDay = calendar.startOfDay(for: anchor)
        let day = calendar.startOfDay(for: scheduledDate)
        guard day >= anchorDay else { return 0 }
        let dates = RecurrenceEngine.dates(for: rule, in: DateInterval(start: anchorDay, end: day), calendar: calendar)
        return max(0, dates.count - 1)
    }

    private static func generates(_ date: Date, rule: RecurrenceRule, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return RecurrenceEngine.dates(for: rule, in: DateInterval(start: day, end: day), calendar: calendar).contains(day)
    }
}
