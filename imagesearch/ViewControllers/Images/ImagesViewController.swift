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

    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        viewModel = ImagesViewModel(for: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        viewModel.handleViewDidLoadEvent()
    }

    private func setupView() {
        setupCollectionView()

        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)

        viewModel.numberOfImages.observe { [weak self] (value) in
            self?.collectionView.reloadData(keepContentOffset: true)
        }

        viewModel.isLoadingImages.observe { [weak self] (isLoading) in
            guard let strongSelf = self else { return }

            if isLoading {
                strongSelf.collectionView.alpha = 0
                strongSelf.loadingIndicatorView.startAnimating()
            } else {
                strongSelf.loadingIndicatorView.stopAnimating()
                UIView.animate(withDuration: 0.2, animations: {
                    strongSelf.collectionView.alpha = 1
                })
            }
        }

    }

    private func setupCollectionView() {
        collectionView.register(ImageCollectionViewCell.self)

        let padding: CGFloat = 1
        let imagesPerRow = 4
        let availableWidth = view.frame.width - padding * max(CGFloat(imagesPerRow - 1), 0)
        let imageWidth = (availableWidth / CGFloat(imagesPerRow)).rounded(.down)

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: imageWidth, height: imageWidth)
        flowLayout.minimumInteritemSpacing = padding
        flowLayout.minimumLineSpacing = padding

        collectionView.collectionViewLayout = flowLayout

        if #available(iOS 10, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
    }

    private func updateImage(_ image: UIImage, at index: Int) {

    }

    // MARK: - Actions

    @objc private func refreshControlValueChanged() {

    }
}

// MARK: - UICollectionViewDataSource

extension ImagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfImages.value
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ImageCollectionViewCell.self, for: indexPath)

        return cell
    }
}

// MARK: - UISearchBarDelegate

extension ImagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.viewDidRequestReloadImages(withSearchText: searchText)
    }
}





