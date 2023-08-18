//
//  UICollectionViewAdapterCellProtocol.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

let SectionInsetNotSupport = UIEdgeInsets(top: -9999, left: -9999, bottom: -9999, right: -9999)
let UISCREEN_WIDTH = UIScreen.main.bounds.width
let UISCREEN_HEIGHT = UIScreen.main.bounds.height

public typealias VoidClosure = () -> Void
typealias ActionClosure = (_ name: String, _ object: Any?) -> Void
typealias ScrollViewCallback = (_ scrollView: UIScrollView) -> Void
typealias CollectionViewDisplayClosure = (_ collectionView: UICollectionView,_ cell: UICollectionViewCell,_ indexPath: IndexPath) -> Void
typealias CollectionViewDisplaySupplementaryViewClosure = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath) -> Void

private var isPageAnimating: Bool = false // page animation인지 검사




protocol UICollectionViewAdapterCellProtocol: UICollectionReusableView {
    ///  0 : SectionInset 무시하고 width full 크기
    ///  1 : SectionInset 적용된 한개 크기
    ///  2 이상 : SectionInset 과 minimumInteritemSpacing 적용된 개수 만큼 크기
    static var SpanSize: Int { get }
    var actionClosure: ActionClosure? { get set }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize
    func setup()
    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath, actionClosure: ActionClosure?)
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath)
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath)
    // didSelect는 cell만 지원가능함
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath)
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath)
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath)
}

extension UICollectionViewAdapterCellProtocol {
    static func getSize(_ data: Any? = nil, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return self.fromXibSize()
    }
    func setup(){}
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath){}
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath){}
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath){}
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath){}
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath){}
}

fileprivate var CacheViewXibs = NSCache<NSString, UIView>()
extension UIView {

    class func fromXib(cache: Bool = false) -> Self {
        return fromXib(cache: cache, as: self)
    }

    private class func fromXib<T>(cache: Bool = false, as type: T.Type) -> T {
        if cache, let view = CacheViewXibs.object(forKey: self.className as NSString) {
            return view as! T
        }
        let view: UIView = Bundle.main.loadNibNamed(self.className, owner: nil, options: nil)!.first as! UIView
        if cache {
            CacheViewXibs.setObject(view, forKey: self.className as NSString)
        }
        return view as! T
    }

    class func fromXibSize() -> CGSize {
        return fromXib(cache: true).frame.size
    }
}

