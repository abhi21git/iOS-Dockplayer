//
//  GradientView.swift
//  DockPlayerDemo
//
//  Created by Abhishek Maurya on 23/02/22.
//

import UIKit

class GradientView: UIImageView {
    
    var gradientColors: [CGColor] = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.cgColor, UIColor.black.cgColor]
    var locations: [CGFloat]? = [0.0, 0.3, 1.0]
    
    override func layoutSubviews() {
        self.contentMode = .scaleToFill
//        self.backgroundColor = .darkGray
        self.image = drawGradientColor(in: self.bounds, colors: gradientColors)
    }
    
    func drawGradientColor(in rect: CGRect, colors: [CGColor]) -> UIImage? {
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.saveGState()
        defer { currentContext?.restoreGState() }
        
        let size = rect.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray,
                                        locations: locations) else { return nil }
        
        let context = UIGraphicsGetCurrentContext()
        context?.drawLinearGradient(gradient,
                                    start: CGPoint.zero,
                                    end: CGPoint(x: 0, y: size.height),
                                    options: [])
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return gradientImage
    }
}
