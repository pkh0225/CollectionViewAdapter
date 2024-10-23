//
//  CollectionViewProtocol.swift
//  ssg
//
//  Created by pkh on 24/06/2019.
//  Copyright © 2019 emart. All rights reserved.
//

import UIKit

public enum InfiniteScrollDirection {
    case none
    case horizontal
    case vertical
}

// MARK: - UICollectionViewAdapter
public class CollectionViewAdapter: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public var isDebugMode: Bool = false
    public static let CHECK_Y_MORE_SIZE: CGFloat = UISCREEN_HEIGHT * 4
    public static let CHECK_X_MORE_SIZE: CGFloat = UISCREEN_WIDTH * 2

    private var checkBeforeHeight: CGFloat = 0.0
    private var checkBeforeHeightIndex: Int = -1
    private var isCheckBeforeHeight = false
    weak var cView: UICollectionView? {
        didSet {
            cView?.delegate = self
            cView?.dataSource = self
        }
    }

    public var stickyVC: StickyViewController?
    var didScrollCallback: [ScrollViewCallback] = []
    var willDisplayCellCallback: [CollectionViewDisplayClosure] = []
    var didEndDisplayCellCallback: [CollectionViewDisplayClosure] = []
    var willEndDraggingCallback: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)?
    var willBeginDraggingCallback: ((UIScrollView) -> Void)?
    var autoRollingCallback: ((CGPoint) -> Void)?
    var didEndDeceleratingCallback: [ScrollViewCallback] = []
    var willDisplaySupplementaryViewCallback: [CollectionViewDisplaySupplementaryViewClosure] = []
    var didEndDisplaySupplementaryViewCallback: [CollectionViewDisplaySupplementaryViewClosure] = []

    var data: CollectionViewAdapterData? {
        didSet {
            if isAutoRolling {
                setCollectionViewDidAppear(value: isAutoRolling)
            }
        }
    }
    var hasNext: Bool = false
    var requestNextClosure: (() -> Void)?

    var isUsedCacheSize: Bool = true
    var cacheSize = [Int: [Int: CGSize]]()
    var infiniteIndexIndexOffset: Int = 0
    var nowPage: Int = 0
    var infinitePageIndex: Int = -1

    // 현재는 가로 스크롤일 경우에만 지원합니다
    var pageSize: CGFloat = 0
    /// 가로스크롤인데 유닛이 가운데에 위치하고 싶을 때 사용
    /// pageSize는 유닛사이즈와 동일해야합니다.
    var alignCenter: Bool = false

    /// 무한 스크롤 방향
    /// Section 0번째만 사용  adpterData를 넣기 전에 셋팅해야함
    var infiniteScrollDirection: InfiniteScrollDirection = .none
    /// index가 바뀌자 마자 호출
    var pageIndexClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        didSet {
            setCollectionViewDidAppear(value: true)
        }
    }
    /// 페이지가 다 이동 후 호출
    var pageIndexAfterClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        didSet {
            setCollectionViewDidAppear(value: true)
        }
    }
    /// page animation인지 검사
    var isPageAnimating: Bool = false
    /// infiniteScrollDirection is not none 일때만 동작
    var isAutoRolling: Bool = false {
        didSet {
            guard isAutoRolling != oldValue else { return }
//            print("isAutoRolling : \(isAutoRolling)")
            delayAutoRolling(start: isAutoRolling)
            setCollectionViewDidAppear(value: isAutoRolling)

            if UIDevice.current.userInterfaceIdiom == .pad, self.observerAble == nil {
                self.observerAble = (UIDevice.orientationDidChangeNotification.rawValue, { [weak self] _ in
                    guard let self else { return }
                    self.delayAutoRolling(start: false)
                    if self.isAutoRolling {
                        self.delayAutoRolling(start: true)
                    }
                })
            }
        }
    }

    private func setCollectionViewDidAppear(value: Bool) {
        if value {
            cView?.viewDidAppear = { [weak self] isVisible in
                guard let self else { return }
//                print("viewDidAppear : \(isVisible)", targetName: .pkh)
                if isVisible {
                    if let cView = self.cView {
                        if self.infiniteScrollDirection != .none {
                            self.pageIndexClosure?(cView, self.nowPage)
                        }
                    }
                }
                if self.isAutoRolling, isVisible {
                    self.delayAutoRolling(start: true)
                }
                else {
                    self.delayAutoRolling(start: false)
                }
            }
        }
        else {
            cView?.viewDidAppear = nil
        }
    }

    func cancelAutoRolling() {
        if infiniteScrollDirection == .horizontal {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.horizontalAutoRolling), object: nil)
        }
        else if infiniteScrollDirection == .vertical {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.verticalAutoRolling), object: nil)
        }
    }

    private func delayAutoRolling(start: Bool) {
        DispatchQueue.main.async {
//            print("cView.isVisible: \(self.cView?.isVisible), start: \(start)")
            if let cView = self.cView, cView.isVisible, start {
                if self.infiniteScrollDirection == .horizontal {
                    self.perform(#selector(self.horizontalAutoRolling), with: nil, afterDelay: 3)
                }
                else if self.infiniteScrollDirection == .vertical {
                    self.perform(#selector(self.verticalAutoRolling), with: nil, afterDelay: 3)
                }
            }
            else {
                self.cancelAutoRolling()
            }
        }
    }

    @objc func horizontalAutoRolling() {
        self.cancelAutoRolling()
        guard infiniteScrollDirection == .horizontal, let cView, let data, let section = data.sectionList[safe: 0], section.cells.count > 1 else { return }
        let pageWidth: CGFloat = (pageSize > 0) ? pageSize : cView.frame.size.width
        let nextIndex = floor(cView.contentOffset.x / pageWidth) + 1
        cView.setContentOffset(CGPoint(x: nextIndex * pageWidth, y: 0), animated: true)
        self.autoRollingCallback?(CGPoint(x: nextIndex * pageWidth, y: 0))
        perform(#selector(self.horizontalAutoRolling), with: nil, afterDelay: 3)
    }

    @objc func verticalAutoRolling() {
        self.cancelAutoRolling()
        guard infiniteScrollDirection == .vertical, let cView, let data, let section = data.sectionList[safe: 0], section.cells.count > 1 else { return }
        let pageHeight: CGFloat = (pageSize > 0) ? pageSize : cView.frame.size.height
        let nextIndex = floor(cView.contentOffset.y / pageHeight) + 1
        cView.setContentOffset(CGPoint(x: 0, y: nextIndex * pageHeight), animated: true)
        self.autoRollingCallback?(CGPoint(x: 0, y: nextIndex * pageHeight))
        perform(#selector(self.verticalAutoRolling), with: nil, afterDelay: 3)
    }


    @discardableResult
    func checkMoreData(_ collecttionView: UICollectionView) -> Bool {
        guard hasNext else { return hasNext }

        let checkXY: CGFloat
        let position: CGFloat

        if let layout = collecttionView.collectionViewLayout as? UICollectionViewFlowLayout, layout.scrollDirection == .horizontal {
            checkXY = collecttionView.contentSize.width - CollectionViewAdapter.CHECK_X_MORE_SIZE
            position = collecttionView.contentOffset.x + collecttionView.frame.size.width
        }
        else {
            checkXY = collecttionView.contentSize.height - CollectionViewAdapter.CHECK_Y_MORE_SIZE
            position = collecttionView.contentOffset.y + collecttionView.frame.size.height
        }

        if position >= checkXY || checkXY <= 0 {
            hasNext = false
            DispatchQueue.main.async {
                self.requestNextClosure?()
            }
        }
        return hasNext
    }

    func getCellInfo(_ indexPath: IndexPath) -> CollectionViewAdapterData.CellInfo? {
        guard let data = self.data else { return nil }
        var checkCellInfo: CollectionViewAdapterData.CellInfo?
        if infiniteScrollDirection != .none {
            if let sectionInfo = data.sectionList[safe: 0], let cellInfo = sectionInfo.cells[safe: (correctedIndex(indexPath.item))] {
                checkCellInfo = cellInfo
            }
        }
        else {
            if let cellInfo = data.sectionList[safe: indexPath.section]?.cells[safe: indexPath.row] {
                checkCellInfo = cellInfo
            }
        }
        return checkCellInfo
    }

    // FOR YOU 그만볼래요 처럼 섹션, 셀 삭제 상황을 위해 기능 구현 by. iSunSoo.
    private func checkCellIndexPath(_ cellInfo: CollectionViewAdapterData.CellInfo) -> IndexPath? {
        guard let data = self.data else { return nil }
        for (sectionIndex, section) in data.sectionList.enumerated() {
            for (cellIndex, cell) in section.cells.enumerated() {
                if cell === cellInfo {
                    return IndexPath(row: cellIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }

    func removeCellInfo(in collectionView: UICollectionView, cellInfo: CollectionViewAdapterData.CellInfo) {
        guard let data = self.data else { return }
        // 해당 cellInfo에 속해있는 item이 오직 1개라면 해당 section까지 지운다.
        if let indexPath = checkCellIndexPath(cellInfo) {
            if data.sectionList[indexPath.section].cells.count <= 1 {
                collectionView.performBatchUpdates {
                    data.sectionList.remove(at: indexPath.section)
                    collectionView.deleteSections(IndexSet(integer: indexPath.section))
                }
            }
            else {
                collectionView.performBatchUpdates {
                    data.sectionList[safe: indexPath.section]?.cells.remove(at: indexPath.row)
                    collectionView.deleteItems(at: [indexPath])
                }
            }
        }
    }

    func registerCell(in collectionView: UICollectionView) {
        guard let data else { return }
        guard data.sectionList.count > 0 else { return }

        for (si, sectionInfo) in data.sectionList.enumerated() {
            if let header = sectionInfo.header {
                if let _ = header.cellType as? UICollectionViewAdapterStickyProtocol.Type {
                    collectionView.registerHeader(Class: header.cellType, withReuseIdentifier: "Header_\(header.cellType)_\(si)")
                }
                else {
                    collectionView.registerHeader(header.cellType)
                }

            }
            if let footer = sectionInfo.footer {
                if let _ = footer.cellType as? UICollectionViewAdapterStickyProtocol.Type {
                    collectionView.registerFooter(Class: footer.cellType, withReuseIdentifier: "Footer_\(footer.cellType)_\(si)")
                }
                else {
                    collectionView.registerFooter(footer.cellType)
                }

            }
            if sectionInfo.cells.count > 0 {
                for (ci, cell) in sectionInfo.cells.enumerated() {
                    if let cellType = cell.cellType as? UICollectionViewCell.Type {
                        if let _ = cell.cellType as? UICollectionViewAdapterStickyProtocol.Type {
                            collectionView.register(Class: cellType, withReuseIdentifier: "Cell_\(cell.cellType)_\(si)_\(ci)")
                        }
                        else {
                            collectionView.register(cellType)
                        }
                    }
                }
            }
        }
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let data else { return 0 }
        checkBeforeHeight = -1
        checkBeforeHeightIndex = -1
        registerCell(in: collectionView)
        collectionView.registerDefaultCell()

//        if horizontalPageSize > 0 {
//            DispatchQueue.main.async {
//                guard let collectoinView = self.cView else { return }
//                if collectoinView.contentInset.right != collectionView.frame.size.width - self.horizontalPageSize {
//                    collectoinView.contentInset.right = collectionView.frame.size.width - self.horizontalPageSize
//                }
//            }
//        }
        if infiniteScrollDirection != .none {
            DispatchQueue.main.async {
                self.centerIfNeeded(collectionView)
            }
            return 1
        }

        if data.sectionList.count == 0 && hasNext {
//            hasNext = false
            requestNextClosure?()
        }

        return data.sectionList.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data else { return 0 }
        if infiniteScrollDirection != .none {
            guard let sectionInfo = data.sectionList[safe: 0] else { return 0 }
            return sectionInfo.cells.count * 3
        }

        guard let sectionInfo = data.sectionList[safe: section] else { return 0 }
        return sectionInfo.cells.count
    }


    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        func defaultReturn() -> UICollectionViewCell { return collectionView.dequeueReusableCell(UICollectionViewCell.self, for: indexPath) }
        guard let cellInfo = self.getCellInfo(indexPath) else { return defaultReturn() }
        guard let cellType = cellInfo.cellType as? UICollectionViewCell.Type else { return defaultReturn() }
        defer {
            checkMoreData(collectionView)
        }

        var cell: UICollectionViewCell!
        if let _ = cellType as? UICollectionViewAdapterStickyProtocol.Type {
            cell = collectionView.dequeueReusableCell(cellType, for: indexPath, withReuseIdentifier: "Cell_\(cellType)_\(indexPath.section)_\(indexPath.row)")
        }
        else {
            cell = collectionView.dequeueReusableCell(cellType, for: indexPath)
        }

        if infiniteScrollDirection != .none {
            // 무한 롤링은 3배수로 처리되기에 indexPath 값 조정
            let maxCount = collectionView.numberOfItems(inSection: indexPath.section)
            cell.indexPath = IndexPath(item: indexPath.row % (maxCount / 3), section: indexPath.section)
        }

        if let cell = cell as? CollectionViewAdapterCellProtocol {
            cell.parentCollectionView = collectionView
            cell.actionClosure = cellInfo.actionClosure
            cell.configure(data: cellInfo.contentObj, subData: cellInfo.subData, collectionView: collectionView, indexPath: indexPath, actionClosure: cellInfo.actionClosure)
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        func defaultReturn() -> UICollectionReusableView { return UICollectionReusableView() }

        guard let data else { return defaultReturn() }
        let cellInfo: CollectionViewAdapterData.CellInfo?
        if kind == UICollectionView.elementKindSectionHeader {
            cellInfo = data.sectionList[safe: indexPath.section]?.header
        }
        else {
            cellInfo = data.sectionList[safe: indexPath.section]?.footer
        }
        guard let cellType = cellInfo?.cellType as? UICollectionReusableView.Type else { return defaultReturn() }

        let view: UICollectionReusableView!
        if let _ = cellType as? UICollectionViewAdapterStickyProtocol.Type {
            if kind == UICollectionView.elementKindSectionHeader {
                view = collectionView.dequeueReusableHeader(cellType, for: indexPath, withReuseIdentifier: "Header_\(cellType)_\(indexPath.section)")
            }
            else {
                view = collectionView.dequeueReusableFooter(cellType, for: indexPath)
            }
        }
        else {
            if kind == UICollectionView.elementKindSectionHeader {
                view = collectionView.dequeueReusableHeader(cellType, for: indexPath)
            }
            else {
                view = collectionView.dequeueReusableFooter(cellType, for: indexPath)
            }
        }

        if let view = view as? CollectionViewAdapterCellProtocol {
            view.configure(data: cellInfo?.contentObj, subData: cellInfo?.subData, collectionView: collectionView, indexPath: indexPath, actionClosure: cellInfo?.actionClosure)
        }

        return view
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let data else { return .zero }
        var checkCellInfo: CollectionViewAdapterData.CellInfo?
        if infiniteScrollDirection != .none {
            if let sectionInfo = data.sectionList[safe: 0], let cellInfo = sectionInfo.cells[safe: (correctedIndex(indexPath.item))] {
                checkCellInfo = cellInfo
            }
        }
        else {
            if let cellInfo = data.sectionList[safe: indexPath.section]?.cells[safe: indexPath.row] {
                checkCellInfo = cellInfo
            }
        }
        guard let cellInfo = checkCellInfo else { return .zero }

        if self.isUsedCacheSize, let size = self.cacheSize[indexPath.section]?[indexPath.row] {
            return size
        }

        var size: CGSize = .zero
        if let sizeClosure = cellInfo.sizeClosure {
            size = sizeClosure()
        }
        else {
            let width = collectionView.getSpanSizeCacheWidth(spanSize: cellInfo.cellType.SpanSize, indexPath: indexPath)
            size = cellInfo.cellType.getSize(data: cellInfo.contentObj, width: width, collectionView: collectionView, indexPath: indexPath)
        }

        if infiniteScrollDirection == .none, isCheckBeforeHeight == false, type(of: collectionViewLayout) === UICollectionViewFlowLayout.self {
            if let layout = collectionViewLayout as? UICollectionViewFlowLayout, layout.scrollDirection == .vertical {
                if size.width < collectionView.frame.size.width {
                    if checkBeforeHeightIndex < indexPath.row || indexPath.row == 0 {
                        checkBeforeHeight = 0
                        checkBeforeHeightIndex = 0
                    }
                    if checkBeforeHeight <= 0 {
                        checkBeforeHeight = size.height
                        checkBeforeHeightIndex = indexPath.row
                        var checkWidht = size.width
                        let cellCount = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
                        var nextIndexPath = indexPath
                        while nextIndexPath.row < cellCount - 1 {
                            nextIndexPath.row += 1
                            isCheckBeforeHeight = true
                            let nextSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: nextIndexPath)
                            isCheckBeforeHeight = false
                            if checkWidht + nextSize.width > collectionView.frame.size.width {
                                break
                            }
                            checkWidht += nextSize.width
                            checkBeforeHeight = max(nextSize.height, checkBeforeHeight)
                            checkBeforeHeightIndex = nextIndexPath.row
                        }
                    }
                    size.height = checkBeforeHeight

                }
                else {
                    checkBeforeHeight = 0
                    checkBeforeHeightIndex = 0
                }

            }
        }
        
        if self.isUsedCacheSize {
            if var sectionDic = self.cacheSize[indexPath.section] {
                sectionDic[indexPath.row] = size
                self.cacheSize[indexPath.section] = sectionDic
            }
            else {
                self.cacheSize[indexPath.section] = [indexPath.row: size]
            }
        }
        return size
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let data else { return .zero }
        guard let cellInfo = data.sectionList[safe: section]?.header else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.cellType.getSize(data: cellInfo.contentObj, width: collectionView.frame.size.width, collectionView: collectionView, indexPath: IndexPath(row: 0, section: section))
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let data else { return .zero }
        guard let cellInfo = data.sectionList[safe: section]?.footer else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellInfo.cellType.getSize(data: cellInfo.contentObj, width: collectionView.frame.size.width, collectionView: collectionView, indexPath: IndexPath(row: 0, section: section))
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let data, let sectionInfo = data.sectionList[safe: section] else { return .zero }
        if sectionInfo.sectionInset != SectionInsetNotSupport {
            return sectionInfo.sectionInset
        }
        else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return layout.sectionInset
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let data, let sectionInfo = data.sectionList[safe: section] else { return 0 }
        if sectionInfo.minimumLineSpacing != -9999 {
            return sectionInfo.minimumLineSpacing
        }
        else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return layout.minimumLineSpacing
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let data, let sectionInfo = data.sectionList[safe: section] else { return 0 }
        if sectionInfo.minimumInteritemSpacing != -9999 {
            return sectionInfo.minimumInteritemSpacing
        }
        else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return layout.minimumInteritemSpacing
        }

        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        for callback in self.willDisplayCellCallback {
            callback(collectionView, cell, indexPath)
        }
        if let cell = cell as? CollectionViewAdapterCellProtocol {
            cell.willDisplay(collectionView: collectionView, indexPath: indexPath)
        }
        addStickyView(view: cell, collectionView: collectionView, at: indexPath)
        if let stickyVC, stickyVC.stickyItems.count > 0 {
            if indexPath.row == 0, self.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: indexPath.section) == .zero {
                stickyVC.sectionYDic[indexPath.section] = cell.frame.origin.y
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CollectionViewAdapterCellProtocol {
            cell.didEndDisplaying(collectionView: collectionView, indexPath: indexPath)
        }
        for callback in self.didEndDisplayCellCallback {
            callback(collectionView, cell, indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        for callback in self.willDisplaySupplementaryViewCallback {
            callback(collectionView, view, elementKind, indexPath)
        }
        if let cell = view as? CollectionViewAdapterCellProtocol {
            cell.willDisplay(collectionView: collectionView, indexPath: indexPath)
        }
        addStickyView(view: view, collectionView: collectionView, at: indexPath)
        if let stickyVC, stickyVC.stickyItems.count > 0 {
            if elementKind == UICollectionView.elementKindSectionHeader {
                stickyVC.sectionYDic[indexPath.section] = view.frame.origin.y
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if let cell = view as? CollectionViewAdapterCellProtocol {
            cell.didEndDisplaying(collectionView: collectionView, indexPath: indexPath)
        }
        for callback in self.didEndDisplaySupplementaryViewCallback {
            callback(collectionView, view, elementKind, indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? (CollectionViewAdapterCellProtocol & UICollectionViewCell) {
            cell.didSelect(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewAdapterCellProtocol {
            cell.didHighlight(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewAdapterCellProtocol {
            cell.didUnhighlight(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("scrollView.contentOffset.x = \(scrollView.contentOffset.x)")
        guard scrollView.contentSize != .zero else { return }
        guard let scrollView = scrollView as? UICollectionView else { return }
        for callback in self.didScrollCallback {
            callback(scrollView)
        }
        if let stickyVC, stickyVC.stickyItems.count > 0 {
            stickyVC.scrollViewDidScroll(scrollView)
        }

        if infiniteScrollDirection != .none {
            centerIfNeeded(scrollView)
        }
        else {
            if scrollView.isPagingEnabled || pageSize > 0 {
                if let flowLayout = scrollView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let pageWidth: CGFloat
                    let position: CGFloat
                    if flowLayout.scrollDirection == .horizontal {
                        pageWidth = pageSize > 0 ? pageSize : scrollView.frame.size.width
                        position = scrollView.contentOffset.x + (pageWidth / 2)
                    }
                    else {
                        pageWidth = pageSize > 0 ? pageSize : scrollView.frame.size.height
                        position = scrollView.contentOffset.y + (pageWidth / 2)
                    }

                    if pageWidth > 0.0 {
                        let index = Int(position / pageWidth)
                        if nowPage != index {
                            nowPage = index
                            if let cView {
                                pageIndexClosure?(cView, nowPage)
                            }
                        }
                    }
                }
            }
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.willBeginDraggingCallback?(scrollView)
        if isAutoRolling {
//            print("scrollViewWillBeginDragging")
            if infiniteScrollDirection != .none {
                self.cancelAutoRolling()
            }
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        print("scrollViewDidEndDragging willDecelerate = \(decelerate)")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("scrollViewDidEndDecelerating")
        for callback in self.didEndDeceleratingCallback {
            callback(scrollView)
        }
        if isAutoRolling {
            if infiniteScrollDirection == .horizontal {
                perform(#selector(self.horizontalAutoRolling), with: nil, afterDelay: 3)
            }
            else if infiniteScrollDirection == .vertical {
                perform(#selector(self.verticalAutoRolling), with: nil, afterDelay: 3)
            }
        }

        if let closure = pageIndexAfterClosure, let cv = scrollView as? UICollectionView {
            closure(cv, nowPage)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        print("scrollViewDidEndScrollingAnimation")
        DispatchQueue.main.async {
            self.isPageAnimating = false
        }
        if let closure = pageIndexAfterClosure, let cv = scrollView as? UICollectionView {
            closure(cv, nowPage)
        }
    }

    // pageSize
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.willEndDraggingCallback?(scrollView, velocity, targetContentOffset)
        guard let scrollView = scrollView as? UICollectionView else { return }
        guard pageSize > 0 else { return }
        if let flowLayout = scrollView.collectionViewLayout as? UICollectionViewFlowLayout {
            if flowLayout.scrollDirection == .horizontal {
                targetContentOffset.pointee.x = getTargetContentOffset(scrollView: scrollView, velocity: velocity)
            }
            else {
                targetContentOffset.pointee.y = getTargetContentOffset(scrollView: scrollView, velocity: velocity)
            }
        }
    }

    func addStickyView(view: UIView, collectionView: UICollectionView, at indexPath: IndexPath ) {
        guard let casp = view as? UICollectionViewAdapterStickyProtocol, casp.isSticky else { return }
        let item = StickyViewController.StickyViewItem(indexPath: indexPath, view: casp)
        if stickyVC == nil {
            stickyVC = StickyViewController(collectionView: collectionView, item: item)
        }
        else {
            stickyVC?.addStickyItem(collectionView: collectionView, addItem: item)
        }
    }

}

// MARK: - private HorizontalInfinite
extension CollectionViewAdapter {
    func centerIfNeeded(_ collectionView: UICollectionView) {
        var pageWidth: CGFloat = collectionView.bounds.width
        var pageHeight: CGFloat = collectionView.bounds.height
        var sectionInset: UIEdgeInsets = .zero

        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let minimumLineSpacing = flowLayout?.minimumLineSpacing ?? 0
        if let flowLayout {
            sectionInset = flowLayout.sectionInset

            if pageSize > 0 {
                if flowLayout.scrollDirection == .horizontal {
                    pageWidth = pageSize
                }
                else {
                    pageHeight = pageSize
                }
            }
        }

        let currentOffset = collectionView.contentOffset
        if infiniteScrollDirection == .horizontal {
            let maxWidth = ceil((collectionView.contentSize.width - sectionInset.left - sectionInset.right - (minimumLineSpacing * 2)) / 3)
            if currentOffset.x < maxWidth + sectionInset.left {
                collectionView.contentOffset = CGPoint(x: currentOffset.x + maxWidth + minimumLineSpacing, y: currentOffset.y)
                collectionView.reloadData()
            }
            else if currentOffset.x >= (maxWidth * 2) + sectionInset.left + minimumLineSpacing {
                collectionView.contentOffset = CGPoint(x: currentOffset.x - maxWidth - minimumLineSpacing, y: currentOffset.y)
                collectionView.reloadData()
            }
            let index: CGFloat = (currentOffset.x + (pageWidth / 2.0) ) / pageWidth
            if infinitePageIndex != Int(index) {
                infinitePageIndex = Int(index)
            }
            let pageIndex = correctedIndex(Int(index))
            if nowPage != pageIndex {
                nowPage = pageIndex
                pageIndexClosure?(collectionView, nowPage)
            }
        }
        else if infiniteScrollDirection == .vertical {
            let maxHeight = ceil((collectionView.contentSize.height - sectionInset.top - sectionInset.bottom - (minimumLineSpacing * 2)) / 3)
            if currentOffset.y < maxHeight + sectionInset.top {
                collectionView.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y + maxHeight + minimumLineSpacing)
            }
            else if currentOffset.y > (maxHeight * 2) + sectionInset.top + minimumLineSpacing {
                collectionView.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y - maxHeight - minimumLineSpacing)
                collectionView.reloadData()
            }
            let index: CGFloat = (currentOffset.y + (pageHeight / 2.0) ) / pageHeight
            if infinitePageIndex != Int(index) {
                infinitePageIndex = Int(index)
            }
            let pageIndex = correctedIndex(Int(index))
            if nowPage != pageIndex {
                nowPage = pageIndex
                pageIndexClosure?(collectionView, nowPage)
            }
        }
    }

    func correctedIndex(_ indexToCorrect: Int) -> Int {
        guard let numberOfItems = data?.sectionList[safe: 0]?.cells.count, numberOfItems > 0 else { return 0 }

        let countInIndex = indexToCorrect % numberOfItems
        return countInIndex
    }

}

// MARK: - ScrollView PageSize
private extension CollectionViewAdapter {
    func getCurrentPage(scrollView: UICollectionView) -> CGFloat {
        guard let flowLayout = scrollView.collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        let sectionInset: UIEdgeInsets = flowLayout.sectionInset

        if flowLayout.scrollDirection == .horizontal {
            return (scrollView.contentOffset.x + scrollView.contentInset.left - sectionInset.left) / pageSize
        }
        else {
            return (scrollView.contentOffset.y + scrollView.contentInset.top - sectionInset.top) / pageSize
        }
    }

    func getTargetContentOffset(scrollView: UICollectionView, velocity: CGPoint) -> CGFloat {
        guard let flowLayout = scrollView.collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        let sectionInset: UIEdgeInsets = flowLayout.sectionInset

        if flowLayout.scrollDirection == .horizontal {
            let targetX: CGFloat = scrollView.contentOffset.x + velocity.x * 60.0

            var targetIndex = (targetX + scrollView.contentInset.left - sectionInset.left) / pageSize
            targetIndex = max(targetIndex, floor(getCurrentPage(scrollView: scrollView)))
            targetIndex = min(targetIndex, ceil(getCurrentPage(scrollView: scrollView)))
            let maxOffsetX = scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right + sectionInset.right
            let maxIndex = (maxOffsetX + scrollView.contentInset.left - sectionInset.left) / pageSize
            if velocity.x > 0 {
                targetIndex = ceil(targetIndex)
            }
            else if velocity.x < 0 {
                targetIndex = floor(targetIndex)
            }
            else {
                let (maxFloorIndex, lastInterval) = modf(maxIndex)
                if targetIndex > maxFloorIndex {
                    if targetIndex >= lastInterval / 2 + maxFloorIndex {
                        targetIndex = maxIndex
                    }
                    else {
                        targetIndex = maxFloorIndex
                    }
                }
                else {
                    targetIndex = round(targetIndex)
                }
            }

            if targetIndex < 0 {
                targetIndex = 0
            }

            var offsetX: CGFloat
            if alignCenter {
                if targetIndex > 0 {
                    let firstOffset = pageSize + flowLayout.sectionInset.left + flowLayout.minimumLineSpacing - ((UISCREEN_WIDTH - pageSize) / 2)
                    offsetX = firstOffset + (pageSize + flowLayout.minimumLineSpacing) * (targetIndex - 1)
                }
                else {
                    offsetX = 0
                }
            }
            else {
                offsetX = (targetIndex * pageSize) - scrollView.contentInset.left// + sectionInset.left
            }
            offsetX = min(offsetX, maxOffsetX)

            return offsetX
        }
        else {
            let targetX: CGFloat = scrollView.contentOffset.y + velocity.y * 60.0

            var targetIndex = (targetX + scrollView.contentInset.top - sectionInset.top) / pageSize
            targetIndex = max(targetIndex, floor(getCurrentPage(scrollView: scrollView)))
            targetIndex = min(targetIndex, ceil(getCurrentPage(scrollView: scrollView)))
            let maxOffsetX = scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom + sectionInset.bottom
            let maxIndex = (maxOffsetX + scrollView.contentInset.top - sectionInset.top) / pageSize
            if velocity.y > 0 {
                targetIndex = ceil(targetIndex)
            }
            else if velocity.y < 0 {
                targetIndex = floor(targetIndex)
            }
            else {
                let (maxFloorIndex, lastInterval) = modf(maxIndex)
                if targetIndex > maxFloorIndex {
                    if targetIndex >= lastInterval / 2 + maxFloorIndex {
                        targetIndex = maxIndex
                    }
                    else {
                        targetIndex = maxFloorIndex
                    }
                }
                else {
                    targetIndex = round(targetIndex)
                }
            }

            if targetIndex < 0 {
                targetIndex = 0
            }

            var offsetX: CGFloat = (targetIndex * pageSize) - scrollView.contentInset.top// + sectionInset.left
            offsetX = min(offsetX, maxOffsetX)

            return offsetX
        }
    }
}

extension Array {
    subscript(safe index: Int?) -> Element? {
        guard let index = index else { return nil }
        if indices.contains(index) {
            return self[index]
        }
        else {
            return nil
        }
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}
