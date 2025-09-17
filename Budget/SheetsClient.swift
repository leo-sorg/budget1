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

    // MARK: - GET Methods (new)
    
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

// MARK: - API Models

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
