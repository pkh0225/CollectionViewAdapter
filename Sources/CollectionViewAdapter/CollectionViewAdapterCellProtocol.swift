//
//  UICollectionViewAdapterCellProtocol.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

public let SectionInsetNotSupport = UIEdgeInsets(top: -9999, left: -9999, bottom: -9999, right: -9999)
public typealias CVACellProtocol = CollectionViewAdapterCellProtocol

@MainActor
public protocol CollectionViewAdapterCellProtocol: UICollectionReusableView {
    ///  Cell Auto Size
    ///
    ///  0 : SectionInset 무시하고 CollectionView width full 크기
    ///
    ///  1 : SectionInset 적용된 한개 크기
    ///
    ///  2 이상 : SectionInset 과 minimumInteritemSpacing 적용된 개수 만큼 크기
    static var SpanSize: Int { get }

    /// 기본 SpanSize를 사용하지 않고 커스텀 Size를 사용하고 싶을때 (안드로이드와 같은 SpapSize 개념)
    /// - Parameters:
    ///   - data: configure에 전달되는 동일한 data
    ///   - width: SpanSize에서 계산된 Width( Section Inst, minimumInteritemSpacing 이 계산된 크기)
    ///   - collectionView: collectionView
    ///   - indexPath: 사용될 indexPath
    /// - Returns: CGSize
    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize


    /// 커스텀 액션을 처리하기 위한 변수
    ///
    /// CVACellInfo.actionClosure 에 전달된 actionClosure
    var actionClosure: ((_ name: String, _ object: Any?) -> Void)? { get set }

    func configureBefore(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath)
    func configure(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath)
    func configureAfter(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath)
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath)
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath)
    // didSelect는 cell만 지원가능함
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath)
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath)
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath)
}

public extension CollectionViewAdapterCellProtocol {
    func configureBefore(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {}
    func configureAfter(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {}
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
}

@MainActor
public class ViewCacheManager {
    static var cacheViewNibs: NSCache<NSString, UIView> = {
        var c = NSCache<NSString, UIView>()
        c.countLimit = 500
        return c
    }()
    static var cacheNibs: NSCache<NSString, UINib> = {
        var c = NSCache<NSString, UINib>()
        c.countLimit = 500
        return c
    }()

    public static func cacheRemoveAll() {
        self.cacheViewNibs.removeAllObjects()
        self.cacheNibs.removeAllObjects()
    }
}

extension CollectionViewAdapterCellProtocol where Self: UIView {
    public static func fromXib(cache: Bool = false) -> Self {
        return fromXib(cache: cache, as: self)
    }

    private static func fromXib<T>(cache: Bool = false, as type: T.Type) -> T {
        if cache, let view = ViewCacheManager.cacheViewNibs.object(forKey: self.className as NSString) {
            return view as! T
        }
        else if let nib = ViewCacheManager.cacheNibs.object(forKey: self.className as NSString) {
            return nib.instantiate(withOwner: nil, options: nil).first as! T
        }
        else if let path: String = Bundle.main.path(forResource: className, ofType: "nib") {
            if FileManager.default.fileExists(atPath: path) {
                let nib = UINib(nibName: self.className, bundle: nil)
                let view = nib.instantiate(withOwner: nil, options: nil).first as! T

                ViewCacheManager.cacheNibs.setObject(nib, forKey: self.className as NSString)
                if cache {
                    ViewCacheManager.cacheViewNibs.setObject(view as! UIView, forKey: self.className as NSString)
                }
                return view
            }
        }
        fatalError("\(className) XIB File Not Exist")
    }

    public static func fromXibSize() -> CGSize {
        return fromXib(cache: true).frame.size
    }
}
