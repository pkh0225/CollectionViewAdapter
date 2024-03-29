//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestFooterCollectionReusableView: UICollectionReusableView, UICollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 0

    var actionClosure: ActionClosure?
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath, actionClosure: ActionClosure?) {
        guard let data = data as? String else { return }
        label.text = data
    }

    // UICollectionViewAdapterCellProtocol Function
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("footer willDisplay : \(indexPath)")
    }
    // UICollectionViewAdapterCellProtocol Function
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("footer didEndDisplaying : \(indexPath)")
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: 50)
    }
}
