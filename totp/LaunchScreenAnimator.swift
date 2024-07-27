//
//  LaunchScreenAnimator.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import UIKit

class LaunchScreenAnimator {

    static let instance = LaunchScreenAnimator()

    var view: UIView?
    var parentView: UIView?

    func loadView() -> UIView {
        return UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

    func animateAfterLaunch(_ parentViewPassedIn: UIView) {

        parentView = parentViewPassedIn
        view = loadView()
        
        parentView!.addSubview(view!)

        view!.frame = parentView!.bounds
        view!.center = parentView!.center
        
        let dot: UIView = view!.viewWithTag(42)!
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0.2,
            options: .curveLinear,
            animations: {
                var transform = CGAffineTransform.identity
                transform = transform.scaledBy(x: 50, y: 50)
                dot.transform = transform
            },
            completion: { _ in
                self.view!.removeFromSuperview()
            }
        )
    }
    
}
