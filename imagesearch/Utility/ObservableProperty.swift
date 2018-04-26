//
//  ObservableProperty.swift
//  imagesearch
//
//  Created by ilia1395 on 26/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import Foundation

protocol Observable {
    associatedtype Value

    var value: Value { get }

    func observe(_ handler: @escaping (Value) -> Void)
}

class ObservableProperty<Value>: Observable {
    typealias ObserverHandler = (Value) -> Void

    // MARK: - Properties

    private var observerHandler: ObserverHandler?

    var value: Value {
        didSet { observerHandler?(value) }
    }

    // MARK: - Lifecycle

    init(_ value: Value) {
        self.value = value
    }

    func observe(_ handler: @escaping ObserverHandler) {
        observerHandler = handler
    }
}
