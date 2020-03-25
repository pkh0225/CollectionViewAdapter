//
//  TestCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestCollectionViewCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    var actionClosure: OnActionClosure?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(_ data: Any?) {
        guard let data = data as? String else { return }
        label.text = data
       
    }
    
    @IBAction func onButton1(_ sender: UIButton) {
        actionClosure?("button1", label.text)
    }
    
    @IBAction func onButton2(_ sender: UIButton) {
        actionClosure?("button2", "\(self.indexPath.section) : \(self.indexPath.row)")
    }
    
    // UICollectionViewAdapterCellProtocol Function
    func willDisplay() {
        print("willDisplay")
    }
    // UICollectionViewAdapterCellProtocol Function
    func didEndDisplaying() {
        print("didEndDisplaying")
    }
}
