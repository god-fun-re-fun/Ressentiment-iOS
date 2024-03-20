import SwiftUI
import SpriteKit
import UIKit

struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // 여기에서 ViewController 인스턴스를 생성하고 반환합니다.
        ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 필요한 경우 ViewController 업데이트 로직
    }
}

class ViewController: UIViewController {

    var imageView: UIImageView!
    var skView: SKView!
    let snowScene = SnowScene()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGIFImageView()
        setupSKView()
    }

    func setupGIFImageView() {
        guard let path = Bundle.main.path(forResource: "testvideo", ofType: "gif"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let gifImage = UIImage.gifImageWithData(data) else {
            return
        }

        imageView = UIImageView(image: gifImage)
        imageView.contentMode = .scaleAspectFill
        imageView.animationDuration = 2
        imageView.frame = view.bounds // 전체 화면에 GIF 이미지를 표시합니다.
        view.addSubview(imageView)
    }

    func setupSKView() {
        skView = SKView(frame: view.bounds)
        skView.backgroundColor = .clear
        view.addSubview(skView)

        snowScene.size = view.bounds.size
        snowScene.scaleMode = .aspectFill
        skView.presentScene(snowScene)
    }
}


class SnowScene: SKScene {
    override func didMove(to view: SKView) {
        setScene(view)
        setSnowNode()
        self.backgroundColor = SKColor.clear // Scene의 배경을 투명하게 설정
    }

    override func didApplyConstraints() {
        guard let view = view else { return }
        scene?.size = view.frame.size
    }

    private func setScene(_ view: SKView) {
        backgroundColor = .clear
        scene?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene?.scaleMode = .aspectFill
    }

    private func setSnowNode() {
        guard let snowNode = SKEmitterNode(fileNamed: "Rain") else { return }
        snowNode.position =  CGPoint(x: 100, y: 100)
        snowNode.particleColor = UIColor(red: 0.5, green: 0.7, blue: 0.7, alpha: 0.2)

        // 5초 후에 snowNode를 제거합니다. 필요에 따라 시간을 조절하세요.
        let delay = SKAction.wait(forDuration: 2) // 2초 동안 대기
        let scaleUp = SKAction.scale(to: 5, duration: 2) // 2초 동안 크기를 5배로 늘림
        let fadeOut = SKAction.fadeOut(withDuration: 2) // 2초 동안 서서히 사라지게 설정
        let remove = SKAction.removeFromParent() // 부모 노드로부터 제거
        snowNode.run(SKAction.sequence([delay, scaleUp, fadeOut, remove]))

//        let delay = SKAction.wait(forDuration: 2) // 2초 동안 대기
//        let stopAction = SKAction.run { snowNode.removeAllActions() } // 모든 액션을 멈추는 액션
//        snowNode.run(SKAction.sequence([delay, stopAction]))
        scene?.addChild(snowNode)
    }
}
