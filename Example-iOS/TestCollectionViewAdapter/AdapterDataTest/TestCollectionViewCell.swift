//
//  TestCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit
import CollectionViewAdapter

class TestCollectionViewCell: UICollectionViewCell, CollectionViewAdapterCellProtocol {
    static var SpanSize: CGFloat = 1
    var actionClosure: ((_ name: String, _ object: Any?) -> Void)?

    @IBOutlet weak var stickyView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: self.fromXibSize().height)
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? String else { return }
        label.text = data
    }
    
    @IBAction func onButton1(_ sender: UIButton) {
        actionClosure?("button1", label.text)
        self.parentCollectionView?.cacheRemoveAfterReloadSections(IndexSet(integer: self.indexPath.section))
    }
    
    @IBAction func onButton2(_ sender: UIButton) {
        actionClosure?("button2", label.text)
        self.parentCollectionView?.cacheRemoveAfterReloadItems(at: [self.indexPath])
    }

    // UICollectionViewAdapterCellProtocol Function
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        actionClosure?("didSelect", label.text)
        self.parentCollectionView?.cacheRemoveAfterReloadData()
    }
    // UICollectionViewAdapterCellProtocol Function
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("cell willDisplay : \(indexPath)")
    }
    // UICollectionViewAdapterCellProtocol Function
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {
//        print("cell didEndDisplaying : \(indexPath)")
    }

//    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
////        print("getSize: \(indexPath)")
//        return CGSize(width: width, height: self.fromXibSize().height)
//    }
}

extension TestCollectionViewCell: UICollectionViewAdapterStickyProtocol {
    var stickyAbleView: UIView {
        return self.stickyView
    }

    var isSticky: Bool {
        if indexPath.row == 0  {
            return true
        }
        return false
    }

    var reloadData: (() -> Void)? {
        return nil
    }

    var isOnlySection: Bool {
        return false
    }

    func onSticky(state: Bool) {

    }

    func setData(data: Any?) {

    }
}
