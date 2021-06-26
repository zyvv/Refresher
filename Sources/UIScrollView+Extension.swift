//
//  UIScrollView+Extension.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/24.
//

import UIKit

extension UIScrollView {
    
    var inset: UIEdgeInsets {
        adjustedContentInset
    }
    
    var topInset: CGFloat {
        get {
            adjustedContentInset.top
        }
        set {
            contentInset.top = newValue - (adjustedContentInset.top - contentInset.top)
        }
    }
    
    var bottomInset: CGFloat {
        get {
            inset.bottom
        }
        set {
            contentInset.bottom = newValue - (adjustedContentInset.bottom - contentInset.bottom)
        }
    }
    
    var leftInset: CGFloat {
        get {
            inset.left
        }
        set {
            contentInset.right = newValue - (adjustedContentInset.right - contentInset.right)
        }
    }
    
    var rightInset: CGFloat {
        get {
            inset.right
        }
        set {
            contentInset.left = newValue - (adjustedContentInset.left - contentInset.left)
        }
    }
    
    var offsetX: CGFloat {
        get {
            contentOffset.x
        }
        set {
            contentOffset.x = newValue
        }
    }
    
    var offsetY: CGFloat {
        get {
            contentOffset.y
        }
        set {
            contentOffset.y = newValue
        }
    }
    
    var contentWidth: CGFloat {
        get {
            contentSize.width
        }
        set {
            contentSize.width = newValue
        }
    }
    
    var contentHeight: CGFloat {
        get {
            contentSize.height
        }
        set {
            contentSize.height = newValue
        }
    }
}
