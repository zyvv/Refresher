//
//  ViewController.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/24.
//

import UIKit

class ViewController: UICollectionViewController {
    
    enum Section {
        case main
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Color>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Color>
    
    lazy var dataSource: DataSource = makeDataSource()
    
    lazy var colors: [Color] = makeColors(10)
    
    var refresherSwitcher: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Refresher"
        view.backgroundColor = .systemBackground
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuserIdentifier)
        configureLayout()
        applySnapshot()
        
        resetRefresher()
    }
    
    func configureLayout() {
        let item = NSCollectionLayoutItem.init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets.top = 2
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)), subitems: [item])
        let layout = UICollectionViewCompositionalLayout(section: .init(group: group))
        collectionView.collectionViewLayout = layout
    }
    
    func makeDataSource() -> DataSource {
        return DataSource(collectionView: collectionView) { collectionView, indexPath, color in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.reuserIdentifier, for: indexPath) as? ColorCell else { fatalError() }
            cell.configureCell(color)
            return cell
        }
    }
    
    func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(colors)
        dataSource.apply(snapshot, animatingDifferences: true)
      }
        
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        collectionView.topRefresher?.beginRefreshing()
    }
    
    @IBAction func toggleAction(_ sender: UIBarButtonItem) {
        resetRefresher()
    }
    
    func loadMoreData() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.async {
                self.colors.append(contentsOf: self.makeColors(3))
                self.applySnapshot()
                if self.colors.count > 30 {
                    self.collectionView.bottomRefresher?.endRefreshing(self.noMoreLabel())
                } else {
                    self.collectionView.bottomRefresher?.endRefreshing()
                }
            }
        }
    }
    
    func refreshData() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.async {
                self.colors.insert(contentsOf: self.makeColors(2), at: 0)
                self.applySnapshot()
                self.collectionView.topRefresher?.endRefreshing()
            }
        }
    }
    
    func makeColors(_ n: Int) -> [Color] {
        return (0..<n).map { _ in Color.random() }
    }
    
    func resetRefresher() {
        if collectionView.topRefresher?.isRefreshing ?? false { return }
        if collectionView.bottomRefresher?.isRefreshing ?? false { return }
        
        refresherSwitcher.toggle()
        
        if refresherSwitcher {
            collectionView.topRefresher = Refresher { [weak self] in
                self?.refreshData()
            }
            collectionView.bottomRefresher = Refresher { [weak self] in
                self?.loadMoreData()
            }
            return
        }
        collectionView.topRefresher = Refresher(ArcAnimateView(.red)) { [weak self] in
            self?.refreshData()
        }
        collectionView.bottomRefresher = Refresher(ArcAnimateView(.red)) { [weak self] in
            self?.loadMoreData()
        }
    }
    
    func noMoreLabel() -> UILabel {
        let label = UILabel()
        label.text = "No More Data."
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.frame.size.height = 30
        return label
    }
}
