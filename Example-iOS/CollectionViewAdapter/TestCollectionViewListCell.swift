//
//  TestCollectionViewListCell.swift
//  CollectionViewAdapter
//
//  Created by SunSoo Jeon on 7/15/24.
//

import UIKit

@available(iOS 14.0, *)
class TestCollectionViewListCell: UICollectionViewListCell,
UICollectionViewAdapterListCellProtocol {
    static var SpanSize: Int = 1

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

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        print("getSize: \(indexPath)")
        return CGSize(width: width, height: 50)
    }
}
