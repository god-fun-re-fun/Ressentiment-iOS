//
//  XYZStore.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/26/24.
//

import Foundation

import Firebase
import FirebaseDatabaseSwift
import FirebaseDatabaseInternal

class XYZStore: ObservableObject {
    @Published var sensors: [Sensor] = []

    var ref: DatabaseReference!

    func getRealtimeDatabase() {
        // Firebase Database의 루트 참조를 초기화
        ref = Database.database().reference()

        // "sensor" 경로의 데이터에 대한 실시간 업데이트를 관찰
        ref.child("sensor").observe(.value, with: { snapshot in
            // snapshot이 감지되면 여기의 코드가 실행됩니다.
            // snapshot.value를 통해 데이터를 가져올 수 있습니다.

            guard let value = snapshot.value as? [String: Any] else {
                print("데이터를 가져오는 데 실패했습니다.")
                return
            }

            // x, y, z 값을 읽어옵니다.
            if let xValue = value["x"] as? Int,
               let yValue = value["y"] as? Int,
               let zValue = value["z"] as? Int {
                print("x: \(xValue), y: \(yValue), z: \(zValue)")
            } else {
                print("올바른 데이터 형식이 아닙니다.")
            }
        }) { error in
            print(error.localizedDescription)
        }
    }
}
