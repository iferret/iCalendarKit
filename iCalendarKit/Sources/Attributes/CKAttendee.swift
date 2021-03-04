//
//  CKAttendee.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


extension CKAttendee {
    /// Key
    public struct Key: Hashable {
        public let rawValue: String
    }
}

extension CKAttendee.Key {
    /// CUTYPE values => "INDIVIDUAL", "GROUP", "RESOURCE", "ROOM", "UNKNOWN"
    public static var CUTYPE: CKAttendee.Key { .init(rawValue: "CUTYPE") }
    /// PARTSTAT values => "NEEDS-ACTION", "ACCEPTED", "DECLINED", "TENTATIVE", "DELEGATED"
    public static var PARTSTAT: CKAttendee.Key { .init(rawValue: "PARTSTAT") }
    /// ROLE values => "CHAIR", "REQ-PARTICIPANT", "OPT-PARTICIPANT", "NON-PARTICIPANT"
    public static var ROLE: CKAttendee.Key { .init(rawValue: "ROLE") }
    /// RSVP values => "TRUE", "FALSE"
    public static var RSVP: CKAttendee.Key { .init(rawValue: "RSVP") }
}


/// CKAttendee
public class CKAttendee: CKAttribute {
    
    /// 构建
    /// - Parameters:
    ///   - value: String
    ///   - attributes: [String: String]
    public init(value: String, attributes: [Key: String]) {
        var attrs: [String: String] = [:]
        attributes.forEach { (key, value) in
            attrs[key.rawValue] = value
        }
        super.init(name: "ATTENDEE", value: value, attrs: attrs)
    }
}
