//
//  UICollectionViewCell+Tools.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionViewCell {
    static var reuseId: String {
        return String(describing: self)
    }

    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
}

protocol ReusableCollectionViewCell where Self: UICollectionViewCell {
    static var nib: UINib { get }
    static var reuseId: String { get }
}
