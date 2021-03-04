//
//  CKCalendar.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


extension CKCalendar {
    /// AttributeKey
    public enum AttributeKey: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case PRODID, VERSION
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CALSCALE, METHOD
    }
}

extension CKCalendar.AttributeKey {
    
    /// is mutable
    internal var mutable: Bool {
        false
    }
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKCalendar
public class CKCalendar {
    
    // MARK: - 公开属性
    
    /// [CKAttribute]
    public private(set) var attributes: [CKAttribute] = []
    /// [CKTimezone]
    public private(set) var timezones: [CKTimezone] = []
    /// [CKEvent]
    public private(set) var events: [CKEvent] = []
    /// [CKTodo]
    public private(set) var todos: [CKTodo] = []
    /// [CKJournal]
    public private(set) var journals: [CKJournal] = []
    /// [CKFreeBusy]
    public private(set) var freebusys: [CKFreeBusy] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: throws
    public init(with contents: String) throws {
        var contents = contents
        // 1. 时区信息
        timezones = try timezones(from: &contents)
        // 2. 解析 VEVENT
        events = try events(from: &contents)
        // 3. todo
        todos = try todos(from: &contents)
        // 4. journal
        journals = try journals(from: &contents)
        // 5. freebusy
        freebusys = try freebusys(from: &contents)
        // 6. 解析属性
        attributes = try attributes(from: &contents)
        
        
    }
}

extension CKCalendar {
    
    /// get attributes for contents string
    /// - Parameter contents: String
    /// - Throws: Error
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
    
    /// get events for contents string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKEvent]
    private func events(from contents: inout String) throws -> [CKEvent] {
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
    
    /// get todos from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKTodo]
    private func todos(from contents: inout String) throws -> [CKTodo] {
        let pattern: String = #"BEGIN:VTODO([\s\S]*?)\END:VTODO"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var todos: [CKTodo] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKTodo.init(from: content)
            todos.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return todos
    }
    
    /// get journals from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKJournal]
    private func journals(from contents: inout String) throws -> [CKJournal] {
        let pattern: String = #"BEGIN:VJOURNAL([\s\S]*?)\END:VJOURNAL"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var journals: [CKJournal] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKJournal.init(from: content)
            journals.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return journals
    }
    
    /// get freebusys from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKJournal]
    private func freebusys(from contents: inout String) throws -> [CKFreeBusy] {
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
    
    /// get timezones from string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKJournal]
    private func timezones(from contents: inout String) throws -> [CKTimezone] {
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

extension CKCalendar {
    
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

// MARK: - CKTextable
extension CKCalendar: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attrs
        for item in attributes {
            contents += item.text
        }
        // timezones
        for item in timezones {
            contents += item.text
        }
        // events
        for item in events {
            contents += item.text
        }
        // todos
        for item in todos {
            contents += item.text
        }
        // journals
        for item in journals {
            contents += item.text
        }
        // freebusys
        for item in freebusys {
            contents += item.text
        }
        
        return "BEGIN:VCALENDAR\r\n" + contents + "END:VCALENDAR"
    }
    
    
}
