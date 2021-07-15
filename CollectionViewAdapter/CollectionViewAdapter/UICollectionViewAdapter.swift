//
//  CollectionViewProtocol.swift
//  ssg
//
//  Created by pkh on 24/06/2019.
//  Copyright © 2019 emart. All rights reserved.
//

import Foundation
import UIKit

/// 0.5 단위 버림 처림
/// 0.5 작으면 0
/// 0.5 보다 크면 0.5
/// - Returns: 0.5 단위 버림 처리
@inline(__always) public func floorUI(_ value: CGFloat) -> CGFloat {
    let roundValue = round(value)
    let floorValue = floor(value)
    if roundValue == floorValue {
        return CGFloat(roundValue)
    }
    return CGFloat(roundValue - 0.5)
}

/// 0.5 단위 올림 처리
/// 0.5 작으면 0.5
/// 0.5 보다 크면 1
/// - Returns: 0.5 단위 올림 처리
@inline(__always) public func ceilUI(_ value: CGFloat) -> CGFloat {
    let roundValue = round(value)
    let ceilValue = ceil(value)
    if roundValue == ceilValue {
        return CGFloat(roundValue)
    }
    return CGFloat(roundValue + 0.5)
}


let SectionInsetNotSupport = UIEdgeInsets(top: -9999, left: -9999, bottom: -9999, right: -9999)
let UISCREEN_WIDTH = UIScreen.main.bounds.width
let UISCREEN_HEIGHT = UIScreen.main.bounds.height
typealias ActionClosure = (_ name: String, _ object: Any?) -> Void

fileprivate class EmptyCollectionCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    static var itemCount: Int = 1

    var actionClosure: ActionClosure?


    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(_ data: Any?) {

    }

    class func getSize(_ data: Any? = nil, width: CGFloat) -> CGSize {
        guard let data = data as? CGFloat else { return .zero }
        return CGSize(width: UISCREEN_WIDTH, height: data)
    }
}

class UICollectionViewAdapterData {
    class CellInfo {
        enum CellKind {
            case header
            case footer
            case cell
        }

        var kind: CellKind = .cell
        var contentObj: Any?
        var type: UICollectionViewAdapterCellProtocol.Type
        var sizeClosure: (() -> CGSize)?
        var actionClosure: ActionClosure?

        init(kind: CellKind = .cell, contentObj: Any?, sizeClosure: (() -> CGSize)? = nil, cellType: UICollectionViewAdapterCellProtocol.Type, actionClosure: ActionClosure? = nil) {
            self.kind = kind
            self.contentObj = contentObj
            self.sizeClosure = sizeClosure
            self.type = cellType
            self.actionClosure = actionClosure
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
        var dataType: String = ""
        var sectionInset: UIEdgeInsets = SectionInsetNotSupport
        var minimumLineSpacing: CGFloat = -9999
        var minimumInteritemSpacing: CGFloat = -9999

        convenience init(emptyHeight: CGFloat) {
            self.init()
            self.dataType = "EmptySection"
            let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: emptyHeight,  cellType: EmptyCollectionCell.self)
            self.cells.append(cellInfo)
        }


    }


    var sectionList = [SectionInfo]()


    func getSectionInfoByDataType(_ dataType: String) -> SectionInfo? {
        for sectionInfo in sectionList {
            if sectionInfo.dataType == dataType {
                return sectionInfo
            }
        }
        return nil
    }

    func getSectionByDataType(_ dataType: String) -> Int {
        for (idx, obj) in sectionList.enumerated() {
            if obj.dataType == dataType {
                return idx
            }
        }
        return -1
    }

    func addEmptySection(height: CGFloat) {
        let emptySectoin = SectionInfo(emptyHeight: 50)
        self.sectionList.append(emptySectoin)
    }
}



protocol UICollectionViewAdapterCellProtocol: UICollectionReusableView {
    static var itemCount: Int { get }
    var actionClosure: ActionClosure? { get set }

    static func getSize(_ data: Any?, width: CGFloat) -> CGSize
    func configure(_ data: Any?)
    func willDisplay()
    func didEndDisplaying()
}
extension UICollectionViewAdapterCellProtocol {
    static func getSize(_ data: Any? = nil, width: CGFloat) -> CGSize {
        return self.fromNibSize()
    }
    func willDisplay(){}
    func didEndDisplaying(){}
}

typealias ScrollViewCallback         = (_ scrollView: UIScrollView) -> Void
typealias CollectionViewDisplayClosure = (_ collectionView: UICollectionView,_ cell: UICollectionViewCell,_ indexPath: IndexPath) -> Void
typealias CollectionViewDisplaySupplementaryViewClosure = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath) -> Void

