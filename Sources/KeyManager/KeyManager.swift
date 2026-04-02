//
//  KeyManager.swift
//
//  Created by Ben Syverson on 2/27/23.
//

import Foundation

public struct KeyManager {
    public enum KeyError: LocalizedError, Equatable {
        case couldNotAdd(key: String, status: OSStatus)
        case couldNotUpdate(key: String, status: OSStatus)
        case duplicate(key: String)
        case notFound(key: String)
        case couldNotDelete(key: String, status: OSStatus)
        case couldNotRead(key: String, status: OSStatus)
        case unexpectedDataType

        public var errorDescription: String? {
            switch self {
            case let .couldNotAdd(key: key, status):
                "Could not add \(key) (OSStatus \(status))"
            case let .couldNotUpdate(key: key, status):
                "Could not update \(key) (OSStatus \(status))"
            case let .duplicate(key: key):
                "Key already exists: \(key)"
            case let .notFound(key: key):
                "Could not find \(key)"
            case .unexpectedDataType:
                "Unexpected data type returned from keychain"
            case let .couldNotRead(key: key, status: status):
                "Could not read \(key) (OSStatus \(status))"
            case let .couldNotDelete(key: key, status: status):
                "Could not delete key \(key) (OSStatus \(status))"
            }
        }
    }

    public let service: String

    public init(service: String) {
        self.service = service
    }

    // MARK: - Instance Methods

    public func store(key: String, value: String, shouldUpdate: Bool = true) throws {
        try Self.store(key: key, value: value, service: service, shouldUpdate: shouldUpdate)
    }

    public func update(key: String, value: String) throws {
        try Self.update(key: key, value: value, service: service)
    }

    public func value(for key: String) throws -> String {
        try Self.value(for: key, service: service)
    }

    public func remove(key: String) throws {
        try Self.remove(key: key, service: service)
    }

    // MARK: - Static Methods

    public static func store(key: String, value: String, service: String, shouldUpdate: Bool = true) throws {
        let valueData = Data(value.utf8)
        let addquery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData,
        ]

        let status = SecItemAdd(addquery as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            if shouldUpdate {
                try update(key: key, value: value, service: service)
            } else {
                throw KeyError.duplicate(key: key)
            }
        default:
            throw KeyError.couldNotAdd(key: key, status: status)
        }
    }

    public static func update(key: String, value: String, service: String) throws {
        let valueData = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: valueData,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeyError.notFound(key: key)
        default:
            throw KeyError.couldNotUpdate(key: key, status: status)
        }
    }

    public static func value(for key: String, service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeyError.notFound(key: key)
        default:
            throw KeyError.couldNotRead(key: key, status: status)
        }
        guard let data = item as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            throw KeyError.unexpectedDataType
        }
        return string
    }

    public static func remove(key: String, service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeyError.notFound(key: key)
        default:
            throw KeyError.couldNotDelete(key: key, status: status)
        }
    }
}
