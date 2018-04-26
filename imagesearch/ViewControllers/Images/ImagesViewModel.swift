//
//  ImagesViewModel.swift
//  imagesearch
//
//  Created by ilia1395 on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation
import UIKit

final class ImagesViewModel {
    // MARK: - Properties

    private weak var viewController: ImagesViewController?

    private let mediaService = MediaService()

    private var imagesFetchResult: ImagesFetchResult? {
        didSet {
            guard let numberOfFetchedItems = imagesFetchResult?.currentResults.last?.numberOfFetchedItems else {
                numberOfImages.value = 0
                return
            }

            numberOfImages.value = numberOfFetchedItems
        }
    }

    private var imagesReloadingWorkItem: DispatchWorkItem?

    let numberOfImages = ObservableProperty<Int>(0)
    let isLoadingImages = ObservableProperty<Bool>(false)

    // MARK: - Lifecycle

    init(for viewController: ImagesViewController) {
        self.viewController = viewController
    }

    deinit {
        imagesReloadingWorkItem?.cancel()
    }

    // Mark: - View data

    func getImage(at index: Int) -> UIImage? {
        return nil
    }

    // MARK: - View events

    func handleViewDidLoadEvent() {

    }

    func handleViewPullToRefreshEvent() {

    }

    func handleImageRequest(at index: Int) {

    }

    func handleImageCancellationRequest(at index: Int) {

    }

    func viewDidRequestReloadImages(withSearchText searchText: String) {
        imagesReloadingWorkItem?.cancel()
        imagesReloadingWorkItem = nil

        guard !searchText.isEmpty else {
            imagesFetchResult = nil
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.reloadImagesAsync(withSearchText: searchText)
        }
        
        imagesReloadingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    // MARK: - Images loading

    @objc private func reloadImagesAsync(withSearchText searchText: String) {
        isLoadingImages.value = true

        // Position starts from `1`
        let query = ImagesFetchQuery(searchText: searchText, imageFormat: .png, limit: 10, position: 1)

        do {
            try mediaService.fetchImages(using: query) { [weak self] (succeed, result, error) in
                guard let strongSelf = self else { return }

                guard succeed else {
                    // TODO
                    strongSelf.isLoadingImages.value = false
                    return
                }

                strongSelf.imagesFetchResult = result
                strongSelf.isLoadingImages.value = false
            }
        } catch {
            // TODO
        }
    }
}











