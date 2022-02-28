//
//  DockPlayerManager.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit
import AVKit

// MARK: - DockPlayerDelegate
protocol DockPlayerDelegate where Self: UIViewController {
    var playerInstantiated: (() -> Void)? { get set }
    var backDownButton: UIButton? { get }
    var isDockingAllowed: Bool { get }
    var playerView: UIView { get }
    var player: AVPlayer? { get }
    var playerWidthConstraint: NSLayoutConstraint { get set }

    func isRotationAllowed(_ playerView: UIView?) -> Bool
    func refreshContent<T>(with contentModel: T)
    func refreshScreen(_ forceRefresh: Bool)
    func setOpeningPoster(with image: UIImage?)
    func updatePlayerControls(for dockState: DockPlayer.DockState, _ isPlayerInitialized: Bool, _ isFlicked: Bool)
    func docking(percentMoved: CGFloat)
}

extension DockPlayerDelegate {
    func docking(percentMoved: CGFloat) {

    }
}

// MARK: - DockPlayer
class DockPlayer {

    // MARK: - Enums
    internal enum SwipeDirection {
        case none
        case up
        case down
        case left
        case right
    }

    internal enum DockState {
        case undocked
        case docking
        case docked
        case undocking
    }

    internal enum PlayerMode {
        case smallScreen
        case fullScreen
    }

    // MARK: - Singleton
    static let manager = DockPlayer()
    private init() { }

