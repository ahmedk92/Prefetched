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

class ViewController: UIViewController {
    private let queue = DispatchQueue(label: "dataQueue")
    
    private lazy var data: [Prefetched<String>] = (0..<1000).map({ _ in
        return Prefetched(queue: queue, generator: { () -> String in
            Thread.sleep(forTimeInterval: 0.01) // Simulate some work e.g. quick db access, etc...
            return randomText(length: Int.random(in: 32...256))
        })
    })
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

