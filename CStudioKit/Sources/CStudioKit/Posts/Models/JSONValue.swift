//
//  JSONValue.swift
//  CStudioKit
//
//  Flexible JSON value type for JSONB payload fields
//

import Foundation

/// Represents any JSON value for flexible payload storage
public enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .number(Double(int))
        } else if let double = try? container.decode(Double.self) {
            self = .number(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode JSONValue"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Convenience Accessors
extension JSONValue {
    /// Get the value as a String if possible
    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
    
    /// Get the value as a Double if possible
    public var numberValue: Double? {
        if case .number(let value) = self {
            return value
        }
        return nil
    }
    
    /// Get the value as a Bool if possible
    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    /// Get the value as an array if possible
    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }
    
    /// Get the value as an object if possible
    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }
    
    /// Check if the value is null
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }
}

// MARK: - Subscript for Objects
extension JSONValue {
    /// Access nested values in objects using subscript
    public subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }
}


