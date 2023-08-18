//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestCollectionReusableView: UICollectionReusableView, UICollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 1

    var actionClosure: ActionClosure?
    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath, actionClosure: ActionClosure?) {
        guard let data = data as? String else { return }
        self.actionClosure = actionClosure
        label.text = data

    }

    @IBAction func onButton(_ sender: UIButton) {
        actionClosure?("Button", label.text)
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
        return CGSize(width: width, height: 50)
    }
}

//extension TestCollectionReusableView: UICollectionViewAdapterStickyProtocol {
//    var stickyContainerView: UIView {
//        return self
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
