import Testing
@testable import KeyManager

private let testService = "com.keymanager.tests"

/// Clean up a key from the test keychain, ignoring errors if it doesn't exist.
private func cleanUp(key: String) {
	try? KeyManager.remove(key: key, service: testService)
}

@Suite("KeyManager Static API")
struct KeyManagerStaticTests {
	@Test func storeAndRetrieve() throws {
		let key = "test-store-retrieve"
		defer { cleanUp(key: key) }

		try KeyManager.store(key: key, value: "hello", service: testService)
		let result = try KeyManager.value(for: key, service: testService)
		#expect(result == "hello")
	}

	@Test func storeUpdatesExistingByDefault() throws {
		let key = "test-store-updates"
		defer { cleanUp(key: key) }

		try KeyManager.store(key: key, value: "first", service: testService)
		try KeyManager.store(key: key, value: "second", service: testService)
		let result = try KeyManager.value(for: key, service: testService)
		#expect(result == "second")
	}

	@Test func storeThrowsDuplicateWhenUpdateDisabled() throws {
		let key = "test-store-no-update"
		defer { cleanUp(key: key) }

		try KeyManager.store(key: key, value: "first", service: testService)
		#expect(throws: KeyManager.KeyError.duplicate(key: key)) {
			try KeyManager.store(key: key, value: "second", service: testService, shouldUpdate: false)
		}
	}

	@Test func update() throws {
		let key = "test-update"
		defer { cleanUp(key: key) }

		try KeyManager.store(key: key, value: "original", service: testService)
		try KeyManager.update(key: key, value: "updated", service: testService)
		let result = try KeyManager.value(for: key, service: testService)
		#expect(result == "updated")
	}

	@Test func updateThrowsNotFoundForMissingKey() throws {
		let key = "test-update-missing"
		cleanUp(key: key)

		#expect(throws: KeyManager.KeyError.notFound(key: key)) {
			try KeyManager.update(key: key, value: "value", service: testService)
		}
	}

	@Test func remove() throws {
		let key = "test-remove"

		try KeyManager.store(key: key, value: "to-delete", service: testService)
		try KeyManager.remove(key: key, service: testService)
		#expect(throws: KeyManager.KeyError.notFound(key: key)) {
			try KeyManager.value(for: key, service: testService)
		}
	}

	@Test func valueThrowsNotFoundForMissingKey() throws {
		let key = "test-value-missing"
		cleanUp(key: key)

		#expect(throws: KeyManager.KeyError.notFound(key: key)) {
			try KeyManager.value(for: key, service: testService)
		}
	}

	@Test func serviceIsolation() throws {
		let key = "test-isolation"
		let otherService = "com.keymanager.tests.other"
		defer {
			cleanUp(key: key)
			try? KeyManager.remove(key: key, service: otherService)
		}

		try KeyManager.store(key: key, value: "service-a", service: testService)
		try KeyManager.store(key: key, value: "service-b", service: otherService)

		let a = try KeyManager.value(for: key, service: testService)
		let b = try KeyManager.value(for: key, service: otherService)
		#expect(a == "service-a")
		#expect(b == "service-b")
	}
}

@Suite("KeyManager Instance API")
struct KeyManagerInstanceTests {
	private let manager = KeyManager(service: testService)

	@Test func storeAndRetrieve() throws {
		let key = "test-instance-store"
		defer { cleanUp(key: key) }

		try manager.store(key: key, value: "instance-value")
		let result = try manager.value(for: key)
		#expect(result == "instance-value")
	}

	@Test func updateAndRemove() throws {
		let key = "test-instance-update"
		defer { cleanUp(key: key) }

		try manager.store(key: key, value: "original")
		try manager.update(key: key, value: "updated")
		let result = try manager.value(for: key)
		#expect(result == "updated")

		try manager.remove(key: key)
		#expect(throws: KeyManager.KeyError.notFound(key: key)) {
			try manager.value(for: key)
		}
	}
}
