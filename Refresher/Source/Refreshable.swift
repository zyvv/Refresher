//
//  Refreshable.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/25.
//

import Foundation
import UIKit

public protocol Refreshable where Self: UIView {
    func animate(_ state: Refresher.State)
}
