//
//  CKError.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

/// CKError
enum CKError {
    case custom(_ message: String)
}

extension CKError: Error {
    
    /// localizedDescription
    internal var localizedDescription: String {
        switch self {
        case .custom(let message):
            return message
        }
    }
}
