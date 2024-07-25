//
//  LaunchScreenAnimator.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import UIKit

class LaunchScreenAnimator {

    // MARK: - Properties

    static let instance = LaunchScreenAnimator(durationBase: 0.3)

    var view: UIView?
    var parentView: UIView?

    let durationBase: Double


    // MARK: - Lifecycle

    init(durationBase: Double) {
        self.durationBase = durationBase
    }

    func loadView() -> UIView {
        return UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

    // MARK: - Animation

    func animateAfterLaunch(_ parentViewPassedIn: UIView) {

        parentView = parentViewPassedIn
        view = loadView()
        
        parentView!.addSubview(view!)

        view!.frame = parentView!.bounds
        view!.center = parentView!.center
        
        let dot: UIView = view!.viewWithTag(42)!
        
        UIView.animate(
            withDuration: durationBase * 1.75,
            delay: durationBase / 1.5,
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
