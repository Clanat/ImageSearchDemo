//
//  ImageCollectionViewCell.swift
//  imagesearch
//
//  Created by ilia1395 on 26/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell, ReusableCollectionViewCell {
    @IBOutlet private var imageView: UIImageView!
    
    var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.backgroundColor = newValue == nil ? UIColor(white: 0.9, alpha: 1) : nil
            imageView.image = newValue
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
