//
//  RessentimentService.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/10/24.
//

import Foundation

class RessentimentService {
    func postColor(parameters: [String : Any], completion: @escaping (Result<ColorResponse, NetworkError>) -> Void) {
        // ✅ paramters 를 JSON 으로 encode.
        let url = URL(string: "http://15.164.149.234:8080/interaction/result")
        let requestBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])

        print("=== RessentimentService2")
        //
        //        guard let url = URL(string: "http://15.164.149.234:8080/interaction/result") else {
        //            print("Error: cannot create URL")
        //            return
        //        }
        //
        //        var request = URLRequest(url: url)
        //        request.httpMethod = "POST"
        //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //        // ✅ request body 추가
        //        request.httpBody = requestBody

        //        let defaultSession = URLSession(configuration: .default)
        //
        //        defaultSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
        //            guard error == nil else {
        //                print("Error occur: error calling POST - \(String(describing: error))")
        //                return
        //            }
        //
        //            guard let data = data, let response = response as? HTTPURLResponse, (200..<300) ~= response.statusCode else {
        //                print("Error: HTTP request failed")
        //                return
        //            }
        //
        //            guard let output = try? JSONDecoder().decode(ColorResponse.self, from: data) else {
        //                print("Error: JSON data parsing failed")
        //                return
        //            }
        //        }.resume()

        guard let url = url else {
            return completion(.failure(.pathErr))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // ✅ request body 추가
        request.httpBody = requestBody

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return completion(.failure(.responseDecodingErr))
            }
            let colorResponse = try? JSONDecoder().decode(ColorResponse.self, from: data)
            if let colorResponse = colorResponse {
                completion(.success(colorResponse))
            } else {
                completion(.failure(.responseErr))
            }
        }.resume()
    }
}
