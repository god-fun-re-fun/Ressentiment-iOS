//
//  ReadyView1.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/30/24.
//

import SwiftUI

// 첫 번째 화면
struct ReadyView1: View {
    @ObservedObject var viewModel = SharedViewModel()

    var body: some View {
        ZStack {
            // 배경 이미지 설정
            Image("ReadyView1")
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
                    Button(action: {
                        viewModel.firstOn = false
                        viewModel.secondOn = true
                    }, label: {
                        Image("NextButton")
                            .resizable() // 이미지 크기 조절 가능하게 설정
                            .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                            .frame(width: 350, height: 138) // 버튼 크기 조정
                    })
                }
            }
            .padding(.bottom, 50)
        }
    }
}

struct ReadyView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyView1()
    }
}
