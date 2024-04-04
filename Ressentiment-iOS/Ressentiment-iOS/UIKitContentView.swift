//
//  UIKitTestModel.swift
//  Scene
//
//  Created by 이조은 on 3/19/24.
//

import UIKit
import SwiftUI

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

struct UIKitTestModel: View {
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
    @State var index = 0
    @State var isRolling = false
    @State var lastDragAmount: CGFloat = 0
    @Binding var rotationDuration: TimeInterval
    @State var rotationPi: Double = .pi
    @State private var timer: Timer? = nil

    @State var velocity: CGFloat = 30

    @State var glassHead: SCNScene? = SCNScene(named: "GlassHead.scn") // Add this line
    @State var crackScene = SCNScene(named: "Concrete-Smooth.usdz")

    @State var red: CGFloat = 0.5
    @State var green: CGFloat = 0.5
    @State var blue: CGFloat = 0.5
    let alpha: CGFloat = 1.0

    // DatabaseReference 인스턴스 생성 및 Firebase Database의 루트 참조를 초기화
    var ref: DatabaseReference? = Database.database().reference()
    @State var xBefore: Int = 0
    @State var yBefore: Int = 0
    @State var zBefore: Int = 0

    @State private var isSceneViewVisible = true
    @State private var isGIFViewVisible = false

    var body: some View {

        if let scene = crackScene {
            // 앞, 뒤, 좌, 우 조명 위치 설정
            let frontLightNode = createLightNode(color: .white, position: SCNVector3(x: 0, y: 30, z: 0))
            let backLightNode = createLightNode(color: .white, position: SCNVector3(x: 0, y: -30, z: 0))

            // 조명 노드를 씬 그래프에 추가
            scene.rootNode.addChildNode(frontLightNode)
            scene.rootNode.addChildNode(backLightNode)
        }

        return ZStack {
            // Background
            if isGIFViewVisible {
                // GIFView 표시
                GIFViewRepresentable(particleColor: UIColor(red: self.red+0.2, green: self.green+0.2, blue: self.blue+0.2, alpha: 1.0))
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            } else {
                SceneView(scene: crackScene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: UIScreen.main.bounds.width*2.5, height: UIScreen.main.bounds.height*2.5)
                    .position(x: UIScreen.main.bounds.width/3, y: UIScreen.main.bounds.height/3)
                // default 상태가 움직이도록
                    .onAppear {
                        let headRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(1, 0, 0), duration: 5))
                        self.glassHead?.rootNode.runAction(headRotationAction)
                        let crackRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(-1, 0, 0), duration: 12))
                        self.crackScene?.rootNode.runAction(crackRotationAction)
                        changeAnimation(0.5, 0.5, 0.5)

                        getRealtimeDatabase()
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { change in
                                self.timer?.invalidate()
                                self.timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                                    print("no event")
                                    let headRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(1, 0, 0), duration: 5))
                                    self.glassHead?.rootNode.runAction(headRotationAction)
                                    let crackRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(-1, 0, 0), duration: 12))
                                    self.crackScene?.rootNode.runAction(crackRotationAction)
                                    changeAnimation(0.5, 0.5, 0.5)
                                }
                                if change.translation.height > 0 {
                                    upRotation()
                                } else if change.translation.height < 0 {
                                    downRotation()
                                } else if change.translation.width > 0 {
                                    rightRotation()
                                } else if change.translation.width < 0 {
                                    leftRotation()
                                }

                                if self.rotationDuration <= 7.0 {
                                    print("===== 끝 =====")
                                    isGIFViewVisible = true
                                    isSceneViewVisible = false
                                    print("red: \(self.red) | green: \(self.green) | blue: \(self.blue)")
                                    RessentimentService().postColor(parameters: ["R":"\(self.red)", "G":"\(self.green)", "B":"\(self.blue)"]) { result in
                                        switch result {
                                        case .success(let colorResponse):
                                            print("=== success: \(colorResponse)")
                                        case .failure(let error):
                                            print("API Error: \(error)")
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                // 사용자가 드래그를 끝내면 타이머를 초기화
                                self.timer?.invalidate()
                                self.timer = nil
                            }
                    )

                // Front
                if isSceneViewVisible {
                    SceneViewRepresentable(scene: glassHead, allowsCameraControl: true)
                        .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.height / 4)
                }
            }
        }.animation(.default, value: isGIFViewVisible)
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
                    upRotation()
                } else if fixRoll - roll > 2 {
                    downRotation()
                } else if fixPitch - pitch > 3 {
                    rightRotation()
                } else if fixPitch - pitch < -2 {
                    leftRotation()
                }

                if self.rotationDuration <= 7.0 {
                    print("끝")
                    print("red: \(self.red) | green: \(self.green) | blue: \(self.blue)")
                    isGIFViewVisible = true
                    isSceneViewVisible = false
                    RessentimentService().postColor(parameters: ["R":"\(self.red)", "G":"\(self.green)", "B":"\(self.blue)"]) { result in
                        switch result {
                        case .success(let colorResponse):
                            print("=== success: \(colorResponse)")
                        case .failure(let error):
                            print("API Error: \(error)")
                        }
                    }
                }
            } else {
                print("올바른 데이터 형식이 아닙니다.")
            }
        }) { error in
            print(error.localizedDescription)
        }
    }

    // 위로 움직임
    func upRotation() {
        let rotationAction = SCNAction.rotate(by: .pi*2, around: SCNVector3(-1, 0, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*2, around: SCNVector3(1, 0, 0), duration: self.rotationDuration-6)
        // -1,0,0
        changeAnimation(0.5, 0.5, 1.0)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
        print("⬆️: \(self.rotationDuration)")
    }

    // 아래 움직임
    func downRotation() {
        self.rotationDuration -= 9
        let rotationAction = SCNAction.rotate(by: .pi*10, around: SCNVector3(1, 0, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*10, around: SCNVector3(-1, 0, 0), duration: self.rotationDuration-6)
        changeAnimation(1.0, 0.5, 0.5)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
        print("⬇️: \(self.rotationDuration)")
    }

    // 왼쪽으로 움직임
    func rightRotation() {
        print("➡️")
        changeAnimation(0.5, 1.0, 0.5)
        let rotationAction = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, -1, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, -1, 0), duration: self.rotationDuration)
        changeAnimation(1.0, 0.5, 0.5)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)
    }

    // 오른쪽으로 움직임
    func leftRotation() {
        print("⬅️")
        changeAnimation(0.5, 1.0, 0.5)
        let rotationAction = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, 1, 0), duration: self.rotationDuration)
        let rotationAction2 = SCNAction.rotate(by: .pi*8, around: SCNVector3(0, 1, 0), duration: self.rotationDuration)
        changeAnimation(1.0, 0.5, 0.5)
        glassHead?.rootNode.removeAllActions()
        crackScene?.rootNode.removeAllActions()
        glassHead?.rootNode.runAction(rotationAction)
        crackScene?.rootNode.runAction(rotationAction2)

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
        UIKitTestModel()
    }
}

