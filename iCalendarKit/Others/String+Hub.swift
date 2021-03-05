//
//  String+Hub.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation
import CommonCrypto

extension String: CompatibleValue {}
extension CompatibleWrapper where Base == String {
    
    /// NSRange
    internal var range: NSRange {
        return .init(base.startIndex..., in: base)
    }
    /// Double
    internal var doubleValue: Double {
        return (base as NSString).doubleValue
    }
    /// Float
    internal var floatValue: Float {
        return (base as NSString).floatValue
    }
    /// Int32
    internal var intValue: Int32 {
        return (base as NSString).intValue
    }
    /// Int
    internal var integerValue: Int {
        return (base as NSString).integerValue
    }
    /// Int64
    internal var longLongValue: Int64 {
        return (base as NSString).longLongValue
    }
    /// Bool
    internal var boolValue: Bool {
        return (base as NSString).boolValue
    }
    
    /// md5
    internal var md5:String {
        let utf8 = base.cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02X", $1) }
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
            guard base.hasSuffix(suffix) == true else { continue }
            return true
        }
        return false
    }
}

extension CompatibleWrapper where Base == String {
    
    /// convert to timezone
    /// - Returns: TimeZone
    internal func toTimeZone() -> TimeZone {
        if let tz = TimeZone.init(identifier: base) {
            return tz
        } else if base.localizedCaseInsensitiveContains("China Standard Time") == true {
            guard let tz = TimeZone.init(identifier: "Asia/Shanghai") else { return .current }
            return tz
        } else {
            return .current
        }
    }
}
