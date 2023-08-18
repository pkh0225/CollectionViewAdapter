//
//  StickyViewController.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit
import EasyConstraints

protocol UICollectionViewAdapterStickyProtocol: UIView {
    /// sticky 될 뷰
    var stickyContainerView: UIView { get }
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
class StickyViewController {
    class StickyViewItem {
        var indexPath: IndexPath
        weak var originalView: UICollectionViewAdapterStickyProtocol?
        weak var originalContainerView: UIView?
        weak var originalSpuerView: UIView?
        weak var stickyView: UIView?
        var originalContainerViewInset: UIEdgeInsets = .zero
        private var reloadDataClouser: (() -> Void)?
        /// 자기 Section에서만 Sticky 유지
        var onlySection: Bool = false
        var stickyStartY: CGFloat {
            get {
                var y = originalView?.frame.origin.y ?? 0
                if originalView !== originalContainerView {
                    y += originalContainerView?.frame.origin.y ?? 0
                }
                return y
            }
        }
        var isSticked: Bool = false {
            didSet {
                guard isSticked != oldValue else { return }
                guard let stickyView, let originalContainerView, let originalView, let originalSpuerView else { return }
                if isSticked {
                    stickyView.isHidden = false
                    stickyView.addSubViewAutoLayout(originalContainerView)
                    stickyView.sendSubviewToBack(originalContainerView)
                    stickyView.setNeedsLayout()
                    originalView.onSticky(state: true)
                }
                else {
                    stickyView.isHidden = true
                        originalSpuerView.addSubViewAutoLayout(originalContainerView, edgeInsets: originalContainerViewInset)
                        originalSpuerView.sendSubviewToBack(originalContainerView)
                        originalSpuerView.setNeedsLayout()
                        originalView.onSticky(state: false)
                }
            }
        }

        init(indexPath: IndexPath, view: UICollectionViewAdapterStickyProtocol) {
            self.indexPath = indexPath
            self.originalView = view
            self.originalContainerViewInset = UIEdgeInsets(top: view.stickyContainerView.ec.top, left: view.stickyContainerView.ec.leading, bottom: view.stickyContainerView.ec.bottom, right: view.stickyContainerView.ec.trailing)
            self.originalContainerView = view.stickyContainerView
            self.originalSpuerView = view.stickyContainerView.superview
            self.onlySection = view.isOnlySection
            self.reloadDataClouser = view.reloadData
        }

        func setData(data: Any?) {
            originalView?.setData(data: data)
        }

        func reloadData() {
            self.reloadDataClouser?()
        }
    }
    weak var collectionView: UICollectionView?
    var stickyItems = [StickyViewItem]() {
        didSet {

        }
    }
    var currentStickItem: StickyViewItem? {
        get {
            return stickyItems.filter { $0.isSticked }.first
        }
    }
    var sectionYDic = [Int: CGFloat]()
    var gapClosure: (() -> CGFloat)?

    init(collectionView: UICollectionView, item: StickyViewItem) {
        self.collectionView = collectionView
        self.stickyItems = [item]
        self.addStickyView(collectionView: collectionView, addItem: item)
    }

    init(collectionView: UICollectionView, gapClosure: @escaping () -> CGFloat) {
        self.collectionView = collectionView
        self.gapClosure = gapClosure
    }

    func reset() {
        sectionYDic.removeAll()

        for item in stickyItems {
            guard let stickyView = item.stickyView, let originalContainerView = item.originalContainerView else { continue }
            stickyView.isHidden = true
            item.originalSpuerView?.addSubViewAutoLayout(originalContainerView, edgeInsets: item.originalContainerViewInset)
            stickyView.removeFromSuperview()
        }

        stickyItems.removeAll()
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
        guard let superView = collectionView.superview, let inView = addItem.originalContainerView else { return }
        let stickyView = UIView(frame: CGRect(x: collectionView.frame.origin.x, y: collectionView.frame.origin.y, width: collectionView.frame.size.width, height: inView.frame.size.height) )
        addItem.stickyView = stickyView
        superView.addSubview(stickyView)

        stickyView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["stickyView": stickyView]
        let metrics: Dictionary = ["y": collectionView.frame.origin.y, "h": inView.frame.size.height, "l": addItem.originalContainerViewInset.left, "r": addItem.originalContainerViewInset.right]
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(l)-[stickyView]-(r)-|",
                                                                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                metrics: metrics,
                                                                views: views as [String: Any]))

        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(y)-[stickyView(h)]",
                                                                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                metrics: metrics,
                                                                views: views as [String: Any]))
        stickyView.isHidden = true

    }

    func scrollViewDidScroll(_ collectionView: UICollectionView) {
        guard stickyItems.count > 0 else { return }

        var paddingValue: CGFloat = 0
        if let gapClosure = self.gapClosure {
            paddingValue = gapClosure()
        }

        let contentOffsetY = collectionView.contentOffset.y + paddingValue

        for (idx, item) in stickyItems.enumerated() {
            guard let stickyView = item.stickyView else { continue }
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
                stickyView.ec.top = paddingValue + collectionView.frame.origin.y
                item.isSticked = true
            }
            else {
                let checkY = endY + stickyView.frame.size.height
                if contentOffsetY > endY, contentOffsetY < checkY {
                    stickyView.ec.top = endY - contentOffsetY + collectionView.frame.origin.y
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
