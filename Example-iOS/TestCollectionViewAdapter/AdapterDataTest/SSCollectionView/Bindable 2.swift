//
//  Bindable.swift
//  SSCollectionViewHelper
//
//  Created by SunSoo Jeon on 12/15/24.
//  Copyright © 2024 전선수. All rights reserved.
//

import UIKit

public protocol Bindable {
    associatedtype DataType
    associatedtype View: Configurable

    var data: DataType? { get set }
    var viewType: View.Type { get }
}

extension Bindable {
    func eraseToAnyBindable() -> AnyBindable<Self.DataType, Self.View> {
        return AnyBindable(self)
    }
}

final class AnyBindable<DataType, View: Configurable>: Bindable {
    var data: DataType? {
        get {
            _wrapper.data
        }
        set {
            _wrapper.data = newValue
        }
    }
    var viewType: View.Type { _wrapper.viewType }

    private let _wrapper: AnyBindableBase<DataType, View>

    init<T: Bindable>(_ obj: T) where T.DataType == DataType, T.View == View {
        self._wrapper = Wrapper(obj)
    }

    private class Wrapper<T: Bindable>: AnyBindableBase<T.DataType, T.View> {
        override var data: T.DataType? {
            get {
                _concrete.data
            }
            set {
                _concrete.data = newValue
            }
        }
        override var viewType: T.View.Type { _concrete.viewType }

        private var _concrete: T

        init(_ concreteBindableObject: T) {
            self._concrete = concreteBindableObject
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

fileprivate class AnyBindableBase<DataType, View: Configurable>: Bindable {
    var data: DataType?
    var viewType: View.Type { fatalError("Not implemented") }
}
