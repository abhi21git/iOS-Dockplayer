//
//  DetailPageController.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit
import AVFoundation

class DetailPageController: BaseController {

    // MARK: - Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var iPadRightContainerView: UIView!
    @IBOutlet weak var BottomContainerView: UIView!
    
    // MARK: - properties
    var playerWidthConstraint: NSLayoutConstraint = NSLayoutConstraint() /// Set this to 1.0 for iPhone & fullscreen, and 0.5 for smallscreen
    var playerInstantiated: (() -> Void)? = nil /// Call this after player starts playing
    var avPlayer: AVPlayer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add code here
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupPlayer()
        // Add code here
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Add code here
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Add code here
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Add code here
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerView.layer.sublayers?.first(where: { $0 is AVPlayerLayer })?.frame = playerView.bounds
    }
    
    // MARK: - Actions
    @IBAction func backDownButtonAction() {
        DockPlayer.manager.removeDockPlayer()
    }
    
    // MARK: - Methods
    func setupUI() {
        view.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerWidthConstraint = NSLayoutConstraint(item: playerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: isPhone ? 1.0 : 0.5, constant: 0.0)
        playerWidthConstraint.isActive = true
    }
    
    func setupPlayer() {
        guard let playUrl = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8") else { return }
        avPlayer = AVPlayer(url: playUrl)
        let avPlayerLayer = AVPlayerLayer(player: avPlayer)
        playerView.layer.addSublayer(avPlayerLayer)
        avPlayerLayer.frame = playerView.bounds
        avPlayerLayer.videoGravity = .resizeAspectFill
        avPlayer?.play()
        playerInstantiated?()
    }
}

// MARK: - Dockplayer extension
extension DetailPageController: DockPlayerDelegate {
    
    var backDownButton: UIButton?  {
        return backButton
    }
    
    var isDockingAllowed: Bool {
        return true
    }
    
    var playerView: UIView {
        return playerContainerView
    }
    
    var player: AVPlayer? {
        return avPlayer
    }
    
    func isRotationAllowed(_ playerView: UIView?) -> Bool {
        return true
    }
    
    func refreshContent<T>(with contentModel: T) {
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
