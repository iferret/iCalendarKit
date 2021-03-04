//
//  Compatible.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

/// Wrapper
struct CompatibleWrapper<Base> {
    /// Base
    internal let base: Base
    
    /// 构建
    /// - Parameter base: Base
    internal init(_ base: Base) {
        self.base = base
    }
}

/// Compatible
protocol Compatible: AnyObject {}
extension Compatible {
    /// Wrapper<Self>
    public var hub: CompatibleWrapper<Self> {
        set {}
        get { .init(self) }
    }
}

/// CompatibleValue
protocol CompatibleValue {}
extension CompatibleValue {
    /// Wrapper<Self>
    public var hub: CompatibleWrapper<Self> {
        set {}
        get { .init(self) }
    }
}

