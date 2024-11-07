//
//  UIviewExtension.swift
//  CollectionViewAdapter
//
//  Created by 박길호(파트너) - 서비스개발담당App개발팀 on 10/24/24.
//  Copyright © 2024 pkh. All rights reserved.
//
import UIKit

extension UIView {
    private struct ViewDidAppearCADisplayLinkKeys {
        static var viewDidAppearIsVisible: UInt8 = 0
        static var viewDidAppear: UInt8 = 0
    }

    public var viewDidAppearIsVisible: Bool? {
        get {
            return objc_getAssociatedObject(self, &ViewDidAppearCADisplayLinkKeys.viewDidAppearIsVisible) as? Bool
        }
        set {
            objc_setAssociatedObject( self, &ViewDidAppearCADisplayLinkKeys.viewDidAppearIsVisible, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var viewDidAppear: ((_ value: Bool) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &ViewDidAppearCADisplayLinkKeys.viewDidAppear) as? ((_ value: Bool) -> Void)
        }
        set {
            objc_setAssociatedObject( self, &ViewDidAppearCADisplayLinkKeys.viewDidAppear, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            DispatchQueue.main.async {
                if newValue != nil {
                    if ViewDidAppearCADisplayLink.shared.views.contains(self) == false {
                        ViewDidAppearCADisplayLink.shared.views.append(self)
                    }
                }
                else {
                    if self.viewDidAppear == nil {
                        if let index = ViewDidAppearCADisplayLink.shared.views.firstIndex(of: self) {
                            ViewDidAppearCADisplayLink.shared.views.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    var windowFrame: CGRect {
        return superview?.convert(frame, to: nil) ?? .zero
    }

    var isVisible: Bool {
        guard let window = self.window else { return false }

        var currentView: UIView = self
        while let superview = currentView.superview {
            if window.bounds.intersects(currentView.windowFrame) == false {
                return false
            }

            if (superview.bounds).intersects(currentView.frame) == false {
                return false
            }

            if currentView.isHidden {
                return false
            }

            if currentView.alpha == 0 {
                return false
            }

            currentView = superview
        }

        return true
    }

    func addSubViewAutoLayout(_ subview: UIView, edgeInsets: UIEdgeInsets = .zero) {
        self.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false

        let views: Dictionary = ["subview": subview]
        let edgeInsetsDic: Dictionary = ["top": (edgeInsets.top), "left": (edgeInsets.left), "bottom": (edgeInsets.bottom), "right": (edgeInsets.right)]

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[subview]-(right)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: edgeInsetsDic,
                                                           views: views))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[subview]-(bottom)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: edgeInsetsDic,
                                                           views: views))
    }

    func getMargin() -> UIEdgeInsets {
        let top = self.findConstraint(attribute: .top)?.constant ?? 0
        let left = self.findConstraint(attribute: .leading)?.constant ?? self.findConstraint(attribute: .left)?.constant ?? 0
        let bottom = self.findConstraint(attribute: .bottom)?.constant ?? self.findConstraint(attribute: .right)?.constant ?? 0
        let right = self.findConstraint(attribute: .trailing)?.constant ?? 0

        // UIEdgeInsets로 반환
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }

    // 특정 뷰에서 주어진 Attribute에 해당하는 제약 조건을 찾는 함수
    func findConstraint(attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        guard let superview else { return nil }
        // superview의 제약 조건을 탐색
        for constraint in superview.constraints {
            // firstItem이 해당 뷰이고, 해당 제약 조건 attribute와 일치하는 경우
            if let firstItem = constraint.firstItem as? UIView, firstItem == self, constraint.firstAttribute == attribute {
                return constraint
            }
            // secondItem이 해당 뷰인 경우도 탐색
            if let secondItem = constraint.secondItem as? UIView, secondItem == self, constraint.secondAttribute == attribute {
                return constraint
            }
        }

        // 뷰 자체에 적용된 제약 조건도 탐색 (width, height 등)
//        for constraint in self.constraints {
//            if constraint.firstAttribute == attribute {
//                return constraint
//            }
//        }

        return nil // 해당 attribute에 대한 제약 조건을 찾지 못한 경우
    }
}

// MARK: -
private class ViewDidAppearCADisplayLink {
    static let shared = ViewDidAppearCADisplayLink()
    private init() {
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationDidEnterBackgroundNotification),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationDidBecomeActiveNotification),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
    }

    var displayLink: CADisplayLink?
    var views: [UIView] = [UIView]() {
        didSet {
            DispatchQueue.main.async {
                if self.views.count > 0 {
                    if self.displayLink == nil {
                        self.start()
                    }
                }
                else {
                    self.stop()
                }
            }
        }
    }

    @objc func applicationDidEnterBackgroundNotification() {
        stop()
        DispatchQueue.main.async {
            for view: UIView in self.views {
                self.setViewVisible(view: view, isVisible: false)
            }
        }
    }

    @objc func applicationDidBecomeActiveNotification() {
        DispatchQueue.main.async {
            for view: UIView in self.views {
                self.setViewVisible(view: view, isVisible: view.isVisible)
            }
        }
        start()
    }

    @objc private func onViewDidAppear() {
        guard self.views.count > 0 else {
            stop()
            return
        }

        for view: UIView in self.views {
            autoreleasepool {
                self.setViewVisible(view: view, isVisible: view.isVisible)
                let windowRect: CGRect = view.superview?.convert(view.frame, to: nil) ?? .zero
                if windowRect == .zero {
                    view.viewDidAppear?(false)
                    view.viewDidAppear = nil
                    if let index = self.views.firstIndex(of: view) {
                        self.views.remove(at: index)
                    }
                }
            }
        }
    }

    func setViewVisible(view: UIView, isVisible: Bool) {
        if view.viewDidAppearIsVisible != isVisible {
            view.viewDidAppearIsVisible = isVisible
            view.viewDidAppear?(isVisible)
        }
    }

    func start() {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(onViewDidAppear))
        displayLink?.add(to: .main, forMode: .common)
        if #available(iOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = 5
        }
        else {
            displayLink?.frameInterval = 5
        }
    }

    func stop() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

}
