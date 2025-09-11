import Foundation

struct SheetsClient {
    let baseURL: URL
    let secret: String

    struct Response: Sendable {
        let status: Int
        let body: String
    }

    func postTransaction(remoteID: String, amount: Decimal, date: Date,
                         categoryName: String?, paymentName: String?, note: String?,
                         completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "transaction",
            "remoteID": remoteID,
            "amount": (amount as NSDecimalNumber).doubleValue,
            "dateISO": DateFormatter.iso8601.string(from: date),
            "categoryName": categoryName ?? "",
            "paymentName": paymentName ?? "",
            "note": note ?? ""
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

    func postPayment(remoteID: String, name: String, sortIndex: Int,
                     completion: @escaping (Response) -> Void = { _ in }) {
        let payload: [String: Any] = [
            "type": "paymentMethod",
            "remoteID": remoteID,
            "name": name,
            "sortIndex": sortIndex
        ]
        postJSON(payload, completion: completion)
    }

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
