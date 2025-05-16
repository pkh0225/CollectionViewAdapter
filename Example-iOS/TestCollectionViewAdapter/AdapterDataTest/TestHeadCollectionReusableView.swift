//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit
import CollectionViewAdapter

class TestHeadCollectionReusableView: UICollectionReusableView, CollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 0
    
    var actionClosure: ((_ name: String, _ object: Any?) -> Void)?
    
    @IBOutlet weak var stickyView: UIView!

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? String else { return }
        label.text = data

    }

    @IBAction func onButton(_ sender: UIButton) {
        actionClosure?("Header Button", label.text)
    }

    // UICollectionViewAdapterCellProtocol Function
     func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("header willDisplay : \(indexPath)")
    }
    // UICollectionViewAdapterCellProtocol Function
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("header willDisplay : \(indexPath)")
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: self.fromXibSize().height)
    }
}

//extension TestHeadCollectionReusableView: UICollectionViewAdapterStickyProtocol {
//    var stickyAbleView: UIView {
//        return stickyView
//    }
//
//    var isSticky: Bool {
//        return true
//    }
//
//    var reloadData: (() -> Void)? {
//        return nil
//    }
//
//    var isOnlySection: Bool {
//        return false
//    }
//
//    func onSticky(state: Bool) {
//
//    }
//
//    func setData(data: Any?) {
//
//    }
//}
