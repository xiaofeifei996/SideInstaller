# AutoSignCore

The initial architecture slice for iOS Auto Sign.

- ASCompatibility.swift: deterministic iOS-version routing.
- ASJob.swift: signing-job state model and backend/device adapter contracts.

These files are included by the existing XcodeGen ios-app source directory. No current signing behavior is replaced in this first slice. The iOS deployment target remains 17.4 until the legacy Lockdown adapter and native dependency audit are complete.


Compatibility routing and job-state contracts are the first implementation milestone; concrete legacy transport adapters are tracked in the architecture document.
