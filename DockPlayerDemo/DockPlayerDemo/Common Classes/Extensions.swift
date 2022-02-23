//
//  Extensions.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit

let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
let isPhone = UIDevice.current.userInterfaceIdiom == .phone
let hasTopNotch: Bool = sceneDelegate?.window?.safeAreaInsets.top ?? 0 > 20

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    func addBlur() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = self.bounds
        blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurredEffectView)
    }
    
    func removeBlur() {
        self.subviews.first(where: { $0 is UIVisualEffectView})?.removeFromSuperview()
    }
}
