//
//  Constants.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 24/02/22.
//

import UIKit

let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
let isPhone = UIDevice.current.userInterfaceIdiom == .phone
let isPad = !isPhone
let hasTopNotch: Bool = sceneDelegate?.window?.safeAreaInsets.top ?? 0 > 20

enum AppStoryboard: String {

    case homeLanding = "HomeLandingVC"
    case detailPage = "DetailPageController"

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }


    func viewController<T: UIViewController>(viewControllerClass: T.Type) -> T {
        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID
        return instance.instantiateViewController(withIdentifier: storyboardID) as! T
    }
}
