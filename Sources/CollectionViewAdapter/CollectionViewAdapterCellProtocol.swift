//
//  UICollectionViewAdapterCellProtocol.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

public let SectionInsetNotSupport = UIEdgeInsets(top: -9999, left: -9999, bottom: -9999, right: -9999)

public typealias VoidClosure = () -> Void
public typealias ActionClosure = (_ name: String, _ object: Any?) -> Void
public typealias ScrollViewCallback = (_ scrollView: UIScrollView) -> Void
public typealias CollectionViewDisplayClosure = (_ collectionView: UICollectionView,_ cell: UICollectionViewCell,_ indexPath: IndexPath) -> Void
public typealias CollectionViewDisplaySupplementaryViewClosure = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath) -> Void


public protocol CollectionViewAdapterCellProtocol: UICollectionReusableView {
    ///  Cell Auto Size
    ///
    ///  0 : SectionInset 무시하고 width full 크기(Deafult Value)
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
    var actionClosure: ActionClosure? { get set }

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

private struct AssociatedKeys {
    @Atomic static var actionClosure: UInt8 = 0
}

public extension CollectionViewAdapterCellProtocol {
    static var SpanSize: Int { return 0 }
    static func getSize(data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: self.fromXibSize().height)
    }

    var actionClosure: ActionClosure? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionClosure) as? ActionClosure
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionClosure, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func configureBefore(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {}
    func configureAfter(data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {}
    func willDisplay(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didEndDisplaying(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didHighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
    func didUnhighlight(collectionView: UICollectionView, indexPath: IndexPath) {}
}

@MainActor
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

@propertyWrapper
public struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    public func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    public mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
