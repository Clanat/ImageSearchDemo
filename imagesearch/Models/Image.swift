//
//  Image.swift
//  imagesearch
//
//  Created by ilia1395 on 26/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation

struct Image: Decodable {
    let title: String
    let url: URL

    private enum CodingKeys: String, CodingKey {
        case title
        case url = "link"
    }
}

extension Image: Equatable {
    static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.title == rhs.title && lhs.url == rhs.url
    }
}
