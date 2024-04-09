//
//  StartViewController.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/6/24.
//

import SwiftUI

// 첫 번째 화면
struct StartView: View {
    @State private var isButtonPressed = false

    var body: some View {
        ZStack {
            // 배경 이미지 설정
            Image("RessentimentBG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)

            // 이미지 버튼 추가
            Button(action: {
                // 버튼 클릭 시 isButtonPressed 상태 변경
                isButtonPressed = true
            }, label: {
                Image("StartButton")
                    .resizable() // 이미지 크기 조절 가능하게 설정
                    .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                    .frame(width: 800, height: 181) // 버튼 크기 조정
            })
            .padding(.top, 840) // 버튼 위치 조정 (아래로 내림)
            .fullScreenCover(isPresented: $isButtonPressed, content: {
                // isButtonPressed가 true일 때 보여질 뷰
                MainView()
            })
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
