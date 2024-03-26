//
//  GlassHeadManager.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/20/24.
//

import Foundation
import SceneKit

//class GlassHeadManager: NSObject, SCNSceneRendererDelegate {
//    var materialProperty = SCNMaterialProperty(contents: 0.0)
//    var elapsedTime: TimeInterval = 0.0
//
//    func addWaterEffect(to node: SCNNode) {
//        let waterEffectShader = """
//        // GLSL 쉐이더 코드
//        #ifdef GL_ES
//        precision mediump float;
//        #endif
//
//        uniform float time;
//        varying vec2 v_texCoord;
//        varying vec3 v_normal;
//
//        void main(void) {
//            // v_texCoord는 텍스처 좌표, v_normal은 정점의 법선 벡터입니다.
//            // 시간에 따라 변하는 파동 효과를 만듭니다.
//            float wave = sin(v_texCoord.x * 10.0 + time) * 0.1;
//            wave += sin(v_texCoord.y * 10.0 + time) * 0.1;
//            // 최종 색상은 파란색 계열로, 파동 효과를 반영하여 조정합니다.
//            vec3 color = vec3(0.0, 0.2 + wave, 0.4 + wave);
//            gl_FragColor = vec4(color, 1.0);
//        }
//        """
//        node.geometry?.materials.forEach { material in
//            if material.name == "Material_001" {
//                material.shaderModifiers = [.surface: waterEffectShader]
//                material.setValue(materialProperty, forKey: "elapsedTime")
//            }
//        }
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        elapsedTime += time
//        materialProperty.contents = elapsedTime
//    }
//}
//
