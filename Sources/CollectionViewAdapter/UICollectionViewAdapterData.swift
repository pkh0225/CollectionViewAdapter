//
//  UICollectionViewAdapterData.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 2023/08/17.
//  Copyright © 2023 pkh. All rights reserved.
//

import UIKit

// MARK: - UICollectionViewAdapterData
class UICollectionViewAdapterData {
    class CellInfo {
        enum CellKind {
            case header
            case footer
            case cell
        }

        var kind: CellKind = .cell
        var contentObj: Any?
        var subData: [String: Any?]?
        var type: UICollectionReusableView.Type
        var sizeClosure: (() -> CGSize)?
        var actionClosure: ActionClosure?

        init(kind: CellKind = .cell, contentObj: Any?, subData: [String: Any?]? = nil, sizeClosure: (() -> CGSize)? = nil, cellType: UICollectionReusableView.Type, actionClosure: ActionClosure? = nil) {
            self.kind = kind
            self.contentObj = contentObj
            self.subData = subData
            self.sizeClosure = sizeClosure
            self.type = cellType
            self.actionClosure = actionClosure
        }
    }

    class SectionInfo {
        var header: CellInfo? {
            didSet {
                header?.kind = .header
            }
        }
        var footer: CellInfo? {
            didSet {
                footer?.kind = .footer
            }
        }
        var cells = [CellInfo]()

        var backgroundColor: UIColor? // UIColor.random
        var sectionInset: UIEdgeInsets = SectionInsetNotSupport {
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
        var minimumLineSpacing: CGFloat = -9999
        var minimumInteritemSpacing: CGFloat = -9999
        var dataType: String = ""
        var indexPath = IndexPath(row: 0, section: 0)
    }

    var sectionList = [SectionInfo]()
}
