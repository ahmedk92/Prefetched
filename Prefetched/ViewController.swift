//
//  ViewController.swift
//  Prefetched
//
//  Created by Ahmed Khalaf on 5/24/19.
//  Copyright © 2019 Ahmed Khalaf. All rights reserved.
//

import UIKit

class Cell: UITableViewCell {
    @IBOutlet var label: UILabel!
}

struct MyData: ElementType {
    let id: Int
}

class ViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    
    private let dataWindow = DataWindow<MyData>(ids: [], dataFetcher: { (ids) in
        return ids.map({ MyData(id: $0) })
    })
    
    private let queue = DispatchQueue(label: "dataQueue")
    private lazy var data: [Prefetched<String>] = (0..<10000).map({ (index) in
        return Prefetched(queue: queue, valueMaker: { () -> String in
            Thread.sleep(forTimeInterval: 0.05) // Simulate some work e.g. quick db access, etc...
            return "\(index): " + randomText(length: Int.random(in: 32...256))
        })
    })
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.scrollToRow(at: IndexPath(row: 5000, section: 0), at: .top, animated: false)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell
        cell.label.text = data[indexPath.row].value
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            data[indexPath.row].prefetch()
        }
    }
}

// Credits: https://gist.github.com/skreutzberger/eac3edc7918d0251f366
func randomText(length: Int, justLowerCase: Bool = false) -> String {
    var text = ""
    for _ in 1...length {
        var decValue = 0  // ascii decimal value of a character
        var charType = 3  // default is lowercase
        if justLowerCase == false {
            // randomize the character type
            charType =  Int(arc4random_uniform(4))
        }
        switch charType {
        case 1:  // digit: random Int between 48 and 57
            decValue = Int(arc4random_uniform(10)) + 48
        case 2:  // uppercase letter
            decValue = Int(arc4random_uniform(26)) + 65
        case 3:  // lowercase letter
            decValue = Int(arc4random_uniform(26)) + 97
        default:  // space character
            decValue = 32
        }
        // get ASCII character from random decimal value
        let char = String(UnicodeScalar(decValue)!)
        text = text + char
        // remove double spaces
        text = text.replacingOccurrences(of: "  ", with: " ")
    }
    return text
}

