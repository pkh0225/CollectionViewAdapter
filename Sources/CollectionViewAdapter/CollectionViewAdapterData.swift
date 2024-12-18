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
}


extension CollectionViewAdapterData.CellInfo {
    public func contentObj(_ contentObj: Any?) -> Self {
        self.contentObj = contentObj
        return self
    }

    public func kind(_ kind: CellKind) -> Self {
        self.kind = kind
        return self
    }

    public func subData(_ subData: [String: Any?]?) -> Self {
        self.subData = subData
        return self
    }

    public func cellType(_ cellType: CollectionViewAdapterCellProtocol.Type) -> Self {
        self.cellType = cellType
        return self
    }

    public func sizeClosure(_ sizeClosure: (() -> CGSize)? = nil) -> Self {
        self.sizeClosure = sizeClosure
        return self
    }

    public func actionClosure(_ actionClosure: ((_ name: String, _ object: Any?) -> Void)? = nil) -> Self {
        self.actionClosure = actionClosure
        return self
    }
}

extension CollectionViewAdapterData.SectionInfo {
    public func header(_ cellInfo: CollectionViewAdapterData.CellInfo) -> Self {
        self.header = cellInfo
        return self
    }

    public func footer(_ cellInfo: CollectionViewAdapterData.CellInfo) -> Self {
        self.footer = cellInfo
        return self
    }

    public func cells(_ cells: [CollectionViewAdapterData.CellInfo]) -> Self {
        self.cells = cells
        return self
    }

    public func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }

    public func sectionInset(_ inset: UIEdgeInsets) -> Self {
        self.sectionInset = inset
        return self
    }

    public func minimumLineSpacing(_ spacing: CGFloat) -> Self {
        self.minimumLineSpacing = spacing
        return self
    }

    public func minimumInteritemSpacing(_ spacing: CGFloat) -> Self {
        self.minimumInteritemSpacing = spacing
        return self
    }

    public func dataType(_ type: String) -> Self {
        self.dataType = type
        return self
    }

    public func indexPath(_ indexPath: IndexPath) -> Self {
        self.indexPath = indexPath
        return self
    }
}
