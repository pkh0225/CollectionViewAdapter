//
//  ViewController.swift
//  CollectionViewAdapter
//
//  Created by pkh on 16/07/2019.
//  Copyright © 2019 pkh. All rights reserved.
//

import UIKit
import CollectionViewAdapter

class MainViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "CollectionViewAdapter"
        if #available(iOS 14.0, *) {
            // test cell auto size
            self.collectionView.setAutoSizeListCellLayout()
        }

        self.collectionView.adapterData = self.makeAdapterDAta()
        self.collectionView.reloadData()
    }



    func makeAdapterDAta() -> CollectionViewAdapterData {
        let adapterData = CVAData()
        let sectionInfo = CVASectionInfo()
        do {
            let cellInfo = CVACellInfo(LineCell.self)
                .contentObj("Adapter Data Test")
                .actionClosure { [weak self] (name, object) in
                    guard let self else { return }
                    self.navigationController?.pushViewController(AdapterDataTestViewController(), animated: true)
                }
            
            sectionInfo.addCell(cellInfo)
        }
        adapterData.addSection(sectionInfo)
        return adapterData
    }

    func alert(title: String, message: String, addAction: (()->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
            addAction?()
        })
        self.present(alert, animated: true, completion: nil)
    }
}

class LineCell: UICollectionViewCell, CollectionViewAdapterCellProtocol {
    static var SpanSize: CGFloat = 0
    
    var actionClosure: ((_ name: String, _ object: Any?) -> Void)?
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -15),
            label.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15),
        ])
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = #colorLiteral(red: 0.8643704653, green: 1, blue: 0.8994206786, alpha: 1)
//        self.contentView.layer.borderColor = UIColor.lightGray.cgColor
        self.contentView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        self.contentView.layer.borderWidth = 0.5

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? String else { return }

        self.label.text = data
    }

    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        self.actionClosure?("didSelect", indexPath)
    }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: 30)
    }
}

func randomColor() -> UIColor {
    let red = CGFloat.random(in: 0...1)
    let green = CGFloat.random(in: 0...1)
    let blue = CGFloat.random(in: 0...1)

    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
}

@MainActor
func alert(vc: UIViewController, title: String, message: String, addAction: (()->Void)? = nil) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
        addAction?()
    })
    vc.present(alert, animated: true, completion: nil)
}
