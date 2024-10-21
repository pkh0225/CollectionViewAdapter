//
//  CollectionViewProtocol.swift
//  ssg
//
//  Created by pkh on 24/06/2019.
//  Copyright © 2019 emart. All rights reserved.
//

import UIKit

private var isPageAnimating: Bool = false // page animation인지 검사

public enum InfiniteScrollDirection {
    case none
    case horizontal
    case vertical
}

// MARK: - UICollectionViewAdapter
public class UICollectionViewAdapter: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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

    var data: UICollectionViewAdapterData? {
        didSet {
            if isAutoRolling {
                setCollectionViewDidAppear(value: isAutoRolling)
            }
        }
    }
    var hasNext: Bool = false
    var requestNextClosure: (() -> Void)?

    fileprivate var isUsedCacheSize: Bool = true
    fileprivate var cacheSize = [Int: [Int: CGSize]]()
    fileprivate var infiniteIndexIndexOffset: Int = 0
    fileprivate var nowPage: Int = 0
    fileprivate var infinitePageIndex: Int = -1

    // 현재는 가로 스크롤일 경우에만 지원합니다. 추가 필요시 길호님께 요청해주세요
    fileprivate var pageSize: CGFloat = 0
    /// 가로스크롤인데 유닛이 가운데에 위치하고 싶을 때 사용
    /// pageSize는 유닛사이즈와 동일해야합니다.
    fileprivate var alignCenter: Bool = false

    /// 무한 스크롤 방향
    /// Section 0번째만 사용  adpterData를 넣기 전에 셋팅해야함
    var infiniteScrollDirection: InfiniteScrollDirection = .none
    /// index가 바뀌자 마자 호출
    fileprivate var pageIndexClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        didSet {
            setCollectionViewDidAppear(value: true)
        }
    }
    /// 페이지가 다 이동 후 호출
    fileprivate var pageIndexAfterClosure: ((_ collectoinView: UICollectionView, _ pageIndex: Int) -> Void)? {
        didSet {
            setCollectionViewDidAppear(value: true)
        }
    }

    /// infiniteScrollDirection is not none 일때만 동작
    fileprivate var isAutoRolling: Bool = false {
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

    @objc fileprivate func horizontalAutoRolling() {
        self.cancelAutoRolling()
        guard infiniteScrollDirection == .horizontal, let cView, let data, let section = data.sectionList[safe: 0], section.cells.count > 1 else { return }
        let pageWidth: CGFloat = (pageSize > 0) ? pageSize : cView.frame.size.width
        let nextIndex = floor(cView.contentOffset.x / pageWidth) + 1
        cView.setContentOffset(CGPoint(x: nextIndex * pageWidth, y: 0), animated: true)
        self.autoRollingCallback?(CGPoint(x: nextIndex * pageWidth, y: 0))
        perform(#selector(self.horizontalAutoRolling), with: nil, afterDelay: 3)
    }

    @objc fileprivate func verticalAutoRolling() {
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
            checkXY = collecttionView.contentSize.width - UICollectionViewAdapter.CHECK_X_MORE_SIZE
            position = collecttionView.contentOffset.x + collecttionView.frame.size.width
        }
        else {
            checkXY = collecttionView.contentSize.height - UICollectionViewAdapter.CHECK_Y_MORE_SIZE
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

    func getCellInfo(_ indexPath: IndexPath) -> UICollectionViewAdapterData.CellInfo? {
        guard let data = self.data else { return nil }
        var checkCellInfo: UICollectionViewAdapterData.CellInfo?
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
    private func checkCellIndexPath(_ cellInfo: UICollectionViewAdapterData.CellInfo) -> IndexPath? {
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

    func removeCellInfo(in collectionView: UICollectionView, cellInfo: UICollectionViewAdapterData.CellInfo) {
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

        if let cell = cell as? UICollectionViewAdapterCellProtocol {
            cell.parentCollectionView = collectionView
            cell.actionClosure = cellInfo.actionClosure
            cell.configure(data: cellInfo.contentObj, subData: cellInfo.subData, collectionView: collectionView, indexPath: indexPath, actionClosure: cellInfo.actionClosure)
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        func defaultReturn() -> UICollectionReusableView { return collectionView.dequeueReusableHeader(UICollectionReusableView.self, for: indexPath) }

        guard let data else { return defaultReturn() }
        let cellInfo: UICollectionViewAdapterData.CellInfo?
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

        if let view = view as? UICollectionViewAdapterCellProtocol {
            view.configure(data: cellInfo?.contentObj, subData: cellInfo?.subData, collectionView: collectionView, indexPath: indexPath, actionClosure: cellInfo?.actionClosure)
        }

        return view
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let data else { return .zero }
        var checkCellInfo: UICollectionViewAdapterData.CellInfo?
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
        guard let cellType = cellInfo.cellType as? UICollectionViewAdapterCellProtocol.Type else { return .zero }

        if self.isUsedCacheSize, let size = self.cacheSize[indexPath.section]?[indexPath.row] {
            return size
        }

        var size: CGSize = .zero
        if let sizeClosure = cellInfo.sizeClosure {
            size = sizeClosure()
        }

        let width = collectionView.getSpanSizeCacheWidth(spanSize: cellType.SpanSize, indexPath: indexPath)
        size = cellType.getSize(data: cellInfo.contentObj, width: width, collectionView: collectionView, indexPath: indexPath)

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
        guard let cellType = cellInfo.cellType as? UICollectionViewAdapterCellProtocol.Type else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellType.getSize(data: cellInfo.contentObj, width: collectionView.frame.size.width, collectionView: collectionView, indexPath: IndexPath(row: 0, section: section))
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let data else { return .zero }
        guard let cellInfo = data.sectionList[safe: section]?.footer else { return .zero }
        guard let cellType = cellInfo.cellType as? UICollectionViewAdapterCellProtocol.Type else { return .zero }
        if let sizeClosure = cellInfo.sizeClosure {
            return sizeClosure()
        }
        return cellType.getSize(data: cellInfo.contentObj, width: collectionView.frame.size.width, collectionView: collectionView, indexPath: IndexPath(row: 0, section: section))
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
        if let cell = cell as? UICollectionViewAdapterCellProtocol {
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
        if let cell = cell as? UICollectionViewAdapterCellProtocol {
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
        if let cell = view as? UICollectionViewAdapterCellProtocol {
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
        if let cell = view as? UICollectionViewAdapterCellProtocol {
            cell.didEndDisplaying(collectionView: collectionView, indexPath: indexPath)
        }
        for callback in self.didEndDisplaySupplementaryViewCallback {
            callback(collectionView, view, elementKind, indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? (UICollectionViewAdapterCellProtocol & UICollectionViewCell) {
            cell.didSelect(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewAdapterCellProtocol {
            cell.didHighlight(collectionView: collectionView, indexPath: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewAdapterCellProtocol {
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
            isPageAnimating = false
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
private extension UICollectionViewAdapter {
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
private extension UICollectionViewAdapter {
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

    public var adapterData: UICollectionViewAdapterData? {
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

    @available(iOS 14.0, *)
    public func setAutoSizeCellLayout() {
        self.collectionViewLayout = createAutoSizeCellLayout()
    }
    
    @available(iOS 14.0, *)
    private func createAutoSizeCellLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            var config = UICollectionLayoutListConfiguration(appearance: .grouped)
            config.showsSeparators = false
            config.headerMode = .supplementary
            config.footerMode = .supplementary
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)

            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
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
        guard isPageAnimating == false else { return }
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
            isPageAnimating = true
            self.setContentOffset(CGPoint(x: x, y: self.contentOffset.y), animated: true)
        }
        else if (x >= -self.contentInset.top) || infiniteScrollDirection == .vertical {
            isPageAnimating = true
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: x), animated: true)
        }
    }

    public func onPageNext() {
        guard self.bounds.width > 0 else { return }
        guard isPageAnimating == false else { return }
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
            isPageAnimating = true
            self.setContentOffset(CGPoint(x: x, y: self.contentOffset.y), animated: true)
        }
        else if (x <= self.contentSize.height - pageWidth) || infiniteScrollDirection == .vertical {
            isPageAnimating = true
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
