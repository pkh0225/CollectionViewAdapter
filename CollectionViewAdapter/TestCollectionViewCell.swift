//
//  TestCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestCollectionViewCell: UICollectionViewCell, AdapterReusableVieProtocol {
    var buttonClosure: OnButtonClosure?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button1.tag_name = "button1"
        button2.tag_name = "button2"
    }

    func configure(_ data: Any?) {
        guard let data = data as? String else { return }
        label.text = data
        button1.tag_value = data
        button2.tag_value = "\(self.indexPath.section) : \(self.indexPath.row)"
    }
    
    @IBAction func onButton1(_ sender: UIButton) {
        buttonClosure?(sender)
    }
    
    @IBAction func onButton2(_ sender: UIButton) {
        buttonClosure?(sender)
    }
}
