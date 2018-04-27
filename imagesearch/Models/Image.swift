//
//  Image.swift
//  imagesearch
//
//  Created by ilia1395 on 26/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation

struct Image: Decodable {
    let id = UUID().uuidString
    let url: URL

    private enum CodingKeys: String, CodingKey {
        case image
    }
    
    private enum ImageCodingKeys: String, CodingKey {
        case thumbnailLink
    }
    
    init(url: URL) {
        self.url = url
    }
    
    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
        let imageContainer = try rootContainer.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .image)
        
        url = try imageContainer.decode(URL.self, forKey: .thumbnailLink)
    }
}

extension Image: Equatable {
    static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url
    }
}
