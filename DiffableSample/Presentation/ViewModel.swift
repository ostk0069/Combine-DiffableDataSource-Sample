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
    
    private let url = "https://qiita.com/api/v2/items?page=1&per_page=20"
    private let urlSession = URLSession.shared
    private let jsonDecoder = JSONDecoder()
    private var subscriptions = Set<AnyCancellable>()

    func fetchArticles(with filter: String? = nil) -> Future<[Article], QiitaAPIError> {
        return Future<[Article], QiitaAPIError> { [weak self] promise in
            guard
                let strongSelf = self,
                let url = URL(string: strongSelf.url)
            else {
                return promise(.failure(.urlError(URLError(URLError.unsupportedURL))))
            }
            strongSelf.urlSession.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw QiitaAPIError.responseError((response as? HTTPURLResponse)?.statusCode ?? 500)
                    }
                    return data
                }
            .decode(type: [Post].self, decoder: strongSelf.jsonDecoder)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                if case let .failure(error) = completion {
                    switch error {
                    case let urlError as URLError:
                        promise(.failure(.urlError(urlError)))
                    case let decodingError as DecodingError:
                        promise(.failure(.decodingError(decodingError)))
                    case let apiError as QiitaAPIError:
                        promise(.failure(apiError))
                    default:
                        promise(.failure(.genericError))
                    }
                 }
            }, receiveValue: { (posts) in
                let articles: [Article] = posts.map { (post) -> Article in
                    let title = post.title
                    let url = post.url
                    return Article(title: title, url: url)
                }
                promise(.success(articles))
            })
            .store(in: &strongSelf.subscriptions)
        }
    }
}
