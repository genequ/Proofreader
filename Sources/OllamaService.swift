import Foundation
import Alamofire

actor OllamaService {
    private var baseURL: String
    
    init(baseURL: String = "http://127.0.0.1:11434") {
        self.baseURL = baseURL
    }
    
    func updateBaseURL(_ url: String) {
        self.baseURL = url
    }
    
    func listModels() async throws -> [String] {
        let url = "\(baseURL)/api/tags"
        
        let response = await AF.request(url, method: .get)
            .serializingDecodable(OllamaModelsResponse.self)
            .response
        
        switch response.result {
        case .success(let modelsResponse):
            return modelsResponse.models.map { $0.name }
        case .failure(let error):
            throw error
        }
    }
    
    func generate(model: String, prompt: String) async throws -> String {
        let url = "\(baseURL)/api/generate"
        let parameters: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        let response = await AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .serializingDecodable(OllamaGenerateResponse.self)
            .response
        
        switch response.result {
        case .success(let generateResponse):
            return generateResponse.response
        case .failure(let error):
            throw error
        }
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
}

struct OllamaGenerateResponse: Codable {
    let response: String
}