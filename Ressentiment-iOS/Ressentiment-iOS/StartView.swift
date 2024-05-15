//
//  StartViewController.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 4/6/24.
//
import Foundation
import SwiftUI

// ObservableObject 프로토콜을 채택한 클래스 선언
class SharedViewModel: ObservableObject {
    @Published var startOn: Bool = true
    @Published var firstOn: Bool = false
    @Published var secondOn: Bool = false
    @Published var mainOn: Bool = false
}

// 첫 번째 화면
struct StartView: View {
    @StateObject var viewModel = SharedViewModel()

    var body: some View {
        ZStack {
            if viewModel.startOn {
                // 배경 이미지 설정
                Image("RessentimentBG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                // 이미지 버튼 추가
                Button(action: {
                    viewModel.startOn = false
                    viewModel.firstOn = true
                }, label: {
                    Image("StartButton")
                        .resizable() // 이미지 크기 조절 가능하게 설정
                        .aspectRatio(contentMode: .fit) // 이미지 비율 유지
                        .frame(width: 800, height: 181) // 버튼 크기 조정
                })
                .padding(.top, 840) // 버튼 위치 조정 (아래로 내림)
            } else if viewModel.firstOn{
                ReadyView1(viewModel: viewModel)
            } else if viewModel.secondOn {
                ReadyView2(viewModel: viewModel)
            }
        }.fullScreenCover(isPresented: $viewModel.mainOn, content: {
            MainView(viewModel: viewModel)
                .transition(.opacity)
        })
        .animation(.easeInOut, value: viewModel.mainOn)
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
