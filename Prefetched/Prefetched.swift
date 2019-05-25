//
//  Prefetched.swift
//  Prefetched
//
//  Created by Ahmed Khalaf on 5/24/19.
//  Copyright © 2019 Ahmed Khalaf. All rights reserved.
//

import Foundation

class Prefetched<T> {
    /// This has to be a serial queue.
    let queue: DispatchQueue
    let valueMaker: () -> T
    var status = Atomic(Status.fresh)
    private var _value: T?
    
    init(queue: DispatchQueue, valueMaker: @escaping () -> T) {
        self.queue = queue
        self.valueMaker = valueMaker
    }
    
    var value: T {
        switch status.value {
        case .fresh:
            print("Value requested when fresh")
            prefetch()
            queue.sync {}
            return self.value
        case .prefetching:
            print("Value requested when prefetching")
            queue.sync {}
            return self.value
        case .prefetched(let value):
            return value
        }
    }
    
    func prefetch() {
        guard case Status.fresh = status.value else { return }
        
        status.value = .prefetching
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let value = self.valueMaker()
            self._value = value
            self.status.value = .prefetched(value)
        }
    }
}

extension Prefetched {
    enum Status {
        case fresh, prefetching, prefetched(T)
    }
}

struct Atomic<T> {
    private var _value: T
    private let queue = DispatchQueue(label: "atomic")
    
    init(_ value: T) {
        _value = value
    }
    
    var value: T {
        get {
            return queue.sync { return _value }
        }
        
        set {
            queue.sync { _value = newValue }
        }
    }
}
