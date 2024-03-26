//
//  UIKitTestModel.swift
//  Scene
//
//  Created by 이조은 on 3/19/24.
//

import UIKit
import SceneKit
import SwiftUI

class SceneViewController: UIViewController {
    var scene: SCNScene?
    var allowsCameraControl: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let scnView = SCNView()
        // scnView의 크기를 부모 뷰의 80%로 설정
        let viewWidth = self.view.frame.width * 0.3
        let viewHeight = self.view.frame.height * 0.3
        // scnView의 프레임을 계산하여 중앙에 위치시킴
        scnView.frame = CGRect(x: 0,
                               y: 0,
                               width: viewWidth+20,
                               height: viewHeight)
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clear
        scnView.allowsCameraControl = allowsCameraControl
        scnView.autoenablesDefaultLighting = true
        self.view.addSubview(scnView)
    }
}

class GlassHeadManager: NSObject, SCNSceneRendererDelegate {
    var materialProperty = SCNMaterialProperty(contents: 0.0)
    var elapsedTime: TimeInterval = 0.0

    func addWaterEffect(to node: SCNNode) {
        let waterEffectShader = """
        // GLSL 쉐이더 코드
        #ifdef GL_ES
        precision mediump float;
        #endif

        uniform float time;
        varying vec2 v_texCoord;
        varying vec3 v_normal;

        void main(void) {
            // v_texCoord는 텍스처 좌표, v_normal은 정점의 법선 벡터입니다.
            // 시간에 따라 변하는 파동 효과를 만듭니다.
            float wave = sin(v_texCoord.x * 10.0 + time) * 0.1;
            wave += sin(v_texCoord.y * 10.0 + time) * 0.1;
            // 최종 색상은 파란색 계열로, 파동 효과를 반영하여 조정합니다.
            vec3 color = vec3(0.0, 0.2 + wave, 0.4 + wave);
            gl_FragColor = vec4(color, 1.0);
        }
        """
        node.geometry?.materials.forEach { material in
            if material.name == "Material_001" {
                print("====== 123123")
                material.shaderModifiers = [.surface: waterEffectShader]
                material.setValue(SCNFloat(elapsedTime), forKey: "time") // 수정된 부분
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        elapsedTime += time
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
    @State var rotationDuration: TimeInterval = 2.0

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
            SceneView(scene: crackScene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width*2.5, height: UIScreen.main.bounds.height*2.5)
                .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
            // default 상태가 움직이도록
                .onAppear {
                    let headRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(1, 0, 0), duration: 2))
                    self.glassHead?.rootNode.runAction(headRotationAction)
                    let crackRotationAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi*1, around: SCNVector3(-1, 0, 0), duration: 8))
                    self.crackScene?.rootNode.runAction(crackRotationAction)
                    changeAnimation(0.5, 0.5, 0.5)

                    let glassHeadManager = GlassHeadManager()
                    glassHeadManager.addWaterEffect(to: glassHead!.rootNode)
                    // SCNSceneRendererDelegate 설정이 필요한 경우 추가 구현
                }
                .gesture(
                    DragGesture()
                        .onChanged { change in
                            self.timer?.invalidate()
                            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                print("no event")
                                changeAnimation(0.5, 0.5, 0.5)
                            }

                            if change.translation.height > 0 {
                                print("⬆️")
                                changeAnimation(0.5, 0.5, 1.0)
                                let rotationAction = SCNAction.rotate(by: .pi*2, around: SCNVector3(-1, 0, 0), duration: self.rotationDuration)
                                // 속도 갱신
                                glassHead?.rootNode.runAction(rotationAction)
                            } else if change.translation.height < 0 {
                                print("⬇️")
                                changeAnimation(1.0, 0.5, 0.5)
                                let rotationAction = SCNAction.rotate(by: .pi*2, around: SCNVector3(1, 0, 0), duration: self.rotationDuration)
                                glassHead?.rootNode.runAction(rotationAction)
                            } else if change.translation.width > 0 {
                                print("➡️")
                                changeAnimation(0.5, 1.0, 0.5)
                                let rotationAction = SCNAction.rotate(by: .pi*2, around: SCNVector3(0, 1, 0), duration: self.rotationDuration)
                                glassHead?.rootNode.runAction(rotationAction)
                            } else if change.translation.width < 0 {
                                print("⬅️")
                                changeAnimation(1.0, 0.5, 1.0)
                                let rotationAction = SCNAction.rotate(by: .pi*2, around: SCNVector3(0, -1, 0), duration: self.rotationDuration)
                                glassHead?.rootNode.runAction(rotationAction)
                            }
                        }
                        .onEnded { _ in
                            // 사용자가 드래그를 끝내면 타이머를 초기화
                            self.timer?.invalidate()
                            self.timer = nil
                        }
                )

            // Front
            SceneViewRepresentable(scene: glassHead, allowsCameraControl: true)
                .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.height / 4)
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
        print("=== color change func 🎨 ===")
        let newRed = self.red + (goalRed - self.red)/velocity
        self.red = newRed
        let newGreen = self.green + (goalGreen - self.green)/velocity
        self.green = newGreen
        let newBlue = self.blue + (goalBlue - self.blue)/velocity
        self.blue = newBlue

        // print("🌀🌀newBlue: \(self.blue)")
        //        print("🌀🌀🌀newBlue: \(self.blue + (goalBlue - self.blue)/velocity)")

        let newColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        return newColor
    }

    func changeAnimation(_ goalRed: CGFloat, _ goalGreen: CGFloat, _ goalBlue: CGFloat) {
        print("=== changeAnimation func 📽️ ===")
        glassHead?.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.materials.forEach { material in
                // Material_001 머테리얼만 찾아서 색상 변경 적용
                if material.name == "Material_001" {

                    let newColor = self.changeColor(goalRed, goalGreen, goalBlue)

                    // SCNTransaction을 사용하여 애니메이션 적용
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5 // 애니메이션 지속 시간 설정
                    material.diffuse.contents = newColor
                    print("🌀🌀newColor: \(newColor)")
                    SCNTransaction.commit()
                }
            }
        }
    }
}

struct UIKitTestModel_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            UIKitTestModel()
                .previewInterfaceOrientation(.landscapeLeft)
        } else {
            UIKitTestModel()
        }
    }
}

