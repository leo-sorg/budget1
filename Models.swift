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
    /// Transactions assigned to this category.
    /// If the category is removed, existing transactions should keep their data
    /// and simply become uncategorized rather than crashing when accessed.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

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
    /// Transactions using this payment method.
    /// Nullify references on delete so history/summary views remain stable.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.paymentMethod)
    var transactions: [Transaction] = []

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
    // Use nullify delete rules so that if the related Category or PaymentMethod
    // is deleted, existing transactions simply lose the reference instead of
    // crashing when their properties are accessed.
    @Relationship(deleteRule: .nullify, inverse: \Category.transactions)
    var category: Category?
    @Relationship(deleteRule: .nullify, inverse: \PaymentMethod.transactions)
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
