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
    private lazy var cache = WindowCache<Element.IdType, Element>(pagesToRetain: 3)
    
    // MARK: - Data Fetcher
    typealias DataFetcher = ([Element.IdType]) -> [Element]
    private let dataFetcher: DataFetcher
    
    // MARK: - Init
    init(ids: [Element.IdType], windowSize: Int = 20, dataFetcher: @escaping DataFetcher, elementsReadyBlock: ElementsReadyBlock?) {
        self.ids = ids
        self.windowSize = windowSize
        self.dataFetcher = dataFetcher
        self.elementsReadyBlock = elementsReadyBlock
    }
    
    // MARK: - Accessors
    subscript(index: Int) -> Element? {
        get {
            let element = cache[ids[index]]
            if element == nil {
                prefetch(index: index)
            }
            return element
        }
        
        set {
            cache[ids[index], page: page(forIndex: index)] = newValue
        }
    }
    
    subscript(index: Int, block block: Bool) -> Element? {
        let element = cache[ids[index]]
        if element == nil {
            prefetch(index: index)
        }
        
        if block {
            queue.sync {}
        }
        return element
    }
    
    // MARK: - Delegates
    typealias ElementsReadyBlock = ([Int]) -> Void
    private let elementsReadyBlock: ElementsReadyBlock?
    
    // MARK: - Paging
    private var page = 0
    let ids: [Element.IdType]
    private let windowSize: Int
    private var isPrefetching = Atomic(false)
    private lazy var queue = DispatchQueue(label: "DataWindow.\(ObjectIdentifier(self))")
    private func page(forIndex index: Int) -> Int {
        return index / windowSize
    }
    func prefetch(index: Int) {
        guard
            !isPrefetching.value,
            cache[ids[index]] == nil
            else { return }
        isPrefetching.value = true
        page = page(forIndex: index)
        
        queue.async { [weak self, page] in
            guard let self = self else { return }
            let startIndex = page * self.windowSize
            let indexRange = startIndex..<min(self.ids.count, startIndex + self.windowSize)
            let ids = Array(self.ids[indexRange])
            let elements = self.dataFetcher(ids)
            
            for (index, element) in elements.enumerated() {
                self[startIndex + index] = element
            }
            
            self.elementsReadyBlock?(Array(indexRange))
            
            self.isPrefetching.value = false
        }
    }
}

protocol ElementType {
    associatedtype IdType: Hashable
    var id: IdType { get }
}

fileprivate struct WindowCache<Key: Hashable, Value> {
    
    // MARK: - Init
    init(pagesToRetain: Int = 5) {
        self.pagesToRetain = pagesToRetain
    }
    
    // MARK: - Storage
    private var dict = Atomic([Key : Item]())
    private struct Item {
        let value: Value
        let page: Int
    }
    
    // MARK: - Purging
    private let pagesToRetain: Int
    private var _lastReferencePage = 0
    private func shouldPurge(newPage: Int, oldPage: Int) -> Bool {
        return abs(newPage - oldPage) > pagesToRetain
    }
    private var lastReferencePage: Int {
        set {
            guard shouldPurge(newPage: newValue, oldPage: lastReferencePage) else { return }
            purge(for: newValue)
            _lastReferencePage = newValue
        }
        
        get {
            return _lastReferencePage
        }
    }
    private mutating func purge(for page: Int) {
        dict.mutate { [shouldPurge] (dict) in
            for (key, value) in dict {
                if shouldPurge(page, value.page) {
                    dict.removeValue(forKey: key)
                }
            }
        }
    }
    
    // MARK: - Accessors
    subscript(key: Key) -> Value? {
        return dict.value[key]?.value
    }
    
    subscript(key: Key, page page: Int) -> Value? {
        get {
            return dict.value[key]?.value
        }
        set {
            if let newValue = newValue {
                dict.value[key] = Item(value: newValue, page: page)
                lastReferencePage = page
            } else {
                dict.value.removeValue(forKey: key)
            }
            
            print("\(dict.value.count) items in cache.")
        }
    }
}
