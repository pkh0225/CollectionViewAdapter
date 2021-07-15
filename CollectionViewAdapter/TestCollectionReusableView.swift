//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestCollectionReusableView: UICollectionReusableView, UICollectionViewAdapterCellProtocol {
    static var itemCount: Int = 1

    var actionClosure: ActionClosure?
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(_ data: Any?) {
        guard let data = data as? String else { return }
        label.text = data
        
    }
    @IBAction func onButton(_ sender: UIButton) {
        actionClosure?("textButton", "data")
    }

    static func getSize(_ data: Any?, width: CGFloat) -> CGSize {
        return CGSize(width: width, height: 50)
    }
}
