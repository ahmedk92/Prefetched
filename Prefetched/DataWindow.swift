//
//  DataWindow.swift
//  Prefetched
//
//  Created by Ahmed Khalaf on 6/18/19.
//  Copyright © 2019 Ahmed Khalaf. All rights reserved.
//

import Foundation

class DataWindow<Element: ElementType> {
    // MARK: - Cache
    private typealias CacheType = NSCache<ObjectWrapper<Element.IdType>, ObjectWrapper<Element>>
    private let cache = CacheType()
    
    // MARK: - Data Fetcher
    typealias DataFetcher = ([Element.IdType]) -> [Element]
    private let dataFetcher: DataFetcher
    
    // MARK: - Init
    init(ids: [Element.IdType], windowSize: Int = 10, dataFetcher: @escaping DataFetcher, elementsReadyBlock: ElementsReadyBlock? = nil) {
        self.ids = ids
        self.windowSize = windowSize
        self.dataFetcher = dataFetcher
        self.elementsReadyBlock = elementsReadyBlock
    }
    
    // MARK: - Accessors
    subscript(index: Int) -> Element? {
        get {
            let element = cache.object(forKey: ObjectWrapper(ids[index])) as? Element
            if element == nil {
                prefetch(index: index)
            }
            return element
        }
        
        set {
            if let newValue = newValue {
                cache.setObject(ObjectWrapper(newValue), forKey: ObjectWrapper(ids[index]))
            } else {
                cache.removeObject(forKey: ObjectWrapper(ids[index]))
            }
        }
    }
    
    // MARK: - Delegates
    typealias ElementsReadyBlock = ([Int]) -> Void
    private let elementsReadyBlock: ElementsReadyBlock?
    
    // MARK: - Paging
    private var page = 0
    private let ids: [Element.IdType]
    private let windowSize: Int
    private var isPrefetching = Atomic(false)
    private lazy var queue = DispatchQueue(label: "DataWindow.\(ObjectIdentifier(self))")
    func prefetch(index: Int) {
        guard !isPrefetching.value else { return }
        isPrefetching.value = true
        page = index / windowSize
        
        queue.async { [weak self, page] in
            guard let self = self else { return }
            let indexRange = (page * self.windowSize)...(page * self.windowSize + self.windowSize)
            let ids = Array(self.ids[indexRange])
            let elements = self.dataFetcher(ids)
            
            for (index, element) in elements.enumerated() {
                self[index] = element
            }
            
            self.elementsReadyBlock?(Array(indexRange))
        }
    }
}

protocol ElementType {
    associatedtype IdType: Hashable
    var id: IdType { get }
}

fileprivate class ObjectWrapper<T> {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}
