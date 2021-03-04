//
//  CKTodo.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension CKTodo {
    
    /// AttributeKey
    public enum AttributeKey: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case DTSTAMP, UID
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CLASS, COMPLETED, CREATED, DESCRIPTION,DTSTART, GEO, LASTMOD = "LAST-MOD", LOCATION, ORGANIZER, PERCENT, PRIORITY, RECURID, SEQ, STATUS, SUMMARY, URL
        /**
         The following is OPTIONAL, but SHOULD NOT occur more than once.
         */
        case RRULE
        /**
         Either 'due' or 'duration' MAY appear in a 'todoprop', but 'due' and 'duration' MUST NOT occur in the same 'todoprop'. If 'duration' appear in a 'todoprop', then 'dtstart' MUST also appear in  the same 'todoprop'.
         */
        case DUE, DURATION
        /**
         The following are OPTIONAL, and MAY occur more than once.
         */
        case ATTACH, ATTENDEE, CATEGORIES, COMMENT, CONTACT, EXDATE, RSTATUS, RELATED, RESOURCES, RDATE
    }
    
}

extension CKTodo.AttributeKey {
    /// mutable
    internal var mutable: Bool {
        switch self {
        case .ATTACH, .ATTENDEE, .CATEGORIES, .COMMENT, .CONTACT, .EXDATE, .RSTATUS, .RELATED, .RESOURCES, .RDATE:
            return true
        default: return false
        }
    }
    
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKTodo
public class CKTodo {
    
    
    // MARK: - 公开属性
    
    /// [CKAttribute]
    public private(set) var attributes: [CKAttribute] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// create alarm from string
    /// - Parameter contents: String
    /// - Throws: throws
    public init(from contents: String) throws {
        var contents = contents
        // 1. get attrs
        attributes = try attributes(from: &contents)
    }
    
}

extension CKTodo {
    
    /// get attrs from ics string
    /// - Parameter contents: String
    /// - Throws: String
    /// - Returns: [CKAttribute]
    private func attributes(from contents: inout String) throws -> [CKAttribute] {
        var attrs: [CKAttribute] = []
        for key in AttributeKey.allCases {
            let reg = try NSRegularExpression.init(pattern: key.pattern, options: [.caseInsensitive])
            if key.mutable == true {
                let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
                guard results.isEmpty == false else { continue }
                for result in results {
                    let content = contents.hub.substring(with: result.range)
                    let attr = try CKAttribute.init(from: content)
                    attrs.append(attr)
                    contents = contents.hub.remove(with: result.range)
                }
            } else {
                guard let result = reg.firstMatch(in: contents, options: [], range: contents.hub.range) else { continue }
                let content = contents.hub.substring(with: result.range)
                let attr = try CKAttribute.init(from: content)
                attrs.append(attr)
                contents = contents.hub.remove(with: result.range)
            }
        }
        // 获取自定义
        // X-PROP / IANA-PROP
        let pattern: String = #"(\r\n)(X-|IANA-)([\s\S]*?)(\r\n)"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let attr = try CKAttribute.init(from: content)
            attrs.append(attr)
            contents = contents.hub.remove(with: result.range)
        }
        return attrs
    }
}

extension CKTodo {
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

extension CKTodo: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attributes
        for attr in attributes {
            contents += attr.text
        }
        return "BEGIN:VTODO\r\n" + contents + "END:VTODO\r\n"
    }
    
}
