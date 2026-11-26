import Foundation
import Testing
@testable import SideInstaller

struct AutoSignCoreTests {
    @Test func legacySystemsDoNotPretendToUseModernTransport() {
        let decision = AutoSignCompatibilityRouter.decision(
            majorVersion: 16,
            minorVersion: 0,
            legacyAdapterAvailable: false
        )
        #expect(decision.route == .unsupported)
        #expect(decision.requiresImportedPairingRecord)
    }

    @Test func legacyRouteIsSelectedOnlyWhenAdapterExists() {
        let decision = AutoSignCompatibilityRouter.decision(
            majorVersion: 17,
            minorVersion: 3,
            legacyAdapterAvailable: true
        )
        #expect(decision.route == .legacyLockdown)
    }

    @Test func iOS174UsesModernTunnelRoute() {
        let decision = AutoSignCompatibilityRouter.decision(
            majorVersion: 17,
            minorVersion: 4
        )
        #expect(decision.route == .rsdTunnel)
    }

    @Test func iOS264UsesRemotePairingRoute() {
        let decision = AutoSignCompatibilityRouter.decision(
            majorVersion: 26,
            minorVersion: 4
        )
        #expect(decision.route == .remotePairing)
    }

    @Test func iOS27UsesSelfPairingRoute() {
        let decision = AutoSignCompatibilityRouter.decision(
            majorVersion: 27,
            minorVersion: 0
        )
        #expect(decision.route == .selfPairing)
    }

    @Test func jobProgressIsClamped() {
        let job = AutoSignJob(sourceName: "sample.ipa", progress: 2)
        #expect(job.progress == 1)
        #expect(job.state == .queued)
    }
}