class UICollectionViewAdapter: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let CHECK_MORE_SIZE: CGFloat = UISCREEN_HEIGHT * 2
    weak var cView: UICollectionView? {
        didSet {
            cView?.delegate = self
            cView?.dataSource = self
        }
    }

    var didScrollCallback: [ScrollViewCallback] = []
    var didEndDeceleratingCallback: [ScrollViewCallback] = []
    var willDisplayCellCallback: [CollectionViewDisplayClosure] = []
    var didEndDisplayCellCallback: [CollectionViewDisplayClosure] = []
    var willDisplaySupplementaryViewCallback: [CollectionViewDisplaySupplementaryViewClosure] = []
    var didEndDisplaySupplementaryViewCallback: [CollectionViewDisplaySupplementaryViewClosure] = []

    var data: UICollectionViewAdapterData?
    var hasNext: Bool = false
    var requestNextClosure: (() -> Void)?

    @discardableResult
    func checkMoreData(_ scrollView: UICollectionView) -> Bool {
        guard hasNext else { return hasNext }
        let checkY = scrollView.contentSize.height - UICollectionViewAdapter.CHECK_MORE_SIZE
        if scrollView.contentOffset.y + scrollView.frame.size.height >= checkY  || checkY <= 0 {
            hasNext = false
            DispatchQueue.main.async {
                self.requestNextClosure?()
            }
        }
        return hasNext
    }

    func registerCell(in collectionView: UICollectionView) {
        guard let data = self.data, data.sectionList.count > 0 else { return }

        for sectionInfo in data.sectionList {
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
        guard let data = self.data else { return 0 }
        registerCell(in: collectionView)
        collectionView.registerDefaultCell()

        if data.sectionList.count == 0 && hasNext {
            hasNext = false
            requestNextClosure?()
        }

        return data.sectionList.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = self.data else { return 0 }
        return data.sectionList[section].cells.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        func defaultReturn() -> UICollectionViewCell { return collectionView.dequeueReusableCell(UICollectionViewCell.self, for: indexPath) }

        guard let data = self.data else { return defaultReturn() }
        let cellInfo = data.sectionList[indexPath.section].cells[indexPath.row]
        guard let cellType = cellInfo.type as? UICollectionViewCell.Type else { return defaultReturn() }
        defer {
            checkMoreData(collectionView)
        }

        let cell = collectionView.dequeueReusableCell(cellType, for: indexPath)
        if let cell = cell as? UICollectionViewAdapterCellProtocol {
            cell.actionClosure = cellInfo.actionClosure
            cell.configure(cellInfo.contentObj)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        func defaultReturn() -> UICollectionReusableView { return collectionView.dequeueReusableHeader(UICollectionReusableView.self, for: indexPath) }
        guard let data = self.data else { return defaultReturn() }

        guard let cellInfo: UICollectionViewAdapterData.CellInfo = (kind == UICollectionView.elementKindSectionHeader) ? data.sectionList[indexPath.section].header : data.sectionList[indexPath.section].footer else { return defaultReturn() }
        let view = (kind == UICollectionView.elementKindSectionHeader) ? collectionView.dequeueReusableHeader(cellInfo.type, for: indexPath) : collectionView.dequeueReusableFooter(cellInfo.type, for: indexPath)
        if let view = view as? UICollectionViewAdapterCellProtocol {
            view.actionClosure = cellInfo.actionClosure
            view.configure(cellInfo.contentObj)
        }
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let data = self.data else { return .zero }

        let cellInfo = data.sectionList[indexPath.section].cells[indexPath.row]
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        var width: CGFloat = collectionView.frame.size.width
        if cellInfo.type.itemCount > 1 {
            let sectionInset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
            let itemSpace = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.section)
            let allCellWidth = collectionView.frame.size.width - sectionInset.left - sectionInset.right - (itemSpace * (CGFloat(cellInfo.type.itemCount) - 1) )
            width = floorUI( allCellWidth / CGFloat(cellInfo.type.itemCount) )
        }
        return cellInfo.type.getSize(cellInfo.contentObj, width: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let data = self.data else { return .zero }
        guard let cellInfo = data.sectionList[section].header else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.type.getSize(cellInfo.contentObj, width: collectionView.frame.size.width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let data = self.data else { return .zero }
        guard let cellInfo = data.sectionList[section].footer else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.type.getSize(cellInfo.contentObj, width: collectionView.frame.size.width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let data = self.data else { return .zero }
        let sectionInfo = data.sectionList[section]
        if sectionInfo.sectionInset != SectionInsetNotSupport {
            return sectionInfo.sectionInset
        }
        else {
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                return layout.sectionInset
            }
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let data = data else { return 0 }
        let sectionInfo = data.sectionList[section]
        if sectionInfo.minimumLineSpacing != -9999 {
            return sectionInfo.minimumLineSpacing
        }
        else {
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                return layout.minimumLineSpacing
            }
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let data = data else { return 0 }
        let sectionInfo = data.sectionList[section]
        if sectionInfo.minimumInteritemSpacing != -9999 {
            return sectionInfo.minimumInteritemSpacing
        }
        else {
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                return layout.minimumInteritemSpacing
            }
        }
        return 0
    }


    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.willDisplayCellCallback.forEach({ (callback) in
            callback(collectionView, cell, indexPath)
        })
        willDisPlayView(view: cell, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didEndDisplayingView(view: cell, at: indexPath)
        self.didEndDisplayCellCallback.forEach({ (callback) in
            callback(collectionView, cell, indexPath)
        })
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        self.willDisplaySupplementaryViewCallback.forEach({ (callback) in
            callback(collectionView, view, elementKind, indexPath)
        })
        willDisPlayView(view: view, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        didEndDisplayingView(view: view, at: indexPath)
        self.didEndDisplaySupplementaryViewCallback.forEach({ (callback) in
            callback(collectionView, view, elementKind, indexPath)
        })
    }

    func willDisPlayView(view: UICollectionReusableView, at indexPath: IndexPath) {
        guard  let viewType = view as? UICollectionViewAdapterCellProtocol else {  return }
        viewType.willDisplay()
    }
    func didEndDisplayingView(view: UICollectionReusableView, at indexPath: IndexPath) {
        guard let viewType = view as? UICollectionViewAdapterCellProtocol else { return }
        viewType.didEndDisplaying()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("scrollView.contentOffset.x = \(scrollView.contentOffset.x)")
        guard let scrollView = scrollView as? UICollectionView else { return }
        self.didScrollCallback.forEach({ callback in
            callback(scrollView)
        })
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        print("scrollViewDidEndDragging willDecelerate = \(decelerate)")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("scrollViewDidEndDecelerating")
        self.didEndDeceleratingCallback.forEach({ callback in
            callback(scrollView)
        })
    }
}

extension UICollectionView {
    private struct AssociatedKeys {
        static var collectionViewAdapter: UInt8 = 0
    }

    var adapter: UICollectionViewAdapter {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.collectionViewAdapter) as? UICollectionViewAdapter {
                return obj
            }
            let obj = UICollectionViewAdapter()
            obj.cView = self
            objc_setAssociatedObject(self, &AssociatedKeys.collectionViewAdapter, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            newValue.cView = self
            objc_setAssociatedObject(self, &AssociatedKeys.collectionViewAdapter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var adapterData: UICollectionViewAdapterData? {
        get {
            return self.adapter.data
        }
        set {
            self.adapter.data = newValue
        }
    }

    func didScrollCallback(_ callback: @escaping ScrollViewCallback) {
        adapter.didScrollCallback.append(callback)
    }
    func didEndDeceleratingCallback(_ callback: @escaping ScrollViewCallback) {
        adapter.didEndDeceleratingCallback.append(callback)
    }
    func willDisplayCellCallback(_ callback: @escaping CollectionViewDisplayClosure) {
        adapter.willDisplayCellCallback.append(callback)
    }
    func didEndDisplayCellCallback(_ callback: @escaping CollectionViewDisplayClosure) {
        adapter.didEndDisplayCellCallback.append(callback)
    }
    func willDisplaySupplementaryViewCallback(_ callback: @escaping CollectionViewDisplaySupplementaryViewClosure) {
        adapter.willDisplaySupplementaryViewCallback.append(callback)
    }
    func didEndDisplaySupplementaryViewCallback(_ callback: @escaping CollectionViewDisplaySupplementaryViewClosure) {
        adapter.didEndDisplaySupplementaryViewCallback.append(callback)
    }

    var adapterHasNext: Bool {
        get {
            return self.adapter.hasNext
        }
        set {
            self.adapter.hasNext = newValue
        }
    }

    var adapterRequestNextClosure: (() -> Void)? {
        get {
            return self.adapter.requestNextClosure
        }
        set {
            self.adapter.requestNextClosure = newValue
        }
    }
}


fileprivate var CacheViewNibs = NSCache<NSString, UIView>()
extension UIView {

    class func fromNib(cache: Bool = false) -> Self {
        return fromNib(cache: cache, as: self)
    }

    private class func fromNib<T>(cache: Bool = false, as type: T.Type) -> T {
        if cache, let view = CacheViewNibs.object(forKey: self.className as NSString) {
            return view as! T
        }
        let view: UIView = Bundle.main.loadNibNamed(self.className, owner: nil, options: nil)!.first as! UIView
        if cache {
            CacheViewNibs.setObject(view, forKey: self.className as NSString)
        }
        return view as! T
    }

    class func fromNibSize() -> CGSize {
        return fromNib(cache: true).frame.size
    }
}

