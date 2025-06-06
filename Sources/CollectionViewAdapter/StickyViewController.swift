//
//  StickyViewController.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

public protocol UICollectionViewAdapterStickyProtocol: UIView {
    /// sticky 될 뷰
    var stickyAbleView: UIView { get }
    /// stick 여부
    var isSticky: Bool { get }
    /// 데이타 리로드
    var reloadData: (() -> Void)? { get }
    /// 자기 Section에서만 Sticky 유지
    var isOnlySection: Bool { get }
    /// stick 됬을때 않됐을때 이벤트
    func onSticky(state: Bool)
    /// data  변경을 수종으로 처리 하고 싶을때
    func setData(data: Any?)
}

// MARK: - StickyViewController
@MainActor
public class StickyViewController: NSObject {
    @MainActor
    public class StickyViewItem: NSObject {
        static func == (lhs: StickyViewController.StickyViewItem, rhs: StickyViewController.StickyViewItem) -> Bool {
            return (lhs.indexPath.section == rhs.indexPath.section) && (lhs.indexPath.row == rhs.indexPath.row)
        }
        var indexPath: IndexPath
        /// UICollectionViewAdapterStickyProtocol을 채택한 뷰
        weak var stickyProtocolView: UICollectionViewAdapterStickyProtocol?
        /// 스티키 될 뷰
        weak var stickableView: UIView?
        /// 스티키 될 뷰가 붙어있는 stickyProtocolView 내의 뷰
        weak var stickableViewSuperView: UIView?
        /// CollectionView 위에 붙은 스티키 되어있는 뷰
        weak var collectionViewInSickyView: UIView?
        /// 스티키 될 뷰의 inset
        var stickableViewInset: UIEdgeInsets = .zero
        private var reloadDataClosure: (() -> Void)?
        /// 자기 Section에서만 Sticky 유지
        var onlySection: Bool = false
        var stickyStartY: CGFloat {
            get {
                var y = stickyProtocolView?.frame.origin.y ?? 0
                if stickyProtocolView !== stickableViewSuperView {
                    y += stickableViewSuperView?.frame.origin.y ?? 0
                }
                y += stickableViewInset.top
                return y
            }
        }
        var isSticked: Bool = false {
            didSet {
                guard isSticked != oldValue else { return }
                guard let collectionViewInSickyView, let stickableView, let stickyProtocolView, let stickableViewSuperView else { return }
                if isSticked {
                    collectionViewInSickyView.isHidden = false
                    collectionViewInSickyView.frame.size.height = stickableView.frame.height
                    collectionViewInSickyView.addSubViewAutoLayout(stickableView)
                    collectionViewInSickyView.sendSubviewToBack(stickableView)
                    collectionViewInSickyView.setNeedsLayout()
                    stickyProtocolView.onSticky(state: true)
                }
                else {
                    collectionViewInSickyView.isHidden = true
                    stickableViewSuperView.addSubViewAutoLayout(stickableView, edgeInsets: stickableViewInset)
                    stickableViewSuperView.sendSubviewToBack(stickableView)
                    stickableViewSuperView.setNeedsLayout()
                    stickyProtocolView.onSticky(state: false)
                }
            }
        }

        init(indexPath: IndexPath, view: UICollectionViewAdapterStickyProtocol) {
            self.indexPath = indexPath
            self.stickyProtocolView = view
            self.stickableViewInset = view.stickyAbleView.getMargin()
            self.stickableView = view.stickyAbleView
            self.stickableViewSuperView = view.stickyAbleView.superview
            self.onlySection = view.isOnlySection
            self.reloadDataClosure = view.reloadData
        }

        func setData(data: Any?) {
            stickyProtocolView?.setData(data: data)
        }

        func reloadData() {
            self.reloadDataClosure?()
        }
    }
    weak var collectionView: UICollectionView?
    var stickyItems = [StickyViewItem]()
    var currentStickItem: StickyViewItem? {
        get {
            return stickyItems.filter { $0.isSticked }.first
        }
    }
    var sectionYDic = [Int: CGFloat]()
    var gapClosure: (() -> CGFloat)?

    init(collectionView: UICollectionView, item: StickyViewItem) {
        super.init()
        self.collectionView = collectionView
        self.stickyItems = [item]
        self.addStickyView(collectionView: collectionView, addItem: item)
    }

    init(collectionView: UICollectionView, gapClosure: @escaping () -> CGFloat) {
        self.collectionView = collectionView
        self.gapClosure = gapClosure
    }

