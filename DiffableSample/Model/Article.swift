//
//  Article.swift
//  DiffableSample
//
//  Created by 長田卓馬 on 2019/09/25.
//  Copyright © 2019 Takuma Osada. All rights reserved.
//

import Foundation

struct Article: Hashable {
    
    let title: String
    let url: String
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func contains(_ filter: String?) -> Bool {
        guard let filterText = filter else { return true }
        if filterText.isEmpty { return true }
        let lowercasedFilter = filterText.lowercased()
        return title.lowercased().contains(lowercasedFilter)
    }
}
