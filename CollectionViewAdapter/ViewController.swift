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
        
        
        DispatchQueue.global().async {
            
            let testData = UICollectionViewAdapterData()
            for i in 0...10 {
                let sectionInfo = UICollectionViewAdapterData.SectionInfo()
                testData.sectionList.append(sectionInfo)
                sectionInfo.header = UICollectionViewAdapterData.CellInfo(contentObj: "@@ header @@ \(i)",
                                                cellType: TestCollectionReusableView.self) { (name, object) in
                                                    guard let object = object else { return }
                                                    print("header btn ---- \(name) : \(object)")
                                                }
                sectionInfo.footer = UICollectionViewAdapterData.CellInfo(contentObj: " --- footer --- \(i)", cellType: TestFooterCollectionReusableView.self)
                for j in 0...5 {
                    let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: "cell \(j)",
                                              cellType: TestCollectionViewCell.self) { (name, object) in
                                                    guard let object = object else { return }
                                                    print("cell btn ---- \(name) : \(object)")
                                             }
                    sectionInfo.cells.append( cellInfo )
                }
            }
            
            DispatchQueue.main.async {
                self.collectoinView.adapterData = testData
                self.collectoinView.reloadData()
            }
        }
        
        
        
    }
    
    
}

