//
//  ViewController.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectoinView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let testData = UICollectionViewAdapterData()
        for i in 0...10 {
            let sectionInfo = UICollectionViewAdapterData.SectionInfo()
            testData.sectionList.append(sectionInfo)
            sectionInfo.header = UICollectionViewAdapterData.CellInfo(contentObj: "@@ header @@ \(i)",
                                                                      cellType: TestCollectionReusableView.self) { [weak self] (name, object) in
                guard let self else { return }
                guard let object = object else { return }

                self.alert(title: "", message: "\(object) : \(name)")
            }
            sectionInfo.footer = UICollectionViewAdapterData.CellInfo(contentObj: " --- footer --- \(i)",
                                                                      cellType: TestFooterCollectionReusableView.self) { [weak self] (name, object) in
                guard let self else { return }
                guard let object = object else { return }
                self.alert(title: "", message: "\(object) : \(name)")
            }
            for j in 0...3 {
                let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: "cell (\(i) : \(j))",
                                                                    cellType: TestCollectionViewCell.self) { [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }
                    self.alert(title: "", message: "\(object) : \(name)")
                }
                sectionInfo.cells.append( cellInfo )
            }

            self.collectoinView.adapterData = testData
            self.collectoinView.isUsedCacheSize = true
            self.collectoinView.reloadData()

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

