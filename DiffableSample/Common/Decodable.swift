//
//  Post.swift
//  DiffableSample
//
//  Created by 長田卓馬 on 2019/09/25.
//  Copyright © 2019 Takuma Osada. All rights reserved.
//

import Foundation

struct Post: Decodable {
    
    var renderedBody: String
    var body: String
    var createdAt: String
    var id: String
    var likesCount: Int
    var title: String
    var url: String
    
    enum CodingKeys: String, CodingKey {
        case renderedBody = "rendered_body"
        case body
        case createdAt = "created_at"
        case id
        case likesCount = "likes_count"
        case title
        case url
    }
}

