//
//  String+Hub.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension String: CompatibleValue {}
extension CompatibleWrapper where Base == String {
    
    /// NSRange
    internal var range: NSRange {
        return .init(base.startIndex..., in: base)
    }
    
}
extension CompatibleWrapper where Base == String {
    
    /// substring from index to end
    /// - Parameter index: Int
    /// - Returns: String
    internal func substring(from index: Int) -> String {
        return (base as NSString).substring(from: index)
    }
    
    /// substring from begin to index
    /// - Parameter index: Int
    /// - Returns: String
    internal func substring(to index: Int) -> String {
        return (base as NSString).substring(to: index)
    }
    
    /// substring with range
    /// - Parameter range: NSRange
    /// - Returns: String
    internal func substring(with range: NSRange) -> String {
        return (base as NSString).substring(with: range)
    }
    
    /// remove with range
    /// - Parameter range: NSRange
    /// - Returns: String
    internal func remove(with range: NSRange) -> String {
        let prefix = (base as NSString).substring(to: range.location)
        let suffix = (base as NSString).substring(from: range.location + range.length)
        return prefix + suffix
    }
    
    /// hasPrefix
    /// - Parameter prefixs: [String]
    /// - Returns: Bool
    internal func hasPrefix(_ prefixs: [String]) -> Bool {
        for prefix in prefixs {
            guard base.hasPrefix(prefix) == true else { continue }
            return true
        }
        return false
    }
    
    /// hasSuffix
    /// - Parameter suffixs: [String]
    /// - Returns: Bool
    internal func hasSuffix(_ suffixs: [String]) -> Bool {
        for suffix in suffixs {
            guard base.hasPrefix(suffix) == true else { continue }
            return true
        }
        return false
    }
}



