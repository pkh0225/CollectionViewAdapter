//
//  UICollectionViewAdapterData.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

// MARK: - UICollectionViewAdapterData
public class UICollectionViewAdapterData {
    public class CellInfo {
        public enum CellKind {
            case header
            case footer
            case cell
        }

        public var kind: CellKind = .cell
        public var contentObj: Any?
        public var subData: [String: Any?]?
        public var type: UICollectionReusableView.Type
        public var sizeClosure: (() -> CGSize)?
        public var actionClosure: ActionClosure?

        public init(kind: CellKind = .cell, contentObj: Any?, subData: [String: Any?]? = nil, sizeClosure: (() -> CGSize)? = nil, cellType: UICollectionReusableView.Type, actionClosure: ActionClosure? = nil) {
            self.kind = kind
            self.contentObj = contentObj
            self.subData = subData
            self.sizeClosure = sizeClosure
            self.type = cellType
            self.actionClosure = actionClosure
        }
    }

    public class SectionInfo {
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

        public var backgroundColor: UIColor? // UIColor.random
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

        public init() {

        }
    }

    public var sectionList = [SectionInfo]()


    public init() {

    }
}
