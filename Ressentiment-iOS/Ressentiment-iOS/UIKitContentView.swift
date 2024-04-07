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

import Firebase
import FirebaseDatabaseSwift
import FirebaseDatabaseInternal

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
    @State var rotationDuration: TimeInterval = 70.0

    var body: some View {
        VStack {
            TestModelUIkit(rotationDuration: $rotationDuration)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
        }
    }
}

struct TestModelUIkit: View {
    @State var glassHead: SCNScene? = SCNScene(named: "GlassHead.scn")
    @State var crackScene = SCNScene(named: "Concrete-Smooth.usdz")

    @State private var timer: Timer? = nil
    @State var velocity: CGFloat = 30
    @Binding var rotationDuration: TimeInterval

    @State var red: CGFloat = 0.5
    @State var green: CGFloat = 0.5
    @State var blue: CGFloat = 0.5
    let alpha: CGFloat = 1.0

    @State var endPoint = 100
    
    @Environment(\.presentationMode) var presentationMode

    // DatabaseReference 인스턴스 생성 및 Firebase Database의 루트 참조를 초기화
    var ref: DatabaseReference? = Database.database().reference()

    @State private var isSceneViewVisible = true
    @State private var isGIFViewVisible = false

    @State var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            if isGIFViewVisible {
                GIFViewRepresentable(particleColor: UIColor(red: self.red, green: self.green, blue: self.blue, alpha: 1.0))
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3)) 
                    .onTapGesture {
                        // 여기에 뷰를 닫는 코드를 추가합니다.
                        presentationMode.wrappedValue.dismiss()
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
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { change in
                                handleDragChange(change: change)
                            }
                            .onEnded { _ in
                                handleDragEnd()
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
        musicRollingBall()
        applyInitialAnimations()
        getRealtimeDatabase()
    }

    // 초기 애니메이션 적용
    private func applyInitialAnimations() {
        // 초기 애니메이션 적용 로직
        if let glassHeadScene = self.glassHead {
            let headRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(1, 0, 0), duration: rotationDuration))
            glassHeadScene.rootNode.runAction(headRotationAction)
        }

        if let crackScene = self.crackScene {
            let crackRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(-1, 0, 0), duration: rotationDuration * 2))
            crackScene.rootNode.runAction(crackRotationAction)
        }

        changeAnimation(0.5, 0.5, 0.5)
    }

    // RealtimeDatabas 값 받아오는 함수
    func getRealtimeDatabase() {
        // "sensor" 경로의 데이터에 대한 실시간 업데이트를 관찰
        ref?.child("sensor").observe(.value, with: { snapshot in
            // snapshot이 감지되면 여기의 코드가 실행됩니다.
            // snapshot.value를 통해 데이터를 가져올 수 있습니다.
            guard let value = snapshot.value as? [String: Any] else {
                print("데이터를 가져오는 데 실패했습니다.")
                return
            }

            let fixPitch = -32
            let fixRoll = 39

            // x, y, z 값을 읽어옵니다.
            if let pitch = value["pitch"] as? Int,
               let roll = value["roll"] as? Int {
                print("pitch: \(pitch), roll: \(roll)")


                if fixRoll - roll < -3{
                    downRotation()
                } else if fixRoll - roll > 2 {
                    upRotation()
                } else if fixPitch - pitch > 3 {
                    leftRotation()
                } else if fixPitch - pitch < -2 {
                    rightRotation()
                }

                if endPoint <= 1 {
                    print("=== The End Arduino===")
                    changeView()
                }
            } else {
                print("올바른 데이터 형식이 아닙니다.")
            }
        }) { error in
            print(error.localizedDescription)
        }
    }

    // 드래그 이벤트 핸들링
    private func handleDragChange(change: DragGesture.Value) {
        // 사용자가 드래그를 시작하면, 드래그의 방향과 거리에 따라 애니메이션을 조정합니다.
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            print("no event")
            let headRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(1, 0, 0), duration: 5))
            self.glassHead?.rootNode.runAction(headRotationAction)
            let crackRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(-1, 0, 0), duration: 12))
            self.crackScene?.rootNode.runAction(crackRotationAction)
            changeAnimation(0.5, 0.5, 0.5)
        }

        musicRollingBall()

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

    private func handleDragEnd() {
        // 사용자가 드래그를 끝내면, 필요한 경우 타이머를 초기화하거나, 애니메이션을 정지합니다.
        self.timer?.invalidate()
        self.timer = nil
        print("Drag ended.")
    }

    // 위로 움직임
    func upRotation() {
        self.rotationDuration += 2
        self.endPoint -= Int(rotationDuration)/7
        let rotationAction = SCNAction.rotate(by: .pi*6, around: SCNVector3(-1, 0, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*6, around: SCNVector3(1, 0, 0), duration: self.rotationDuration-6)
        // -1,0,0
        changeAnimation(0.15, 0.87, 1.0)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
        print("⬆️: \(self.rotationDuration)")
    }

    @State var downCount: Int = 0

    // 아래 움직임
    func downRotation() {
        if self.rotationDuration <= 7{
            self.rotationDuration = 7
        } else {
            self.rotationDuration -= 5
        }
        self.endPoint -= Int(rotationDuration)/7
        self.downCount += 1
        if (downCount > 8) {
            changeAnimation(0.86, 0.04, 0.17)
        } else {
            changeAnimation(1.0, 0.4, 0.55)
        }
        let rotationAction = SCNAction.rotate(by: .pi*10, around: SCNVector3(1, 0, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*10, around: SCNVector3(-1, 0, 0), duration: self.rotationDuration-6)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
        print("⬇️: \(self.rotationDuration)")
    }

    // 왼쪽으로 움직임
    func rightRotation() {
        print("➡️")
        self.endPoint -= Int(rotationDuration)/7
        changeAnimation(0.71, 0.94, 0.17)
        let rotationAction = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, -1, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, -1, 0), duration: self.rotationDuration)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
    }

    // 오른쪽으로 움직임
    func leftRotation() {
        print("⬅️")
        self.endPoint -= Int(rotationDuration)/7
        changeAnimation(0.71, 0.94, 0.17)
        let rotationAction = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, 1, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, 1, 0), duration: self.rotationDuration)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)

    }

    // view 전환 및 api post
    func changeView() {
        // print("red: \(self.red) | green: \(self.green) | blue: \(self.blue)")
        withAnimation(.easeOut(duration: 0.7)) {
            isGIFViewVisible = true
        }
        // isSceneViewVisible = false
        self.rotationDuration = 30.0
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
        let newRed = self.red + (goalRed - self.red)/(velocity/2)
        self.red = newRed
        let newGreen = self.green + (goalGreen - self.green)/(velocity/2)
        self.green = newGreen
        let newBlue = self.blue + (goalBlue - self.blue)/(velocity/2)
        self.blue = newBlue

        // print("🌀🌀newBlue: \(self.blue)")
        // print("🌀🌀🌀newBlue: \(self.blue + (goalBlue - self.blue)/velocity)")

        let newColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
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

