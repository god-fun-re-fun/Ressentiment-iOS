//
//  UIKitTestModel.swift
//  Scene
//
//  Created by 이조은 on 3/19/24.
//

import UIKit
import SwiftUI

import AVFoundation
import SceneKit

import CocoaMQTT

class SceneViewController: UIViewController {
    var scene: SCNScene?
    var allowsCameraControl: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let scnView = SCNView()
        // scnView의 크기를 부모 뷰의 80%로 설정
        let viewWidth = self.view.frame.width * 0.25
        let viewHeight = self.view.frame.height * 0.25
        // scnView의 프레임을 계산하여 중앙에 위치시킴
        scnView.frame = CGRect(x: 0,
                               y: 0,
                               width: viewWidth+10,
                               height: viewHeight)
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clear
        scnView.allowsCameraControl = allowsCameraControl
        scnView.autoenablesDefaultLighting = true
        self.view.addSubview(scnView)
    }
}

struct SceneViewRepresentable: UIViewControllerRepresentable {
    var scene: SCNScene?
    var allowsCameraControl: Bool

    func makeUIViewController(context: Context) -> SceneViewController {
        let viewController = SceneViewController()
        viewController.scene = scene
        viewController.allowsCameraControl = allowsCameraControl

        let lightNode1 = SCNNode()
        lightNode1.light = SCNLight()
        lightNode1.light?.type = .omni
        lightNode1.position = SCNVector3(x: 0, y: 20, z: 0)
        viewController.scene?.rootNode.addChildNode(lightNode1)

        return viewController
    }

    func updateUIViewController(_ uiViewController: SceneViewController, context: Context) {
        uiViewController.scene = scene
        uiViewController.view.setNeedsLayout()
    }
}

struct MainView: View {
    @State var rotationDuration: TimeInterval = 80.0
    @ObservedObject var viewModel = SharedViewModel()

    var body: some View {
        VStack {
            TestModelUIkit(rotationDuration: $rotationDuration, viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
        }
    }

}

struct TestModelUIkit: View {
    @State var glassHead: SCNScene? = SCNScene(named: "GlassHead.scn")
    @State var crackScene = SCNScene(named: "Concrete-Smooth.usdz")

    @State private var timer: Timer? = nil
    @State var velocity: CGFloat = 20
    @Binding var rotationDuration: TimeInterval
    @State var fixPI: CGFloat = .pi*8

    @State var red: CGFloat = 0.5
    @State var green: CGFloat = 0.5
    @State var blue: CGFloat = 0.5
    let alpha: CGFloat = 1.0

    @State private var isSceneViewVisible = true
    @State private var isGIFViewVisible = false

    @State var audioPlayer: AVAudioPlayer?

    @ObservedObject var mqttManager = MQTTManager()

    let endPoinValue = 92
    @State var endPoint = 92
    @State var alphaa: CGFloat = 2
    @State var beta: CGFloat = 100
    @State var gamma: Int = 1

    @State var redOnBlue: Bool = false
    @State var redOnGreen: Bool = false
    @State var redOnGray: Bool = false

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel = SharedViewModel()

