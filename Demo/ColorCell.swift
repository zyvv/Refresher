//
//  ColorCell.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/26.
//

import UIKit

class ColorCell: UICollectionViewCell {
    static let reuserIdentifier = "ColorCell"
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell(_ color: Color) {
        backgroundColor = color.color
        label.text = color.name
    }

}
