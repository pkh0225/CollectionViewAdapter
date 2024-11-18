//
//  CountCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 11/4/24.
//  Copyright © 2024 pkh. All rights reserved.
//

import UIKit
import CollectionViewAdapter

class CountCollectionViewCell: UICollectionViewCell, CollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 2
    var actionClosure: ((_ name: String, _ object: Any?) -> Void)?

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: self.fromXibSize().height)
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let text = data as? String else { return }
        self.label.text = text
    }

    override func layoutSubviews() {
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    }
}
