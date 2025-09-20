import Testing
@testable import Budget

@Suite("API model decoding tolerance")
struct APIDecodingTests {

    @Test("Payment method emoji as empty string")
    func paymentEmojiEmptyString() throws {
        let json = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "pm-1", "name": "Card", "emoji": "", "sortIndex": 0, "timestamp": "2025-09-19T00:00:00Z" }
            ]
        }
        """
        let resp = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: Data(json.utf8))
        #expect(resp.data.count == 1)
        #expect(resp.data[0].emoji == "")
        #expect(resp.data[0].sortIndex == 0)
    }

    @Test("Payment method emoji as number 0")
    func paymentEmojiNumberZero() throws {
        let json = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "pm-2", "name": "Pix", "emoji": 0, "sortIndex": 2, "timestamp": null }
            ]
        }
        """
        let resp = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: Data(json.utf8))
        #expect(resp.data.count == 1)
        // Our tolerant decoder converts numeric emoji to ""
        #expect(resp.data[0].emoji == "")
        #expect(resp.data[0].sortIndex == 2)
    }

    @Test("Payment method emoji as real emoji")
    func paymentEmojiValid() throws {
        let json = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "pm-3", "name": "Cash", "emoji": "💵", "sortIndex": 1, "timestamp": "2025-09-19T00:00:00Z" }
            ]
        }
        """
        let resp = try JSONDecoder().decode(APIPaymentMethodsResponse.self, from: Data(json.utf8))
        #expect(resp.data.count == 1)
        #expect(resp.data[0].emoji == "💵")
        #expect(resp.data[0].sortIndex == 1)
    }

    @Test("Category emoji basic and tolerant")
    func categoryEmojiCases() throws {
        // Valid emoji
        let json1 = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "cat-1", "name": "Food", "emoji": "🍕", "sortIndex": 0, "isIncome": false, "timestamp": "2025-09-19T00:00:00Z" }
            ]
        }
        """
        let resp1 = try JSONDecoder().decode(APICategoriesResponse.self, from: Data(json1.utf8))
        #expect(resp1.data.first?.emoji == "🍕")

        // Numeric emoji -> tolerated as ""
        let json2 = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "cat-2", "name": "Transport", "emoji": 0, "sortIndex": "1", "isIncome": false, "timestamp": null }
            ]
        }
        """
        let resp2 = try JSONDecoder().decode(APICategoriesResponse.self, from: Data(json2.utf8))
        #expect(resp2.data.first?.emoji == "")
        #expect(resp2.data.first?.sortIndex == 1)
    }
}