    var body: some View {
        ZStack {
            if isGIFViewVisible {
                GIFViewRepresentable(particleColor: UIColor(red: self.red, green: self.green, blue: self.blue, alpha: 1.0))
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3))
                    .onTapGesture {
                        // 현재 뷰 닫기
                        presentationMode.wrappedValue.dismiss()
                        viewModel.mainOn = false
                        viewModel.startOn = true
                    }
                    .onDisappear {
                        stopMusic()
                        timeStop()
                    }
            } else {
                SceneView(scene: crackScene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: UIScreen.main.bounds.width*2.5, height: UIScreen.main.bounds.height*2.5)
                    .position(x: UIScreen.main.bounds.width/3, y: UIScreen.main.bounds.height/3)
                    .onAppear {
                        setupScene()
                    }
                    .onDisappear {
                        stopMusic()
                        timeStop()
                    }
                    .onReceive(mqttManager.$receivedMessage) { newValue in
                        print("📢📢📢📢=== Here: \(newValue)")

                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                            print("== no event 2 🫥 ==")
                            rotationAction(glassVector: SCNVector3(1, 0, 0), headVector: SCNVector3(-1, 0, 0))

                            changeAnimation(0.7, 0.7, 0.7)

                            self.endPoint -= 1

                            if endPoint <= 1 {
                                print("=== The End handleDragChange===")
                                changeView()
                            }
                        }

                        receivedMessage(receivedMessage: mqttManager.receivedMessage)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { change in
                                handleDragChange(change: change)

                                print("==== 🔊 Duration: \(self.rotationDuration)")
                            }
                    )
            }
            if isSceneViewVisible && !isGIFViewVisible {
                SceneViewRepresentable(scene: glassHead, allowsCameraControl: true)
                    .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.height / 4)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isGIFViewVisible)
    }

    // 모든 초기 설정을 처리하는 함수
    private func setupScene() {
        // 음악 재생 및 초기 애니메이션 적용
        self.rotationDuration = 80.0
        self.endPoint = endPoinValue

        musicRollingBall()
        applyInitialAnimations()
        receivedMessage(receivedMessage: mqttManager.receivedMessage)
    }

    // 초기 애니메이션 적용
    private func applyInitialAnimations() {
        // 초기 애니메이션 적용 로직
        let rotationAction = SCNAction.rotate(by: .pi*15, around: SCNVector3(1, 0, 0), duration: 100)
        let rotationAction2 = SCNAction.rotate(by: .pi*15, around: SCNVector3(-1, 0, 0), duration: 100/2+100/3)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
        changeAnimation(0.7, 0.7, 0.7)
    }

    // MQTT 통신
    func receivedMessage(receivedMessage: String) {
        if (mqttManager.receivedMessage) == "up" {
            upRotation()
        } else if (mqttManager.receivedMessage) == "down" {
            downRotation()
        } else if (mqttManager.receivedMessage) == "left" {
            rightRotation()
        } else if (mqttManager.receivedMessage) == "right" {
            leftRotation()
        } else if (mqttManager.receivedMessage) == "up-right" {
            upRightRotation()
        } else if (mqttManager.receivedMessage) == "up-left" {
            upLeftRotation()
        } else if (mqttManager.receivedMessage) == "down-right" {
            downRightRotation()
        } else if (mqttManager.receivedMessage) == "down-left" {
            downLeftRotation()
        }

        print("==== endPoint: \(self.endPoint)")

        if endPoint <= 1 {
            print("=== The End Arduino===")
            changeView()
        }
    }

    // 드래그 이벤트 핸들링
    private func handleDragChange(change: DragGesture.Value) {
        // 사용자가 드래그를 시작하면, 드래그의 방향과 거리에 따라 애니메이션을 조정합니다.
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            print("== no event 1 🫥 ==")
            rotationAction(glassVector: SCNVector3(1, 0, 0), headVector: SCNVector3(-1, 0, 0))

            changeAnimation(0.7, 0.7, 0.7)

            self.endPoint -= Int(beta/self.rotationDuration)

            if endPoint <= 1 {
                print("=== The End handleDragChange===")
                changeView()
            }
        }

        // musicRollingBall()

        if change.translation.height > 0 {
            upRotation()
        } else if change.translation.height < 0 {
            downRotation()
        } else if change.translation.width > 0 {
            rightRotation()
        } else if change.translation.width < 0 {
            leftRotation()
        }

        print("==== endPoint: \(self.endPoint)")

        if endPoint <= 1 {
            print("=== The End TouchEvent===")
            changeView()
        }
    }

    private func timeStop() {
        // 사용자가 드래그를 끝내면, 필요한 경우 타이머를 초기화하거나, 애니메이션을 정지합니다.
        self.timer?.invalidate()
        self.timer = nil
        print("=== disappear")
    }

    private func rotationAction(glassVector: SCNVector3, headVector: SCNVector3) {
        let rotationAction = SCNAction.rotate(by: fixPI, around: glassVector, duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: fixPI, around: headVector, duration: self.rotationDuration/2+self.rotationDuration/3)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
    }

    // 위로 움직임
    func upRotation() {
        if self.rotationDuration >= 75 {
            self.rotationDuration = 75
        } else {
            self.rotationDuration += alphaa
        }

        self.endPoint -= Int(beta/self.rotationDuration) + Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(-1, 0, 0), headVector: SCNVector3(1, 0, 0))
        print("===== blue ")

        if (self.blue >= 0.9 && !self.redOnBlue) {
            self.redOnBlue = true
        } 
        else if (self.redOnBlue && (self.red-self.blue) >= 0.1 ) {
            self.redOnBlue = false
        }

        if (self.redOnBlue) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🔵 blue 🔵")
            changeAnimation(0.24, 0.47, 1)
        }

        print("⬆️ veolocity: \(fixPI/self.rotationDuration)")
    }

    // 아래 움직임
    func downRotation() {
        if self.rotationDuration <= 10 {
            self.rotationDuration = 10
        } else {
            self.rotationDuration -= alphaa
        }

        self.endPoint -= Int(beta/(self.rotationDuration))

        rotationAction(glassVector: SCNVector3(1, 0, 0), headVector: SCNVector3(-1, 0, 0))

        let averageColorValue = (self.red + self.green + self.blue) / 3

        if (averageColorValue >= 0.63 && !self.redOnGray) {
            self.redOnGray = true
        } else if (self.redOnGray && (self.red-self.blue) >= 0.15 ) {
            self.redOnGreen = false
        }

        if (self.redOnGray) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🔘 gray 🔘")
            changeAnimation(0.66, 0.66, 0.66)
        }

        print("⬇️ veolocity: \(fixPI/self.rotationDuration)")
    }

    // 오른쪽으로 움직임
    func rightRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(0, -1, 0), headVector: SCNVector3(0, 1, 0))
        
        if (self.green >= 0.9 && !self.redOnGreen) {
            self.redOnGreen = true
        } else if (self.redOnBlue && (self.red-self.green) >= 0.4 ) {
            self.redOnGreen = false
        }

        if (self.redOnGreen) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🟢 green 🟢")
            changeAnimation(0.24, 1, 0.24)
        }

        print("➡️ veolocity: \(fixPI/self.rotationDuration)")
    }

    // 왼쪽으로 움직임
    func leftRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(0, 1, 0), headVector: SCNVector3(0, -1, 0))

        if (self.green >= 0.9 && !self.redOnGreen) {
            self.redOnGreen = true
        } else if (self.redOnBlue && (self.red-self.green) >= 0.4 ) {
            self.redOnGreen = false
        }

        if (self.redOnGreen) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🟢 green 🟢")
            changeAnimation(0.24, 1, 0.24)
        }

        print("⬅️")
    }

    // MARK: - 대각선 움직임
    func upLeftRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(-1, -1, 0), headVector: SCNVector3(1, 1, 0))

        if (self.blue >= 0.9 && !self.redOnBlue) {
            self.redOnBlue = true
        }
        else if (self.redOnBlue && (self.red-self.blue) >= 0.1 ) {
            self.redOnBlue = false
        }

        if (self.redOnBlue) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🔵 blue 🔵")
            changeAnimation(0.24, 0.47, 1)
        }
    }
    func upRightRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(-1, 1, 0), headVector: SCNVector3(1, -1, 0))

        if (self.blue >= 0.9 && !self.redOnBlue) {
            self.redOnBlue = true
        }
        else if (self.redOnBlue && (self.red-self.blue) >= 0.1 ) {
            self.redOnBlue = false
        }

        if (self.redOnBlue) {
            // UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
            print("🔴 red 🔴")
            changeAnimation(1, 0.24, 0.24)
        } else {
            print("🔵 blue 🔵")
            changeAnimation(0.24, 0.47, 1)
        }
    }
    func downLeftRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(1, -1, 0), headVector: SCNVector3(-1, 1, 0))
    }
    func downRightRotation() {
        self.endPoint -= Int(beta/self.rotationDuration)

        rotationAction(glassVector: SCNVector3(1, 1, 0), headVector: SCNVector3(-1, -1, 0))
    }

    // view 전환 및 api post
    func changeView() {
        // print("red: \(self.red) | green: \(self.green) | blue: \(self.blue)")
        self.endPoint = endPoinValue
        withAnimation(.easeOut(duration: 0.7)) {
            isGIFViewVisible = true
        }
        isSceneViewVisible = false
        stopMusic()
        RessentimentService().postColor(parameters: ["R":"\(self.red)", "G":"\(self.green)", "B":"\(self.blue)"]) { result in
            switch result {
            case .success(let colorResponse):
                print("=== success: \(colorResponse)")
            case .failure(let error):
                print("API Error: \(error)")
            }
        }
    }

    // 음악 Play 함수
    func musicRollingBall() {
        if let bundlePath = Bundle.main.path(forResource: "rollingBall.mp3", ofType: nil),
           let music = URL(string: bundlePath) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: music)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                audioPlayer?.numberOfLoops = -1
            } catch {
                print("음악 파일을 재생할 수 없습니다.")
            }
        }
    }

    func stopMusic() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            // 재생 위치를 초기화
            audioPlayer?.currentTime = 0
            print("=== 음악 멈춤")
        }
    }

    // 조명 생성 함수
    func createLightNode(color: UIColor, position: SCNVector3) -> SCNNode {
        let light = SCNLight() // 조명 인스턴스 생성
        light.type = .omni // 전방향 조명
        light.color = color // 조명의 색상 설정

        let lightNode = SCNNode() // 조명 노드 생성
        lightNode.light = light // 노드에 조명 추가
        lightNode.position = position // 조명의 위치 설정

        return lightNode
    }

    // 색상 변경 함수
    func changeColor(_ goalRed: CGFloat, _ goalGreen: CGFloat, _ goalBlue: CGFloat) -> UIColor {
        // print("=== color change func 🎨 ===")
        let newRed = self.red + (goalRed - self.red)/velocity
        self.red = newRed
        let newGreen = self.green + (goalGreen - self.green)/velocity
        self.green = newGreen
        let newBlue = self.blue + (goalBlue - self.blue)/velocity
        self.blue = newBlue

        let newColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        print("==== red-blue: \(red-blue)")
        // print("=== UIColore: \(newColor)")

        return newColor
    }

    // 색상 변경 반영하면서 애니메이션 적용
    func changeAnimation(_ goalRed: CGFloat, _ goalGreen: CGFloat, _ goalBlue: CGFloat) {
        //print("=== changeAnimation func 📽️ ===")
        glassHead?.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.materials.forEach { material in
                // Material_001 머테리얼만 찾아서 색상 변경 적용
                if material.name == "Material_001" {

                    let newColor = self.changeColor(goalRed, goalGreen, goalBlue)

                    // SCNTransaction을 사용하여 애니메이션 적용
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5 // 애니메이션 지속 시간 설정
                    material.diffuse.contents = newColor
                    // print("🌀🌀newColor: \(newColor)")
                    SCNTransaction.commit()
                }
            }
        }
    }
}

struct UIKitTestModel_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
