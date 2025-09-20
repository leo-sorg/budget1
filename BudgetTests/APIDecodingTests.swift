import XCTest
@testable import Budget

final class APIDecodingTests: XCTestCase {

    func testPaymentEmojiEmptyString() throws {
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
        XCTAssertEqual(resp.data.count, 1)
        XCTAssertEqual(resp.data[0].emoji, "")
        XCTAssertEqual(resp.data[0].sortIndex, 0)
    }

    func testPaymentEmojiNumberZero() throws {
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
        XCTAssertEqual(resp.data.count, 1)
        XCTAssertEqual(resp.data[0].emoji, "")
        XCTAssertEqual(resp.data[0].sortIndex, 2)
    }

    func testPaymentEmojiValid() throws {
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
        XCTAssertEqual(resp.data.count, 1)
        XCTAssertEqual(resp.data[0].emoji, "💵")
        XCTAssertEqual(resp.data[0].sortIndex, 1)
    }

    func testCategoryEmojiCases() throws {
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
        XCTAssertEqual(resp1.data.first?.emoji, "🍕")

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
        XCTAssertEqual(resp2.data.first?.emoji, "")
        XCTAssertEqual(resp2.data.first?.sortIndex, 1)
    }
}
