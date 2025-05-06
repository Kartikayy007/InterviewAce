import Foundation

/// Model for the enhanced AI response format with text and code cards
struct AIResponseModel: Codable {
    let text: String
    let code_cards: [CodeCard]?

    struct CodeCard: Codable, Identifiable, Equatable {
        let title: String
        let language: String
        let code: String

        // Computed property to satisfy Identifiable protocol
        var id: String {
            // Create a unique ID based on title and code
            return "\(title)-\(code.hashValue)"
        }

        // Implement Equatable
        static func == (lhs: CodeCard, rhs: CodeCard) -> Bool {
            return lhs.id == rhs.id
        }
    }

    // Helper method to parse JSON string into AIResponseModel
    static func parse(from jsonString: String) -> AIResponseModel? {
        print("AIResponseModel: Attempting to parse JSON: \(jsonString.prefix(100))...")

        // Clean up the JSON string if needed
        var cleanedJson = jsonString

        // If the string starts with "json", remove it
        if cleanedJson.hasPrefix("json") {
            cleanedJson = cleanedJson.replacingOccurrences(of: "^json\\s*", with: "", options: .regularExpression)
        }

        // Remove any backticks that might be surrounding the JSON (common in markdown code blocks)
        if cleanedJson.hasPrefix("```") {
            cleanedJson = cleanedJson.replacingOccurrences(of: "^```json\\s*", with: "", options: .regularExpression)
            cleanedJson = cleanedJson.replacingOccurrences(of: "^```\\s*", with: "", options: .regularExpression)
            cleanedJson = cleanedJson.replacingOccurrences(of: "\\s*```$", with: "", options: .regularExpression)
        }

        // Ensure we have a valid JSON object
        if !cleanedJson.hasPrefix("{") || !cleanedJson.hasSuffix("}") {
            print("AIResponseModel: JSON doesn't start with { or end with }, attempting to extract JSON object")

            // Try to extract the JSON object
            if let startRange = cleanedJson.range(of: "{"),
               let endRange = cleanedJson.range(of: "}", options: .backwards) {
                let startIndex = startRange.lowerBound
                let endIndex = endRange.upperBound

                if startIndex < endIndex {
                    cleanedJson = String(cleanedJson[startIndex..<endIndex])
                    print("AIResponseModel: Extracted JSON object: \(cleanedJson.prefix(100))...")
                }
            }
        }

        // Try to convert the string to data
        guard let data = cleanedJson.data(using: .utf8) else {
            print("AIResponseModel: Failed to convert string to data")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(AIResponseModel.self, from: data)
            print("AIResponseModel: Successfully parsed JSON with \(response.code_cards?.count ?? 0) code cards")

            // Debug the code cards
            if let codeCards = response.code_cards {
                print("AIResponseModel: Found \(codeCards.count) code cards:")
                for (index, card) in codeCards.enumerated() {
                    print("  Card \(index+1): \(card.title) (\(card.language)) - \(card.code.count) chars")
                }
            } else {
                print("AIResponseModel: No code cards found in the response")
            }

            return response
        } catch {
            print("AIResponseModel: Error parsing AI response: \(error)")

            // Try a more lenient approach - manually extract the fields
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("AIResponseModel: Attempting manual extraction from JSON object")

                    // Extract the text field
                    let text = jsonObject["text"] as? String ?? "No text found in response"

                    // Extract the code_cards array
                    var codeCards: [CodeCard]? = nil

                    if let cardsArray = jsonObject["code_cards"] as? [[String: Any]] {
                        codeCards = cardsArray.compactMap { cardDict -> CodeCard? in
                            guard let title = cardDict["title"] as? String,
                                  let language = cardDict["language"] as? String,
                                  let code = cardDict["code"] as? String else {
                                return nil
                            }

                            return CodeCard(title: title, language: language, code: code)
                        }

                        print("AIResponseModel: Manually extracted \(codeCards?.count ?? 0) code cards")
                    }

                    return AIResponseModel(text: text, code_cards: codeCards)
                }
            } catch {
                print("AIResponseModel: Error during manual JSON extraction: \(error)")
            }

            // If all parsing attempts fail, return a simple text-only response
            print("AIResponseModel: Falling back to text-only response")
            return AIResponseModel(text: cleanedJson, code_cards: nil)
        }
    }
}
