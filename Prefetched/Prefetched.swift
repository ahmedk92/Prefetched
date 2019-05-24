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
    let generator: () -> T
    var status = Status.fresh
    private var _value: T?
    
    init(queue: DispatchQueue, generator: @escaping () -> T) {
        self.queue = queue
        self.generator = generator
    }
    
    var value: T {
        switch status {
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
        guard case Status.fresh = status else { return }
        
        status = .prefetching
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let value = self.generator()
            self._value = value
            self.status = .prefetched(value)
        }
    }
}

extension Prefetched {
    enum Status {
        case fresh, prefetching, prefetched(T)
    }
}
