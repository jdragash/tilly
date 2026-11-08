import OSLog
import SwiftData

extension ModelContext {
    /// Runs `operation`, its writes and its save, and if anything in it throws, discards every
    /// pending change before rethrowing. A failed save then leaves nothing half-written waiting
    /// for the next save to carry out by accident.
    func applyOrRollBack(_ operation: () throws -> Void) rethrows {
        do {
            try operation()
        } catch {
            rollback()
            throw error
        }
    }

    /// Saves, or rolls back and logs `what` failed. For changes a person can simply make again.
    /// Returns whether the save went through.
    @discardableResult
    func saveOrRollBack(_ what: String, logger: Logger) -> Bool {
        do {
            try applyOrRollBack { try save() }
            return true
        } catch {
            logger.error("\(what, privacy: .public) failed: \(error, privacy: .public)")
            return false
        }
    }
}
