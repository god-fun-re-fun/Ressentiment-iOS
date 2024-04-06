//
//  Ressentiment_iOSApp.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/4/24.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Ressentiment_iOSApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate


  var body: some Scene {
    WindowGroup {
        StartView()
    }
  }
}

//@main
//struct Ressentiment_iOSApp: App {
//    var body: some Scene {
//        WindowGroup {
//            UIKitTestModel()
//        }
//    }
//}
