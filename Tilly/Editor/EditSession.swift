import Foundation
import SwiftData
import TillyCore

/// Everything the editor needs to edit one charge, built from the timeline's entry that was
/// tapped. See `docs/DESIGN.md`, "Opening a charge edits it".
struct EditSession: Identifiable, Equatable {
    let expenseID: UUID
    let scheduledDate: Date
    let draft: ExpenseDraft // baseline set
    let hasLaterCharge: Bool
    let isFirstCharge: Bool
    /// For "Deleting future charges keeps Aug 28 and earlier"; nil on the bill's very first
    /// charge, where deleting takes everything and there's nothing to keep.
    let previousChargeDate: Date?

    var id: String { "\(expenseID.uuidString)-\(Int(scheduledDate.timeIntervalSince1970))" }

    @MainActor
    static func make(
        expenseID: UUID, scheduledDate: Date, context: ModelContext, calendar: Calendar
    ) throws -> EditSession? {
        guard let expense = try context.expense(id: expenseID) else { return nil }

        let day = calendar.startOfDay(for: scheduledDate)
        let series = try BillEditor.series(of: expense, in: context)
        let dayKey = CalendarDay(day, calendar: calendar)
        let override = (expense.overrides ?? []).first { $0.scheduled == dayKey }

        // A skip only older data could hold — nothing in v1 writes one — reads as €0 rather
        // than as the record's own amount, since a skip means the charge itself was zero.
        let digits: String
        if override?.isSkipped == true {
            digits = "0"
        } else if let amount = override?.actualAmount ?? expense.amount {
            digits = ExpenseDraft.digits(for: amount)
        } else {
            digits = ""
        }

        let effectiveDate = override?.movedDate(in: calendar) ?? day
        let recordIndex = series.firstIndex { $0 === expense } ?? 0
        let paymentsBeforeRule = series[..<recordIndex].reduce(0) {
            $0 + (BillEditor.paymentCount(of: $1, calendar: calendar) ?? 0)
        }
        let chargeIndex = BillEditor.chargeIndex(
            of: day, anchoredAt: expense.anchorDate(in: calendar), interval: expense.recurrenceInterval,
            unit: expense.recurrenceUnit, calendar: calendar
        )

        let wholeBillPaymentCount: Int?
        if series.last?.end != nil {
            wholeBillPaymentCount = series.reduce(0) { $0 + (BillEditor.paymentCount(of: $1, calendar: calendar) ?? 0) }
        } else {
            wholeBillPaymentCount = nil
        }

        let previousChargeDate: Date?
        if chargeIndex == 0 {
            // The record's own first charge: the previous charge, if any, is the earlier
            // record's last — not nil, unless this is the bill's first record too.
            if recordIndex > 0, let count = BillEditor.paymentCount(of: series[recordIndex - 1], calendar: calendar),
               count > 0 {
                previousChargeDate = RecurrenceEngine.date(ofPayment: count - 1, for: series[recordIndex - 1].rule(calendar: calendar), calendar: calendar)
            } else {
                previousChargeDate = nil
            }
        } else {
            previousChargeDate = RecurrenceEngine.date(ofPayment: chargeIndex - 1, for: expense.rule(calendar: calendar), calendar: calendar)
        }

        let baseline = EditBaseline(
            digits: digits, name: expense.name, date: effectiveDate,
            interval: expense.recurrenceInterval, unit: expense.recurrenceUnit,
            paymentCount: wholeBillPaymentCount, categoryID: expense.category?.id,
            ruleAnchor: expense.anchorDate(in: calendar), paymentsBeforeRule: paymentsBeforeRule,
            chargeIndex: chargeIndex,
            earliestDate: previousChargeDate.flatMap {
                calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: $0))
            }
        )

        return EditSession(
            expenseID: expenseID, scheduledDate: day, draft: ExpenseDraft(editing: baseline),
            hasLaterCharge: BillEditor.hasLaterCharge(than: day, in: series, calendar: calendar),
            isFirstCharge: BillEditor.isFirstCharge(day, in: series, calendar: calendar),
            previousChargeDate: previousChargeDate
        )
    }
}
