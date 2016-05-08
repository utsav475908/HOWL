//
//  FlipViewController.swift
//  HOWL
//
//  Created by Daniel Clelland on 2/12/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import UIKit
import SnapKit

class FlipViewController: UIViewController {
    
    @IBOutlet var frontView: UIView?
    @IBOutlet var backView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backView?.removeFromSuperview()
    }
    
    func flip() {
        guard let frontView = frontView, let backView = backView, let state = state else {
            return
        }
        
        switch state {
        case .PresentingFrontView:
            flip(fromView: frontView, toView: backView)
        case .PresentingBackView:
            flip(fromView: backView, toView: frontView)
        }
    }
    
    private func flip(fromView fromView: UIView, toView: UIView) {
        view.addSubview(toView)
        
        toView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        UIView.transitionFromView(fromView, toView: toView, duration: 0.5, options: [.TransitionFlipFromLeft], completion: nil)
    }
    
    // MARK: - State
    
    enum State {
        case PresentingFrontView
        case PresentingBackView
    }
    
    var state: State? {
        if frontView?.superview != nil {
            return .PresentingFrontView
        }
        
        if backView?.superview != nil {
            return .PresentingBackView
        }
        
        return nil
    }
    
    // MARK: - View controllers
    
    var frontViewController: UIViewController? {
        return childViewControllers.filter { $0.view == frontView?.subviews.first }.first
    }
    
    var backViewController: UIViewController? {
        return childViewControllers.filter { $0.view == backView?.subviews.first }.first
    }

}

// MARK: - Reverse access

extension UIViewController {
    
    var flipViewController: FlipViewController? {
        return parentViewController as? FlipViewController
    }
    
}
