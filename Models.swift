import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    var emoji: String?
    /// Controls display order via drag & drop.
    var sortIndex: Int
    /// Stable ID used when syncing to Google Sheets (and future backends).
    var remoteID: String

    init(
        name: String,
        emoji: String? = nil,
        sortIndex: Int = 0,
        remoteID: String = UUID().uuidString
    ) {
        self.name = name
        self.emoji = emoji
        self.sortIndex = sortIndex
        self.remoteID = remoteID
    }
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var name: String
    /// Controls display order via drag & drop.
    var sortIndex: Int
    /// Stable ID used when syncing to Google Sheets (and future backends).
    var remoteID: String

    init(
        name: String,
        sortIndex: Int = 0,
        remoteID: String = UUID().uuidString
    ) {
        self.name = name
        self.sortIndex = sortIndex
        self.remoteID = remoteID
    }
}

@Model
final class Transaction {
    var amount: Decimal
    var date: Date
    var note: String?
    var category: Category?
    var paymentMethod: PaymentMethod?
    /// Stable ID used when syncing to Google Sheets (and future backends).
    var remoteID: String

    init(
        amount: Decimal,
        date: Date = .now,
        note: String? = nil,
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil,
        remoteID: String = UUID().uuidString
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.paymentMethod = paymentMethod
        self.remoteID = remoteID
    }
}