    // MARK: - Properties
    var dockableView: UIView? {
        willSet {
            guard newValue == nil else { return }
            self.deallocateDockplayer() /// Do not put this in Dispatch. (Next run loop will cause issues as dockableView will have a value by then)
        }
        didSet {
            self.makeViewDockable()
        }
    }
    var animator: (frame: CGRect?, imageView: UIImageView?)
    var playerView: UIView? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if self?.playerView == nil {
                    DockPlayer.manager.playerMode = .smallScreen
                    DockPlayer.manager.panGesture.state = .cancelled
                    DockPlayer.manager.swipeDirection = .none
                    DockPlayer.manager.dockState = .undocked
                    self?.showHideBackButton(false)
                    self?.backButtonState()
                }
            }
        }
    }
    var detailBaseController: DockPlayerDelegate?

    var dockState = DockState.undocked {
        didSet {
            if let dockY = dockableView?.frame.origin.y, dockY == 0 && dockState != .undocked && overDockingCompleted() {
                dockState = .undocked
                return
            }
            detailBaseController?.updatePlayerControls(for: dockState, isPlayerInitialized, isFlicked)
        }
    }
    var playerMode: PlayerMode = .smallScreen {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.showHideBackButton(self?.playerMode == .fullScreen)
            }
        }
    }

    var isDockingAllowed: Bool {
        return detailBaseController?.isDockingAllowed ?? false
    }

    var backDownButton: UIButton {
        return detailBaseController?.backDownButton ?? UIButton()
    }

    var swipeDirection = SwipeDirection.none
    var isPlayerInitialized = false

    // MARK: - Private Properties
    private var isVertical = false {
        didSet {
            if isVertical {
                isHorizontal = false
            }
        }
    }
    private var isHorizontal = false {
        didSet {
            if isHorizontal {
                isVertical = false
            }
        }
    }
    private var isBeingReset = false
    private var isFlicked: Bool = true
    private var overDockingPoint: CGFloat = 0.0
    private let screenHeight = UIScreen.main.bounds.height
    private let screenWidth = UIScreen.main.bounds.width
    private let rightOffset: CGFloat = isPhone ? 14.0 : 20
    private let swipeThreshold: CGFloat = 80.0
    private let verticalDeltaMultiplier: CGFloat = 0.625
    private let minimumMultiplerForVerticalMovement: CGFloat = 0.375
    private let horizontalDeltaMultiplier: CGFloat = 0.5
    private let minimumMultiplerForHorizontalMovement: CGFloat = 0.5

    // MARK: Docking computation
    private var currentThreshold: CGFloat = 0.0 {
        didSet {
            if panGesture.state == .ended {
                if currentThreshold < swipeThreshold { /// If user scrolls little bit where changing dock state isn't good for UX
                    if dockState == .docking && swipeDirection == .down {
                        updateDetailViewFrameToFullMode()
                    } else if dockState == .undocking && swipeDirection == .up {
                        updateDetailViewFrameToSmallMode()
                    } else if dockState != .undocked && swipeDirection == .left || swipeDirection == .right {
                        updateDetailViewFrameToSmallMode()
                    } else {
                        updateEndingMovingFrame()
                    }
                } else {
                    updateEndingMovingFrame()
                }
            } else if panGesture.state == .cancelled {
                endingSwipeVertical() /// If device is locked or another app opens while performing swiping
            } else {
                updateMovingFrame()
            }
        }
    }

    // MARK: Swipe Direction computation
    private var currentPoint = CGPoint(x: 0, y: 0) {
        willSet {
            if newValue == .zero {
//                swipeDirection = .none
            } else if !isHorizontal && abs(newValue.y - currentPoint.y) >= abs(newValue.x - currentPoint.x) && dockableView?.transform.tx == 0 {
                isVertical = true
                if newValue.y > currentPoint.y {
                    swipeDirection = .down
                } else if newValue.y < currentPoint.y {
                    swipeDirection = .up
                }
            } else if dockState == .docked && abs(newValue.y - currentPoint.y) < abs(newValue.x - currentPoint.x) && overDockingCompleted() {
                isHorizontal = true
                if newValue.x > currentPoint.x {
                    swipeDirection = .right
                } else if newValue.x < currentPoint.x {
                    swipeDirection = .left
                }
            }
        }
        didSet {
            switch swipeDirection {
            case .left, .right:
                currentThreshold = abs(currentPoint.x)
            case .up, .down:
                currentThreshold = abs(currentPoint.y)
            default:
                break
            }
        }
    }

    // MARK: - Private Computed Properties
    private var animationTime: Double {
        return isFlicked ? 0.3 : 0.0
    }

    private var bottomOffset: CGFloat {
        return (isPhone ? 60.0 : 80.0) + (hasTopNotch ? 34.0 : 0.0)
    }

    private var minHeight: CGFloat {
        return (isPhone ? screenWidth : screenHeight) / 3.0
    }

    private var minWidth: CGFloat {
        return minHeight * (16.0 / 9.0)
    }

    private var finalDistanceFromTop: CGFloat {
        return screenHeight - bottomOffset - minHeight
    }

    private var finalDistanceFromLeft: CGFloat {
        return screenWidth - rightOffset - minWidth
    }

    // MARK: - Lazy Properties
    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))


    // MARK: - Methods
    func initialize<T>(_ detailVC: DockPlayerDelegate, for content: T, with imageView: UIImageView? = nil) {
        if detailExists() {
            resetFrame {
                self.detailBaseController?.refreshContent(with: content)
            }
        } else {
            setOpeningAnimationFromImage(imageView) /// This will save animatorFrame and Image for sweet opening animation
//            detailVC.contentViewModel = content
            detailBaseController = detailVC
            dockableView = detailVC.view
        }
    }

    func bringDockPlayerToTop(completion: (() -> Void)? = nil) {
        guard let dockView = DockPlayer.manager.dockableView, detailBaseController?.presentingViewController == nil, detailBaseController?.presentedViewController == nil else {
            completion?()
            return
        }
        UIView.animateKeyframes(withDuration: animationTime, delay: 0.0, animations: {
            sceneDelegate?.window?.bringSubviewToFront(dockView)
        }, completion: { _ in
            completion?()
        })
    }

    func detailExists() -> Bool {
        return detailBaseController != nil
    }

    // MARK: Back Button handling
    func backButtonState(isBackButton: Bool = true) {
        UIView.animate(withDuration: animationTime) { [weak self] in
            self?.backDownButton.transform = isBackButton ? .identity : CGAffineTransform(rotationAngle: -CGFloat(Double.pi / 2))
        }
    }

    func showHideBackButton(_ flag: Bool) {
        backDownButton.isHidden = flag
    }

    func setOpeningAnimationFromImage(_ imgView: UIImageView?) {
        guard let imageView = imgView, let imageOrigin = imageView.superview?.convert(imageView.frame.origin, to: nil) else { return }
        animator.frame = CGRect(x: imageOrigin.x, y: imageOrigin.y, width: imageView.frame.width, height: imageView.frame.height)
        animator.imageView = imageView
    }

    // MARK: Remove dock player
    func removeDockPlayer(_ forceRemove: Bool = false, completion: (() -> Void)? = nil) {
        if dockState == .undocked, !forceRemove, playerView != nil, isDockingAllowed, panGesture.state != .failed {
            updateDetailViewFrameToSmallMode(completion: completion) //No need to remove, down button tapped
            backButtonState(isBackButton: false)
            return
        }

        guard let dockView = dockableView, isDockingAllowed || dockState == .docked || playerView == nil, overDockingCompleted() else {
            completion?()
            return
        }

        deallocatePlayer()

        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
            dockView.transform = .identity
            if let _ = self?.animator.frame, self?.detailBaseController?.player == nil {
                dockView.frame = .zero
                dockView.center = sceneDelegate?.window?.center ?? .zero
                dockView.alpha = .zero
            } else if self?.swipeDirection == .left && !forceRemove {
                dockView.transform = CGAffineTransform(translationX: -(self?.screenWidth ?? 1000), y: 0.0)
            } else {
                dockView.transform = CGAffineTransform(translationX: self?.screenWidth ?? 1000, y: 0.0)
            }
        }, completion: { [weak self] _ in
            self?.dockableView = nil
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DockPlayerClosedNotification"), object: nil, userInfo: nil)
            completion?()
        })
    }

    // MARK: Deallocation
    private func deallocateDockplayer() {
        NotificationCenter.default.removeObserver(self)
        animator.frame = nil
        detailBaseController = nil
        dockableView?.removeFromSuperview()
        isBeingReset = false
        playerView = nil
    }

    private func deallocatePlayer() {
        panGesture.removeTarget(self, action: #selector(panGestureAction(_:)))
        if let player = detailBaseController?.player {
            player.replaceCurrentItem(with: nil)
        }
        isPlayerInitialized = false
    }

    func pauseContent() {
        guard let player = detailBaseController?.player, dockableView != nil else { return }
        player.pause()
    }

    func playContent() {
        guard let player = detailBaseController?.player, dockableView != nil else { return }
        player.play()
    }

    func restartPlayer(_ forceRefresh: Bool = false) {
        detailBaseController?.refreshScreen(forceRefresh)
    }

    func reloadScreen() {
        guard let detail = detailBaseController else { return }
        detail.refreshContent(with: "Data")
    }

    // MARK: Reset dock frame to full
    func resetFrame(completion: (() -> Void)? = nil) {
        guard playerMode == .smallScreen, let window = sceneDelegate?.window, let dockView = dockableView, let detailControllerRootViewSubviews = self.getDetailSubviews() else {
            completion?()
            return
        }

        if isPad, let widthConstraint = detailBaseController?.playerWidthConstraint.setMultiplier(multiplier: minimumMultiplerForHorizontalMovement) {
            detailBaseController?.playerWidthConstraint = widthConstraint
        }

        isBeingReset = true
        if panGesture.state == .changed {
            panGesture.state = .ended
        }

        if playerView == nil {
            backButtonState(isBackButton: true)
        }
        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            dockView.frame = window.frame
            self?.backDownButton.alpha = 1.0
            detailControllerRootViewSubviews.forEach {
                $0.alpha = 1
                $0.isUserInteractionEnabled = true
            }
        }, completion: { [weak self] _ in
            self?.dockState = .undocked
            self?.isBeingReset = false
            self?.bringDockPlayerToTop(completion: completion)
        })
    }

    // MARK: Gesture setup
    func setupGestureOnPlayerView() {
        guard isDockingAllowed else { return }

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        playerView = detailBaseController?.playerView
        playerView?.addGestureRecognizer(panGesture)

        guard panGesture.state != .failed else { return } //Don't add down button if pangesture is failing otherwise user will get blocked and dock won't close

        backButtonState(isBackButton: false)
    }

    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        guard !isBeingReset else { return }
        isFlicked = sender.state == .ended

        if let dockY = dockableView?.frame.origin.y {
            if dockY == finalDistanceFromTop && dockState != .docked && overDockingCompleted() && sender.state == .ended {
                dockState = (sender.state == .changed) ? .docking : .docked
            }
        }

        guard isPlayerInitialized, let dockView = dockableView, playerMode == .smallScreen, detailBaseController?.player != nil else { return }

        let translation = sender.translation(in: dockView)
        currentPoint = sender.state == .began ? .zero : translation
    }

    // MARK: - Private Methods
    private func manageShadow(value: Float) {
        dockableView?.layer.shadowOpacity = (value / 2)
    }

    private func makeViewDockable() {
        guard let dockView = dockableView, let window = sceneDelegate?.window else { return }
        window.addSubview(dockView)
        bringDockPlayerToTop()
        setupOpeningAnimation(for: dockView, from: window) { [unowned self] in
            self.addShadowBehindDockView()
        }
        detailBaseController?.playerInstantiated = { [unowned  self] in
            self.isPlayerInitialized = true
            self.setupGestureOnPlayerView()
        }
    }

    private func setupOpeningAnimation(for dockView: UIView, from window: UIWindow, completion: (() -> Void)? = nil) {
        guard let frame = animator.frame else {
            let transition = CATransition()
            transition.duration = animationTime
            transition.type = .push
            transition.subtype = .fromRight
            dockView.layer.add(transition, forKey: kCATransition)
            dockView.frame = window.frame
            completion?()
            return
        }

        detailBaseController?.setOpeningPoster(with: animator.imageView?.image)
        detailBaseController?.view.clipsToBounds = true
        dockView.clipsToBounds = true
        dockView.frame = frame
        UIView.animate(withDuration: animationTime, delay: 0.0, options: [], animations: {
            dockView.frame = window.frame
        }, completion: { _ in
            completion?()
        })
    }

    private func addShadowBehindDockView() {
        guard let dockView = dockableView else { return }
        dockView.layer.masksToBounds = false
        dockView.layer.shadowColor = UIColor.black.cgColor
        dockView.layer.shadowOpacity = 0.0
        dockView.layer.shadowOffset = CGSize(width: 0, height: 24)
        dockView.layer.shadowRadius = 24
    }

    private func getDetailSubviews() -> [UIView]? {
        return detailBaseController?.view.subviews.filter({ subview in
            return subview != playerView
        })
    }

    private func shouldAllowDocking(_ percentMoved: CGFloat) -> Bool {
        if dockState == .undocking && currentPoint.y > 0 && swipeDirection == .down {
            return false
        } else if dockState == .docking && currentPoint.y < 0 && swipeDirection == .up {
            return false
        } else if (dockState == .docked && swipeDirection == .down) || (swipeDirection == .up && dockState == .undocked) {
            return false
        } else if panGesture.state == .ended {
            return false
        } else if dockableView?.transform.ty ?? 0.0 > 0 {
            return false
        } else if percentMoved > 1.0 || percentMoved < 0.0 {
            return false
        } else {
            return true
        }
    }

    private func overDockingCompleted() -> Bool {
        return dockableView?.transform.ty == 0
    }

    private func updateMovingFrame() {
        switch swipeDirection {
        case .down, .up:
            movingSwipeVertical()
        case .right, .left:
            movingSwipeHorizontal()
        default:
            break
        }
    }

    private func updateEndingMovingFrame() {
        switch swipeDirection {
        case .left, .right:
            removeDockPlayer(false)
        case .down, .up:
            endingSwipeVertical()
        default:
            break
        }

        isVertical = false
        isHorizontal = false
    }

    private func endingSwipeVertical(completion: (() -> Void)? = nil) {
        if self.swipeDirection == .up {
            updateDetailViewFrameToFullMode(completion: completion)
        } else {
            updateDetailViewFrameToSmallMode(completion: completion)
        }
    }

    // MARK: Undock
    func updateDetailViewFrameToFullMode(completion: (() -> Void)? = nil) {
        guard let window = sceneDelegate?.window, let dockView = dockableView, let detailControllerRootViewSubviews = self.getDetailSubviews() else {
            completion?()
            return
        }

        guard overDockingCompleted() else {
            updateDetailViewFrameToSmallMode(completion: completion) //It was being overDocked
            return
        }

        if dockState == .docked && swipeDirection == .down {
            completion?()
            return
        }

        if isPad, let widthConstraint = detailBaseController?.playerWidthConstraint.setMultiplier(multiplier: minimumMultiplerForHorizontalMovement) {
            detailBaseController?.playerWidthConstraint = widthConstraint
        }
        bringDockPlayerToTop()
        detailBaseController?.docking(percentMoved: 1)
        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            CATransaction.setDisableActions(false)
            dockView.frame = window.frame
            self?.dockState = .undocking
            self?.manageShadow(value: 0.0)
            detailControllerRootViewSubviews.forEach {
                $0.alpha = 1
                $0.isUserInteractionEnabled = true
            }
            self?.backDownButton.alpha = 1.0
        }, completion: { [weak self] _ in
            self?.dockState = .undocked
            self?.swipeDirection = .none
            completion?()
        })
    }

    // MARK: Dock
    private func updateDetailViewFrameToSmallMode(completion: (() -> Void)? = nil) {
        if dockState == .undocked && swipeDirection == .up {
            completion?()
            return
        }

        guard let dockView = dockableView, let detailControllerRootViewSubviews = self.getDetailSubviews() else {
            completion?()
            return
        }

        if isPad, let widthConstraint = detailBaseController?.playerWidthConstraint.setMultiplier(multiplier: 1.0) {
            detailBaseController?.playerWidthConstraint = widthConstraint
        }
        detailBaseController?.docking(percentMoved: 0)
        let dockFrame = CGRect(x: self.finalDistanceFromLeft, y: self.finalDistanceFromTop, width: self.minWidth, height: self.minHeight)

        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            CATransaction.setDisableActions(false)
            dockView.transform = .identity
            dockView.frame = dockFrame
            self?.dockState = .docking
            self?.manageShadow(value: 1)

            detailControllerRootViewSubviews.forEach {
                $0.alpha = 0
                $0.isUserInteractionEnabled = false
            }
            self?.backDownButton.alpha = 0.0
        }, completion: { [weak self] _ in
            self?.overDockingPoint = 0.0
            self?.dockState = .docked
            self?.isHorizontal = false
            self?.isVertical = false
            self?.swipeDirection = .none
            self?.bringDockPlayerToTop(completion: completion)
        })
    }

    // MARK: Swipe Up/Down following finger
    private func movingSwipeVertical() {
        let currentDistanceFromTop = (dockState == .docking || dockState == .undocked) ? currentPoint.y : (finalDistanceFromTop - abs(currentPoint.y))
        let percentMoved = CGFloat(Int((currentDistanceFromTop / finalDistanceFromTop) * 10000)) / 10000
        let currentX = finalDistanceFromLeft * percentMoved
        let currentY = finalDistanceFromTop * percentMoved
        let currentWidth = screenWidth - finalDistanceFromLeft * percentMoved - (rightOffset * percentMoved)
        let currentHeight = screenHeight - finalDistanceFromTop * percentMoved - (bottomOffset * percentMoved)
        let alpha = 1 - percentMoved

        guard shouldAllowDocking(percentMoved) else {
            if currentHeight < screenHeight / 2 {
                overDock()
                detailBaseController?.docking(percentMoved: 1)
            }
            return
        }

        guard let dockView = dockableView, let detailControllerRootViewSubviews = getDetailSubviews() else { return }

        if isPad, let widthConstraint = detailBaseController?.playerWidthConstraint.setMultiplier(multiplier: minimumMultiplerForHorizontalMovement + percentMoved * horizontalDeltaMultiplier) {
            detailBaseController?.playerWidthConstraint = widthConstraint
        }
        detailBaseController?.docking(percentMoved: percentMoved)
        overDockingPoint = currentPoint.y

        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            CATransaction.setDisableActions(true)
            detailControllerRootViewSubviews.forEach {
                $0.alpha = alpha
                $0.isUserInteractionEnabled = false
            }
            self?.backDownButton.alpha = alpha
            self?.manageShadow(value: Float(percentMoved))
            dockView.frame = CGRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
        }, completion: { [weak self] _ in
            if self?.dockState == .undocked {
                self?.dockState = .docking
            } else if self?.dockState == .docked {
                self?.dockState = .undocking
            }
            self?.isHorizontal = false
        })

    }

    // MARK: Swipe Left/Right following finger
    private func movingSwipeHorizontal() {
        guard overDockingCompleted(), dockState == .docked, swipeDirection == .left || swipeDirection == .right, let dockView = dockableView else { return }

        UIView.animate(withDuration: animationTime, delay: 0.0, options: .curveLinear, animations: { [weak self] in
            CATransaction.setDisableActions(true)
            dockView.transform = CGAffineTransform(translationX: self?.currentPoint.x ?? 0.0, y: 0.0)
        }, completion: { [weak self] _ in
            self?.isVertical = false
        })
    }

    // MARK: Swipe down after docking following finger
    private func overDock() {
        guard swipeDirection == .down || swipeDirection == .up, let dockView = dockableView else { return }
        let dockFrame = CGRect(x: self.finalDistanceFromLeft, y: self.finalDistanceFromTop, width: self.minWidth, height: self.minHeight)

        UIView.animateKeyframes(withDuration: animationTime, delay: 0.0, options: [], animations: { [weak self] in
            CATransaction.setDisableActions(true)
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                if Int(dockView.frame.height) != Int(dockFrame.height) {
                    dockView.frame = dockFrame
                }
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.75) {
                dockView.transform = CGAffineTransform(translationX: 0.0, y: (self?.currentPoint.y ?? 0.0) - (self?.overDockingPoint ?? 0.0))
            }
        }, completion: { [weak self] _ in
            if self?.panGesture.state != .changed {
                self?.updateDetailViewFrameToSmallMode()
            }
        })
    }
}
