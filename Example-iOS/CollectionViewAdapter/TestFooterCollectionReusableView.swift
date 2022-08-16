//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestFooterCollectionReusableView: UICollectionReusableView, UICollectionViewAdapterCellProtocol {
    static var itemCount: Int = 0

    var actionClosure: ActionClosure?
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(_ data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? String else { return }
        label.text = data
    }

    static func getSize(_ data: Any?, width: CGFloat) -> CGSize {
        return CGSize(width: width, height: 50)
    }
}
