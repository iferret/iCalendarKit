//
//  CKAttendee.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


extension CKAttendee {
    
    /// Default is INDIVIDUAL
    public enum CUTYPE: String {
        /// An individual
        case INDIVIDUAL
        /// A group of individuals
        case GROUP
        /// A physical resource
        case RESOURCE
        /// A room resource
        case ROOM
        /// Otherwise not known
        case UNKNOWN
    }
    
    /// PARTSTAT
    public enum PARTSTAT: String {
        case NEEDSACTION = "NEEDS-ACTION"
        case ACCEPTED
        case DECLINED
        case TENTATIVE
        case DELEGATED
    }
    
    /// Default is REQ-PARTICIPANT
    public enum ROLE: String {
        /// Indicates chair of the calendar entity
        case CHAIR
        /// Indicates a participant whose participation is required
        case REQPARTICIPANT = "REQ-PARTICIPANT"
        /// Indicates a participant whose participation is optional
        case OPTPARTICIPANT = "OPT-PARTICIPANT"
        /// Indicates a participant who is copied for information
        case NONPARTICIPANT = "NON-PARTICIPANT"
    }
    
    /// Default is FALSE
    public enum RSVP: String {
        case TRUE
        case FALSE
    }
    
}


/// CKAttendee
public class CKAttendee: CKAttribute {
    
    /// 构建
    /// - Parameters:
    ///   - value: String
    ///   - attributes: [String: String]
    public init(value: String, attributes: [String: String]) {
        super.init(name: "ATTENDEE", value: value, attrs: attributes)
    }
}
