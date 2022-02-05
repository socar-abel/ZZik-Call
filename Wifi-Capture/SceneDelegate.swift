import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    let blueBlackBackgroundColor = UIColor(red: 7/255, green: 13/255, blue: 56/255, alpha: 1.0)
    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {return}
        
        // custom function
        setRootViewController(windowScene)
        
        
//        window = UIWindow(windowScene: windowScene)
//
//        let mainViewController = MainViewController()
//        let navigationController = UINavigationController(rootViewController: mainViewController)
//
//        window?.backgroundColor = .black
//        window?.rootViewController = navigationController
//        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
}


extension SceneDelegate {
    // 루트 뷰 컨트롤러 설정
    private func setRootViewController(_ windowScene: UIWindowScene) {
        window = UIWindow(windowScene: windowScene)
        // 사용자가 앱을 처음 실행한다면 Onboarding 화면으로 이동
        if UserInfoStorage.isUserFirstTime() {
            let onBoardingViewController = OnboardingViewController()
            let navigationController = UINavigationController(rootViewController: onBoardingViewController)
            window?.backgroundColor = blueBlackBackgroundColor
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
        // 아니라면 MainViewController 로 이동
        else {
            window = UIWindow(windowScene: windowScene)
            let mainViewController = MainViewController()
            let navigationController = UINavigationController(rootViewController: mainViewController)
            window?.backgroundColor = blueBlackBackgroundColor
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
    }
    
    
}

