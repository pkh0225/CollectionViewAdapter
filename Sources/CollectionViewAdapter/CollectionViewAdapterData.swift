//
//  UICollectionViewAdapterData.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

public typealias CVAData = CollectionViewAdapterData
public typealias CVASectionInfo = CollectionViewAdapterData.SectionInfo
public typealias CVACellInfo = CollectionViewAdapterData.CellInfo

// MARK: - UICollectionViewAdapterData
public class CollectionViewAdapterData: NSObject {
    public class CellInfo: NSObject {
//        private let id: UUID = UUID()
//        public override var hash: Int { id.hashValue }

        public enum CellKind {
            case header
            case footer
            case cell
        }

        public var kind: CellKind = .cell
        public var contentObj: Any?
        public var subData: [String: Any?]?
        public var cellType: CollectionViewAdapterCellProtocol.Type
        public var sizeClosure: (() -> CGSize)?
        public var actionClosure: ((_ name: String, _ object: Any?) -> Void)?

        public init(_ cellType: CollectionViewAdapterCellProtocol.Type) {
            self.cellType = cellType
        }
    }

    public class SectionInfo: NSObject {
//        private let id: UUID = UUID()
//        public override var hash: Int { id.hashValue }
        
        public var header: CellInfo? {
            didSet {
                header?.kind = .header
            }
        }
        public var footer: CellInfo? {
            didSet {
                footer?.kind = .footer
            }
        }
        public var cells = [CellInfo]()

        public var backgroundColor: UIColor?
        public var sectionInset: UIEdgeInsets = SectionInsetNotSupport {
            didSet {
                guard sectionInset != oldValue else { return }
                if sectionInset.top == -9999 {
                    sectionInset.top = 0
                }
                if sectionInset.left == -9999 {
                    sectionInset.left = 0
                }
                if sectionInset.right == -9999 {
                    sectionInset.right = 0
                }
                if sectionInset.bottom == -9999 {
                    sectionInset.bottom = 0
                }
            }
        }
        public var minimumLineSpacing: CGFloat = -9999
        public var minimumInteritemSpacing: CGFloat = -9999
        public var dataType: String = ""
        public var indexPath = IndexPath(row: 0, section: 0)

        public override init() {}

        public init(cells: [CellInfo]) {
            self.cells = cells
        }
    }

    public var sectionList = [SectionInfo]()

    public func getCellInfo(_ indexPath: IndexPath) -> CellInfo? {
        guard indexPath.section < sectionList.count else { return nil }
        let section = sectionList[indexPath.section]
        guard indexPath.row < section.cells.count else { return nil }
        return section.cells[indexPath.row]
    }
}


extension CollectionViewAdapterData.CellInfo {
    @discardableResult
    public func contentObj(_ contentObj: Any?) -> Self {
        self.contentObj = contentObj
        return self
    }

    @discardableResult
    public func kind(_ kind: CellKind) -> Self {
        self.kind = kind
        return self
    }

    @discardableResult
    public func subData(_ subData: [String: Any?]?) -> Self {
        self.subData = subData
        return self
    }

    @discardableResult
    public func cellType(_ cellType: CollectionViewAdapterCellProtocol.Type) -> Self {
        self.cellType = cellType
        return self
    }

    @discardableResult
    public func sizeClosure(_ sizeClosure: (() -> CGSize)?) -> Self {
        self.sizeClosure = sizeClosure
        return self
    }

    @discardableResult
    public func actionClosure(_ actionClosure: ((_ name: String, _ object: Any?) -> Void)?) -> Self {
        self.actionClosure = actionClosure
        return self
    }
}

extension CollectionViewAdapterData.SectionInfo {
    @discardableResult
    public func header(_ cellInfo: CollectionViewAdapterData.CellInfo) -> Self {
        self.header = cellInfo
        return self
    }

    @discardableResult
    public func footer(_ cellInfo: CollectionViewAdapterData.CellInfo) -> Self {
        self.footer = cellInfo
        return self
    }

    @discardableResult
    public func cells(_ cells: [CollectionViewAdapterData.CellInfo]) -> Self {
        self.cells = cells
        return self
    }

    @discardableResult
    public func addCell(_ cells: CollectionViewAdapterData.CellInfo) -> Self {
        self.cells.append(cells)
        return self
    }

    @discardableResult
    public func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }

    @discardableResult
    public func sectionInset(_ inset: UIEdgeInsets) -> Self {
        self.sectionInset = inset
        return self
    }

    @discardableResult
    public func minimumLineSpacing(_ spacing: CGFloat) -> Self {
        self.minimumLineSpacing = spacing
        return self
    }

    @discardableResult
    public func minimumInteritemSpacing(_ spacing: CGFloat) -> Self {
        self.minimumInteritemSpacing = spacing
        return self
    }

    @discardableResult
    public func dataType(_ type: String) -> Self {
        self.dataType = type
        return self
    }

    @discardableResult
    public func indexPath(_ indexPath: IndexPath) -> Self {
        self.indexPath = indexPath
        return self
    }
}

extension CollectionViewAdapterData {
    @discardableResult
    public func addSection(_ sectionInfo: SectionInfo) -> Self {
        self.sectionList.append(sectionInfo)
        return self
    }

    @discardableResult
    public func section(_ sectionInfo: [SectionInfo]) -> Self {
        self.sectionList = sectionInfo
        return self
    }
}
