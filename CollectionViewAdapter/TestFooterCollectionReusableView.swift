//
//  TestCollectionReusableView.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit

class TestFooterCollectionReusableView: UICollectionReusableView, AdapterReusableVieProtocol {
    var buttonClosure: OnButtonClosure?
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(_ data: Any?) {
        guard let data = data as? String else { return }
        label.text = data
        
    }
}
