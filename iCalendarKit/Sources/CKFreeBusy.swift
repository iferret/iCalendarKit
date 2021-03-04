//
//  CKFreeBusy.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension CKFreeBusy {
    
    /// AttributeKey
    public enum AttributeKey: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case DTSTAMP, UID
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CONTACT, DTSTART, DTEND, ORGANIZER, URL
        /**
         The following are OPTIONAL, and MAY occur more than once.
         */
        case ATTENDEE, COMMENT, FREEBUSY, RSTATUS
    }
    
}

extension CKFreeBusy.AttributeKey: CKRegularable {
    /// mutable
    internal var mutable: Bool {
        switch self {
        case .ATTENDEE, .COMMENT, .FREEBUSY, .RSTATUS:
            return true
        default: return false
        }
    }
    
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKFreeBusy
public class CKFreeBusy {
    
    
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
        attributes = try CKAttribute.attributes(from: &contents, withKeys: AttributeKey.allCases)
    }
    
    /// get freebusys from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKJournal]
    public static func freebusys(from contents: inout String) throws -> [CKFreeBusy] {
        let pattern: String = #"BEGIN:VFREEBUSY([\s\S]*?)\END:VFREEBUSY"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var freebusys: [CKFreeBusy] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKFreeBusy.init(from: content)
            freebusys.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return freebusys
    }
}

// MARK: - 属性相关
extension CKFreeBusy {
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
extension CKFreeBusy: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attributes
        for attr in attributes {
            contents += attr.text
        }
        return "BEGIN:VFREEBUSY\r\n" + contents + "END:VFREEBUSY\r\n"
    }
    
}
