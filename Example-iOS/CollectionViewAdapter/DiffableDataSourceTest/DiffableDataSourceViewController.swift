//
//  Untitled.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/30/24.
//  Copyright © 2024 pkh. All rights reserved.
//

import UIKit

class Section: Hashable {
    let id = UUID()
    var subItems = [Item]()

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Section, rhs: Section) -> Bool {
        lhs.id == rhs.id
    }
}

class Item: Hashable {
    let id = UUID()
    var title: String = ""

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    init(title: String) {
        self.title = title
    }
}

@available(iOS 13.0, *)
class DiffableDataSourceViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.getLayout())
        collectionView.backgroundColor = .systemGray5
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.register(CompositionalTestCell.self, forCellWithReuseIdentifier: "cell")
        self.view.addSubview(collectionView)

        return collectionView
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor(red: 230 / 255, green: 247 / 255, blue: 230 / 255, alpha: 1.0)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(onTextFieldDidChange(textField:)), for: .editingChanged)
        self.view.addSubview(textField)
        return textField
    }()
    private var dataSource: DataSource!
    private var testItems = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.MakeAutoLayout()

        self.testItems = makeAdapterData()
//        self.collectionView.dataSource = self

        dataSource = DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let self else { return UICollectionViewCell() }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CompositionalTestCell
            cell.actionClosure = { _, _ in
                print("indexPath section: \(indexPath.section), item: \(indexPath.item)")
                if indexPath.item == 0 {
                    self.updateItem(item: item)
                }
                else if cell.label.text == "new item" {
                    self.deleteItem(item: item)
                }
                else {
                    self.addNewItem(item: item)
                }
            }
            cell.configure(data: item.title, subData: nil, collectionView: collectionView, indexPath: indexPath)
            return cell
        }

        var snapshot = Snapshot()
        snapshot.appendSections(testItems)
        testItems.forEach { snapshot.appendItems($0.subItems, toSection: $0) }
        dataSource.apply(snapshot, animatingDifferences: true)

    }

    private func MakeAutoLayout() {
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            textField.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            textField.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            textField.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -5),
            textField.heightAnchor.constraint(equalToConstant: 50),

            collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
        ])
    }

    private func addNewItem(item: Item) {
        var snapshot = dataSource.snapshot()
        let newItem = Item(title: "new item")
        snapshot.insertItems([newItem], afterItem: item)
//        snapshot.appendItems([newItem], toSection: snapshot.sectionIdentifier(containingItem: item))
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func deleteItem(item: Item) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([item])
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateItem(item: Item) {
        item.title = "updated item"
        var snapshot = dataSource.snapshot()
        if #available(iOS 15.0, *) {
            snapshot.reconfigureItems([item])
        }
        else {
            snapshot.reloadItems([item])
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func getLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env -> NSCollectionLayoutSection? in
            return self.getGridSection()
        }
        return layout
    }

    private func getGridSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .absolute(50)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(50)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 20, trailing: 15)
        section.interGroupSpacing = 8


        return section
    }

    @objc private func onTextFieldDidChange(textField: UITextField) {
        if let text = textField.text {
            print(text)
            var snapshot = Snapshot()
            if text.isEmpty {
                snapshot.appendSections(testItems)
                testItems.forEach { snapshot.appendItems($0.subItems, toSection: $0) }
            }
            else {
                let filtered = testItems.flatMap { section in
                    section.subItems.filter { item in
                        item.title.contains(text)
                    }
                }

                snapshot.appendSections([Section()])
                snapshot.appendItems(filtered)
            }
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    private func makeAdapterData() -> [Section] {
        var testData = [Section]()
        for i in 0...10 {
            let section = Section()
            for j in 0...3 {
                let item = Item(title: "cell (\(i) : \(j))")
                section.subItems.append(item)
            }
            testData.append(section)
        }

        return testData
    }
}

@available(iOS 13.0, *)
extension DiffableDataSourceViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let cell = cell as? CompositionalTestCell else { return }
//        print("will display cell at section: \(indexPath.section), item: \(indexPath.item)")
    }
}


//@available(iOS 13.0, *)
//extension DiffableDataSourceViewController: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return UICollectionViewCell()
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 100
//    }
//}
