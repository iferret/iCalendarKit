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

extension CKTimezone.AttributeKey {
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
        // 1. get attrs
        attributes = try attributes(from: contents)
        // 2. get standards
        standards = try standards(from: contents)
        // 3. get daylight
        daylights = try daylights(from: contents)
    }
    
    
}

extension CKTimezone {
    
    /// get attrs from ics string
    /// - Parameter contents: String
    /// - Throws: String
    /// - Returns: [CKAttribute]
    private func attributes(from contents: String) throws -> [CKAttribute] {
        var attrs: [CKAttribute] = []
        for key in AttributeKey.allCases {
            let reg = try NSRegularExpression.init(pattern: key.pattern, options: [.caseInsensitive])
            if key.mutable == true {
                let results = reg.matches(in: contents, options: [], range: contents.hub.range)
                guard results.isEmpty == true else { continue }
                for result in results {
                    let content = (contents as NSString).substring(with: result.range)
                    let attr = try CKAttribute.init(from: content)
                    attrs.append(attr)
                }
            } else {
                guard let result = reg.firstMatch(in: contents, options: [], range: contents.hub.range) else { continue }
                let content = (contents as NSString).substring(with: result.range)
                let attr = try CKAttribute.init(from: content)
                attrs.append(attr)
            }
        }
        // 获取自定义
        // X-PROP / IANA-PROP
        let pattern: String = #"(\r\n)(X-|IANA-)([\s\S]*?)(\r\n)"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range)
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let attr = try CKAttribute.init(from: content)
            attrs.append(attr)
        }
        
        return attrs
    }
    
    /// get standards from ics string
    /// - Parameter contents: String
    /// - Throws: String
    /// - Returns: [CKAttribute]
    private func standards(from contents: String) throws -> [CKStandard] {
        let pattern: String = #"BEGIN:STANDARD([\s\S]*?)\END:STANDARD"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range)
        let standards = try results.map({ (result) -> CKStandard in
            let content = (contents as NSString).substring(with: result.range)
            return try CKStandard.init(from: content)
        })
        return standards
    }
    
    /// get daylights from ics string
    /// - Parameter contents: String
    /// - Throws: String
    /// - Returns: [CKAttribute]
    private func daylights(from contents: String) throws -> [CKDaylight] {
        let pattern: String = #"BEGIN:STANDARD([\s\S]*?)\END:STANDARD"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range)
        let daylights = try results.map({ (result) -> CKDaylight in
            let content = (contents as NSString).substring(with: result.range)
            return try CKDaylight.init(from: content)
        })
        return daylights
    }
}

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
    public func set(_ attrs: [CKAttribute], for key: AttributeKey) {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = key.rawValue.uppercased()
        }
        
        lock.hub.safe {
            if let index = attributes.firstIndex(where: { $0.name.uppercased() == key.rawValue.uppercased() }) {
                if key.mutable == true {
                    attributes.removeAll(where: { $0.name.uppercased() == key.rawValue.uppercased() })
                    attributes.insert(contentsOf: attrs, at: index)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes[index] = attr
                }
            } else {
                if key.mutable == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes.append(attr)
                }
            }
        }
    }
    
    /// set attr for key
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - key: AttributeKey
    public func set(_ attr: CKAttribute, for key: AttributeKey) {
        set([attr], for: key)
    }
    
    /// set attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - name: string
    public func set(_ attrs: [CKAttribute], for name: String) {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = name.uppercased()
        }
        
        lock.hub.safe {
            if let index = attributes.firstIndex(where: { $0.name.uppercased() == name.uppercased() }) {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.removeAll(where: { $0.name.uppercased() == name.uppercased() })
                    attributes.insert(contentsOf: attrs, at: index)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes.append(attr)
                }
            }
        }
    }
    
    /// set attr for name
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - name: String
    public func set(_ attr: CKAttribute, for name: String) {
        set([attr], for: name)
    }
    
    /// add attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - key: AttributeKey
    public func add(_ attrs: [CKAttribute], for key: AttributeKey) {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = key.rawValue.uppercased()
        }
        
        lock.hub.safe {
            if let index = attributes.lastIndex(where: { $0.name.uppercased() == key.rawValue.uppercased() }) {
                if key.mutable == true {
                    attributes.insert(contentsOf: attrs, at: index + 1)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes[index] = attr
                }
            } else {
                if key.mutable == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes.append(attr)
                }
            }
        }
    }
    
    /// add attr for key
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - key: AttributeKey
    public func add(_ attr: CKAttribute, for key: AttributeKey) {
        add([attr], for: key)
    }
    
    /// add attrs
    /// - Parameters:
    ///   - attrs: [CKAttribute]
    ///   - name: String
    public func add(_ attrs: [CKAttribute], for name: String) {
        // update name
        attrs.forEach {
            guard $0.name.isEmpty == true else { return }
            $0.name = name.uppercased()
        }
        
        lock.hub.safe {
            if let index = attributes.lastIndex(where: { $0.name.uppercased() == name.uppercased() }) {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.insert(contentsOf: attrs, at: index + 1)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return }
                    attributes.append(attr)
                }
            }
        }
    }
    
    /// add attr for name
    /// - Parameters:
    ///   - attr: CKAttribute
    ///   - name: String
    public func add(_ attr: CKAttribute, for name: String) {
        add([attr], for: name)
    }
    
    /// remove all attrs for key
    /// - Parameter key: AttributeKey
    public func removeAll(for key: AttributeKey) {
        attributes.removeAll(where: { $0.name.uppercased() == key.rawValue.uppercased() })
    }
    
    /// remove all attrs for key
    /// - Parameter key: String
    public func removeAll(for name: String) {
        attributes.removeAll(where: { $0.name.uppercased() == name.uppercased() })
    }
}

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
