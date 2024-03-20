//
//  ColorResponse.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/10/24.
//

import Foundation

struct ColorResponse: Codable {
    let code, message: String
    let data: DataClass
    let isSuccess: Bool
}

// MARK: - DataClass
struct DataClass: Codable {
    let b: Double
    let r: Double
    let g: Double
}
