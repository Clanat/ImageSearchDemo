//
//  MediaService.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation
import UIKit

enum ImageFormat: String {
    // TODO: support other formats
    case jpg
}

enum ImageSize: String {
    case medium
}

struct ImagesFetchQuery {
    static let limit = 10
    
    private enum Keys: String {
        case searchText = "q"
        case imageFormat = "fileType"
        case imageSize = "imgSize"
        case limit = "num"
        case position = "start"
    }

    let searchText: String?
    let imageFormat: ImageFormat
    let position: Int
    
    // TODO: support sizes
    let imageSize: ImageSize = .medium

    func serialize() -> [String: String] {
        var rawObject = [String: String]()

        if let searchText = self.searchText, !searchText.isEmpty {
            rawObject[Keys.searchText.rawValue] = searchText
        }

        // TODO: validation
        rawObject[Keys.imageFormat.rawValue] = imageFormat.rawValue
        rawObject[Keys.limit.rawValue] = "\(ImagesFetchQuery.limit)"
        rawObject[Keys.position.rawValue] = "\(position)"
        rawObject[Keys.imageSize.rawValue] = imageSize.rawValue

        return rawObject
    }
}

final class ImagesSearchResult: Decodable {
    private enum ResultKeys: String, CodingKey {
        case queries
        case items
    }

    private enum QueriesKeys: String, CodingKey {
        case request
        case nextPage
    }

    let currentResults: [SearchResultInfo]
    let nextResults: [SearchResultInfo]
    let images: [Image]

    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: ResultKeys.self)

        let queriesContainer = try rootContainer.nestedContainer(keyedBy: QueriesKeys.self, forKey: .queries)
        currentResults = try queriesContainer.decode([SearchResultInfo].self, forKey: .request)
        nextResults = try queriesContainer.decode([SearchResultInfo].self, forKey: .nextPage)

        images = try rootContainer.decode([Image].self, forKey: .items)
    }
}

final class ImagesFetchResult {
    var images: [Image]
    var position: Int
    
    var nextPosition: Int?
    
    init(images: [Image], position: Int, nextPosition: Int?) {
        self.images = images
        self.position = position
        self.nextPosition = nextPosition
    }
}

struct SearchResultInfo: Decodable {
    let numberOfFoundItems: Int
    let numberOfFetchedItems: Int
    let position: Int

    private enum CodingKeys: String, CodingKey {
        case numberOfFoundItems = "totalResults"
        case numberOfFetchedItems = "count"
        case position = "startIndex"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Google returns String instead of Int =\
        let numberOfFoundItemsString = try container.decode(String.self, forKey: .numberOfFoundItems)
        guard let numberOfFoundItems = Int(numberOfFoundItemsString) else {
            let context = DecodingError.Context(codingPath: [CodingKeys.numberOfFoundItems],
                                                debugDescription: "Expected Int value inside String")
            throw DecodingError.typeMismatch(String.self, context)
        }

        self.numberOfFoundItems = numberOfFoundItems
        numberOfFetchedItems = try container.decode(Int.self, forKey: .numberOfFetchedItems)
        position = try container.decode(Int.self, forKey: .position)
    }
}

final class MediaService {
    typealias ImagesFetchCallback = (_ succeed: Bool, _ result: ImagesFetchResult?, _ error: Error?) -> Void
    typealias ImageLoadCallback = (_ succeed: Bool, _ image: UIImage?, _ error: Error?) -> Void

    private enum Constants {
        static let googleSearchURLString = "https://www.googleapis.com/customsearch/v1"
        static let googleApiKey = "AIzaSyAlFYcGh4ZqNe3EVuc-2mTv1E17e0qhINE"
        static let googleSearchEngineId = "004647109859050968818:jy5dzwbbbxw"
    }

    private enum Keys {
        static let googleApiKey = "key"
        static let googleSearchEngineId = "cx"
        static let googleSearchType = "searchType"
    }

    // MARK: - Properties

    private let urlSession: URLSession = URLSession(configuration: .default)
}

// MARK: - Images fetching

