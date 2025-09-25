import Foundation

struct SheetsClient {
    let baseURL: URL
    let secret: String

    struct Response: Sendable {
        let status: Int
        let body: String
    }

    // MARK: - POST Methods
    
    func postTransaction(remoteID: String, amount: Decimal, date: Date,
                         categoryName: String?, paymentName: String?, merchantName: String? = nil,
                         note: String?,
                         completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "transaction",
            "remoteID": remoteID,
            "amount": (amount as NSDecimalNumber).doubleValue,
            "dateISO": DateFormatter.iso8601.string(from: date),
            "categoryName": categoryName ?? "",
            "paymentMethod": paymentName ?? "",
            "merchantName": merchantName ?? "",
            "note": note ?? "",
            "transactionType": ""
        ]
        postJSON(payload, completion: completion)
    }

    func postCategory(remoteID: String, name: String, emoji: String?, sortIndex: Int,
                      isIncome: Bool,
                      completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "category",
            "remoteID": remoteID,
            "name": name,
            "emoji": emoji ?? "",
            "sortIndex": sortIndex,
            "isIncome": isIncome
        ]
        postJSON(payload, completion: completion)
    }

    func postPayment(remoteID: String, name: String, emoji: String?, sortIndex: Int,
                     completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "paymentMethod",
            "remoteID": remoteID,
            "name": name,
            "emoji": emoji ?? "",
            "sortIndex": sortIndex
        ]
        postJSON(payload, completion: completion)
    }

    // MARK: - EDIT Methods (NEW)
    
    /// Edit a transaction by remoteID - all fields except remoteID are optional
    func editTransaction(
        remoteID: String,
        amount: Decimal? = nil,
        categoryName: String? = nil,
        paymentMethod: String? = nil,
        merchantName: String? = nil,
        note: String? = nil,
        dateISO: String? = nil,
        transactionType: String? = nil,
        completion: @escaping (Response) -> Void = { _ in }
    ) {
        var payload: [String: Any] = [
            "type": "editTransaction",
            "remoteID": remoteID
        ]
        
        // Only include fields that are provided
        if let amount = amount {
            payload["amount"] = (amount as NSDecimalNumber).doubleValue
        }
        if let categoryName = categoryName {
            payload["categoryName"] = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let paymentMethod = paymentMethod {
            payload["paymentMethod"] = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let merchantName = merchantName {
            payload["merchantName"] = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let note = note {
            payload["note"] = note.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let dateISO = dateISO {
            payload["dateISO"] = dateISO
        }
        if let transactionType = transactionType {
            payload["transactionType"] = transactionType
        }
        
        postJSON(payload, completion: completion)
    }
    
    /// Convenience method to edit only the category name
    func editTransactionCategory(remoteID: String, categoryName: String, completion: @escaping (Response) -> Void = { _ in }) {
        editTransaction(
            remoteID: remoteID,
            categoryName: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            completion: completion
        )
    }

    // MARK: - UPDATE Methods (Legacy - kept for compatibility)
    
    /// Update transaction category by remoteID
    func updateTransactionCategory(remoteID: String, categoryName: String, completion: @escaping (Response) -> Void = { _ in }) {
        // Use the new edit API
        editTransactionCategory(remoteID: remoteID, categoryName: categoryName, completion: completion)
    }
    
    /// Update transaction payment method by remoteID
    func updateTransactionPaymentMethod(remoteID: String, paymentMethod: String, completion: @escaping (Response) -> Void = { _ in }) {
        editTransaction(remoteID: remoteID, paymentMethod: paymentMethod, completion: completion)
    }
    
    /// Update transaction note by remoteID
    func updateTransactionNote(remoteID: String, note: String, completion: @escaping (Response) -> Void = { _ in }) {
        editTransaction(remoteID: remoteID, note: note, completion: completion)
    }
    
    /// Update transaction amount by remoteID
    func updateTransactionAmount(remoteID: String, amount: Decimal, completion: @escaping (Response) -> Void = { _ in }) {
        editTransaction(remoteID: remoteID, amount: amount, completion: completion)
    }
    
    /// Update multiple transaction fields at once
    func updateTransaction(remoteID: String, categoryName: String? = nil, paymentMethod: String? = nil, note: String? = nil, amount: Decimal? = nil, completion: @escaping (Response) -> Void = { _ in }) {
        editTransaction(
            remoteID: remoteID,
            amount: amount,
            categoryName: categoryName,
            paymentMethod: paymentMethod,
            note: note,
            completion: completion
        )
    }

    // MARK: - DELETE Methods
    
    /// Delete a transaction by remoteID
    func deleteTransaction(remoteID: String, completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "deleteTransaction",
            "remoteID": remoteID
        ]
        postJSON(payload, completion: completion)
    }
    
    /// Delete a category by remoteID
    func deleteCategory(remoteID: String, completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "deleteCategory",
            "remoteID": remoteID
        ]
        postJSON(payload, completion: completion)
    }
    
    /// Delete a payment method by remoteID
    func deletePaymentMethod(remoteID: String, completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "deletePaymentMethod",
            "remoteID": remoteID
        ]
        postJSON(payload, completion: completion)
    }

    // MARK: - GET Methods (unchanged)
    
    func getTransactions(startDate: Date, endDate: Date, limit: Int = 300,
                        completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "startDate", value: DateFormatter.iso8601.string(from: startDate)),
            URLQueryItem(name: "endDate", value: DateFormatter.iso8601.string(from: endDate)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Get uncategorized transactions (transactions with empty categoryName)
    func getUncategorizedTransactions(completion: @escaping (Result<APIResponse, Error>) -> Void) {
        print("🔗 SheetsClient.getUncategorizedTransactions called")
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "categoryName", value: ""), // ✅ Empty string to filter for uncategorized
            URLQueryItem(name: "limit", value: "100") // Reasonable limit for uncategorized
        ]
        
        print("🌐 Uncategorized API URL: \(components.url?.absoluteString ?? "invalid")")
        print("🔍 Query parameters:")
        components.queryItems?.forEach { item in
            print("   - \(item.name): '\(item.value ?? "nil")'")
        }
        
        guard let url = components.url else {
            print("❌ Invalid URL for uncategorized transactions")
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    print("✅ Successfully decoded uncategorized API response")
                    print("📊 Response success: \(apiResponse.success)")
                    print("📋 Response message: \(apiResponse.message)")
                    print("🔢 Uncategorized transactions count: \(apiResponse.data.count)")
                    
                    // Additional debug: Check first few transactions
                    for (index, transaction) in apiResponse.data.prefix(3).enumerated() {
                        print("🔍 Transaction \(index): categoryName='\(transaction.categoryName)', merchantName='\(transaction.merchantName)', amount=\(transaction.amount)")
                    }
                    
                    completion(.success(apiResponse))
                } catch {
                    print("🚨 Failed to decode uncategorized API response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Raw response: \(responseString.prefix(500))")
                    }
                    completion(.failure(error))
                }
            case .failure(let error):
                print("🚨 Uncategorized API request failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Get transactions by category name
    func getTransactionsByCategory(categoryName: String, limit: Int = 300, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "categoryName", value: categoryName),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get transactions by payment method
    func getTransactionsByPaymentMethod(paymentMethod: String, limit: Int = 300, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "paymentMethod", value: paymentMethod),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get transactions by transaction type (income/expense)
    func getTransactionsByType(transactionType: String, limit: Int = 300, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "transactionType", value: transactionType),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getCategories(completion: @escaping (Result<APICategoriesResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getCategories")
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APICategoriesResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Categories decode error. Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getPaymentMethods(completion: @escaping (Result<APIPaymentMethodsResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getPaymentMethods")
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Payment methods decode error. Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - SEARCH/FILTER Methods
    
    /// Search transactions by text in note or merchantName
    func searchTransactions(query: String, limit: Int = 100, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "searchTransactions"),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get transactions within an amount range
    func getTransactionsByAmountRange(minAmount: Decimal, maxAmount: Decimal, limit: Int = 300, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getTransactions"),
            URLQueryItem(name: "minAmount", value: String(describing: minAmount)),
            URLQueryItem(name: "maxAmount", value: String(describing: maxAmount)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - STATISTICS Methods
    
    /// Get summary statistics for a date range
    func getSummaryStatistics(startDate: Date, endDate: Date, completion: @escaping (Result<APISummaryResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getSummary"),
            URLQueryItem(name: "startDate", value: DateFormatter.iso8601.string(from: startDate)),
            URLQueryItem(name: "endDate", value: DateFormatter.iso8601.string(from: endDate))
        ]
        
        guard let url = components.url else {
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APISummaryResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private Helpers
    
    private func performGETRequest(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    completion(.failure(SheetsError.httpError(httpResponse.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(SheetsError.noData))
                return
            }
            
            // Check if response is HTML (error page) instead of JSON
            if let responseString = String(data: data, encoding: .utf8),
               responseString.lowercased().contains("<html") {
                completion(.failure(SheetsError.htmlResponse))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    private func postJSON(_ body: [String: Any], completion: @escaping (Response) -> Void) {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "secret", value: secret)]
        guard let url = comps.url else {
            completion(.init(status: -1, body: "bad url"))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                completion(.init(status: -1, body: "network error: \(err.localizedDescription)"))
                return
            }
            let http = resp as? HTTPURLResponse
            let status = http?.statusCode ?? -1
            let text = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
            completion(.init(status: status, body: text))
        }.resume()
    }
}

// MARK: - Error Types

enum SheetsError: LocalizedError {
    case invalidURL
    case noData
    case htmlResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .noData:
            return "No data received from server"
        case .htmlResponse:
            return "Server returned an error page instead of data"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}

// MARK: - API Models

struct APIResponse: Codable {
    let success: Bool
    let message: String
    let total: Int?
    let filtered: Int?
    let data: [APITransaction]
}

// UPDATED: Added categoryEmoji field and Equatable conformance
struct APITransaction: Codable, Equatable {
    let remoteID: String
    let amount: Double
    let categoryName: String
    let categoryEmoji: String // Category emoji field
    let paymentMethod: String
    let merchantName: String
    let note: String
    let dateISO: String
    let transactionType: String
    
    // Custom decoder to handle potential missing categoryEmoji field
    enum CodingKeys: String, CodingKey {
        case remoteID, amount, categoryName, categoryEmoji, paymentMethod, merchantName, note, dateISO, transactionType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        remoteID = try container.decode(String.self, forKey: .remoteID)
        amount = try container.decode(Double.self, forKey: .amount)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        merchantName = try container.decode(String.self, forKey: .merchantName)
        note = try container.decode(String.self, forKey: .note)
        dateISO = try container.decode(String.self, forKey: .dateISO)
        transactionType = try container.decode(String.self, forKey: .transactionType)
        
        // Handle categoryEmoji with fallback to empty string if missing
        categoryEmoji = (try? container.decode(String.self, forKey: .categoryEmoji)) ?? ""
    }
    
    // Manual init for mock data
    init(remoteID: String, amount: Double, categoryName: String, categoryEmoji: String = "", paymentMethod: String, merchantName: String, note: String, dateISO: String, transactionType: String) {
        self.remoteID = remoteID
        self.amount = amount
        self.categoryName = categoryName
        self.categoryEmoji = categoryEmoji
        self.paymentMethod = paymentMethod
        self.merchantName = merchantName
        self.note = note
        self.dateISO = dateISO
        self.transactionType = transactionType
    }
    
    // MARK: - Equatable implementation
    static func == (lhs: APITransaction, rhs: APITransaction) -> Bool {
        return lhs.remoteID == rhs.remoteID // Compare by unique ID
    }
}

// MARK: - API Models - Simple camelCase structure

struct APICategoriesResponse: Codable {
    let success: Bool
    let message: String
    let total: Int?
    let data: [APICategory]
}

struct APICategory: Codable {
    let remoteID: String
    let name: String
    let emoji: String
    let sortIndex: Int
    let isIncome: Bool
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case remoteID
        case name
        case emoji
        case sortIndex
        case isIncome
        case timestamp
    }
    
    // Tolerant decoder: handle emoji as string/number/bool/null; sortIndex as int/string/double
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.remoteID = try c.decode(String.self, forKey: .remoteID)
        self.name = try c.decode(String.self, forKey: .name)
        
        if let s = try? c.decode(String.self, forKey: .emoji) {
            self.emoji = s
        } else if let n = try? c.decode(Double.self, forKey: .emoji) {
            self.emoji = n == 0 ? "" : String(n)
        } else if let b = try? c.decode(Bool.self, forKey: .emoji) {
            self.emoji = b ? "true" : ""
        } else {
            self.emoji = ""
        }
        
        if let i = try? c.decode(Int.self, forKey: .sortIndex) {
            self.sortIndex = i
        } else if let s = try? c.decode(String.self, forKey: .sortIndex),
                  let i = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.sortIndex = i
        } else if let d = try? c.decode(Double.self, forKey: .sortIndex) {
            self.sortIndex = Int(d)
        } else {
            self.sortIndex = 0
        }
        
        self.timestamp = try? c.decode(String.self, forKey: .timestamp)
        self.isIncome = (try? c.decode(Bool.self, forKey: .isIncome)) ?? false
    }
}

struct APIPaymentMethodsResponse: Codable {
    let success: Bool
    let message: String
    let total: Int?
    let data: [APIPaymentMethod]
}

struct APIPaymentMethod: Codable {
    let remoteID: String
    let name: String
    let emoji: String
    let sortIndex: Int
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case remoteID
        case name
        case emoji
        case sortIndex
        case timestamp
    }
    
    // Custom decoder to tolerate non-string emoji and mixed sortIndex types
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        self.remoteID = try c.decode(String.self, forKey: .remoteID)
        self.name = try c.decode(String.self, forKey: .name)
        
        // emoji can come as a string, number, bool, or null -> coerce to ""
        if let s = try? c.decode(String.self, forKey: .emoji) {
            self.emoji = s
        } else if let n = try? c.decode(Double.self, forKey: .emoji) {
            // If Sheets gave 0 (or any number), treat as empty string
            self.emoji = n == 0 ? "" : String(n)
        } else if let b = try? c.decode(Bool.self, forKey: .emoji) {
            self.emoji = b ? "true" : ""
        } else {
            self.emoji = ""
        }
        
        // sortIndex may be Int or String; default to 0 if missing
        if let i = try? c.decode(Int.self, forKey: .sortIndex) {
            self.sortIndex = i
        } else if let s = try? c.decode(String.self, forKey: .sortIndex),
                  let i = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.sortIndex = i
        } else if let d = try? c.decode(Double.self, forKey: .sortIndex) {
            self.sortIndex = Int(d)
        } else {
            self.sortIndex = 0
        }
        
        // timestamp as optional string; ignore non-strings
        self.timestamp = (try? c.decode(String.self, forKey: .timestamp))
    }
}

// MARK: - Summary Statistics Response

struct APISummaryResponse: Codable {
    let success: Bool
    let message: String
    let data: APISummaryData
}

struct APISummaryData: Codable {
    let totalIncome: Double
    let totalExpenses: Double
    let netAmount: Double
    let transactionCount: Int
    let categoryBreakdown: [APICategorySummary]
    let paymentMethodBreakdown: [APIPaymentMethodSummary]
}

struct APICategorySummary: Codable {
    let categoryName: String
    let categoryEmoji: String
    let totalAmount: Double
    let transactionCount: Int
    let isIncome: Bool
}

struct APIPaymentMethodSummary: Codable {
    let paymentMethod: String
    let totalAmount: Double
    let transactionCount: Int
}

// MARK: - Date Formatter

private extension DateFormatter {
    static let iso8601: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
