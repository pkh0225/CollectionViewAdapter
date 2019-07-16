//
//  UICollectionViewExtension.swift
//  WiggleSDK
//
//  Created by pkh on 2017. 11. 28..
//  Copyright © 2017년 leejaejin. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    private struct AssociatedKeys {
        static var registerCellName: UInt8 = 0
    }
    
    private var registerCellNames: Set<String>? {
        get {
            if let result = objc_getAssociatedObject(self, &AssociatedKeys.registerCellName) as? Set<String> {
                return result
            }
            let result = Set<String>()
            objc_setAssociatedObject(self, &AssociatedKeys.registerCellName, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return result
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registerCellName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func isXibFileExists(_ className: String) -> Bool {
        if let path = Bundle.main.path(forResource: className, ofType: "nib") {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    public func registerDefaultCell() {
        register(UICollectionViewCell.self)
        registerHeader(UICollectionReusableView.self)
        registerFooter(UICollectionReusableView.self)
    }
    
    public func register(_ Classs: UICollectionViewCell.Type...) {
        for Class in Classs {
            guard registerCellNames?.contains(Class.className) == false else { continue }
            
            registerCellNames?.insert(Class.className)
            if isXibFileExists(Class.className) {
                registerNibCell(Class)
            }
            else {
                register(Class, forCellWithReuseIdentifier: Class.className)
            }
        }
        
    }
    
    public func registerHeader(_ Classs: UICollectionReusableView.Type...) {
        for Class in Classs {
            guard registerCellNames?.contains(Class.className) == false else { continue }
            
            if isXibFileExists(Class.className) {
                registerNibCellHeader(Class)
            }
            else {
                register(Class, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Class.className)
            }
        }
    }
    
    
    public func registerFooter(_ Classs: UICollectionReusableView.Type...) {
        for Class in Classs {
            guard registerCellNames?.contains(Class.className) == false else { continue }
            
            if isXibFileExists(Class.className) {
                registerNibCellFooter(Class)
                return
            }
            else {
                register(Class, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Class.className)
            }
        }
    }
    
    private func registerNibCell(_ Classs: UICollectionViewCell.Type...) {
        Classs.forEach { (Class) in
            register(UINib(nibName: Class.className, bundle: nil), forCellWithReuseIdentifier: Class.className)
        }
    }
    
    
    private func registerNibCellHeader(_ Classs: UICollectionReusableView.Type...) {
        Classs.forEach { (Class) in
            register(UINib(nibName: Class.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Class.className)
        }
    }
    
    
    private func registerNibCellFooter(_ Classs: UICollectionReusableView.Type...) {
        Classs.forEach { (Class) in
            register(UINib(nibName: Class.className, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Class.className)
        }
    }
    
    public func registerCustomKindReusableView(_ Class: UICollectionReusableView.Type, _ Kind: String, _ identifier: String) {
        register(Class, forSupplementaryViewOfKind: Kind, withReuseIdentifier: identifier)
    }
    
    public func dequeueReusableCell<T:UICollectionViewCell>(_ Class: T.Type, for indexPath: IndexPath) -> T {
        let cell = dequeueReusableCell(withReuseIdentifier: Class.className, for: indexPath) as! T
        cell.indexPath = indexPath
        return cell
    }
    
    public func dequeueReusableHeader<T:UICollectionReusableView>(_ Class: T.Type, for indexPath: IndexPath) -> T {
        let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Class.className, for: indexPath) as! T
        view.indexPath = indexPath
        return view
    }
    
    public func dequeueReusableFooter<T:UICollectionReusableView>(_ Class: T.Type, for indexPath: IndexPath) -> T {
        let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Class.className, for: indexPath) as! T
        view.indexPath = indexPath
        return view
    }
    
    public func dequeueDefaultSupplementaryView(ofKind kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "UICollectionReusableView", for: indexPath)
        view.indexPath = indexPath
        return view
    }
    
    public func realodSectionWithoutAnimation(_ indexPath: IndexPath) {
        self.realodSectionWithoutAnimation(indexPath.section)
    }
    
    public func realodSectionWithoutAnimation(_ section: Int) {
        UIView.setAnimationsEnabled(false)
        self.performBatchUpdates({
            self.reloadSections([section])
        }, completion: { (finished) in
            UIView.setAnimationsEnabled(true)
        })
    }
    
}


extension UICollectionReusableView {
    private struct AssociatedKeys {
        static var indexPath: UInt8 = 0
        static var iVarName: UInt8 = 0
        static var iVarValue: UInt8 = 0
    }
    var indexPath: IndexPath {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.indexPath) as! IndexPath }
        set { objc_setAssociatedObject(self, &AssociatedKeys.indexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
}

extension NSObject {

    private struct AssociatedKeys {
        static var className: UInt8 = 0
        static var iVarName: UInt8 = 0
        static var iVarValue: UInt8 = 0
    }
    
    public var tag_name: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.iVarName) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.iVarName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    public var tag_value: Any? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.iVarValue)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.iVarValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var className: String {
        if let name = objc_getAssociatedObject(self, &AssociatedKeys.className) as? String {
            return name
        }
        else {
            let name = String(describing: type(of:self))
            objc_setAssociatedObject(self, &AssociatedKeys.className, name, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return name
        }
        
        
    }
    public class var className: String {
        if let name = objc_getAssociatedObject(self, &AssociatedKeys.className) as? String {
            return name
        }
        else {
            let name = String(describing: self)
            objc_setAssociatedObject(self, &AssociatedKeys.className, name, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return name
        }
    }
}
