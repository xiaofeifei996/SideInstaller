# iOS Auto Sign — RootHide architecture

## Product goal

A standalone Home Screen app for managing Apple ID sessions, 2FA, signing certificates, App IDs, provisioning profiles, IPA import, signing, installation, and renewal reminders. It is not a Settings bundle or SpringBoard tweak.

The first implementation is based on SideInstaller. Existing Apple account and signing code remains the source of truth; new code introduces explicit compatibility and job orchestration boundaries rather than duplicating authentication or signing.

## Compatibility contract

The requested target is iOS 16 through iOS 27. This is a target matrix, not a claim that every route is already implemented or verified.

| OS range | Device-link strategy | State |
|---|---|---|
| iOS 16.0–17.3 | Classic Lockdown / usbmuxd pairing and installation path; pairing record may need to be imported | Design target; requires implementation and device testing |
| iOS 17.4–26.3 | Existing SideInstaller RPPairing / tunnel / RSD path; imported pairing material where required | Reuse existing code; test on devices |
| iOS 26.4–26.7 | Remote-pairing record path; classic Lockdown over LocalDevVPN is not assumed to work | Design target; imported remote pairing required |
| iOS 27.x | Native self-pairing where supported; imported remote pairing fallback | Reuse existing code; test on devices |

The upstream SideInstaller documentation currently says versions below 17.4 are unsupported. Therefore iOS 16 support requires a genuine legacy transport implementation and cannot be achieved by lowering firmware or deployment-target values alone. The upstream compatibility page also distinguishes 17.4–26.3, 26.4–26.7, and 27+ pairing behavior.

## Layered source architecture

- AutoSignCore/Models: immutable signing jobs, state, device capabilities, and compatibility profiles.
- AutoSignCore/Compatibility: OS-version router. It selects a transport strategy; it does not claim that a strategy is available until its adapter reports capability.
- AutoSignCore/Device: protocol boundary for pairing, device discovery, app listing, installation, and refresh. Adapters: LegacyLockdownAdapter, RSDTunnelAdapter, RemotePairingAdapter, SelfPairingAdapter.
- AutoSignCore/Signing: protocol boundary around the existing Engine / Rust FFI / isideload flow. Preserve existing Apple ID, 2FA, certificate, App ID, profile, and signing behavior.
- AutoSignCore/Import: IPA intake, archive validation, bundle metadata, nested extension inventory, and safe staging.
- AutoSignCore/Queue: persistent job queue, cancellation, retry classification, progress events, and structured redacted logs.
- AutoSignUI: Home, IPA Library, Accounts, Certificates, Profiles, Device, Queue, and Settings screens.
- Packaging/RootHide: RootHide app entitlements and Debian packaging; no hard-coded /var/jb paths.

## Core flows

1. Import IPA from Files or URL; copy to app-controlled staging and inspect archive metadata.
2. Select target device and ask CompatibilityRouter for a supported transport.
3. Pair/connect through the selected adapter; register device with the selected Apple Developer team.
4. Reuse the existing SideInstaller account session and 2FA bridge.
5. Register/resolve App ID, certificate, and provisioning profile through the existing signer.
6. Sign the app and nested extensions with matching profiles/entitlements; verify signatures and bundle structure.
7. Install through the selected device adapter; record expiry and renewal metadata.
8. Queue renewal jobs without storing plaintext Apple ID passwords in logs or exported archives.

## Security rules

- Never log Apple ID passwords, 2FA codes, anisette secrets, private keys, or provisioning-profile contents.
- Keep credentials in Keychain; keep private signing material in the existing protected private store.
- Do not weaken entitlements for embedded frameworks or extensions. RootHide elevated entitlements belong only on the main app executable when required by RootHide.
- Do not assume /var/jb; RootHide uses a randomized jbroot. Use RootHide APIs only for actual jailbreak-root paths. App data belongs in the app's container/private store.
- Validate imported IPA paths and archive entries; reject path traversal and malformed archives.
- A successful build is not proof of device compatibility. Each OS band needs hardware tests.

## Build and test plan

1. Keep the existing RootHide packaging workflow separate from source compatibility.
2. Add compile-time deployment target 16.0 only after auditing Swift APIs and every Rust/native dependency's minimum OS.
3. Build the Rust static library with IPHONEOS_DEPLOYMENT_TARGET=16.0; inspect linked Mach-O minos and dependency availability.
4. Add unit tests for version routing, job transitions, retry classification, and IPA validation.
5. Add CI build jobs for iOS 16-compatible SDK deployment and current SDK packaging. A modern SDK can build a lower deployment target, but the actual binary minos and runtime APIs must be audited.
6. Hardware test one device per transport band: 16.x, 17.4–26.3, 26.4–26.7, and 27.x.

## First implementation slice

This branch adds the compatibility router and signing-job contracts only. Device adapters and lowering the deployment target are intentionally not faked: the current repository's project.yml, build-rust.sh, and Rust dependency graph still declare/assume 17.4. Those are follow-up work after the legacy transport is implemented and dependency min-OS checks pass.
