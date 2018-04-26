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
    @IBOutlet private var loadingIndicatorVIew: UIActivityIndicatorView!
}
