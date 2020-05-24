//
//  Extensions.swift
//  GraphQLGen
//
//  Created by Manuel on 23/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import Foundation

extension Array where Element == String {
    /// Returns a collection of indexes that contain a string
    func indexes(of element: String) -> [Int] {
        return self.enumerated().filter({ $0.element.contains(element) }).map({ $0.offset })
    }
}

extension String {
    var fromSchemaCommentToFragmentComment: String {
        "#\(self.replacingOccurrences(of: "\"\"\"", with: ""))"
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}
