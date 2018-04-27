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

    private var imagesFetchResult: ImagesFetchResult?

    /// Image loading tasks keyed by image id
    private lazy var imagesLoadingTasksMap = [String: URLSessionTask]()
    
    private var imagesFetchTask: URLSessionTask?
    
    var numberOfImages: Int {
        return imagesFetchResult?.images.count ?? 0
    }
    
    // MARK: - Lifecycle

    init(for viewController: ImagesViewController) {
        self.viewController = viewController
    }

    deinit {
        imagesFetchTask?.cancel()
    }

    // MARK: - View events
    
    func viewDidRequestImage(at imageIndex: Int) {
        guard let image = imagesFetchResult?.images[imageIndex] else {
            return
        }
        
        let imageId = image.id
        let imageURL = image.url
        let task = mediaService.loadImage(from: imageURL) { [weak self] (succeed, image, error) in
            guard let strongSelf = self else { return }
            
            guard succeed, let image = image else {
                strongSelf.didFailLoadingImage(at: imageIndex, with: error ?? ImageLoadError.unknown)
                return
            }
            
            strongSelf.didLoadImage(image, at: imageIndex, withId: imageId)
        }
        
        imagesLoadingTasksMap[imageId] = task
    }
    
    func viewDidCancelImageLoading(at imageIndex: Int) {
        guard !imagesLoadingTasksMap.isEmpty else { return }
        
        guard let imageId = imagesFetchResult?.images[imageIndex].id else {
            return
        }
        
        guard let task = imagesLoadingTasksMap[imageId] else {
            return
        }
        
        task.cancel()
        imagesLoadingTasksMap[imageId] = nil
    }
    
    func viewDidRequestNextImages() {
        guard imagesFetchTask == nil else { return }
        
        // Assume we have next page
        guard let fetchResult = imagesFetchResult, let nextPosition = fetchResult.nextPosition else { return }
        
        viewController?.beginNextPageLoading()
        
        let query = ImagesFetchQuery(searchText: viewController?.searchText, imageFormat: .jpg, position: nextPosition)
        do {
            imagesFetchTask = try mediaService.fetchFakeImages(using: query) { [weak self] (succeed, result, error) in
                guard let strongSelf = self else { return }
                
                strongSelf.viewController?.endNextPageLoading()
                
                // TODO: handle errors
                
                strongSelf.imagesFetchTask = nil
                
                if let oldResult = strongSelf.imagesFetchResult, let newResult = result {
                    oldResult.images += newResult.images
                    oldResult.position = newResult.position
                    oldResult.nextPosition = newResult.nextPosition
                    strongSelf.viewController?.insertNewImages(count: newResult.images.count)
                }
            }
        } catch {
            viewController?.endNextPageLoading()
            // TODO: handle errors
        }
    }

    func viewDidRequestReloadImages() {
        imagesFetchTask?.cancel()
        imagesFetchTask = nil
        
        imagesLoadingTasksMap.forEach { (imageId, imageLoadingTask) in
            imageLoadingTask.cancel()
        }
        
        imagesLoadingTasksMap = [:]
        
        viewController?.beginReloading()
        
        // Position starts from `1`
        let query = ImagesFetchQuery(searchText: viewController?.searchText, imageFormat: .jpg, position: 1)

        do {
            imagesFetchTask = try mediaService.fetchFakeImages(using: query) { [weak self] (succeed, result, error) in
                guard let strongSelf = self else { return }
                
                // TODO: handle errors
                
                strongSelf.imagesFetchTask = nil
                strongSelf.imagesFetchResult = result
                strongSelf.viewController?.reloadImages()
                strongSelf.viewController?.endReloading()
            }
        } catch {
            // TODO: handle errors
        }
    }
    
    private func didLoadImage(_ image: UIImage, at imageIndex: Int, withId imageId: String) {
        imagesLoadingTasksMap[imageId] = nil
        viewController?.updateImage(at: imageIndex, with: image)
    }
    
    private func didFailLoadingImage(at imageIndex: Int, with error: Error) {
        guard let image = imagesFetchResult?.images[imageIndex] else { return }
        
        NSLog("Could not load image at \(image.url), reason: ", error.localizedDescription)
    }
}









