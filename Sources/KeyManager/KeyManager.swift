//
//  KeyManager.swift
//  MastodonClient
//
//  Created by Ben Syverson on 2/27/23.
//

import Foundation

public struct KeyManager {
	public enum KeyError: LocalizedError {
		case couldNotAdd(key: String, status: OSStatus)
		case duplicate(key: String)
		case notFound(key: String)
		case unexpectedDataType(item: CFTypeRef?)

		public var errorDescription: String? {
			switch self {
			case .couldNotAdd(key: let key, let status):
				return "Could not add \(key) (OSStatus \(status))"
			case .duplicate(key: let key):
				return "Key already exists: \(key)"
			case .notFound(key: let key):
				return "Could not find \(key)"
			case .unexpectedDataType(item: let item):
				if let item {
					return "Found unexpected data: \(item)"
				} else {
					return "Nil data returned from key search"
				}
			}
		}
	}

	public static func store(key: String, value: String, shouldUpdate: Bool = true) throws {
		let keyData = Data(key.utf8)
		let valueData = Data(value.utf8)
		let addquery: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: keyData,
			kSecValueData as String: valueData
		]

		let status = SecItemAdd(addquery as CFDictionary, nil)
		switch status {
		case errSecSuccess:
			return
		case errSecDuplicateItem:
			if shouldUpdate {
				try update(key: key, value: value)
			} else {
				throw KeyError.duplicate(key: key)
			}
		default:
			throw KeyError.couldNotAdd(key: key, status: status)
		}
	}

	public static func update(key: String, value: String) throws {
		let keyData = Data(key.utf8)
		let valueData = Data(value.utf8)

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: keyData,
		]

		let attributes: [String: Any] = [
			kSecValueData as String: valueData
		]

		let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

		switch status {
		case errSecSuccess:
			return
		case errSecItemNotFound:
			throw KeyError.notFound(key: key)
		default:
			throw KeyError.couldNotAdd(key: key, status: status)
		}
	}

	public static func value(for key: String) throws -> String {
		let keyData = Data(key.utf8)

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecMatchLimit as String: kSecMatchLimitOne,
			kSecAttrAccount as String: keyData,
			kSecReturnData as String: true
		]

		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		guard status == errSecSuccess else {
			throw KeyError.notFound(key: key)
		}
		guard let key = item as? Data,
			  let string = String(data: key, encoding: .utf8) else {
			throw KeyError.unexpectedDataType(item: item)
		}
		return string
	}
}
