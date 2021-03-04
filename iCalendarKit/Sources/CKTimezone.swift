//
//  CKTimezone.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension CKTimezone {
    
    /// AttributeKey
    public enum AttributeKey: String, CaseIterable {
        /**
         'tzid' is REQUIRED, but MUST NOT occur more than once.
         */
        case TZID
        /**
         'last-mod' and 'tzurl' are OPTIONAL, but MUST NOT occur more than once.
         LAST-MOD / TZURL /
         */
        case LASTMOD = "LAST-MOD", TZURL
    }
    
}

extension CKTimezone.AttributeKey: CKRegularable {
    /// mutable
    internal var mutable: Bool {
        return false
    }
    
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKTimezone
public class CKTimezone {
    
    
    // MARK: - 公开属性
    
    /// [CKAttribute]
    public private(set) var attributes: [CKAttribute] = []
    /// [CKStandard]
    public private(set) var standards: [CKStandard] = []
    /// [CKDaylight]
    public private(set) var daylights: [CKDaylight] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// create alarm from string
    /// - Parameter contents: String
    /// - Throws: throws
    public init(from contents: String) throws {
        var contents = contents
        // 1. get standards
        standards = try CKStandard.standards(from: &contents)
        // 2. get daylight
        daylights = try CKDaylight.daylights(from: &contents)
        // 3. get attrs
        attributes = try CKAttribute.attributes(from: &contents, withKeys: AttributeKey.allCases)
    }
    
    /// get timezones from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKJournal]
    public static func timezones(from contents: inout String) throws -> [CKTimezone] {
        let pattern: String = #"BEGIN:VTIMEZONE([\s\S]*?)\END:VTIMEZONE"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var timezones: [CKTimezone] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKTimezone.init(from: content)
            timezones.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return timezones
    }
}

// MARK: - 属性相关
extension CKTimezone {
    /// attrs for key
    /// - Parameter key: AttributeKey
    /// - Returns: [CKAttribute]
    public func attributes(for key: AttributeKey) -> [CKAttribute] {
        return lock.hub.safe {
            return attributes.filter { $0.name.uppercased() == key.rawValue.uppercased() }
        }
    }
    
    /// get first attribute for key
    /// - Parameter key: AttributeKey
    /// - Returns: CKAttribute?
    public func attribute(for key: AttributeKey) -> CKAttribute? {
        return lock.hub.safe {
            return attributes(for: key).first
        }
    }
    
    /// attributes for name
    /// - Parameter name: String
    /// - Returns: [CKAttribute]
    public func attributes(for name: String) -> [CKAttribute] {
        return lock.hub.safe {
            return attributes.filter { $0.name.uppercased() == name.uppercased() }
        }
    }
    
    /// attribute for name
    /// - Parameter name: String
    /// - Returns: [CKAttribute]
    public func attribute(for name: String) -> CKAttribute? {
        return lock.hub.safe {
            return attributes(for: name).first
        }
    }
    
    /// set attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - key: AttributeKey
    @discardableResult
    public func set(_ attrs: [CKAttribute], for key: AttributeKey) -> Self {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = key.rawValue.uppercased()
        }
        return lock.hub.safe {
            if let index = attributes.firstIndex(where: { $0.name.uppercased() == key.rawValue.uppercased() }) {
                if key.mutable == true {
                    attributes.removeAll(where: { $0.name.uppercased() == key.rawValue.uppercased() })
                    attributes.insert(contentsOf: attrs, at: index)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes[index] = attr
                }
            } else {
                if key.mutable == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes.append(attr)
                }
            }
            return self
        }
    }
    
    /// set attr for key
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - key: AttributeKey
    @discardableResult
    public func set(_ attr: CKAttribute, for key: AttributeKey) -> Self {
        return set([attr], for: key)
    }
    
    /// set attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - name: string
    @discardableResult
    public func set(_ attrs: [CKAttribute], for name: String) -> Self {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = name.uppercased()
        }
        return lock.hub.safe {
            if let index = attributes.firstIndex(where: { $0.name.uppercased() == name.uppercased() }) {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.removeAll(where: { $0.name.uppercased() == name.uppercased() })
                    attributes.insert(contentsOf: attrs, at: index)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes.append(attr)
                }
            }
            return self
        }
    }
    
    /// set attr for name
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - name: String
    @discardableResult
    public func set(_ attr: CKAttribute, for name: String) -> Self {
        return set([attr], for: name)
    }
    
    /// add attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - key: AttributeKey
    @discardableResult
    public func add(_ attrs: [CKAttribute], for key: AttributeKey) -> Self {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = key.rawValue.uppercased()
        }
        return lock.hub.safe {
            if let index = attributes.lastIndex(where: { $0.name.uppercased() == key.rawValue.uppercased() }) {
                if key.mutable == true {
                    attributes.insert(contentsOf: attrs, at: index + 1)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes[index] = attr
                }
            } else {
                if key.mutable == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes.append(attr)
                }
            }
            return self
        }
    }
    
    /// add attr for key
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - key: AttributeKey
    @discardableResult
    public func add(_ attr: CKAttribute, for key: AttributeKey) -> Self {
        return add([attr], for: key)
    }
    
    /// add attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - name: String
    @discardableResult
    public func add(_ attrs: [CKAttribute], for name: String) -> Self {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = name.uppercased()
        }
        return lock.hub.safe {
            if let index = attributes.lastIndex(where: { $0.name.uppercased() == name.uppercased() }) {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.insert(contentsOf: attrs, at: index + 1)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return self }
                    attributes.append(attr)
                }
            }
            return self
        }
    }
    
    /// add attr for name
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - name: String
    @discardableResult
    public func add(_ attr: CKAttribute, for name: String) -> Self {
        return add([attr], for: name)
    }
    
    /// remove all attrs for key
    @discardableResult
    public func removeAll(for key: AttributeKey) -> Self {
        return lock.hub.safe {
            attributes.removeAll(where: { $0.name.uppercased() == key.rawValue.uppercased() })
            return self
        }
    }
    
    /// remove all attrs for key
    /// - Parameter key: String
    @discardableResult
    public func removeAll(for name: String) -> Self {
        return lock.hub.safe {
            attributes.removeAll(where: { $0.name.uppercased() == name.uppercased() })
            return self
        }
    }
}

// MARK: - CKTextable
extension CKTimezone: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attributes
        for item in attributes {
            contents += item.text
        }
        // standards
        for item in standards {
            contents += item.text
        }
        // daylights
        for item in daylights {
            contents += item.text
        }
        return "BEGIN:VTIMEZONE\r\n" + contents + "END:VTIMEZONE\r\n"
    }
    
}