    func reset(afterIndexPath: IndexPath? = nil) {
        if let afterIndexPath {
            for k in sectionYDic.keys.reversed() {
                if k > afterIndexPath.section {
                    sectionYDic.removeValue(forKey: k)
                }
            }
        }
        else {
            sectionYDic.removeAll()
        }

        for item in stickyItems.reversed() {
            let section: Int = afterIndexPath?.section ?? -1
            guard let collectionViewInSickyView = item.collectionViewInSickyView, let originalContainerView = item.stickableView, item.indexPath.section > section else { continue }
            collectionViewInSickyView.isHidden = true
            item.stickableViewSuperView?.addSubViewAutoLayout(originalContainerView, edgeInsets: item.stickableViewInset)
            item.stickableViewSuperView?.sendSubviewToBack(originalContainerView)
            collectionViewInSickyView.removeFromSuperview()
            stickyItems.remove(object: item)
        }
    }

    func getStickItem(section: Int) -> StickyViewItem? {
        if stickyItems.count == 1 {
            return stickyItems.first
        }
        return stickyItems.filter { $0.indexPath.section == section }.first
    }

    func addStickyItem(collectionView: UICollectionView, addItem: StickyViewItem) {
        var chekc = true
        for item in stickyItems {
            if item.indexPath == addItem.indexPath {
                chekc = false
                break
            }
        }
        if chekc {
            self.stickyItems.append(addItem)
            self.stickyItems = self.stickyItems.sorted(by: {
                if $0.indexPath.section < $1.indexPath.section {
                    return true
                }
                else if $0.indexPath.row < $1.indexPath.row {
                    return true
                }
                return false
            })
            self.addStickyView(collectionView: collectionView, addItem: addItem)
        }
    }

    private func addStickyView(collectionView: UICollectionView, addItem: StickyViewItem) {
        guard let superView = collectionView.superview, let inView = addItem.stickableView else { return }

        var layoutInset = UIEdgeInsets.zero
        if addItem.stickyProtocolView is UICollectionViewCell {
            layoutInset = collectionView.adapter.collectionView(collectionView, layout: collectionView.collectionViewLayout, insetForSectionAt: addItem.indexPath.section)
        }

        let collectionViewInSickyView = UIView(frame: CGRect(x: addItem.stickableViewInset.left + layoutInset.left,
                                                             y: collectionView.frame.origin.y,
                                                             width: collectionView.frame.size.width - addItem.stickableViewInset.left - addItem.stickableViewInset.right - layoutInset.left - layoutInset.right,
                                                             height: inView.frame.size.height))
        addItem.collectionViewInSickyView = collectionViewInSickyView
        collectionViewInSickyView.autoresizingMask = [.flexibleWidth]
        collectionViewInSickyView.backgroundColor = .clear
        superView.addSubview(collectionViewInSickyView)
        collectionViewInSickyView.isHidden = true

    }

    func scrollViewDidScroll(_ collectionView: UICollectionView) {
        guard stickyItems.count > 0 else { return }

        var paddingValue: CGFloat = 0
        if let gapClosure = self.gapClosure {
            paddingValue = gapClosure()
        }

        let contentOffsetY = collectionView.contentOffset.y + paddingValue

        for (idx, item) in stickyItems.enumerated() {
            guard let stickyView = item.collectionViewInSickyView else { continue }
            var endY: CGFloat = CGFloat.greatestFiniteMagnitude
            if item.onlySection {
                if let y = sectionYDic[item.indexPath.section + 1] {
                    endY = y - stickyView.frame.size.height
                }
            }
            else {
                if let nextItem = stickyItems[safe: idx + 1] {
                    endY = nextItem.stickyStartY - stickyView.frame.size.height
                }
            }
            if contentOffsetY >= item.stickyStartY, contentOffsetY <= endY {
                stickyView.frame.origin.y = paddingValue + collectionView.frame.origin.y
                item.isSticked = true
            }
            else {
                let checkY = endY + stickyView.frame.size.height
                if contentOffsetY > endY, contentOffsetY < checkY {
                    stickyView.frame.origin.y = endY - contentOffsetY + collectionView.frame.origin.y + paddingValue
                    item.isSticked = true
                }
                else {
                    item.isSticked = false
                }
            }
        }

        if let _ = self.gapClosure {
            collectionView.layoutIfNeeded()
        }
    }
}
