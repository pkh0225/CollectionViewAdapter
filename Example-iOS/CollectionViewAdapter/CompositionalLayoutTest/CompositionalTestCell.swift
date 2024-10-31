//
//  CompositionalTestCell.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/30/24.
//  Copyright © 2024 pkh. All rights reserved.
//

import UIKit

class CompositionalTestCell: UICollectionViewCell, CollectionViewAdapterCellProtocol {
    static var SpanSize: Int = 0

    var actionClosure: ActionClosure?
    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        return label
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = randomColor()
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 12),
            self.label.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -12),
            self.label.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5),
            self.label.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5),
        ])

        let btn = UIButton(frame: frame)
        self.contentView.addSubview(btn)
        btn.addTarget(self, action: #selector(self.onBtnAction), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
            btn.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
            btn.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            btn.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0),
        ])
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? String else { return }
        self.label.text = data


    }

    @objc func onBtnAction() {
        self.actionClosure?("", self.label.text)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if indexPath.section == 0 || indexPath.section == 1 {
            self.layer.cornerRadius = self.frame.size.height / 2.0
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.gray.cgColor
        }
        else {
            self.layer.cornerRadius = 10
            self.layer.borderWidth = 0
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

class BackgroundDecorationView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.red // 배경 색상 설정
        self.layer.cornerRadius = 10 // 모서리 둥글기 설정

        self.backgroundColor = randomColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
