//
//  DetailPageController.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit
import AVFoundation

class DetailPageController: BaseController {

    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var playerContainerWidthConstraint: NSLayoutConstraint! /// Set this to 1.0 for iPhone & fullscreen, and 0.5 for smallscreen
    @IBOutlet weak var iPadRightContainerView: UIView!
    @IBOutlet weak var BottomContainerView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add code here
    }
    @IBAction func backDownButtonAction() {
        DockPlayer.manager.removeDockPlayer()
    }
    
}

extension DetailPageController: DockPlayerDelegate {
    var playerWidthConstraint: NSLayoutConstraint {
        return NSLayoutConstraint()
    }
    
    var backDownButton: UIButton?  {
        return UIButton()
    }
    
    var isDockingAllowed: Bool {
        return true
    }
    
    var playerView: UIView {
        return UIView()
    }
    
    var player: AVPlayer {
        return AVPlayer()
    }
    
    func isRotationAllowed(_ playerView: UIView?) -> Bool {
        return true
    }
    
    func refreshContent<T>(with contentViewModel: T) {
        // Add code here
    }
    
    func refreshScreen(_ forceRefresh: Bool) {
        // Add code here
    }
    
    func setOpeningPoster(with image: UIImage?) {
        // Add code here
    }
    
    func updatePlayerControls(for dockState: DockPlayer.DockState, _ isPlayerInitialized: Bool, _ isFlicked: Bool) {
        // Add code here
    }
}
