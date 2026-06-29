//
//  GeckoView.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import UIKit

public class GeckoView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var session: GeckoSession? {
        didSet {
            embedSessionView()
        }
    }
    
    private func embedSessionView() {
        subviews.forEach { $0.removeFromSuperview() }
        
        guard let session else {
            return
        }
        
        guard let window = session.window else {
            NSLog("GeckoView: session window is unavailable during assignment")
            return
        }
        
        guard let engineView = window.view() else {
            NSLog("GeckoView: session window has no view!")
            return
        }
        
        if engineView.superview != nil {
            fatalError("attempt to assign GeckoSession to multiple GeckoView instances")
        }

        attach(engineView)
    }

    public func restoreSessionViewIfNeeded() {
        guard let engineView = session?.engineView else { return }
        if engineView.superview === self {
            engineView.isHidden = false
            engineView.alpha = 1
            engineView.isUserInteractionEnabled = true
            setNeedsLayout()
            return
        }

        guard engineView.superview == nil else {
            NSLog("GeckoView: refusing to steal a session view from another host")
            return
        }

        attach(engineView)
    }

    private func attach(_ engineView: UIView) {
        
        engineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(engineView)
        
        NSLayoutConstraint.activate([
            engineView.topAnchor.constraint(equalTo: topAnchor),
            engineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            engineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            engineView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}
