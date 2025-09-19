import Foundation

struct SheetsClient {
    let baseURL: URL
    let secret: String

    struct Response: Sendable {
        let status: Int
        let body: String
    }

    // MARK: - POST Methods (existing)
    
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
            "paymentMethod": paymentName ?? "", // API expects paymentMethod, not paymentName
            "merchantName": merchantName ?? "", // Now properly accepting merchantName parameter
            "note": note ?? "",
            "transactionType": "" // API expects this field, even if empty
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

    // MARK: - GET Methods (existing + new)
    
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
            print("SheetsClient ❌ bad URL for getTransactions")
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        print("SheetsClient 🔗 GET: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("SheetsClient ❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("SheetsClient ❌ No data received")
                completion(.failure(SheetsError.noData))
                return
            }
            
            // Debug: Print raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("SheetsClient 📄 Raw response: \(rawResponse.prefix(500))...")
            }
            
            // Check if response is HTML (error page) instead of JSON
            if let responseString = String(data: data, encoding: .utf8),
               responseString.lowercased().contains("<html") {
                print("SheetsClient ❌ Received HTML instead of JSON")
                completion(.failure(SheetsError.htmlResponse))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                print("SheetsClient ✅ Decoded \(apiResponse.data.count) transactions")
                completion(.success(apiResponse))
            } catch {
                print("SheetsClient ❌ Decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - NEW: Get Categories
    func getCategories(completion: @escaping (Result<APICategoriesResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getCategories")
        ]
        
        guard let url = components.url else {
            print("SheetsClient ❌ bad URL for getCategories")
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        print("SheetsClient 🔗 GET Categories: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("SheetsClient ❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("SheetsClient ❌ No data received")
                completion(.failure(SheetsError.noData))
                return
            }
            
            // Debug: Print raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("SheetsClient 📄 Categories Raw response: \(rawResponse.prefix(1000))...")
            }
            
            // Check if response is HTML (error page) instead of JSON
            if let responseString = String(data: data, encoding: .utf8),
               responseString.lowercased().contains("<html") {
                print("SheetsClient ❌ Received HTML instead of JSON")
                completion(.failure(SheetsError.htmlResponse))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APICategoriesResponse.self, from: data)
                print("SheetsClient ✅ Decoded \(apiResponse.data.count) categories")
                completion(.success(apiResponse))
            } catch {
                print("SheetsClient ❌ Categories decode error: \(error)")
                // Print more detailed error information
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type): \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found for type \(type): \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error: \(error)")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - NEW: Get Payment Methods
    func getPaymentMethods(completion: @escaping (Result<APIPaymentMethodsResponse, Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "action", value: "getPaymentMethods")
        ]
        
        guard let url = components.url else {
            print("SheetsClient ❌ bad URL for getPaymentMethods")
            completion(.failure(SheetsError.invalidURL))
            return
        }
        
        print("SheetsClient 🔗 GET Payment Methods: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("SheetsClient ❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("SheetsClient ❌ No data received")
                completion(.failure(SheetsError.noData))
                return
            }
            
            // Debug: Print raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("SheetsClient 📄 Payment Methods Raw response: \(rawResponse.prefix(1000))...")
            }
            
            // Check if response is HTML (error page) instead of JSON
            if let responseString = String(data: data, encoding: .utf8),
               responseString.lowercased().contains("<html") {
                print("SheetsClient ❌ Received HTML instead of JSON")
                completion(.failure(SheetsError.htmlResponse))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: data)
                print("SheetsClient ✅ Decoded \(apiResponse.data.count) payment methods")
                completion(.success(apiResponse))
            } catch {
                print("SheetsClient ❌ Payment Methods decode error: \(error)")
                // Print more detailed error information
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type): \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found for type \(type): \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error: \(error)")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Private POST helper
    
    private func postJSON(_ body: [String: Any], completion: @escaping (Response) -> Void) {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "secret", value: secret)]
        guard let url = comps.url else {
            print("SheetsClient ❌ bad URL")
            completion(.init(status: -1, body: "bad url"))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                let msg = "network error: \(err.localizedDescription)"
                print("SheetsClient ❌", msg)
                completion(.init(status: -1, body: msg))
                return
            }
            let http = resp as? HTTPURLResponse
            let status = http?.statusCode ?? -1
            let text = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
            print("SheetsClient ↩︎ status=\(status) body=\(text)")
            completion(.init(status: status, body: text))
        }.resume()
    }
}

// MARK: - Error Types

enum SheetsError: LocalizedError {
    case invalidURL
    case noData
    case htmlResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .noData:
            return "No data received from server"
        case .htmlResponse:
            return "Server returned an error page instead of data"
        }
    }
}

// MARK: - API Models (existing)

struct APIResponse: Codable {
    let success: Bool
    let message: String
    let total: Int?
    let filtered: Int?
    let data: [APITransaction]
}

struct APITransaction: Codable {
    let remoteID: String
    let amount: Double
    let categoryName: String
    let paymentMethod: String
    let merchantName: String
    let note: String
    let dateISO: String
    let transactionType: String
}

// MARK: - NEW API Models for Categories and Payment Methods

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
        case remoteID = "Remote ID"
        case name = "Name"
        case emoji = "Emoji"
        case sortIndex = "Sort Index"
        case isIncome = "Is Income"
        case timestamp = "Timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        remoteID = try container.decode(String.self, forKey: .remoteID)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        
        // Handle sortIndex as either Int or String
        if let sortInt = try? container.decode(Int.self, forKey: .sortIndex) {
            sortIndex = sortInt
        } else if let sortString = try? container.decode(String.self, forKey: .sortIndex),
                  let sortInt = Int(sortString) {
            sortIndex = sortInt
        } else {
            sortIndex = 0
        }
        
        // Handle isIncome as either Bool or String (including empty strings)
        if let incomeBool = try? container.decode(Bool.self, forKey: .isIncome) {
            isIncome = incomeBool
        } else if let incomeString = try? container.decode(String.self, forKey: .isIncome) {
            isIncome = incomeString.lowercased() == "true"
        } else {
            isIncome = false
        }
        
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
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
        case timestamp = ""  // Empty string key for timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract remoteID
        remoteID = try container.decode(String.self, forKey: .remoteID)
        
        // Extract name
        name = try container.decode(String.self, forKey: .name)
        
        // Extract emoji - handle both String and Int cases
        if let emojiString = try? container.decode(String.self, forKey: .emoji) {
            emoji = emojiString
        } else if let emojiInt = try? container.decode(Int.self, forKey: .emoji) {
            emoji = String(emojiInt) // Convert number to string, but it's probably not a real emoji
        } else {
            emoji = ""
        }
        
        // Extract sortIndex - handle both String and Int, with empty string handling
        if let sortInt = try? container.decode(Int.self, forKey: .sortIndex) {
            sortIndex = sortInt
        } else if let sortString = try? container.decode(String.self, forKey: .sortIndex) {
            if sortString.isEmpty {
                sortIndex = 0
            } else if let sortInt = Int(sortString) {
                sortIndex = sortInt
            } else {
                sortIndex = 0
            }
        } else {
            sortIndex = 0
        }
        
        // Extract timestamp from empty key
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
    }
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
