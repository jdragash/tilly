import Foundation
import TillyCore

/// One record of a bill, reduced for the builder so it is pure and testable without SwiftData.
struct BillInput: Equatable, Sendable {
    let seriesKey: UUID
    let expenseID: UUID
    let name: String
    let categoryID: UUID?
    let snapshot: ExpenseSnapshot
    let overrides: [OccurrenceOverride]
}

/// What All bills normalises every bill to. Stored, so the raw values never change.
enum BillPeriod: String, CaseIterable, Sendable {
    case month, year
}

/// A charge, named the way the editor finds it: its record and the date the rule scheduled it.
struct ChargeRef: Equatable, Sendable {
    let expenseID: UUID
    let scheduledDate: Date
}

enum BillState: Equatable, Sendable {
    case runs
    case starts(Date) // its first charge is after today
    case changes(Date, from: Decimal?) // a later record starts after today
    case ends(Date) // the series' last charge, after today
    case ended(Date) // the series' last charge, today or earlier
}

/// One bill: every record of a series, read through its latest.
struct BillRow: Identifiable, Equatable, Sendable {
    let id: UUID // seriesKey
    let name: String // the latest record's
    let categoryID: UUID?
    let charge: Decimal? // the latest record's amount
    let rule: RecurrenceRule // the latest record's
    let figure: Decimal? // per period, whole units; nil when the amount isn't known
    let state: BillState
    let paidInAll: Decimal // non-skipped charges up to today, across the series
    let opens: ChargeRef? // next charge after today, else the last charge
}

struct BillCard: Identifiable, Equatable, Sendable {
    let category: CategoryInfo? // nil: bills saved before categories existed
    let rows: [BillRow] // figure descending, ties by name, nil last
    let total: Decimal // sum of its rows' figures

    var id: String { category?.id.uuidString ?? "uncategorised" }
}

struct AllBills: Equatable, Sendable {
    let cards: [BillCard] // bills still running; total descending, ties in Settings order
    let ended: [BillRow] // paidInAll descending
    let total: Decimal // over the bills still running
}
