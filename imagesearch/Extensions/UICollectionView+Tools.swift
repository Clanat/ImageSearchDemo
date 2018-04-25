//
//  UICollectionView+Tools.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation
import UIKit

// MARK: - UICollectionView + Custom reloading

extension UICollectionView {
    func reloadData(keepContentOffset: Bool) {
        guard keepContentOffset else {
            reloadData()
            return
        }

        let oldContentOffset = contentOffset
        reloadData()
        let newContentOffset = contentOffset

        let maxDelta: CGFloat = 0.1
        if (newContentOffset.x - oldContentOffset.x) > maxDelta || (newContentOffset.y - oldContentOffset.y) > maxDelta {
            contentOffset = oldContentOffset
        }
    }
}

// MARK: - UICollectionView + ReusableCollectionViewCell

extension UICollectionView {
    func register<Cell: ReusableCollectionViewCell>(_ cellClass: Cell.Type) {
        register(Cell.nib, forCellWithReuseIdentifier: Cell.reuseId)
    }

    func dequeueReusableCell<Cell: ReusableCollectionViewCell>(_ cellClass: Cell.Type, for indexPath: IndexPath) -> Cell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: Cell.reuseId, for: indexPath) as? Cell else {
            fatalError("Invalid collection view configuration")
        }

        return cell
    }
}

