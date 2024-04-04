//
//  RessentimentService.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/10/24.
//

import Foundation

class RessentimentService {
    func postColor(parameters: [String : String], completion: @escaping (Result<ColorResponse, NetworkError>) -> Void) {
        // ✅ paramters 를 JSON 으로 encode.
        let url = URL(string: "http://15.164.149.234:8080/interaction/result")
        let requestBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])

        print("=== RessentimentService2")

        guard let url = url else {
            return completion(.failure(.pathErr))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // ✅ request body 추가
        request.httpBody = requestBody

        print("=== requestBody: \(parameters)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return completion(.failure(.responseDecodingErr))
            }
            do {
                let colorResponse = try JSONDecoder().decode(ColorResponse.self, from: data)
                completion(.success(colorResponse))
                print("=== SUCCESS: \(colorResponse)")
            } catch {
                print("Decoding Error: \(error)")
                completion(.failure(.responseDecodingErr))
            }
        }.resume()

    }
}
