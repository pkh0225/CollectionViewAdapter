//
//  TestCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestCollectionViewCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 1

    var actionClosure: ActionClosure?
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath, actionClosure: ActionClosure?) {
        guard let data = data as? String else { return }
        label.text = data
       
    }
    
    @IBAction func onButton1(_ sender: UIButton) {
        actionClosure?("button1", label.text)
    }
    
    @IBAction func onButton2(_ sender: UIButton) {
        actionClosure?("button2", label.text)
    }

    // UICollectionViewAdapterCellProtocol Function
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        actionClosure?("didSelect", label.text)
    }
    // UICollectionViewAdapterCellProtocol Function
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("cell willDisplay : \(indexPath)")
    }
    // UICollectionViewAdapterCellProtocol Function
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("cell didEndDisplaying : \(indexPath)")
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: 50)
    }
}

//extension TestCollectionViewCell: UICollectionViewAdapterStickyProtocol {
//    var stickyContainerView: UIView {
//        return self.containerView
//    }
//
//    var isSticky: Bool {
//        if indexPath.row == 1  {
//            return true
//        }
//        return false
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
