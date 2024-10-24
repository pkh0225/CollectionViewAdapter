//
//  ViewController.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 14.0, *) {
            // cell auto size
            self.collectionView.setAutoSizeListCellLayout(apperance: .grouped)
        }

        let testData = CollectionViewAdapterData()
        for i in 0...10 {
            let sectionInfo = CollectionAdapterSectionInfo()
            testData.sectionList.append(sectionInfo)
            sectionInfo.header = CollectionAdapterCellInfo(cellType: TestHeadCollectionReusableView.self)
                .setContentObj("@@ header @@ \(i)\n1247\nasdighj")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    self.alert(title: "", message: "\(object) : \(name)")
                })

            sectionInfo.footer = CollectionAdapterCellInfo(cellType: TestFooterCollectionReusableView.self)
                .setContentObj(" --- footer --- \(i)\nasdlk;fj\n213p4987")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }
                    self.alert(title: "", message: "\(object) : \(name)")
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
                        self.alert(title: name, message: "\(object)")
                    })

                sectionInfo.cells.append(cellInfo)
            }

            self.collectionView.adapterData = testData
            self.collectionView.isUsedCacheSize = true
            self.collectionView.reloadData()

        }
    }

    func alert(title: String, message: String, addAction: (()->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
            addAction?()
        })
        self.present(alert, animated: true, completion: nil)
    }

}

