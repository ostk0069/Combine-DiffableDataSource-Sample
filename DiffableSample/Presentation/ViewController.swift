//
//  ViewController.swift
//  DiffableSample
//
//  Created by 長田卓馬 on 2019/09/25.
//  Copyright © 2019 Takuma Osada. All rights reserved.
//

import UIKit
import Combine

enum Section: CaseIterable {
    case main
}

class ViewController: UIViewController {
    
    private let viewModel = ViewModel()
    private let searchBar = UISearchBar(frame: .zero)
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Article>?
    private var subscriptions = Set<AnyCancellable>()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        $0.hidesWhenStopped = true
        $0.center = self.view.center
        self.view.addSubview($0)
        return $0
    }(UIActivityIndicatorView(style: .large))
    private var isFetchingData = CurrentValueSubject<Bool, Never>(false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        fetchArticles(with: nil)
    }
    
    private func bindActivityIndicator() {
        isFetchingData
            .assign(to: \UIActivityIndicatorView.animatable,
                    on: self.activityIndicator)
            .store(in: &subscriptions)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource
            <Section, Article>(collectionView: collectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath,
                article: Article) -> UICollectionViewCell? in
            guard
                let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: LabelCell.reuseIdentifier,
                for: indexPath) as? LabelCell
                else {
                    fatalError("Cannot create new cell")
                }
            cell.label.text = article.title
            return cell
        }
    }
    
    private func performQuery(with articles: [Article], filter: String?) {
        let filteredArticles = articles.filter { $0.contains(filter) }.sorted { $0.title < $1.title }
        var snapshot = NSDiffableDataSourceSnapshot<Section, Article>()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredArticles)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func fetchArticles(with filter: String?) {
        isFetchingData.value = true
        viewModel.fetchArticles()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.handleError(apiError: error)
                }
                self.isFetchingData.value = false
                }, receiveValue: { [weak self] in
                    self?.performQuery(with: $0, filter: filter)
            })
            .store(in: &self.subscriptions)
    }
    
    private func configureHierarchy() {
        view.backgroundColor = .systemBackground
        let layout = createLayout()
        let cv = UICollectionView(
            frame: view.bounds, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.register(
            LabelCell.self, forCellWithReuseIdentifier: LabelCell.reuseIdentifier)
        view.addSubview(cv)
        view.addSubview(searchBar)

        let views = ["cv": cv, "searchBar": searchBar]
        var constraints = [NSLayoutConstraint]()
        constraints.append(
            contentsOf: NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[cv]|",
                options: [], metrics: nil, views: views))
        constraints.append(
            contentsOf: NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[searchBar]|",
                options: [], metrics: nil, views: views))
        constraints.append(
            contentsOf: NSLayoutConstraint.constraints(
                withVisualFormat: "V:[searchBar]-20-[cv]|",
                options: [], metrics: nil, views: views))
        constraints.append(
            searchBar.topAnchor.constraint(
                equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor,
                multiplier: 1.0))
        NSLayoutConstraint.activate(constraints)
        collectionView = cv

        searchBar.delegate = self
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            let contentSize = layoutEnvironment.container.effectiveContentSize
            let columns = contentSize.width > 800 ? 3 : 2
            let spacing = CGFloat(10)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(32))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize, subitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 10, leading: 10, bottom: 10, trailing: 10)

            return section
        }
        return layout
    }
    
    func handleError(apiError: QiitaAPIError) {
        let alertController = UIAlertController(title: "Error", message: apiError.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true)
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchArticles(with: searchText)
    }
}

