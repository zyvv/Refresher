//
//  Color.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/26.
//

import Foundation
import UIKit

struct Color: Hashable {
    let name: String
    let color: UIColor
}

extension Color {
    static func random() -> Color {
        let r = CGFloat.random()
        let g = CGFloat.random()
        let b = CGFloat.random()
        let color = UIColor(red: r, green: g, blue: b, alpha: 1)
        let name = "R:\(Int(r*255)) G:\(Int(g*255)) B:\(Int(b*255))"
        return Color(name: name, color: color)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

