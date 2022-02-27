//
//  HomeLandingVC.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit

class HomeLandingVC: BaseController {
    @IBOutlet weak var backgroundPosterImage: UIImageView!
    @IBOutlet weak var posterContainerView: UIView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var bottomContainerView: GradientView!
    @IBOutlet weak var bottomHeadupsView: UIView!
    @IBOutlet weak var bottomCardView: UIView!
    @IBOutlet weak var watchNowButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performAnimation()
    }
    
    func setupUI() {
        backgroundPosterImage.addBlur()
    }
    
    func setupAnimation() {
        bottomHeadupsView.transform = CGAffineTransform(translationX: 0, y: 50)
        posterImageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
    }
    
    func performAnimation() {
        UIView.animate(withDuration: 0.4, delay: 0.5) { [weak self] in
            self?.bottomHeadupsView.transform = .identity
            self?.posterImageView.transform = .identity
        }
    }

    @IBAction func watchButtonAction() {
        DockPlayer.manager.initialize(DetailPageController.instantiate(from: .detailPage), for: "", with: posterImageView)
    }
}
