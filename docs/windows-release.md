# Windows release and verification

Releases from 0.3.41 use `.github/workflows/release.yml`. Earlier releases were built locally and do not have this workflow provenance.

## Maintainers

1. Update `pubspec.yaml` (semantic version and increasing build number), review the changes and push to `main`.
2. Optionally run the workflow manually on that commit; it uploads an Actions artifact only.
3. Push a new `mimio-vX.Y.Z` tag matching `pubspec.yaml`. Never move a published tag or replace an existing release silently.
4. The Windows 2022 runner uses Flutter 3.47.8 and the committed lockfile, generates models, runs analysis and tests, then builds Windows x64. Source changes during generation/build fail the job.
5. Packaging takes only the fresh release output, adds the MIT license, usage notes and source/build metadata, and verifies ZIP contents. No local installation or AppData is uploaded. Generic secret and unwanted-runtime-file checks are a guard, not an exhaustive privacy audit; review source and history before tagging.
6. A separate job generates GitHub provenance, verifies it, creates a draft release, downloads the assets and checks hashes and provenance again before making it public. No personal publishing token or Android signing credentials are needed.

Build jobs have read-only repository access. Publishing uses the temporary `GITHUB_TOKEN` plus GitHub OIDC. Third-party actions in the release workflow are pinned to full commit SHAs. Failed publication may leave a draft for investigation; do not delete or overwrite assets automatically to bypass a failed check.

## Users

Download and fully extract `Mimio-X.Y.Z-windows-x64.zip`, then run `Mimio.exe`. The executable remains unsigned. Back up the previous application folder before upgrading.

Check the ZIP hash against `SHA256SUMS.txt`:

```powershell
Get-FileHash .\Mimio-0.3.41-windows-x64.zip -Algorithm SHA256
```

With a recent GitHub CLI, authenticate and verify its build provenance:

```sh
gh attestation verify Mimio-0.3.41-windows-x64.zip --repo i-iooi-i/Mimio --signer-workflow i-iooi-i/Mimio/.github/workflows/release.yml
```

`BUILD-INFO.json` records the source commit, workflow run, SDK and version. Inspect that run's logs and tagged source. Provenance does not imply byte-for-byte reproducibility across independent builds, Windows code signing, or a security audit.
