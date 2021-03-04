//
//  NSLock+Hub.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/4.
//

import Foundation

extension NSLock: Compatible {}
extension CompatibleWrapper where Base: NSLock {
    
    /// safe lock
    /// - Parameter block: ()->Void
    internal func safe(_ block: () -> Void) {
        base.lock()
        block()
        base.unlock()
    }
    
    /// safe lock
    /// - Parameter block: () -> T
    /// - Returns: T
    internal func safe<T>(_ block: () -> T) -> T {
        base.lock()
        let value = block()
        base.unlock()
        return value
    }
}
