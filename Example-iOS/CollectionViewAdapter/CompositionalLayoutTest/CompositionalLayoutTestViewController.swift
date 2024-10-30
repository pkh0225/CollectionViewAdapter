//
//  Untitled.swift
//  TestProduct
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/29/24.
//

import UIKit

@available(iOS 13.0, *)
class CompositionalLayoutTestViewController: UIViewController {

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.getLayout())
        collectionView.backgroundColor = .lightGray
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        return collectionView
    }()

    var dataSource: [SectionItem] = [
        .init(text: "header",
              layoutType: .horizontalListAutoSize,
              subItems: [.init(text: "사과"),
                         .init(text: "사과ㄴㅁㅇㅎ"),
                         .init(text: "사과ㅁㄴㅇㅎㅁㄴㅇㅎㅎ"),
                         .init(text: "사과"),
                         .init(text: "사과ㅁㄴㅇㅎㅁㄴㅇㅎ"),
                         .init(text: "사과ㅁㅇㅎ"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과ㅁㄴㅇㅎㅇㄴㅁ"),
                         .init(text: "사과"),
                         .init(text: "사과ㅁㄴㅇㅎ"),
                         .init(text: "사과")]),
        .init(text: "header",
              layoutType: .grid,
              subItems: [.init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과ㅁㄴㅇㅎ"),
                         .init(text: "사과"),
                         .init(text: "사과ㅁㅇㅇ"),
                         .init(text: "사과"),
                         .init(text: "사과ㅇㅇㅇ"),
                         .init(text: "사과")]),
        .init(text: "header",
              layoutType: .horizontalList,
              subItems: [.init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과")]),
        .init(text: "header",
              layoutType: .horizontalList,
              subItems: [.init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과"),
                         .init(text: "사과")])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "CompositionalLayout"
        self.view.backgroundColor = .white

        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            self.collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])

        self.collectionView.adapterData = makeAdapterData()
        self.collectionView.reloadData()
    }

    func makeAdapterData() -> CollectionViewAdapterData {
        let testData = CollectionViewAdapterData()
        for (s, sectionItem) in dataSource.enumerated() {
            let sectionInfo = CollectionAdapterSectionInfo()
            testData.sectionList.append(sectionInfo)
            sectionInfo.header = CollectionAdapterCellInfo(cellType: TestFooterCollectionReusableView.self)
                .setContentObj("\(sectionItem.text) \(s)")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "", message: "\(object) : \(name)")
                })

            for (i, subItem) in sectionItem.subItems.enumerated() {
                let cellInfo = CollectionAdapterCellInfo(cellType: CompositionalTestCell.self)
                    .setContentObj("\(subItem.text) \(i)")
                    .setActionClosure({ [weak self] (name, object) in
                        guard let self else { return }
                        guard let object = object else { return }
                        alert(vc: self, title: name, message: "\(object)")
                        self.collectionView.scrollToItem(at: IndexPath(item: i, section: s), at: .centeredHorizontally, animated: true)
                    })

                sectionInfo.cells.append(cellInfo)
            }
        }

        return testData
    }

    func getLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env -> NSCollectionLayoutSection? in
            switch self.dataSource[sectionIndex].layoutType {
            case .horizontalListAutoSize:
                return self.getListSectionAutoSize()
            case .grid:
                return self.getGridSection()
            case .horizontalList:
                return self.getListSection()
            }
        }
        layout.register(BackgroundDecorationView.self, forDecorationViewOfKind: "BackgroundDecorationView")
        return layout
    }


    func getGridSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .estimated(30)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
//        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: NSCollectionLayoutSpacing.fixed(0),
//                                                         top: NSCollectionLayoutSpacing.fixed(0),
//                                                         trailing: NSCollectionLayoutSpacing.fixed(8),
//                                                         bottom: NSCollectionLayoutSpacing.fixed(0))
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(30)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
//        group.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        section.interGroupSpacing = 8

        // sectionHeader 사이즈 설정
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        // section에 헤더 추가
        section.boundarySupplementaryItems = [sectionHeader]

        // Decoration Item 추가
        let decorationItem = NSCollectionLayoutDecorationItem.background(elementKind: "BackgroundDecorationView")
        section.decorationItems = [decorationItem]
        return section
    }

    func getListSectionAutoSize() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .estimated(30)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .estimated(30)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        section.interGroupSpacing = 8
        //        section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, env) in
        //            //            print("sub scrollView \(offset)")
        //            guard let ss = self else { return }
        //            let normalizedOffsetX = offset.x
        //            let centerPoint = CGPoint(x: normalizedOffsetX + ss.collectionView.bounds.width / 2, y: 20)
        //            visibleItems.forEach({ item in
        //                guard let cell = ss.collectionView.cellForItem(at: item.indexPath) else { return }
        //                UIView.animate(withDuration: 0.3) {
        //                    cell.transform = item.frame.contains(centerPoint) ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
        //                }
        //            })
        //        }

        // sectionHeader 사이즈 설정
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        // section에 헤더 추가
        section.boundarySupplementaryItems = [sectionHeader]

        // Decoration Item 추가
        let decorationItem = NSCollectionLayoutDecorationItem.background(elementKind: "BackgroundDecorationView")
        section.decorationItems = [decorationItem]

        return section
    }

    func getListSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.35),
            heightDimension: .fractionalHeight(0.3)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        //        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
        //        let group = NSCollectionLayoutGroup.horizontal(
        //            layoutSize: groupSize,
        //            subitem: item,
        //            count: 4
        //        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        section.interGroupSpacing = 8
        //        section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, env) in
        //            //            print("sub scrollView \(offset)")
        //            guard let ss = self else { return }
        //            let normalizedOffsetX = offset.x
        //            let centerPoint = CGPoint(x: normalizedOffsetX + ss.collectionView.bounds.width / 2, y: 20)
        //            visibleItems.forEach({ item in
        //                guard let cell = ss.collectionView.cellForItem(at: item.indexPath) else { return }
        //                UIView.animate(withDuration: 0.3) {
        //                    cell.transform = item.frame.contains(centerPoint) ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
        //                }
        //            })
        //        }

        // sectionHeader 사이즈 설정
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        // section에 헤더 추가
        section.boundarySupplementaryItems = [sectionHeader]

        // Decoration Item 추가
        let decorationItem = NSCollectionLayoutDecorationItem.background(elementKind: "BackgroundDecorationView")
        section.decorationItems = [decorationItem]

        return section
    }

}

enum layoutType {
    case grid
    case horizontalList
    case horizontalListAutoSize
}
struct SectionItem {
    let text: String
    let layoutType: layoutType
    let subItems: [SubItem]
}

struct SubItem {
    let text: String
}

