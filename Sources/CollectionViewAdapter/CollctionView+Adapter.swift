//
//  UICollctionView+Adapter.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/22/24.
//  Copyright © 2024 pkh. All rights reserved.
//
import UIKit

public class DisplayLinkInfo {
    var displayLink: CADisplayLink?
    var postion: CGPoint = .zero
    var duration: TimeInterval = 0
    var delay: TimeInterval = 0
    var completion: VoidClosure?
    var d_x: CGFloat = 0
    var d_y: CGFloat = 0

    init(displayLink: CADisplayLink) {
        self.displayLink = displayLink
    }
}
// MARK: - UICollectionView Extension
extension UICollectionView {
    private struct AssociatedKeys {
        static var collectionViewAdapter: UInt8 = 0
        static var unitWidthDIc: UInt8 = 0
        static var displayLinkInfo: UInt8 = 0
    }

    public var flowLayout: UICollectionViewFlowLayout? {
        get {
            return collectionViewLayout as? UICollectionViewFlowLayout
        }
        set {
            guard let newValue else { return }
            collectionViewLayout = newValue
        }
    }

    public var displayLinkInfo: DisplayLinkInfo? {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.displayLinkInfo) as? DisplayLinkInfo {
                return obj
            }
            let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkRun(displayLink:)))
            displayLink.add(to: .main, forMode: RunLoop.Mode.common)
            displayLink.preferredFramesPerSecond = 30
            displayLink.isPaused = true
            let displayLinkInfo = DisplayLinkInfo(displayLink: displayLink)
            objc_setAssociatedObject(self, &AssociatedKeys.displayLinkInfo, displayLinkInfo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return displayLinkInfo
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.displayLinkInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var adapter: UICollectionViewAdapter {
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

    public var adapterData: CollectionViewAdapterData? {
        get {
            return self.adapter.data
        }
        set {
            self.adapter.data = newValue
//            self.stickyViewReset()   //중간에 있는 stickyView를 날리면 다시 add가 안되어있어서 주석처리 김요석 - https://redmine.ssgadm.com/redmine/issues/381529

            if self.adapter.infiniteScrollDirection == .horizontal {
                guard let layout = self.collectionViewLayout as? UICollectionViewFlowLayout else { return }
                layout.scrollDirection = .horizontal
                self.showsHorizontalScrollIndicator = false
                self.nowPage = 0
                self.adapter.infiniteScrollDirection = .none
                self.setContentOffset(.zero, animated: false)
                self.adapter.infiniteScrollDirection = .horizontal
            }
            else if self.adapter.infiniteScrollDirection == .vertical {
                guard let layout = self.collectionViewLayout as? UICollectionViewFlowLayout else { return }
                layout.scrollDirection = .vertical
                self.showsVerticalScrollIndicator = false
                self.nowPage = 0
                self.adapter.infiniteScrollDirection = .none
                self.setContentOffset(.zero, animated: false)
                self.adapter.infiniteScrollDirection = .vertical
            }

            if self.adapter.pageSize > 0 {
                self.showsHorizontalScrollIndicator = false
                self.showsVerticalScrollIndicator = false

                self.isPagingEnabled = false
                self.decelerationRate = .fast
            }

            if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout, flowLayout.estimatedItemSize == UICollectionViewFlowLayout.automaticSize {
                flowLayout.estimatedItemSize = .zero
            }
        }
    }

    public var unitWidthDic: [Int: CGFloat] {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.unitWidthDIc) as? [Int: CGFloat] {
                return obj
            }
            let obj = [Int: CGFloat]()
            objc_setAssociatedObject(self, &AssociatedKeys.unitWidthDIc, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.unitWidthDIc, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func getCacheWidth(spanSize: Int, sectionInset: UIEdgeInsets, minimumColumnSpacing: CGFloat) -> CGFloat {
        if let width = unitWidthDic[spanSize] {
            return width
        }
        else {
            let width = getSpanSizeWidth(spanSize: spanSize, sectionInset: sectionInset, minimumColumnSpacing: minimumColumnSpacing)
            unitWidthDic[spanSize] = width
            if UIDevice.current.userInterfaceIdiom == .pad, self.observerAble == nil {
                self.observerAble = (UIDevice.orientationDidChangeNotification.rawValue, { [weak self] _ in
                    guard let self else { return }
                    self.unitWidthDic.removeAll()
                })
            }
            return width
        }
    }

    /// 유닛 SpanSize로 Widht 계산
    /// - Parameter spanSize: spansize
    /// - Returns: unitWidthhttps://app.zeplin.io/project/5ed063ed0c643ab302fdadad/dashboard?seid=5fc74865abb9b5078f438cec
    public func getSpanSizeCacheWidth(spanSize: Int, indexPath: IndexPath) -> CGFloat {
        guard spanSize > 0 else { return self.frame.size.width }

        let sectionInset: UIEdgeInsets = getSectionInset(section: indexPath.section)
        let minimumColumnSpacing: CGFloat = getMinimumInteritemSpacing(section: indexPath.section)

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            if sectionInset == layout.sectionInset, minimumColumnSpacing == layout.minimumInteritemSpacing {
                return getCacheWidth(spanSize: spanSize, sectionInset: sectionInset, minimumColumnSpacing: minimumColumnSpacing)
            }
        }

        return getSpanSizeWidth(spanSize: spanSize, sectionInset: sectionInset, minimumColumnSpacing: minimumColumnSpacing)
    }

    /// 유닛 SpanSize로 Widht 계산
    /// - Parameter spanSize: spansize
    /// - Returns: unitWidth
    public func getSpanSizeWidth(spanSize: Int, sectionInset: UIEdgeInsets, minimumColumnSpacing: CGFloat) -> CGFloat {
        let spanSizef: CGFloat = CGFloat(spanSize)
        let full: CGFloat = self.frame.size.width - sectionInset.left - sectionInset.right
        let space: CGFloat = minimumColumnSpacing * (spanSizef - 1)
        return (full - space) / spanSizef
    }

    public func getMinimumInteritemSpacing(section: Int) -> CGFloat {
        let delegate = delegate as? UICollectionViewDelegateFlowLayout
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return delegate?.collectionView?(self, layout: self.collectionViewLayout, minimumInteritemSpacingForSectionAt: section) ?? layout.minimumInteritemSpacing
        }
        return 0
    }

    public func getMinimumLineSpacing(section: Int) -> CGFloat {
        let delegate = delegate as? UICollectionViewDelegateFlowLayout
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return delegate?.collectionView?(self, layout: self.collectionViewLayout, minimumLineSpacingForSectionAt: section) ?? layout.minimumLineSpacing
        }
        return 0
    }

    public func getSectionInset(section: Int) -> UIEdgeInsets {
        let delegate = delegate as? UICollectionViewDelegateFlowLayout
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return delegate?.collectionView?(self, layout: self.collectionViewLayout, insetForSectionAt: section) ?? layout.sectionInset
        }
        return .zero
    }

    public func didScrollCallback(_ callback: @escaping ScrollViewCallback) {
        adapter.didScrollCallback.append(callback)
    }
    public func didEndDeceleratingCallback(_ callback: @escaping ScrollViewCallback) {
        adapter.didEndDeceleratingCallback.append(callback)
    }
    public func willEndDraggingCallback(_ callback: @escaping (UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void) {
        adapter.willEndDraggingCallback = callback
    }
    public func willBeginDraggingCallback(_ callback: @escaping ScrollViewCallback) {
        adapter.willBeginDraggingCallback = callback
    }
    public func willDisplayCellCallback(_ callback: @escaping CollectionViewDisplayClosure) {
        adapter.willDisplayCellCallback.append(callback)
    }
    public func didEndDisplayCellCallback(_ callback: @escaping CollectionViewDisplayClosure) {
        adapter.didEndDisplayCellCallback.append(callback)
    }
    public func willDisplaySupplementaryViewCallback(_ callback: @escaping CollectionViewDisplaySupplementaryViewClosure) {
        adapter.willDisplaySupplementaryViewCallback.append(callback)
    }
    public func didEndDisplaySupplementaryViewCallback(_ callback: @escaping CollectionViewDisplaySupplementaryViewClosure) {
        adapter.didEndDisplaySupplementaryViewCallback.append(callback)
    }
    public func autoRollingCallback(_ callback: @escaping (CGPoint) -> Void) {
        adapter.autoRollingCallback = callback
    }

    public var adapterHasNext: Bool {
        get {
            return self.adapter.hasNext
        }
        set {
            self.adapter.hasNext = newValue
        }
    }

    public var adapterRequestNextClosure: (() -> Void)? {
        get {
            return self.adapter.requestNextClosure
        }
        set {
            self.adapter.requestNextClosure = newValue
        }
    }
    /// 무한 스크롤
    /// Section 0번째만 사용  adpterData를 넣기 전에 셋팅해야함
    public var infiniteScrollDirection: InfiniteScrollDirection {
        get {
            return self.adapter.infiniteScrollDirection
        }
        set {
            self.adapter.infiniteScrollDirection = newValue
        }
    }

    public var pageIndexClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        get {
            return self.adapter.pageIndexClosure
        }
        set {
            self.adapter.pageIndexClosure = newValue
        }
    }
    public var pageIndexAfterClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        get {
            return self.adapter.pageIndexAfterClosure
        }
        set {
            self.adapter.pageIndexAfterClosure = newValue
        }
    }
    public var isAutoRolling: Bool {
        get {
            return self.adapter.isAutoRolling
        }
        set {
            self.adapter.isAutoRolling = newValue
        }
    }
    public var nowPage: Int {
        get {
            return self.adapter.nowPage
        }
        set {
            self.adapter.nowPage = newValue
        }
    }

    public var pageSize: CGFloat {
        get {
            return self.adapter.pageSize
        }
        set {
            self.adapter.pageSize = newValue
        }
    }

    public var alignCenter: Bool {
        get {
            return self.adapter.alignCenter
        }
        set {
            self.adapter.alignCenter = newValue
        }
    }

    public var isUsedCacheSize: Bool {
        get {
            return self.adapter.isUsedCacheSize
        }
        set {
            self.adapter.isUsedCacheSize = newValue
        }
    }
    public var cacheSize: [Int: [Int: CGSize]] {
        get {
            return self.adapter.cacheSize
        }
        set {
            self.adapter.cacheSize = newValue
        }
    }

    public func cacheRemoveAfterReloadData() {
        self.adapter.cacheSize.removeAll()
        self.reloadData()
    }

    public func cacheRemoveAfterReloadSections(_ sections: IndexSet) {
        for s in sections {
            self.adapter.cacheSize.removeValue(forKey: s)
        }
        self.reloadSections(sections)
    }

    public func cacheRemoveAfterReloadItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if var sectionDic = self.adapter.cacheSize[indexPath.section] {
                sectionDic.removeValue(forKey: indexPath.row)
                self.adapter.cacheSize[indexPath.section] = sectionDic
            }
        }
        self.reloadItems(at: indexPaths)
    }

    public func setTabTouchContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        self.scrollsToTop = false

        self.setContentOffset(contentOffset, animated: animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.scrollsToTop = true
        }
    }
    /// StickyView Function
    public func scrollTopStickyView(section: Int, animated: Bool) {
            guard let stickyItem = self.adapter.stickyVC?.getStickItem(section: section) else { return }
            var gapY: CGFloat = 0
            if let gapClousure = self.adapter.stickyVC?.gapClosure {
                gapY = gapClousure()
            }
            let y = stickyItem.stickyStartY - gapY
                // base header footer가 움직이는걸 막기위해
            self.setTabTouchContentOffset(CGPoint(x: 0, y: y), animated: animated)
    }

    /// StickyView Function
    public func scrollTopStickyViewForEmpty(section: Int, animated: Bool) {
        DispatchQueue.main.async {
            guard let stickyItem = self.adapter.stickyVC?.getStickItem(section: section) else { return }

            // base header footer가 움직이는걸 막기위해
            self.setTabTouchContentOffset(CGPoint(x: 0, y: stickyItem.stickyStartY), animated: animated)
        }

    }
    // StickyView Function
    public func scrollTopSectionForStickyView(section: Int, animated: Bool = true) {
        DispatchQueue.main.async {
            if let att = self.layoutAttributesForItem(at: IndexPath(row: 0, section: section)) {
                var y: CGFloat = att.frame.origin.y
                if let stickyItem = self.adapter.stickyVC?.getStickItem(section: section) {
                    y -= stickyItem.stickableView?.frame.size.height ?? 0
                }

                self.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
            }
        }
    }

    /// StickyView Function
    public func scrollTopSectionHeaderForStickyView(section: Int) {
        DispatchQueue.main.async {
            if let att = self.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: section)) {
                var y: CGFloat = att.frame.origin.y
                if let stickyItem = self.adapter.stickyVC?.getStickItem(section: section), stickyItem.indexPath.section < section {
                    y -= stickyItem.stickableView?.frame.size.height ?? 0
                }

                self.setContentOffset(CGPoint(x: 0, y: y + 1), animated: true)
            }
        }
    }

    public func getStickItem(section: Int) -> StickyViewController.StickyViewItem? {
        return adapter.stickyVC?.getStickItem(section: section)
    }

    // StickyView Function
    public func stickyViewReset() {
        guard let stickyVC = adapter.stickyVC else { return }
        stickyVC.reset()
    }

    public func getIndexPathOfScrollY(_ x: CGFloat, _ y: CGFloat) -> IndexPath? {
        if let indexPath = indexPathForItem(at: CGPoint(x: x, y: y)) {
           return indexPath
        }
        else if let view = visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)[safe: 0] {
            if view.frame.origin.y <= y {
                return view.indexPath
            }
        }
        else if let view = visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)[safe: 0] {
            if view.frame.origin.y > y {
                return view.indexPath
            }
        }
        return nil
    }

    public func onPagePrev() {
        guard self.bounds.width > 0 else { return }
        guard self.adapter.isPageAnimating == false else { return }
        guard let maxCount = adapterData?.sectionList[safe: 0]?.cells.count else { return }

        var pageWidth: CGFloat
        if pageSize > 0 {
            pageWidth = pageSize
        }
        else {
            pageWidth = self.bounds.width
        }
        var x: CGFloat = 0
        if infiniteScrollDirection != .none {
            x = CGFloat(maxCount + nowPage - 1) * pageWidth
        }
        else {
            x = CGFloat(nowPage - 1) * pageWidth
        }
        if (x >= -self.contentInset.left) || infiniteScrollDirection == .horizontal {
            self.adapter.isPageAnimating = true
            self.setContentOffset(CGPoint(x: x, y: self.contentOffset.y), animated: true)
        }
        else if (x >= -self.contentInset.top) || infiniteScrollDirection == .vertical {
            self.adapter.isPageAnimating = true
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: x), animated: true)
        }
    }

    public func onPageNext() {
        guard self.bounds.width > 0 else { return }
        guard self.adapter.isPageAnimating == false else { return }
        guard let maxCount = adapterData?.sectionList[safe: 0]?.cells.count else { return }

        var pageWidth: CGFloat
        if pageSize > 0 {
            pageWidth = pageSize
        }
        else {
            pageWidth = self.bounds.width
        }
        var x: CGFloat = 0
        if infiniteScrollDirection != .none {
            x = CGFloat(maxCount + nowPage + 1) * pageWidth
        }
        else {
            x = CGFloat(nowPage + 1) * pageWidth
        }
        if (x <= self.contentSize.width - pageWidth) || infiniteScrollDirection == .horizontal {
            self.adapter.isPageAnimating = true
            self.setContentOffset(CGPoint(x: x, y: self.contentOffset.y), animated: true)
        }
        else if (x <= self.contentSize.height - pageWidth) || infiniteScrollDirection == .vertical {
            self.adapter.isPageAnimating = true
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: x), animated: true)
        }
    }

    /// scrollToPostion(position: duration: delay: completion:) function animation stop
    public func scrollToPostionEnd() {
        guard let displayLinkInfo = self.displayLinkInfo else { return }
        displayLinkInfo.displayLink?.isPaused = true
        displayLinkInfo.displayLink?.invalidate()
        self.displayLinkInfo?.displayLink = nil
        self.displayLinkInfo = nil
    }

    /// CollectionView contentOffset Animation
    ///
    /// 화면을 벗어나면 애니메이션이 자동으로 멈춤
    /// - Parameters:
    ///   - position: position
    ///   - duration: duration
    ///   - delay: delay
    ///   - completion: completion
    public func scrollToPostion(position: CGPoint, duration: TimeInterval, delay: TimeInterval, completion: VoidClosure? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard self.contentSize.width > self.frame.size.width else { return }
            guard duration > 0, self.contentOffset != position else {
                self.contentOffset = position
                completion?()
                return
            }
            guard let displayLinkInfo = self.displayLinkInfo else { return }

            displayLinkInfo.postion = position
            displayLinkInfo.duration = duration
            displayLinkInfo.delay = delay
            displayLinkInfo.completion = completion
            let d = duration * (CGFloat(displayLinkInfo.displayLink?.preferredFramesPerSecond ?? 1) / 2.0)
            displayLinkInfo.d_x = (displayLinkInfo.postion.x - self.contentOffset.x) / d
            displayLinkInfo.d_y = (displayLinkInfo.postion.y - self.contentOffset.y) / d
            self.displayLinkInfo?.displayLink?.isPaused = false
//            print("d: \(d), displayLinkInfo.d_x: \(displayLinkInfo.d_x)")
        }
    }

    @objc public func displayLinkRun(displayLink: CADisplayLink) {
        guard let displayLinkInfo = self.displayLinkInfo else { return }
        guard isVisible else {
            displayLinkInfo.displayLink?.isPaused = true
            displayLinkInfo.displayLink?.invalidate()
            self.displayLinkInfo?.displayLink = nil
            self.displayLinkInfo = nil
            return
        }

        self.contentOffset.x += displayLinkInfo.d_x
        self.contentOffset.y += displayLinkInfo.d_y

        var endX = false
        var endY = false
        if displayLinkInfo.d_x > 0 {
            if self.contentOffset.x >= displayLinkInfo.postion.x {
                self.contentOffset.x = displayLinkInfo.postion.x
                endX = true
            }
        }
        else {
            if self.contentOffset.x <= displayLinkInfo.postion.x {
                self.contentOffset.x = displayLinkInfo.postion.x
                endX = true
            }
        }

        if displayLinkInfo.d_y > 0 {
            if self.contentOffset.y >= displayLinkInfo.postion.y {
                self.contentOffset.y = displayLinkInfo.postion.y
                endY = true
            }
        }
        else {
            if self.contentOffset.y <= displayLinkInfo.postion.y {
                self.contentOffset.y = displayLinkInfo.postion.y
                endY = true
            }
        }

        if endX, endY {
            displayLinkInfo.displayLink?.isPaused = true
            displayLinkInfo.displayLink?.invalidate()
            let completion = displayLinkInfo.completion
            self.displayLinkInfo?.displayLink = nil
            self.displayLinkInfo = nil

            completion?()
        }

//        print(displayLink.timestamp)
    }

    /// infinite 일때 첫 로딩시 센터가 틀어질때 width가 결정이 된 후 호출 하면 센터를 맞춰줌
    public func centerIfNeeded() {
        self.adapter.centerIfNeeded(self)
    }
}

