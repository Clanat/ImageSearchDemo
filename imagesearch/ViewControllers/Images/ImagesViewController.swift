//
//  ImagesViewController.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import UIKit

class ImagesViewController: UIViewController {
    // MARK: - Properties

    private var viewModel: ImagesViewModel!

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var searchBar: UISearchBar!
    
    var searchText: String? {
        return searchBar.text
    }
    
    // MARK: - Lifecycle

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        viewModel = ImagesViewModel(for: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        collectionView.register(ImageCollectionViewCell.self)
        
        let padding: CGFloat = 1
        let imagesPerRow = 4
        
        var imageWidth: CGFloat = 100
        if let windowWidth = UIApplication.shared.keyWindow?.frame.width {
            let availableWidth = windowWidth - padding * max(CGFloat(imagesPerRow - 1), 0)
            imageWidth = (availableWidth / CGFloat(imagesPerRow)).rounded(.down)
        }
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: imageWidth, height: imageWidth)
        flowLayout.minimumInteritemSpacing = padding
        flowLayout.minimumLineSpacing = padding
        
        collectionView.collectionViewLayout = flowLayout
    }
    
    // MARK: - UI updating
    
    func reloadImages() {
        collectionView.contentOffset = .zero
        collectionView.reloadData()
    }
    
    func insertNewImages(count: Int) {
        guard count > 0 else { return }
        
        let startIndex = viewModel.numberOfImages - count
        let endIndex = viewModel.numberOfImages - 1
        let indexPaths = (startIndex...endIndex).map { IndexPath(item: $0, section: 0) }
        collectionView.insertItems(at: indexPaths)
    }
    
    func updateImage(at imageIndex: Int, with image: UIImage) {
        let indexPath = IndexPath(item: imageIndex, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell else {
            return
        }
        
        cell.image = image
    }
    
    func beginReloading() {
        UIView.animate(withDuration: 0.2) {
            self.collectionView.alpha = 0
        }
        loadingIndicatorView.startAnimating()
    }
    
    func endReloading() {
        loadingIndicatorView.stopAnimating()
        collectionView.alpha = 1
    }
    
    func beginNextPageLoading() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func endNextPageLoading() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// MARK: - UICollectionViewDataSource

extension ImagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfImages
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ImageCollectionViewCell.self, for: indexPath)
        viewModel.viewDidRequestImage(at: indexPath.row)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ImagesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard viewModel.numberOfImages > 0 else { return }
        guard indexPath.row == viewModel.numberOfImages - 1 else { return }
        
        // TODO: display footer loading indicator
        viewModel.viewDidRequestNextImages()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.viewDidCancelImageLoading(at: indexPath.row)
    }
}

// MARK: - UISearchBarDelegate

extension ImagesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        viewModel.viewDidRequestReloadImages()
    }
}




