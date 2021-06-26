//
//  UIScrollView+Refresher.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/25.
//

import UIKit

private struct AssociatedKeys {
    static var topRefresherKey: UInt8 = 0
    static var bottomRefresherKey: UInt8 = 0
}

public extension UIScrollView {
    
    var topRefresher: Refresher? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.topRefresherKey) as? Refresher
        }
        
        set {
            if newValue != self.topRefresher {
                self.topRefresher?.removeFromSuperview()
                newValue?.position = .top
                guard let refresher = newValue else { return }
                self.insertSubview(refresher, at: 0)
            }
            objc_setAssociatedObject(self, &AssociatedKeys.topRefresherKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var bottomRefresher: Refresher? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.bottomRefresherKey) as? Refresher
        }
        
        set {
            if newValue != self.bottomRefresher {
                self.bottomRefresher?.removeFromSuperview()
                newValue?.position = .bottom
                guard let refresher = newValue else { return }
                self.insertSubview(refresher, at: 0)
            }
            objc_setAssociatedObject(self, &AssociatedKeys.bottomRefresherKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
