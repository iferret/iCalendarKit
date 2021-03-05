//
//  CKAttribute.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


/// CKAttribute
public class CKAttribute {
    
    
    // MARK: - 公开有属性
    
    /// String
    public var name: String
    /// String
    public let value: String
    /// [String: String]
    public var attrs: [String: String] = [:]
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: Error
    public init(from contents: String, name: String) throws {
        self.name = name
        let pattern = #"^((\r\n)\#(name);)"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        if reg.firstMatch(in: contents, options: [], range: contents.hub.range) != nil {
            var contents = contents
            // 1. get name
            do {
                let pattern: String = #"(?<=\r\n)([\s\S]*?)(?=;)"#
                let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
                guard let result = reg.firstMatch(in: contents, options: [], range: contents.hub.range) else {
                    throw CKError.custom("Can not get attribute name from string")
                }
                // update contents
                contents = contents.hub.substring(from: result.range.location + result.range.length + 1)
            }
            // 2. get attrs
            let components = contents.components(separatedBy: ";")
            
            for component in components where component.hasSuffix("\r\n") == false {
                let components = component.components(separatedBy: "=")
                guard components.count >= 2 else {
                    throw CKError.custom("Can not get attribute attrs from string")
                }
                attrs[components[0]] = components[1]
            }
            
            // 3. get value
            guard var component = components.first(where: { $0.hasSuffix("\r\n") }) else {
                throw CKError.custom("Can not get attribute value from string")
            }
            do {
                let pattern: String = #"(?<=:)([\s\S]*?)(?=\r\n)"#
                let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
                guard let result = reg.firstMatch(in: component, options: [], range: component.hub.range) else {
                    throw CKError.custom("Can not get attribute value from string")
                }
                // set value
                value = component.hub.substring(with: result.range)
                // update component
                component = component.hub.substring(to: result.range.location - 1)
            }
            // 4. add attr
            if component.contains("=") == true {
                let components = component.components(separatedBy: "=")
                if components.count >= 2 {
                    attrs[components[0]] = components[1]
                }
            }
            
        } else {
            // 1. get name
            let pattern: String = #"(?<=\r\n)([\s\S]*?)(?=:)"#
            let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
            guard let result = reg.firstMatch(in: contents, options: [], range: contents.hub.range) else {
                throw CKError.custom("Can not get attribute name from string")
            }
            self.name = contents.hub.substring(with: result.range)
            // 2. get value
            self.value = contents.hub.substring(from: result.range.location + result.range.length + 1).replacingOccurrences(of: "\r\n", with: "")
            // 3. default attrs
            self.attrs = [:]
        }
    }
    
    /// 构建
    /// - Parameters:
    ///   - name: String
    ///   - value: String
    ///   - attrs: [String: String]
    public init(name: String = "", value: String, attrs: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.attrs = attrs
    }
    
    /// get attrs from ics string
    /// - Parameter contents: String
    /// - Throws: String
    /// - Returns: [CKAttribute]
    internal static func attributes(from contents: inout String, withKeys keys: [CKRegularable]) throws -> [CKAttribute] {
        var attrs: [CKAttribute] = []
        for key in keys {
            let reg = try NSRegularExpression.init(pattern: key.pattern, options: [.caseInsensitive])
            if key.mutable == true {
                let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
                guard results.isEmpty == false else { continue }
                for result in results {
                    let content = contents.hub.substring(with: result.range)
                    let attr = try CKAttribute.init(from: content, name: key.name)
                    attrs.append(attr)
                    contents = contents.hub.remove(with: result.range)
                }
            } else {
                guard let result = reg.firstMatch(in: contents, options: [], range: contents.hub.range) else { continue }
                let content = contents.hub.substring(with: result.range)
                let attr = try CKAttribute.init(from: content, name: key.name)
                attrs.append(attr)
                contents = contents.hub.remove(with: result.range)
            }
        }
        // 获取自定义
        // X-PROP / IANA-PROP
        let pattern: String = #"(\r\n)(X-|IANA-)([\s\S]*?)(\r\n)"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        guard results.isEmpty == false else { return attrs }
        for result in results {
            let content = contents.hub.substring(with: result.range)
            print("content", content)
            let pattern: String = #"(?<=\r\n)(X-|IANA-)([\s\S]*?)((?=:)|(?=;))"#
            let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
            guard let res = reg.firstMatch(in: content, options: [], range: content.hub.range) else {
                print(content)
                throw CKError.custom("Can not get attribiute name")
            }
            let name = content.hub.substring(with: res.range)
            let attr = try CKAttribute.init(from: content, name: name)
            attrs.append(attr)
            contents = contents.hub.remove(with: result.range)
        }
        return attrs
    }
}

// MARK: - 属性相关
extension CKAttribute {
    
    /// contains
    /// - Parameter attrKey: String
    /// - Returns: Bool
    public func contains(_ attrKey: String) -> Bool {
        return lock.hub.safe {
            return attrs.keys.contains(where: { $0.uppercased() == attrKey.uppercased() })
        }
    }
    
    /// value for key
    /// - Parameter attrKey: String
    /// - Returns: String
    public func value(for attrKey: String) -> String? {
        return lock.hub.safe {
            return attrs.first(where: { $0.key.uppercased() == attrKey.uppercased() })?.value
        }
    }
    
    /// set value for key
    /// - Parameters:
    ///   - value: String
    ///   - attrKey: String
    /// - Returns: Self
    @discardableResult
    public func set(value: String, for attrKey: String) -> Self {
        return lock.hub.safe {
            attrs[attrKey] = value
            return self
        }
    }
    
    ///  remove value for key
    /// - Parameter attrKey: String
    /// - Returns: Self
    @discardableResult
    public func removeValue(for attrKey: String) -> Self {
        return lock.hub.safe {
            attrs.removeValue(forKey: attrKey)
            return self
        }
    }
}

// MARK: - CKTextable
extension CKAttribute: CKTextable {
    
    /// text with ics format
    public var text: String {
        var contents: String = ""
        contents += name
        if attrs.isEmpty == true {
            contents += ":"
            contents += value
        } else {
            for key in attrs.filter({ $0.value.contains(":") == true }) .keys.sorted(by: > ) {
                guard let value = attrs[key] else { continue }
                contents += ";"
                contents += key
                contents += "="
                contents += value
            }
            for key in attrs.filter({ $0.value.contains(":") == false }) .keys.sorted(by: > ) {
                guard let value = attrs[key] else { continue }
                contents += ";"
                contents += key
                contents += "="
                contents += value
            }
            contents += ":"
            contents += value
        }
        contents += "\r\n"
        return contents
    }
    
}
