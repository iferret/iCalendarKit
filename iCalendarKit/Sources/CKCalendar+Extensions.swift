//
//  CKCalendar+Extensions.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/4.
//

import Foundation
import EventKit
import EventKitUI

extension CKCalendar {
    
    
    /// get EKEvent form calender
    /// - Parameter store: EKEventStore
    /// - Throws: Error
    /// - Returns: [EKEvent]
    public func events(with store: EKEventStore) throws -> [EKEvent] {
        return try events.map {
            return try convert(evt: $0, with: store)
        }
    }
  
    
    /// convert CKEvent to EK Event
    /// - Parameters:
    ///   - evt: CKEvent
    ///   - store: EKEventStore
    /// - Throws: Error
    /// - Returns: EKEvent
    private func convert(evt: CKEvent, with store: EKEventStore) throws -> EKEvent {
        guard let md5 = evt.attribute(for: .UID)?.value.hub.md5 else { throw CKError.custom("Can not get UID from CKEvent") }
        let startDate = try self.startDate(for: evt)
        let predicate = store.predicateForEvents(withStart: startDate, end: startDate.addingTimeInterval(0.1), calendars: nil)
        let event: EKEvent
        if let _event = store.events(matching: predicate).first(where: { $0.hasNotes == true && $0.notes?.contains(md5) == true }) {
            event = _event
        } else {
            event = EKEvent.init(eventStore: store)
        }
        // 设置标题
        if let title = evt.attribute(for: .SUMMARY)?.value.replacingOccurrences(of: "\\r\\n", with: "") {
            event.title = title
        }
        // 设置 notes
        if let notes = evt.attribute(for: .DESCRIPTION)?.value.replacingOccurrences(of: "\\r\\n", with: ""), notes.isEmpty == false {
            event.notes = md5 + "\n" + notes
        } else {
            event.notes = md5
        }
        // 设置位置信息
        if let location = evt.attribute(for: .LOCATION)?.value.replacingOccurrences(of: "\\r\\n", with: "") {
            event.location = location
        }
        // 设置URL
        if let link = evt.attribute(for: .URL)?.value, let url = URL.init(string: link) {
            event.url = url
        }
        // 设置开始时间
        event.startDate = startDate
        // 设置结束时间
        if let attr = evt.attribute(for: .DTEND) {
            event.endDate = date(from: attr)
        }
        // GEO
        if let attr = evt.attribute(for: .GEO) {
            event.structuredLocation?.geoLocation = geo(from: attr)
        }
        /// EKCalendar
        event.calendar = store.defaultCalendarForNewEvents
        
        return event
    }
}

extension CKCalendar {
    
    /// date from CKAttribute
    /// - Parameter attribute: CKAttribute
    /// - Returns: Date
    private func date(from attribute: CKAttribute) -> Date? {
        let contents = attribute.value.replacingOccurrences(of: "T", with: "", options: [.caseInsensitive], range: nil)
        if contents.hub.hasSuffix(["Z","z"]) == true {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.dateFormat = "yyyyMMddHHmmssZ"
            return dateFormatter.date(from: contents)
        } else if let TZID = attribute.value(for: "TZID") {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.timeZone = TZID.hub.toTimeZone()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            return dateFormatter.date(from: contents)
        } else if timezones.isEmpty == false, let TZID = timezones.first?.attribute(for: .TZID)?.value  {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.timeZone = TZID.hub.toTimeZone()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            return dateFormatter.date(from: contents)
        } else {
            let dateFormatter: DateFormatter = .init()
            dateFormatter.timeZone = "Asia/Shanghai".hub.toTimeZone()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            return dateFormatter.date(from: contents)
        }
    }
    
    /// geo from CKAttribute
    /// - Parameter attribute: CKAttribute
    /// - Returns: CLLocation?
    private func geo(from attribute: CKAttribute) -> CLLocation? {
        guard attribute.value.contains(";") == true else { return nil }
        let components = attribute.value.components(separatedBy: ";")
        let latitude: CLLocationDegrees = components[0].hub.doubleValue
        let longitude: CLLocationDegrees = components[1].hub.doubleValue
        return .init(latitude: latitude, longitude: longitude)
    }
    
    /// start date for CKEvent
    /// - Parameter event: CKEvent
    /// - Throws: Error
    /// - Returns: Date
    private func startDate(for event: CKEvent) throws -> Date {
        if let attr = event.attribute(for: .DTSTART), let date = date(from: attr) {
            return date
        } else if let attr = event.attribute(for: .DTSTAMP), let date = date(from: attr) {
            return date
        } else {
            throw CKError.custom("Can not get start date for CKEvent")
        }
    }
}
