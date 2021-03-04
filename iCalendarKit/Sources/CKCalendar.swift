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

extension CKCalendar.AttributeKey: CKRegularable {
    
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
    
    /// [CKEvent]
    public private(set) var events: [CKEvent] = []
    /// [CKJournal]
    public private(set) var journals: [CKJournal] = []
    /// [CKTodo]
    public private(set) var todos: [CKTodo] = []
    /// [CKFreeBusy]
    public private(set) var freebusys: [CKFreeBusy] = []
    /// [CKTimezone]
    public private(set) var timezones: [CKTimezone] = []
    /// [CKAlarm]
    public private(set) var alarms: [CKAlarm] = []
    /// [CKAttribute]
    public private(set) var attributes: [CKAttribute] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: throws
    public init(with contents: String) throws {
        var contents = contents
        // 解析 VEVENT
        events = try CKEvent.events(from: &contents)
        // 时区信息
        timezones = try CKTimezone.timezones(from: &contents)
        // journal
        journals = try CKJournal.journals(from: &contents)
        // freebusy
        freebusys = try CKFreeBusy.freebusys(from: &contents)
        /// alarms
        alarms = try CKAlarm.alarms(from: &contents)
        // todo
        todos = try CKTodo.todos(from: &contents)
        // 解析属性
        attributes = try CKAttribute.attributes(from: &contents, withKeys: AttributeKey.allCases)
    }
    
    /// get CKCalendar Array
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public static func calendars(from contents: inout String) throws -> [CKCalendar] {
        let pattern: String = #"BEGIN:VCALENDAR([\s\S]*?)END:VCALENDAR"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var calendars: [CKCalendar] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let calendar = try CKCalendar.init(with: content)
            calendars.append(calendar)
            contents = contents.hub.remove(with: result.range)
        }
        return calendars
    }
}

// MARK: -  event
extension CKCalendar {
    
    /// add events
    /// - Parameter events: [CKEvent]
    @discardableResult
    public func add(events: [CKEvent]) -> Self {
        return lock.hub.safe {
            self.events.append(contentsOf: events)
            return self
        }
    }
    
    /// add event
    /// - Parameter event: CKEvent
    @discardableResult
    public func add(event: CKEvent) -> Self {
        return add(events: [event])
    }
    
    /// set events
    /// - Parameter events: [CKEvent]
    @discardableResult
    public func set(events: [CKEvent]) -> Self {
        return lock.hub.safe {
            self.events = events
            return self
        }
    }
    
    /// set event
    /// - Parameter event: CKEvent
    @discardableResult
    public func set(event: CKEvent) -> Self {
        return set(events: [event])
    }
    
