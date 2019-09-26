//
//  ViewModel.swift
//  DiffableSample
//
//  Created by 長田卓馬 on 2019/09/25.
//  Copyright © 2019 Takuma Osada. All rights reserved.
//

import Foundation
import Combine

final class ViewModel: ObservableObject {
    
    private let urlString = "https://qiita.com/api/v2/items?page=1&per_page=20"
    private let urlSession = URLSession.shared
    private let jsonDecoder = JSONDecoder()
    private var subscriptions = Set<AnyCancellable>()
    
    func fetchArticles(with filter: String? = nil) -> AnyPublisher<[Article], QiitaAPIError> {
        guard let url = URL(string: urlString) else {
                return Fail<[Article], QiitaAPIError>(error: .urlError(URLError(URLError.unsupportedURL))).eraseToAnyPublisher()
        }

        return urlSession.dataTaskPublisher(for: url)
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                    throw QiitaAPIError.responseError((response as? HTTPURLResponse)?.statusCode ?? 500)
                }
                return data
        }
        .decode(type: [Post].self, decoder: jsonDecoder)
        .mapError { (error) -> QiitaAPIError in
            switch error {
            case let urlError as URLError:
                return .urlError(urlError)
            case let decodingError as DecodingError:
                return .decodingError(decodingError)
            case let apiError as QiitaAPIError:
                return apiError
            default:
                return .genericError
            }
        }
        .map { (posts) -> [Article] in
            posts.map { (post) -> Article in
                let title = post.title
                let url = post.url
                return Article(title: title, url: url)
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
}
