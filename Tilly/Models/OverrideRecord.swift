import Foundation
import SwiftData
import TillyCore

/// The stored form of `TillyCore.OccurrenceOverride`. Named differently on purpose, so the
/// persisted type and the engine's value type never collide in a file or in a reader's head.
@Model
final class OverrideRecord {
    var scheduledDate: Date = Date()
    var actualAmount: Decimal?
    var movedDate: Date?
    var isSkipped: Bool = false
    var expense: Expense?

    init(
        scheduledDate: Date = Date(),
        actualAmount: Decimal? = nil,
        movedDate: Date? = nil,
        isSkipped: Bool = false,
        expense: Expense? = nil
    ) {
        self.scheduledDate = scheduledDate
        self.actualAmount = actualAmount
        self.movedDate = movedDate
        self.isSkipped = isSkipped
        self.expense = expense
    }
}

extension OverrideRecord {
    var snapshot: OccurrenceOverride {
        OccurrenceOverride(
            scheduledDate: scheduledDate,
            actualAmount: actualAmount,
            movedDate: movedDate,
            isSkipped: isSkipped
        )
    }
}