@available(iOS 14.0, *)
extension UICollectionView {
    /// Cell의 TableView처럼 가로가 꽉 찬 형태의 Cell AutoSize 지원
    /// - Parameter apperance: plain (header, footer 생성시 자동으로 스티기 됨),
    ///                        grouped(header, footer 생성시 스키키 안됨 수동처리해야됨)
    public func setAutoSizeListCellLayout(apperance: UICollectionLayoutListConfiguration.Appearance = .plain) {
        self.collectionViewLayout = createAutoSizeListCellLayout(apperance: apperance)
    }

    private func createAutoSizeListCellLayout(apperance: UICollectionLayoutListConfiguration.Appearance) -> UICollectionViewCompositionalLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            var config = UICollectionLayoutListConfiguration(appearance: apperance)
            config.showsSeparators = false
            config.headerMode = (self.adapterData?.sectionList[safe: sectionIndex]?.header != nil) ? .supplementary : .none
            config.footerMode = (self.adapterData?.sectionList[safe: sectionIndex]?.footer != nil) ? .supplementary : .none

            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            section.interGroupSpacing = 0
            section.contentInsets = .zero
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
}

@available(iOS 13.0, *)
extension UICollectionView {
    static func fixedSpacedFlowLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(70),
            heightDimension: .estimated(32)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(8)

        let section = NSCollectionLayoutSection(group: group)

        let sectionHeaderPadding: CGFloat = 32

        section.contentInsets = NSDirectionalEdgeInsets(top: 16 + sectionHeaderPadding,
                                                        leading: 16,
                                                        bottom: 8,
                                                        trailing: 16)
        section.interGroupSpacing = 12

        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                    heightDimension: .absolute(18)),
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .topLeading,
                                                                 absoluteOffset: CGPoint(x: 0, y: sectionHeaderPadding))
        section.boundarySupplementaryItems = [header]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
