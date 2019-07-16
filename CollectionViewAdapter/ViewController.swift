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
        
        var testData = AdapterData()
        for i in 0...10 {
            let sectionInfo = SectionInfo()
            testData.append(sectionInfo)
            sectionInfo.header = CellInfo(contentObj: "@@ header @@ \(i)", sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 150) }, cellType: TestCollectionReusableView.self) { btn in
                guard let name = btn?.tag_name, let value = btn?.tag_value else { return }
                print("header btn ---- \(name) : \(value)")
            }
            sectionInfo.footer = CellInfo(contentObj: " --- footer --- \(i)", cellType: TestFooterCollectionReusableView.self)
            for j in 0...5 {
                let cellInfo = CellInfo(contentObj: "cell \(j)",
                    sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 50) },
                    cellType: TestCollectionViewCell.self) { btn in
                        guard let name = btn?.tag_name, let value = btn?.tag_value else { return }
                        print("cell btn ---- \(name) : \(value)")
                }
                sectionInfo.cells.append( cellInfo )
            }
        }
        
        collectoinView.data = testData
        collectoinView.reloadData()
        
    }


}

