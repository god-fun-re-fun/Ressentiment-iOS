//
//  StartViewController.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/6/24.
//

import SwiftUI

class NavigationStackManager: ObservableObject {
    @Published var isAtRootView: Bool = false
}

// 첫 번째 화면
struct StartView: View {
    @State private var isButtonPressed = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 이미지 설정
                Image("RessentimentBG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                NavigationLink(destination: ReadyView1()) {
                    Image("StartButton")
                        .resizable() // 이미지 크기 조절 가능하게 설정
                        .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                        .frame(width: 700, height: 171)
                }.padding(.top, 840)
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