    /// event for uid
    /// - Parameter UID: String
    /// - Returns: CKEvent?
    public func event(for UID: String) -> CKEvent? {
        return lock.hub.safe {
            return events.first(where:  { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all events with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeEvents(with UID: String) -> Self {
        return lock.hub.safe {
            self.events.removeAll(where: { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all events
    /// - Returns: description
    @discardableResult
    public func removeEvents() -> Self {
        return lock.hub.safe {
            self.events.removeAll()
            return self
        }
    }
}

// MARK: - timezones
extension CKCalendar {
    
    /// add timezones
    /// - Parameter timezones: [CKTimezone]
    @discardableResult
    public func add(timezones: [CKTimezone]) -> Self {
        return lock.hub.safe {
            self.timezones.append(contentsOf: timezones)
            return self
        }
    }
    
    /// add timezone
    /// - Parameter timezone: CKTimezone
    @discardableResult
    public func add(timezone: CKTimezone) -> Self {
        return add(timezones: [timezone])
    }
    
    /// set timezones
    /// - Parameter timezones: [CKTimezone]
    @discardableResult
    public func set(timezones: [CKTimezone]) -> Self {
        return lock.hub.safe {
            self.timezones = timezones
            return self
        }
    }
    
    /// set timezone
    /// - Parameter timezone: CKTimezone
    @discardableResult
    public func set(timezone: CKTimezone) -> Self {
        return set(timezones: [timezone])
    }
    
    /// timezone for uid
    /// - Parameter TZID: String
    /// - Returns: CKTimezone?
    public func timezone(for TZID: String) -> CKTimezone? {
        return lock.hub.safe {
            return timezones.first(where:  { $0.attribute(for: .TZID)?.value.uppercased() == TZID.uppercased() })
        }
    }
    
    /// remove all timezones with TZID
    /// - Parameter TZID: String
    @discardableResult
    public func removeTimezones(with TZID: String) -> Self {
        return lock.hub.safe {
            self.timezones.removeAll(where: { $0.attribute(for: .TZID)?.value.uppercased() == TZID.uppercased() })
            return self
        }
    }
    
    /// remove all Timezones
    /// - Returns: description
    @discardableResult
    public func removeTimezones() -> Self {
        return lock.hub.safe {
            self.timezones.removeAll()
            return self
        }
    }
}

// MARK: - journals
extension CKCalendar {
    
    /// add journal
    /// - Parameter journals: [CKJournal]
    @discardableResult
    public func add(journals: [CKJournal]) -> Self {
        return lock.hub.safe {
            self.journals.append(contentsOf: journals)
            return self
        }
    }
    
    /// add journal
    /// - Parameter journal: CKJournal
    @discardableResult
    public func add(journal: CKJournal) -> Self {
        return add(journals: [journal])
    }
    
    /// set journals
    /// - Parameter journals: [CKJournal]
    @discardableResult
    public func set(journals: [CKJournal]) -> Self {
        return lock.hub.safe {
            self.journals = journals
            return self
        }
    }
    
    /// set journal
    /// - Parameter journal: CKJournal
    @discardableResult
    public func set(journal: CKJournal) -> Self {
        return set(journals: [journal])
    }
    
    /// journal for uid
    /// - Parameter UID: String
    /// - Returns: CKJournal?
    public func journal(for UID: String) -> CKJournal? {
        return lock.hub.safe {
            return journals.first(where:  { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all journals with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeJournals(with UID: String) -> Self {
        return lock.hub.safe {
            self.journals.removeAll(where: { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all journals
    /// - Returns: description
    @discardableResult
    public func removeJournals() -> Self {
        return lock.hub.safe {
            self.journals.removeAll()
            return self
        }
    }
}

// MARK: - freebusys
extension CKCalendar {
    
    /// add freebusy
    /// - Parameter freebusys: [CKFreeBusy]
    @discardableResult
    public func add(freebusys: [CKFreeBusy]) -> Self {
        return lock.hub.safe {
            self.freebusys.append(contentsOf: freebusys)
            return self
        }
    }
    
    /// add freebusy
    /// - Parameter freebusy: CKFreeBusy
    @discardableResult
    public func add(freebusy: CKFreeBusy) -> Self {
        return add(freebusys: [freebusy])
    }
    
    /// set freebusys
    /// - Parameter freebusys: [CKFreeBusy]
    @discardableResult
    public func set(freebusys: [CKFreeBusy]) -> Self {
        return lock.hub.safe {
            self.freebusys = freebusys
            return self
        }
    }
    
    /// set freebusy
    /// - Parameter freebusy: CKFreeBusy
    @discardableResult
    public func set(freebusy: CKFreeBusy) -> Self {
        return set(freebusys: [freebusy])
    }
    
    /// freebusy for uid
    /// - Parameter UID: String
    /// - Returns: CKFreeBusy?
    public func freebusy(for UID: String) -> CKFreeBusy? {
        return lock.hub.safe {
            return freebusys.first(where:  { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all freebusys with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeFreebusys(with UID: String) -> Self {
        return lock.hub.safe {
            self.freebusys.removeAll(where: { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all freebusys
    /// - Returns: description
    @discardableResult
    public func removeFreebusys() -> Self {
        return lock.hub.safe {
            self.freebusys.removeAll()
            return self
        }
    }
}

// MARK: - alarms
extension CKCalendar {
    
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

// MARK: - todo
extension CKCalendar {
    
    
    /// add todos
    /// - Parameter todos: [CKTodo]
    @discardableResult
    public func add(todos: [CKTodo]) -> Self {
        return lock.hub.safe {
            self.todos.append(contentsOf: todos)
            return self
        }
    }
    
    /// add todo
    /// - Parameter todo: CKTodo
    @discardableResult
    public func add(todo: CKTodo) -> Self {
        return add(todos: [todo])
    }
    
    /// set todos
    /// - Parameter todos: [CKTodo]
    @discardableResult
    public func set(todos: [CKTodo]) -> Self {
        return lock.hub.safe {
            self.todos = todos
            return self
        }
    }
    
    /// set todo
    /// - Parameter todo: CKFreeBusy
    @discardableResult
    public func set(todo: CKTodo) -> Self {
        return set(todos: [todo])
    }
    
    /// todo for uid
    /// - Parameter UID: String
    /// - Returns: CKFreeBusy?
    public func todo(for UID: String) -> CKTodo? {
        return lock.hub.safe {
            return todos.first(where:  { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all todos with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeTodos(with UID: String) -> Self {
        return lock.hub.safe {
            self.todos.removeAll(where: { $0.attribute(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all todos
    /// - Returns: description
    @discardableResult
    public func removeTodos() -> Self {
        return lock.hub.safe {
            self.todos.removeAll()
            return self
        }
    }
}

// MARK: - 属性相关
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
                    guard let attr = attrs.first else { return self}
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return self}
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
                    guard let attr = attrs.first else { return  self }
                    attributes[index] = attr
                }
            } else {
                if AttributeKey.init(rawValue: name)?.mutable == true || name.uppercased().hub.hasPrefix(["X-", "IANA-"]) == true {
                    attributes.append(contentsOf: attrs)
                } else {
                    guard let attr = attrs.first else { return  self }
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
    /// - Parameter key: AttributeKey
    @discardableResult
    public func removeAttrs(for key: AttributeKey) -> Self {
        return lock.hub.safe {
            attributes.removeAll(where: { $0.name.uppercased() == key.rawValue.uppercased() })
            return self
        }
    }
    
    /// remove all attrs for key
    /// - Parameter key: String
    @discardableResult
    public func removeAttrs(for name: String) -> Self {
        return lock.hub.safe {
            attributes.removeAll(where: { $0.name.uppercased() == name.uppercased() })
            return self
        }
    }
    
    /// removeAttrs
    @discardableResult
    public func removeAttrs() -> Self {
        return lock.hub.safe {
            attributes.removeAll()
            return self
        }
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
