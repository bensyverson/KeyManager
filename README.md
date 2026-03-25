# KeyManager

A lightweight Swift wrapper around the system Keychain for securely storing, retrieving, updating, and deleting secrets. Works on all Apple platforms.

## Installation

Add KeyManager to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bensyverson/KeyManager.git", from: "1.0.0"),
]
```

Then add it as a dependency of your target:

```swift
.target(name: "MyApp", dependencies: ["KeyManager"]),
```

## Usage

### Instance API

Create a `KeyManager` with a service name to namespace your keychain items:

```swift
import KeyManager

let keys = KeyManager(service: "com.myapp.credentials")

// Store a secret
try keys.store(key: "api-token", value: "sk_live_abc123")

// Retrieve it
let token = try keys.value(for: "api-token")

// Update it
try keys.update(key: "api-token", value: "sk_live_newtoken")

// Delete it
try keys.remove(key: "api-token")
```

### Static API

If you prefer not to hold an instance, pass the service name directly:

```swift
try KeyManager.store(key: "api-token", value: "sk_live_abc123", service: "com.myapp.credentials")
let token = try KeyManager.value(for: "api-token", service: "com.myapp.credentials")
```

### Handling Duplicates

By default, `store` will update an existing key. To throw an error on duplicates instead:

```swift
try keys.store(key: "api-token", value: "secret", shouldUpdate: false)
// Throws KeyManager.KeyError.duplicate if the key already exists
```

## Error Handling

All methods throw `KeyManager.KeyError`:

| Error | Meaning |
|---|---|
| `.couldNotAdd(key:status:)` | Failed to add item to keychain |
| `.couldNotUpdate(key:status:)` | Failed to update existing item |
| `.duplicate(key:)` | Key already exists (when `shouldUpdate` is `false`) |
| `.notFound(key:)` | Key does not exist in the keychain |
| `.couldNotDelete(key:status:)` | Failed to delete item |
| `.unexpectedDataType` | Keychain returned data in an unexpected format |

## Platform Support

- macOS 13+
- iOS 16+
- tvOS 16+
- watchOS 9+

## License

MIT
