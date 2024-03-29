//
//  XYZResponse.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/26/24.
//

import Foundation

// MARK: - XYZResponse
struct XYZResponse: Codable {
    let sensor: Sensor
}

// MARK: - Sensor
struct Sensor: Codable {
    let x, y, z: Int
}