extension MediaService {
    @discardableResult
    func fetchImages(using query: ImagesFetchQuery, _ callback: @escaping ImagesFetchCallback) throws -> URLSessionTask {
        guard var urlComponents = URLComponents(string: Constants.googleSearchURLString) else {
            throw ImagesFetchError.requestCreationFailure
        }

        var queryItems = query.serialize().map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: Keys.googleApiKey, value: Constants.googleApiKey))
        queryItems.append(URLQueryItem(name: Keys.googleSearchEngineId, value: Constants.googleSearchEngineId))
        queryItems.append(URLQueryItem(name: Keys.googleSearchType, value: "image"))
        urlComponents.queryItems = queryItems

        guard let requestURL = urlComponents.url else {
            throw ImagesFetchError.requestCreationFailure
        }

        var request = URLRequest(url: requestURL)
        // TODO: headers?
        request.httpMethod = "GET"

        let failureHandler = { (error: Error) in
            DispatchQueue.main.async { callback(false, nil, error) }
        }

        let successHandler = { (data: Data) in
            let decoder = JSONDecoder()

            do {
                let searchResult = try decoder.decode(ImagesSearchResult.self, from: data)
                
                // Retrieving info about results
                guard let searchResultInfo = searchResult.currentResults.last else {
                    failureHandler(ImagesFetchError.invalidResponse)
                    return
                }
                
                
                // Google image search is deprecated and no longer available
                // Google CSE (custom search engine) has some limitations
                // 1. Limit is low
                // 2. 100 requests per day
                // https://stackoverflow.com/questions/37579267/custom-google-search-increase-number-of-results
                
                // Make fake copies for pagination
                var fetchedImages = searchResult.images
                if fetchedImages.count == ImagesFetchQuery.limit {
                    fetchedImages += fetchedImages
                    fetchedImages += fetchedImages
                    fetchedImages += fetchedImages
                    fetchedImages += fetchedImages
                    fetchedImages += fetchedImages
                }
                
                let nextPosition = searchResult.nextResults.last?.position
                let fetchResult = ImagesFetchResult(images: fetchedImages,
                                                    position: searchResultInfo.position,
                                                    nextPosition: nextPosition)
                DispatchQueue.main.async { callback(true, fetchResult, nil) }
            } catch {
                failureHandler(error)
            }
        }

        let task = urlSession.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                failureHandler(error ?? ImagesFetchError.invalidResponse)
                return
            }

            switch response.statusCode {
            // OK
            case 200:
                guard let data = data else {
                    failureHandler(ImagesFetchError.invalidResponse)
                    return
                }
                successHandler(data)
            // TODO: handle other statuses
            default:
                failureHandler(error ?? ImagesFetchError.invalidResponse)
            }
        }

        task.resume()
        return task
    }
    
    @discardableResult
    func fetchFakeImages(using query: ImagesFetchQuery, _ callback: @escaping ImagesFetchCallback) throws -> URLSessionTask {
        DispatchQueue.global().async {
            guard let fakeImageURL = URL(string: "https://png.icons8.com/ios/400/swift-filled.png") else {
                DispatchQueue.main.async {
                    callback(false, nil, ImagesFetchError.invalidImageURL)
                }
                return
            }
            
            let images = [Image](repeating: Image(url: fakeImageURL), count: 100)
            let result = ImagesFetchResult(images: images, position: query.position, nextPosition: query.position + 100)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                callback(true, result, nil)
            }
        }
        
        return URLSessionTask()
    }
    
    @discardableResult
    func loadImage(from url: URL, _ callback: @escaping ImageLoadCallback) -> URLSessionTask {
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            
            if let error = error, (error as NSError).code == NSURLErrorCancelled {
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback(false, nil, error ?? ImageLoadError.unknown)
                }
                return
            }
            
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                callback(true, image, nil)
            }
        }
        
        task.resume()
        return task
    }
}

enum ImagesFetchError: Error {
    // TODO: localized errors
    case requestCreationFailure
    case invalidImageURL
    case invalidResponse
}

enum ImageLoadError: Error {
    // TODO: localized errors
    case unknown
}




