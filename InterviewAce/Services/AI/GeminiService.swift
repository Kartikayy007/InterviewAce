import Foundation
import Combine

// Represents different AI service states
enum AIServiceState {
    case idle
    case processing
    case success(String)
    case error(String)
}

// Request model for Gemini API
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig
    
    struct GeminiContent: Codable {
        let parts: [ContentPart]
        let role: String
    }
    
    struct ContentPart: Codable {
        let text: String
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double
        let maxOutputTokens: Int
        let topP: Double
    }
} 

// Response model for Gemini API
struct GeminiResponse: Codable {
    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?
    let error: GeminiError?
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            let role: String
            
            struct Part: Codable {
                let text: String
            }
        }
    }
    
    struct PromptFeedback: Codable {
        let safetyRatings: [SafetyRating]
        
        struct SafetyRating: Codable {
            let category: String
            let probability: String
        }
    }
    
    struct GeminiError: Codable {
        let code: Int
        let message: String
        let status: String
    }
}

// Service to interact with Gemini API
class GeminiService: ObservableObject {
    @Published var state: AIServiceState = .idle
    
    private var apiKey: String = ""
    
    // Updated to use Gemini 2.0 Flash model
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-001:generateContent"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("GeminiService: Initialized")
    }
    
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    // Process a query and get a response from Gemini
    func processQuery(_ query: String) {
        print("GeminiService: Processing query: \(query)")
        
        // Update state to indicate processing
        self.state = .processing
        
        // Prepare the request body
        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.GeminiContent(
                    parts: [GeminiRequest.ContentPart(text: query)],
                    role: "user"
                )
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 800,
                topP: 0.95
            )
        )
        
        guard let requestData = try? JSONEncoder().encode(requestBody) else {
            print("GeminiService: Failed to encode request")
            self.state = .error("Failed to encode request")
            return
        }
        
        // Create the URL with API key
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            print("GeminiService: Invalid URL")
            self.state = .error("Invalid URL")
            return
        }
        
        print("GeminiService: Sending request to URL: \(url.host ?? "unknown host")")
        
        // Set up the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        // Make the network request
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("GeminiService: Received response with status code: \(httpResponse.statusCode)")
                    
                    // Check for HTTP errors
                    guard (200...299).contains(httpResponse.statusCode) else {
                        // Try to get more info from the error response
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorMessage = errorJson["error"] as? [String: Any],
                           let message = errorMessage["message"] as? String {
                            throw NSError(domain: "GeminiError", code: httpResponse.statusCode, 
                                          userInfo: [NSLocalizedDescriptionKey: message])
                        } else {
                            throw NSError(domain: "GeminiError", code: httpResponse.statusCode,
                                          userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                        }
                    }
                }
                return data
            }
            .decode(type: GeminiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("GeminiService: Request failed: \(error.localizedDescription)")
                        self?.state = .error("Request failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if let error = response.error {
                        print("GeminiService: API Error: \(error.message)")
                        self?.state = .error("API Error: \(error.message)")
                        return
                    }
                    
                    guard let candidates = response.candidates,
                          let firstCandidate = candidates.first,
                          let firstPart = firstCandidate.content.parts.first else {
                        print("GeminiService: No response from AI")
                        self?.state = .error("No response from AI")
                        return
                    }
                    
                    print("GeminiService: Received successful response")
                    self?.state = .success(firstPart.text)
                }
            )
            .store(in: &cancellables)
    }
    
    // Cancel ongoing requests
    func cancelRequest() {
        print("GeminiService: Cancelling request")
        cancellables.forEach { $0.cancel() }
        state = .idle
    }
}
