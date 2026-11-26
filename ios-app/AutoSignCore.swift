import Foundation

/// Shared job model for the standalone Auto Sign application.
/// Keep this file compatible with the iOS 16 deployment target.
enum AutoSignJobState: String, Codable {
    case queued
    case inspecting
    case waitingForAccount
    case signing
    case installing
    case completed
    case failed
    case cancelled
}

struct AutoSignJob: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceName: String
    let createdAt: Date
    var state: AutoSignJobState
    var progress: Double
    var message: String?

    init(
        id: UUID = UUID(),
        sourceName: String,
        createdAt: Date = Date(),
        state: AutoSignJobState = .queued,
        progress: Double = 0,
        message: String? = nil
    ) {
        self.id = id
        self.sourceName = sourceName
        self.createdAt = createdAt
        self.state = state
        self.progress = min(max(progress, 0), 1)
        self.message = message
    }
}

/// Transport selection is deliberately separate from implementation.
/// A route is usable only after its adapter has passed capability checks.
enum AutoSignDeviceRoute: String, Codable {
    case legacyLockdown
    case rsdTunnel
    case remotePairing
    case selfPairing
    case unsupported
}

struct AutoSignCompatibilityDecision: Equatable {
    let route: AutoSignDeviceRoute
    let requiresImportedPairingRecord: Bool
    let explanation: String
}

enum AutoSignCompatibilityRouter {
    static func decision(
        majorVersion: Int,
        minorVersion: Int,
        legacyAdapterAvailable: Bool = false,
        modernAdapterAvailable: Bool = true
    ) -> AutoSignCompatibilityDecision {
        if majorVersion < 16 {
            return .init(route: .unsupported, requiresImportedPairingRecord: false,
                         explanation: "iOS 16 or later is required.")
        }

        if majorVersion == 16 || (majorVersion == 17 && minorVersion < 4) {
            return .init(
                route: legacyAdapterAvailable ? .legacyLockdown : .unsupported,
                requiresImportedPairingRecord: true,
                explanation: legacyAdapterAvailable
                    ? "Use the legacy Lockdown adapter and an imported pairing record."
                    : "Legacy Lockdown support is not implemented yet; this device route is unavailable."
            )
        }

        if majorVersion >= 27 {
            return .init(
                route: modernAdapterAvailable ? .selfPairing : .unsupported,
                requiresImportedPairingRecord: !modernAdapterAvailable,
                explanation: modernAdapterAvailable
                    ? "Use native self-pairing when the device reports support."
                    : "The iOS 27 pairing adapter is unavailable."
            )
        }

        if majorVersion == 26 && minorVersion >= 4 {
            return .init(
                route: modernAdapterAvailable ? .remotePairing : .unsupported,
                requiresImportedPairingRecord: true,
                explanation: "Use the remote-pairing record path; do not assume the older tunnel route works."
            )
        }

        return .init(
            route: modernAdapterAvailable ? .rsdTunnel : .unsupported,
            requiresImportedPairingRecord: false,
            explanation: modernAdapterAvailable
                ? "Use the existing RPPairing / RSD tunnel route."
                : "The modern device transport is unavailable."
        )
    }
}

/// Boundary for the existing SideInstaller signer. The production adapter
/// must call the existing account, 2FA, certificate, profile and Rust signing
/// implementation; this protocol intentionally does not duplicate secrets.
protocol AutoSignSigningEngine {
    func sign(ipaURL: URL, completion: @escaping (Result<URL, Error>) -> Void)
}
