//
//  CollectionViewProtocol.swift
//  ssg
//
//  Created by pkh on 24/06/2019.
//  Copyright © 2019 emart. All rights reserved.
//

import Foundation
import UIKit

let UISCREEN_HEIGHT = UIScreen.main.bounds.height
typealias OnButtonClosure = (_ sender: UIButton?) -> Void
typealias AdapterData = [SectionInfo]

class CellInfo {
    enum CellKind {
        case header
        case footer
        case cell
    }
    
    var kind: CellKind = .cell
    var contentObj: Any?
    var type: AdapterReusableVieProtocol.Type
    var sizeClosure: (() -> CGSize)?
    var buttonClosure: OnButtonClosure?
    
    init(kind: CellKind = .cell, contentObj: Any?, sizeClosure: (() -> CGSize)? = nil, cellType: AdapterReusableVieProtocol.Type, buttonClosure: OnButtonClosure? = nil) {
        self.kind = kind
        self.contentObj = contentObj
        self.sizeClosure = sizeClosure
        self.type = cellType
        self.buttonClosure = buttonClosure
    }
}

class SectionInfo {
    var header: CellInfo? {
        didSet {
            footer?.kind = .header
        }
    }
    var footer: CellInfo? {
        didSet {
            footer?.kind = .footer
        }
    }
    var cells = [CellInfo]()
}


protocol AdapterReusableVieProtocol: UICollectionReusableView {
    var buttonClosure: OnButtonClosure? { get set }
    
    static func getSize(_ data: Any?) -> CGSize
    func configure(_ data: Any?)
    
}

extension AdapterReusableVieProtocol {
    static func getSize(_ data: Any? = nil) -> CGSize {
        return self.fromNibSize()
    }
}

class CollectionViewAdapter: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var cView: UICollectionView? {
        didSet {
            cView?.delegate = self
            cView?.dataSource = self
        }
    }
    var data = AdapterData()
    var hasNext: Bool = false
    var requestNextClosure: (() -> Void)?
    
    func checkMoreData(_ collectionView: UICollectionView) {
        guard hasNext else { return }
        let checkY = collectionView.contentSize.height - (UISCREEN_HEIGHT * 4)
        if collectionView.contentOffset.y + collectionView.frame.size.height >= checkY  || checkY <= 0 {
            hasNext = false
            requestNextClosure?()
        }
    }
    
    func registerCell(in collectionView: UICollectionView) {
        guard data.count > 0 else { return }
        
        for sectionInfo in data {
            if let header = sectionInfo.header {
                collectionView.registerHeader(header.type)
            }
            if let footer = sectionInfo.footer {
                collectionView.registerFooter(footer.type)
            }
            if sectionInfo.cells.count > 0 {
                for cell in sectionInfo.cells {
                    if let cellType = cell.type as? UICollectionViewCell.Type {
                        collectionView.register(cellType)
                    }
                }
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        registerCell(in: collectionView)
        collectionView.registerDefaultCell()
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        func defaultReturn() -> UICollectionViewCell { return collectionView.dequeueReusableCell(UICollectionViewCell.self, for: indexPath) }
        
        let cellInfo = data[indexPath.section].cells[indexPath.row]
        guard let cellType = cellInfo.type as? UICollectionViewCell.Type else { return defaultReturn() }
        defer {
            checkMoreData(collectionView)
        }
        
        let cell = collectionView.dequeueReusableCell(cellType, for: indexPath)
        if let cell = cell as? AdapterReusableVieProtocol {
            cell.configure(cellInfo.contentObj)
            cell.buttonClosure = cellInfo.buttonClosure
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        func defaultReturn() -> UICollectionReusableView { return collectionView.dequeueReusableHeader(UICollectionReusableView.self, for: indexPath) }
        
        guard let cellInfo: CellInfo = (kind == UICollectionView.elementKindSectionHeader) ? data[indexPath.section].header : data[indexPath.section].footer else { return defaultReturn() }
        let view = (kind == UICollectionView.elementKindSectionHeader) ? collectionView.dequeueReusableHeader(cellInfo.type, for: indexPath) : collectionView.dequeueReusableFooter(cellInfo.type, for: indexPath)
        if let view = view as? AdapterReusableVieProtocol {
            view.configure(cellInfo.contentObj)
            view.buttonClosure = cellInfo.buttonClosure
        }
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellInfo = data[indexPath.section].cells[indexPath.row]
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.type.getSize(cellInfo.contentObj)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let cellInfo = data[section].header else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.type.getSize(cellInfo.contentObj)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let cellInfo = data[section].footer else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.type.getSize(cellInfo.contentObj)
    }
    
}

extension UICollectionView {
    private struct AssociatedKeys {
        static var collectionViewAdapter: UInt8 = 0
    }
    
    var adapter: CollectionViewAdapter {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.collectionViewAdapter) as? CollectionViewAdapter {
                return obj
            }
            let obj = CollectionViewAdapter()
            obj.cView = self
            objc_setAssociatedObject(self, &AssociatedKeys.collectionViewAdapter, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            newValue.cView = self
            objc_setAssociatedObject(self, &AssociatedKeys.collectionViewAdapter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var data: AdapterData {
        get {
            return self.adapter.data
        }
        set {
            self.adapter.data = newValue
        }
    }
    
    var hasNext: Bool {
        get {
            return self.adapter.hasNext
        }
        set {
            self.adapter.hasNext = newValue
        }
    }
    
    var requestNextClosure: (() -> Void)? {
        get {
            return self.adapter.requestNextClosure
        }
        set {
            self.adapter.requestNextClosure = newValue
        }
    }
}


fileprivate var ViewNibs = [String : UIView]()
extension UIView {
    
    class func fromNib(cache: Bool = false) -> Self {
        return fromNib(cache: cache, as: self)
    }
    
    private class func fromNib<T>(cache: Bool = false, as type: T.Type) -> T {
        if cache, let view = ViewNibs[self.className] {
            return view as! T
        }
        let view: UIView = Bundle.main.loadNibNamed(self.className, owner: nil, options: nil)!.first as! UIView
        return view as! T
    }
    
    class func fromNibSize() -> CGSize {
        return fromNib(cache: true).frame.size
    }
}
