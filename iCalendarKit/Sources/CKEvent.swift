//
//  CKEvent.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension CKEvent {
    
    /// AttributeKey
    public enum AttributeKey: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case DTSTAMP, UID
        /**
         The following is REQUIRED if the component appears in an iCalendar object that doesn't specify the "METHOD" property; otherwise, it is OPTIONAL; in any case, it MUST NOT occur more than once.
         */
        case DTSTART
        /**
         The following is OPTIONAL, but SHOULD NOT occur more than once.
         */
        case RRULE
        /**
         Either 'dtend' or 'duration' MAY appear in a 'eventprop', but 'dtend' and 'duration' MUST NOT occur in the same 'eventprop'.
         */
        case DTEND, DURATION
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CLASS, CREATED, DESCRIPTION, GEO, LASTMOD = "LAST-MOD", LOCATION, PRIORITY, SEQ, STATUS, SUMMARY, TRANSP, URL, RECURID, ORGANIZER
        /**
         The following are OPTIONAL,  and MAY occur more than once.
         */
        case ATTACH, ATTENDEE, CATEGORIES, COMMENT, CONTACT, EXDATE, RSTATUS, RELATED, RESOURCES, RDATE
    }
}

extension CKEvent.AttributeKey: CKRegularable {
    
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


/// CKEvent
public class CKEvent {
    
    // MARK: - 公开属性
    
    /// [CKAttribute]
    public private(set) var attributes: [CKAttribute] = []
    /// [CKAlarm]
    public private(set) var alarms: [CKAlarm] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: Error
    public init(from contents: String) throws {
        var contents = contents
        // 1. get alarms from string of contents
        alarms = try CKAlarm.alarms(from: &contents)
        // 2. get attributes from string of contents
        attributes = try CKAttribute.attributes(from: &contents, withKeys: AttributeKey.allCases)
    }
    
    /// get events for contents string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKEvent]
    public static func events(from contents: inout String) throws -> [CKEvent] {
        let pattern: String = #"BEGIN:VEVENT([\s\S]*?)\END:VEVENT"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var events: [CKEvent] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKEvent.init(from: content)
            events.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return events
    }
}

extension CKEvent {
    
    /// add alarm
    /// - Parameter alarms: [CKAlarm]
    @discardableResult
    public func add(alarms: [CKAlarm]) -> Self {
        return lock.hub.safe {
            self.alarms.append(contentsOf: alarms)
            return self
        }
    }
    
    /// add alarm
    /// - Parameter alarm: CKAlarm
    @discardableResult
    public func add(alarm: CKAlarm) -> Self {
        return add(alarms: [alarm])
    }
    
    /// set alarms
    /// - Parameter alarms: [CKAlarm]
    @discardableResult
    public func set(alarms: [CKAlarm]) -> Self {
        return lock.hub.safe {
            self.alarms = alarms
            return self
        }
    }
    
    /// set alarm
    /// - Parameter alarm: CKAlarm
    @discardableResult
    public func set(alarm: CKAlarm) -> Self {
        return set(alarms: [alarm])
    }
    
    /// remove all alarms
    /// - Returns: description
    @discardableResult
    public func removeAlarms() -> Self {
        return lock.hub.safe {
            self.alarms.removeAll()
            return self
        }
    }
}

// MARK: - 属性相关
extension CKEvent {
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
extension CKEvent: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attributes
        for attr in attributes {
            contents += attr.text
        }
        // alarms
        for alarm in alarms {
            contents += alarm.text
        }
        
        return "BEGIN:VEVENT\r\n" + contents + "END:VEVENT\r\n"
    }
    
    
}
