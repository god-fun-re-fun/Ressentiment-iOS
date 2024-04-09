//
//  MQTTManager.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/8/24.
//

import SwiftUI
import CocoaMQTT

final class MQTTManager: ObservableObject {
    private var mqtt: CocoaMQTT?
    @Published var receivedMessage: String = ""

    init() {
        setupMQTT()
    }

    private func setupMQTT() {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)

        mqtt = CocoaMQTT(clientID: clientID, host: "192.168.172.230", port: 8884)
        mqtt?.keepAlive = 60
        //        mqtt?.willMessage = CocoaMQTTMessage(topic: "topic", string: "==== Connected iOS")
        mqtt?.autoReconnect = true
        mqtt?.allowUntrustCACertificate = true
        mqtt?.delegate = self
        mqtt?.connect()
    }

    func subscribe(to topic: String) {
        if (self.mqtt?.connState == .connected) {
            print("✅ topic 구독 성공")

            self.mqtt?.didReceiveMessage = { mqtt, message, id in
                print("Message received in topic \(message.topic) with payload \(message.string!)")
            }

        }else{
            print("❌ 구독 연결이 끊어져있습니다.")
        }
    }

    func publish(topic: String, message: String) {
        mqtt?.publish(topic, withString: message)
    }
}

extension MQTTManager: CocoaMQTTDelegate {
    /// MQTT 연결 완료 콜백
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {

        print(":::: didConnectAck ::::")

        if ack == .accept{
            print(":::: 👏didConnectAck ::::\n")
            print(":::: 👏브로커 연결 완료 ::::\n")
            self.mqtt?.subscribe("topic", qos: CocoaMQTTQoS.qos1)
        }
    }

    /// 발행 메시지
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }

    /// 발행 완료
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }

    /// 구독한 토픽 메시지 Receive
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        // print(":::: 📥didReceiveMessage ::::")
        // print(":::: 📥message : \(message.string ?? "nil msg") , id: \(id)")

        // receivedMessage = message.string ?? "No didReceiveMessage"
        receivedMessage = message.string ?? "No didReceiveMessage"
        print("=== receivedMessage: \(receivedMessage)")
    }

    func handleReceivedMessage(_ message: String) {
        // 받은 메시지에 대한 처리 로직
        print("메시지 처리: \(message)")
    }
    /// 토픽 구독 성공 콜백
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print(":::: didSubscribeTopics ::::")
        print(":::: success: \(success)")
        print(":::: failed: \(failed)")
        self.mqtt?.didReceiveMessage = { mqtt, message, id in
            print("Message received in topic \(message.topic) with payload \(message.string!)")
        }
    }

    /// 토픽 구독 취소 콜백
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print(":::: didUnsubscribeTopics ::::")
        print(":::: topics: \(topics)")
    }

    /// 연결 상태 체크 ping
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        //        print(":::: mqttDidPing ::::")
        //        print(":::: mqtt 연결상태 : \(mqtt.connState.description)\n")
    }

    /// 연결 상태 체크 pong
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        //        print(":::: mqttDidReceivePong 1 ::::")
        //        print(":::: mqtt 연결상태 : \(mqtt.connState.description)\n")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        //        print(":::: mqttDidReceivePong 2 ::::")
        //        print(":::: err : \(err?.localizedDescription ?? "error...")")
        //        print(":::: err : \(String(describing: err))")
    }
}
