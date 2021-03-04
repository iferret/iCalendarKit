//
//  CKSerialization.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

/// CKSerialization
public class CKSerialization {
    public typealias Encoding = String.Encoding
    
    // MARK: - 公开属性
    
    /// content of ics file
    public let contents: String
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter fileUrl: local file url
    /// - Throws: Error
    public init(with fileUrl: URL, encoding: Encoding = .utf8) throws {
        guard fileUrl.isFileURL == true, fileUrl.pathExtension.lowercased() == "ics" else {
            throw CKError.custom("You should put a local ics file url ... eg: xxx.ics")
        }
        let data = try Data.init(contentsOf: fileUrl)
        guard var value = String.init(data: data, encoding: encoding) else { throw CKError.custom("Can not convert file to String ...") }
        // 预处理
        while value.contains("  ") == true {
            value = value.replacingOccurrences(of: "  ", with: " ")
        }
        value = value.replacingOccurrences(of: "\r\n ", with: "")
        value = value.replacingOccurrences(of: "\n ", with: "")
        while value.contains("\r\n\r\n") {
            value = value.replacingOccurrences(of: "\r\n\r\n", with: "\r\n")
        }
        value = value.replacingOccurrences(of: "\r\n", with: "\r\n\r\n")
        // set contents
        self.contents = value
    }
}

extension CKSerialization {
    
    /// get CKCalendar Array
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public func calendars() throws -> [CKCalendar] {
        let pattern: String = #"BEGIN:VCALENDAR([\s\S]*?)END:VCALENDAR"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range)
        // create CKCalendar
        let calendars = try results.map { (result) -> CKCalendar in
            let content = self.contents.hub.substring(with: result.range)
            return try CKCalendar.init(with: content)
        }
        return calendars
    }
}
