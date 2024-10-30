//
//  AdapterDataTestViewController.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/30/24.
//  Copyright © 2024 pkh. All rights reserved.
//

import UIKit

class AdapterDataTestViewController: UIViewController {

    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.backgroundColor = .lightGray
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Adapter Data"
        self.view.backgroundColor = .white
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            self.collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])

        self.collectionView.adapterData = makeAdapterDAta()
        self.collectionView.isUsedCacheSize = true
        self.collectionView.reloadData()
    }


    func makeAdapterDAta() -> CollectionViewAdapterData {
        let testData = CollectionViewAdapterData()
        for i in 0...10 {
            let sectionInfo = CollectionAdapterSectionInfo()
            testData.sectionList.append(sectionInfo)
            sectionInfo.header = CollectionAdapterCellInfo(cellType: TestHeadCollectionReusableView.self)
                .setContentObj("@@ header @@ \(i)\n1247\nasdighj")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "기본 layout으로 변경", message: "\(object) : \(name)")
                    self.collectionView.collectionViewLayout = self.layout
                })

            sectionInfo.footer = CollectionAdapterCellInfo(cellType: TestFooterCollectionReusableView.self)
                .setContentObj(" --- footer --- \(i)\nasdlk;fj\n213p4987")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "AutoSize Layout으로 변경", message: "\(object) : \(name)")
                    if #available(iOS 14.0, *) {
                        self.collectionView.setAutoSizeListCellLayout()
                    }
                })
            //
            for j in 0...3 {
                let contentObj: String
                if #available(iOS 14.0, *) {
                    // cell auto size test
                    contentObj = "cell (\(i) : \(j))\n12351235\n1235512345"
                }
                else {
                    // cell fix size
                    contentObj = "cell (\(i) : \(j))"
                }

                let cellInfo = CollectionAdapterCellInfo(cellType: TestCollectionViewCell.self)
                    .setContentObj(contentObj)
                    .setActionClosure({ [weak self] (name, object) in
                        guard let self else { return }
                        guard let object = object else { return }
                        alert(vc: self, title: name, message: "\(object)")
                    })

                sectionInfo.cells.append(cellInfo)
            }
        }

        return testData
    }
}
