import Foundation

/// Connection strategy selected for the target iOS release.
/// Selection is descriptive only; an adapter must separately report that it
/// can actually perform the operation on the current device.
enum ASConnectionStrategy: String, Codable, CaseIterable {
    case legacyLockdown
    case rsdTunnel
    case remotePairing
    case nativeSelfPairing
    case unsupported
}

struct ASOSVersion: Comparable, Codable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(_ version: OperatingSystemVersion) {
        self.init(major: version.majorVersion,
                  minor: version.minorVersion,
                  patch: version.patchVersion)
    }

    static func < (lhs: ASOSVersion, rhs: ASOSVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }

    var description: String { "\(major).\(minor).\(patch)" }
}

struct ASCompatibilityProfile: Equatable {
    let strategy: ASConnectionStrategy
    let requiresImportedPairingRecord: Bool
    let notes: String
}

enum ASCompatibilityRouter {
    /// Routes iOS 16–27 into a transport family. This is not a support
    /// guarantee: the concrete adapter must pass its own capability checks.
    static func profile(for version: ASOSVersion) -> ASCompatibilityProfile {
        let v16 = ASOSVersion(16)
        let v17_4 = ASOSVersion(17, 4)
        let v26_4 = ASOSVersion(26, 4)
        let v27 = ASOSVersion(27)

        guard version >= v16 else {
            return ASCompatibilityProfile(
                strategy: .unsupported,
                requiresImportedPairingRecord: false,
                notes: "Auto Sign targets iOS 16 and later."
            )
        }

        if version < v17_4 {
            return ASCompatibilityProfile(
                strategy: .legacyLockdown,
                requiresImportedPairingRecord: true,
                notes: "Legacy Lockdown transport must be implemented and verified for this OS."
            )
        }

        if version < v26_4 {
            return ASCompatibilityProfile(
                strategy: .rsdTunnel,
                requiresImportedPairingRecord: true,
                notes: "Use the existing SideInstaller RPPairing/RSD tunnel path where available."
            )
        }

        if version < v27 {
            return ASCompatibilityProfile(
                strategy: .remotePairing,
                requiresImportedPairingRecord: true,
                notes: "Use a remote-pairing record; do not assume classic Lockdown works over the local tunnel."
            )
        }

        return ASCompatibilityProfile(
            strategy: .nativeSelfPairing,
            requiresImportedPairingRecord: false,
            notes: "Try native self-pairing first; allow imported remote pairing as a fallback."
        )
    }

    static func currentDeviceProfile() -> ASCompatibilityProfile {
        profile(for: ASOSVersion(ProcessInfo.processInfo.operatingSystemVersion))
    }
}
