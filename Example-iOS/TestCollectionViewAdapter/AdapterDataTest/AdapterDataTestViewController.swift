//
//  AdapterDataTestViewController.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/30/24.
//  Copyright © 2024 pkh. All rights reserved.
//

import UIKit
import CollectionViewAdapter

class AdapterDataTestViewController: UIViewController {

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
        ])

        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Adapter Data"
        self.view.backgroundColor = .white


        self.collectionView.adapterData = makeAdapterData()
        self.collectionView.isUsedCacheSize = true
        self.collectionView.reloadData()
    }


    private func makeAdapterData() -> CVAData {
        let testData = CVAData()
        for i in 0...5 {
            let sectionInfo = CVASectionInfo()
            sectionInfo.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            sectionInfo.header = CVACellInfo(TestHeadCollectionReusableView.self)
                .contentObj("@@ header @@ \(i)\n1247\nasdighj")
                .actionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "기본 layout으로 변경", message: "\(object) : \(name)")
                    self.collectionView.collectionViewLayout = self.layout
                })

            sectionInfo.footer = CVACellInfo(TestFooterCollectionReusableView.self)
                .contentObj(" --- footer --- \(i)\nasdlk;fj\n213p4987")
                .actionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "Line Mode AutoSize Layout으로 변경", message: "\(object) : \(name)")
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

                let cellInfo = CVACellInfo(TestCollectionViewCell.self)
                    .contentObj(contentObj)
                    .actionClosure({ [weak self] (name, object) in
                        guard let self else { return }
                        guard let object = object else { return }
                        alert(vc: self, title: name, message: "\(object)")
                    })

                sectionInfo.addCell(cellInfo)
            }
            testData.addSection(sectionInfo)
        }

        for i in 0...5 {
            let sectionInfo = CVASectionInfo()
            sectionInfo.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            sectionInfo.minimumInteritemSpacing = 10
            sectionInfo.minimumLineSpacing = 5
            sectionInfo.header = CVACellInfo(TestHeadCollectionReusableView.self)
                .contentObj("@@ header @@ \(i)\n1247\nasdighj")
                .actionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "기본 layout으로 변경", message: "\(object) : \(name)")
                    self.collectionView.collectionViewLayout = self.layout
                })

            sectionInfo.footer = CVACellInfo(TestFooterCollectionReusableView.self)
                .contentObj(" --- footer --- \(i)\nasdlk;fj\n213p4987")
                .actionClosure({ [weak self] (name, object) in
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

                let cellInfo = CVACellInfo(CountCollectionViewCell.self)
                    .contentObj(contentObj)
                    .actionClosure({ [weak self] (name, object) in
                        guard let self else { return }
                        guard let object = object else { return }
                        alert(vc: self, title: name, message: "\(object)")
                    })

                sectionInfo.addCell(cellInfo)
            }
            testData.addSection(sectionInfo)
        }

        return testData
    }
}
