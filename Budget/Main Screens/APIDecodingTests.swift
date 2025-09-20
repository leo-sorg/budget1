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

    @Test("Category emoji basic case")
    func categoryEmojiBasic() throws {
        let json = """
        {
            "success": true,
            "message": "ok",
            "total": 1,
            "data": [
                { "remoteID": "cat-1", "name": "Food", "emoji": "🍕", "sortIndex": 0, "isIncome": false, "timestamp": "2025-09-19T00:00:00Z" }
            ]
        }
        """
        let resp = try JSONDecoder().decode(APICategoriesResponse.self, from: Data(json.utf8))
        #expect(resp.data.count == 1)
        #expect(resp.data[0].emoji == "🍕")
        #expect(resp.data[0].isIncome == false)
    }
}
