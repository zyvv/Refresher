//
//  DefaultAnimateView.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/26.
//

import UIKit

public final class DefaultAnimateView: UIView, Refreshable {

    lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            return activityIndicator
        } else {
            let activityIndicator = UIActivityIndicatorView(style: .gray)
            return activityIndicator
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(activityIndicator)
        addConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(activityIndicator)
        addConstraints()
    }
    
    func addConstraints() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func transform(to progress: CGFloat) {
        activityIndicator.isHidden = false
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: progress, y: progress)
        transform = transform.rotated(by: CGFloat(Double.pi) * progress * 2)
        activityIndicator.transform = transform
    }
    
    public func animate(_ state: Refresher.State) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
        case .pulling(let progress):
            transform(to: progress)
        case .willRefresh(_):
            transform(to: 1)
        case .refreshing:
            activityIndicator.startAnimating()
        case .rebounding(progress: let progress):
            transform(to: 1-progress)
        }
    }
}
