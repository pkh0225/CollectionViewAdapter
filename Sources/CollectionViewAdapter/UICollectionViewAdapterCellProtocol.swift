//
//  UICollectionViewAdapterCellProtocol.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

public let SectionInsetNotSupport = UIEdgeInsets(top: -9999, left: -9999, bottom: -9999, right: -9999)
public let UISCREEN_WIDTH = UIScreen.main.bounds.width
public let UISCREEN_HEIGHT = UIScreen.main.bounds.height

public typealias VoidClosure = () -> Void
public typealias ActionClosure = (_ name: String, _ object: Any?) -> Void
public typealias ScrollViewCallback = (_ scrollView: UIScrollView) -> Void
public typealias CollectionViewDisplayClosure = (_ collectionView: UICollectionView,_ cell: UICollectionViewCell,_ indexPath: IndexPath) -> Void
public typealias CollectionViewDisplaySupplementaryViewClosure = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath) -> Void

private var isPageAnimating: Bool = false // page animation인지 검사




public protocol UICollectionViewAdapterCellProtocol: UICollectionReusableView {
    ///  0 : SectionInset 무시하고 width full 크기
    ///  1 : SectionInset 적용된 한개 크기
    ///  2 이상 : SectionInset 과 minimumInteritemSpacing 적용된 개수 만큼 크기
    static var SpanSize: Int { get }
    var actionClosure: ActionClosure? { get set }

    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize
    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath, actionClosure: ActionClosure?)
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath)
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath)
    // didSelect는 cell만 지원가능함
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath)
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath)
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath)
}

public extension UICollectionViewAdapterCellProtocol {
    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return self.fromXibSize()
    }
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
}

fileprivate var CacheViewXibs = {
    let cache = NSCache<NSString, UIView>()
    cache.countLimit = 200
    return cache
}()

public extension UIView {

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

