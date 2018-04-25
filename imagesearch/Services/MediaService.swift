//
//  MediaService.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation

enum ImageFormat: String {
    // TODO: support other formats
    case png
}

struct ImagesFetchQuery {
    private enum Keys: String {
        case searchText = "q"
        case imageFormat = "fileType"
        case imageSize = "imgSize"
        case limit = "num"
        case position = "start"
    }

    let searchText: String?
    let imageFormat: ImageFormat
    let limit: Int
    let position: Int

    func serialize() -> [String: String] {
        var rawObject = [String: String]()

        if let searchText = self.searchText, !searchText.isEmpty {
            rawObject[Keys.searchText.rawValue] = searchText
        }

        // TODO: validation
        rawObject[Keys.imageFormat.rawValue] = imageFormat.rawValue
        rawObject[Keys.limit.rawValue] = "\(limit)"
        rawObject[Keys.position.rawValue] = "\(position)"
        rawObject[Keys.imageSize.rawValue] = "medium"

        return rawObject
    }
}

struct ImagesFetchResult: Decodable {
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

    private enum Constants {
        static let endpointURLString = "https://www.googleapis.com/customsearch/v1"
        static let googleApiKey = "AIzaSyAlFYcGh4ZqNe3EVuc-2mTv1E17e0qhINE"
        static let googleSearchEngineId = "004647109859050968818:jy5dzwbbbxw"
    }

    private enum Keys {
        static let googleApiKey = "key"
        static let googleSearchEngineId = "cx"
        static let googleSearchType = "searchType"
    }

    // MARK: - Properties

    private let urlSession: URLSession

    init() {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 5
        urlSession = URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
    }
}

// MARK: - Images fetching

extension MediaService {
    @discardableResult
    func fetchImages(using query: ImagesFetchQuery, _ callback: @escaping ImagesFetchCallback) throws -> URLSessionTask {
        guard var urlComponents = URLComponents(string: Constants.endpointURLString) else {
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
                let result = try decoder.decode(ImagesFetchResult.self, from: data)
                DispatchQueue.main.async { callback(true, result, nil) }
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
}

enum ImagesFetchError: Error {
    case requestCreationFailure
    case invalidResponse
}
