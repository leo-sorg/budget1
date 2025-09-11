import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    var emoji: String?
    /// Controls display order via drag & drop.
    var sortIndex: Int

    init(name: String, emoji: String? = nil, sortIndex: Int = 0) {
        self.name = name
        self.emoji = emoji
        self.sortIndex = sortIndex
    }
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var name: String
    /// Controls display order via drag & drop.
    var sortIndex: Int

    init(name: String, sortIndex: Int = 0) {
        self.name = name
        self.sortIndex = sortIndex
    }
}

@Model
final class Transaction {
    var amount: Decimal
    var date: Date
    var note: String?
    var category: Category?
    var paymentMethod: PaymentMethod?

    init(amount: Decimal,
         date: Date = .now,
         note: String? = nil,
         category: Category? = nil,
         paymentMethod: PaymentMethod? = nil) {
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.paymentMethod = paymentMethod
    }
}
