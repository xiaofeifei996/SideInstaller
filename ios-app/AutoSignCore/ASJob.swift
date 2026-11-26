import Foundation

enum ASSigningJobState: String, Codable {
    case queued
    case inspecting
    case waitingForDevice
    case pairing
    case signingIn
    case waitingForTwoFactor
    case registeringAppID
    case preparingProfile
    case signing
    case installing
    case verifying
    case completed
    case failed
    case cancelled
}

struct ASSigningJob: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceName: String
    let createdAt: Date
    var state: ASSigningJobState
    var progress: Double
    var bundleIdentifier: String?
    var targetDeviceIdentifier: String?
    var errorCode: String?

    init(sourceName: String, id: UUID = UUID(), createdAt: Date = Date()) {
        self.id = id
        self.sourceName = sourceName
        self.createdAt = createdAt
        self.state = .queued
        self.progress = 0
    }

    mutating func transition(to next: ASSigningJobState, progress: Double? = nil) {
        state = next
        if let progress {
            self.progress = min(1, max(0, progress))
        }
        if next == .completed {
            self.progress = 1
        }
    }
}

/// Adapter boundary. The first concrete implementation will wrap the
/// existing SideInstaller Engine instead of reimplementing Apple auth/signing.
@MainActor
protocol ASSigningBackend: AnyObject {
    func signIPA(at url: URL, for deviceIdentifier: String) async throws -> URL
}

protocol ASDeviceTransport: AnyObject {
    var strategy: ASConnectionStrategy { get }
    func canHandleCurrentDevice() async -> Bool
    func connect(pairingRecord: URL?) async throws
    func install(signedAppAt url: URL) async throws
}
