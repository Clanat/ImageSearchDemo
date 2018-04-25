//
//  ImagesViewController.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import UIKit

class ImagesViewController: UIViewController {
    private var imagesViewModel: ImagesViewModel!

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        imagesViewModel = ImagesViewModel(with: self)
    }
}
