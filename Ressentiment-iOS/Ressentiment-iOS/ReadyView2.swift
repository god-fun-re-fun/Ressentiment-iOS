//
//  ReadyView2.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/30/24.
//

import SwiftUI

struct ReadyView2: View {
    @State private var isButtonPressed = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 이미지 설정
                Image("ReadyView2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                // 이미지를 오른쪽 아래로 배치하기 위한 VStack
                VStack {
                    // 상단 공간을 차지하기 위한 Spacer
                    Spacer()
                    // 이미지 버튼을 오른쪽으로 배치하기 위한 HStack
                    HStack {
                        // 왼쪽 공간을 차지하기 위한 Spacer
                        Spacer()
                        // 이미지 버튼 추가
                        NavigationLink(destination: MainView()) {
                            Image("NextButton")
                                .resizable() // 이미지 크기 조절 가능하게 설정
                                .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                                .frame(width: 350, height: 138)
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.trailing, 15)
            }
        }.navigationBarBackButtonHidden(true)
    }
}

struct ReadyView2_Previews: PreviewProvider {
    static var previews: some View {
        ReadyView2()
    }
}
