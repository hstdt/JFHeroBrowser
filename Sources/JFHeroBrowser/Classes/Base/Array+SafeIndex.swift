//
//  Array+SafeIndex.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/9/25.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
