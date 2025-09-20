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

    // MARK: - GET Methods
    
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
                    print("❌ Transactions decode error: \(error)")
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
        
        print("🔗 Categories URL: \(url.absoluteString)")
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APICategoriesResponse.self, from: data)
                    print("✅ Successfully decoded \(apiResponse.data.count) categories")
                    completion(.success(apiResponse))
                } catch {
                    print("❌ Categories decode error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Raw categories response: \(responseString)")
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
        
        print("🔗 Payment Methods URL: \(url.absoluteString)")
        
        performGETRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let apiResponse = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: data)
                    print("✅ Successfully decoded \(apiResponse.data.count) payment methods")
                    completion(.success(apiResponse))
                } catch {
                    print("❌ Payment Methods decode error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Raw payment methods response: \(responseString)")
                    }
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
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📈 HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    completion(.failure(SheetsError.httpError(httpResponse.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(SheetsError.noData))
                return
            }
            
            // Check if response is HTML (error page) instead of JSON
            if let responseString = String(data: data, encoding: .utf8),
               responseString.lowercased().contains("<html") {
                print("❌ Received HTML instead of JSON: \(responseString.prefix(200))")
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
            print("📤 POST response: status=\(status) body=\(text)")
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

// MARK: - FIXED API Models - Simple camelCase structure

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
    
    // Simple camelCase - matches what the fixed script returns
    enum CodingKeys: String, CodingKey {
        case remoteID
        case name
        case emoji
        case sortIndex
        case isIncome
        case timestamp
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
    
    // Simple camelCase - matches what the fixed script returns
    enum CodingKeys: String, CodingKey {
        case remoteID
        case name
        case emoji
        case sortIndex
        case timestamp
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