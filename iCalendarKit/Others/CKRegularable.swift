//
//  CKRegularable.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/4.
//

import Foundation

 protocol CKRegularable {
    var mutable: Bool { get }
    var pattern: String { get }
}
