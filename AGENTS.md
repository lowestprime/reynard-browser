# AGENTS.md

## Mission

You are operating in the root of the `lowestprime/reynard-browser` fork. Your job is to act as an autonomous senior build/release engineer and iOS browser engineer for Reynard. Deliver working code and a downloadable IPA artifact, not just analysis.

The primary user goal is to build a latest-main Reynard IPA that includes post-0.4.0 upstream fixes, especially iOS 26.6 / iPhone 15 Pro Max JIT/TXM-related fixes, and then add a robust Page Zoom feature comparable to or better than iOS Safari.

## Repository map

Important root-level paths:

* `.github/workflows/build-latest-reynard-ipa.yml` — custom GitHub Actions workflow for building the latest Reynard IPA.
* `tools/development/update-gecko.sh` — checks out the Firefox source tag from `engine/release.txt`.
* `tools/development/apply-patches.sh` — applies Reynard’s Firefox patches.
* `tools/development/build-idevice.sh` — builds the idevice FFI library used by JIT/pairing support.
* `tools/development/build-gecko.sh` — generates Gecko `.mozconfig` and runs `./mach build`.
* `tools/release/build-app.sh` — archives the iOS app with Xcode.
* `tools/release/create-ipa.sh` — creates `dist/Reynard.ipa`.
* `browser/Reynard` — native iOS app source.
* `browser/GeckoView` — iOS GeckoView wrapper code.
* `browser/Configuration/Reynard.xcconfig` — app build configuration.
* `engine/release.txt` — Firefox source release tag.
* `engine/firefox` — large Firefox submodule; treat as third-party generated/checked-out source.
* `patches/` — durable Reynard patches applied to Firefox source.

## Critical constraints

* Do not start from or treat `engine/firefox` as the project root.
* Do not directly commit arbitrary edits inside `engine/firefox`; the workflow checks out Firefox source and applies patches. Durable Firefox-source changes must be represented as root-level workflow edits, `tools/` edits, or patch files under `patches/`.
* Do not delete user work.
* Do not run destructive git commands such as `git reset --hard`, `git clean -fdx`, or `git checkout -- .` unless the user explicitly approves.
* Do not replace Apple/Xcode clang for iOS/macOS compilation unless a log proves it is necessary. The working build direction is Apple clang for host/target plus Homebrew LLVM/LLD only for WASM/WASI.
* Do not trust or recommend random third-party IPAs as the final success path unless the artifact, source commit, and provenance are verifiably better than building from this fork.
* Do not stop after writing a plan. Plans guide implementation; the deliverable is a working GitHub Actions artifact.

## Known current build state

The workflow has already advanced through these prior blockers:

* GitHub Actions checkout works.
* Firefox 152 source checkout works.
* Reynard patches apply.
* idevice FFI builds.
* Gecko target linker has been patched to identify Xcode `ld64`.
* Gecko host linker has been patched to identify Xcode `ld64`.
* `cbindgen` is installed and found.
* WASM compiler setup advanced far enough to expose a separate linker problem.

The latest known failure is in the `Install build dependencies` step after adding a WASI wrapper. The workflow hard-coded `/opt/homebrew/opt/llvm/bin/wasm-ld`, but Homebrew’s LLVM install on the runner does not provide `wasm-ld` there. The next likely fix is to explicitly install Homebrew `lld`, prepend `/opt/homebrew/opt/lld/bin` before `/opt/homebrew/opt/llvm/bin` for WASM-only use, and find `wasm-ld` with `command -v wasm-ld` rather than hard-coding the LLVM path.

## Required build strategy

Use this order:

1. Inspect current `git status`, latest commit, workflow file, and latest failed GitHub Actions log.
2. Fix the immediate build failure with the smallest targeted change.
3. Commit and push the fix.
4. Trigger the GitHub Actions workflow.
5. Watch the run.
6. If it fails, retrieve the failed log and debug artifact.
7. Parse the exact failing lines.
8. Patch the root cause.
9. Repeat until `Reynard-latest-main-ipa` is uploaded and `dist/Reynard.ipa` exists.
10. Download and verify the IPA artifact before declaring success.

Use these commands when appropriate:

```powershell
gh workflow run "Build Latest Reynard IPA" --repo lowestprime/reynard-browser --ref main
gh run list --repo lowestprime/reynard-browser --workflow "Build Latest Reynard IPA" --limit 5
gh run watch <RUN_ID> --repo lowestprime/reynard-browser
gh run view <RUN_ID> --repo lowestprime/reynard-browser --log-failed
gh run download <RUN_ID> --repo lowestprime/reynard-browser --name Reynard-build-debug --dir "$env:USERPROFILE\Desktop\reynard-build-debug-latest"
gh run download <RUN_ID> --repo lowestprime/reynard-browser --name Reynard-latest-main-ipa --dir "$env:USERPROFILE\Downloads\Reynard-latest-main"
```

## Immediate build hypothesis to test first

Patch `.github/workflows/build-latest-reynard-ipa.yml` so the dependency step:

* installs `lld` explicitly,
* does not call `/opt/homebrew/opt/llvm/bin/wasm-ld` directly,
* uses `command -v wasm-ld`,
* prepends `/opt/homebrew/opt/lld/bin:/opt/homebrew/opt/llvm/bin` for WASM-only wrapper commands,
* verifies a real WASM link with `--target=wasm32-unknown-wasi` and `--sysroot=/opt/homebrew/share/wasi-sysroot`.

If the WASI link still fails after explicit `lld`, perform one further targeted attempt. If that still fails, use the Gecko fallback `--without-wasm-sandboxed-libraries` only as a documented build-product-first fallback, and record the decision in the ExecPlan.

## Page Zoom feature requirements

After the latest-main IPA pipeline is green, implement a Page Zoom feature in Reynard with these properties:

* User-visible Page Zoom controls comparable to or better than iOS Safari.
* Supports zoom out, zoom in, reset, and a displayed current percentage.
* Provides sensible zoom levels, ideally including 50%, 75%, 85%, 100%, 115%, 125%, 150%, 175%, 200%, 250%, and 300%, unless existing architecture suggests a better set.
* Persists zoom per-site/domain when feasible.
* Provides a default/global zoom setting when feasible.
* Applies to the active tab without requiring app restart.
* Does not break JIT, browsing, extension behavior, app startup, or existing navigation UI.
* Uses existing Reynard/GeckoView architecture and preferences wherever possible rather than adding a brittle CSS-only hack.
* Includes a conservative fallback path if true Gecko page zoom is unavailable in the current iOS GeckoView layer.
* Verifies with build-level checks and, where possible, small unit-level or logic-level tests.

Search the codebase first. Identify how tabs, sessions, settings, menus, and Gecko preferences are represented before editing. Do not assume WebKit APIs exist; Reynard is Gecko-based.

## Verification standards

Done means all of the following are true:

* Latest upstream main is integrated or the fork is explicitly synchronized with `minh-ton/reynard-browser@main`.
* Workflow runs on GitHub Actions without failure.
* `Reynard-latest-main-ipa` artifact exists.
* Downloaded artifact contains `Reynard.ipa`.
* `Reynard.ipa` contains the main app and required extensions.
* Build identity in the workflow logs shows a post-0.4.0 commit/build, not only `63836c3`.
* Page Zoom feature is implemented, discoverable, and documented.
* The final response identifies the exact GitHub Actions run ID, commit SHA, artifact name, and remaining risks.

## Reporting format

At the end of work, report:

* Final commit SHA.
* Successful GitHub Actions run ID and URL.
* Artifact name and local downloaded path if downloaded.
* Summary of workflow fixes.
* Summary of Page Zoom implementation.
* Tests/builds run.
* Any remaining risks, especially around iOS 26.6 JIT behavior that cannot be verified without the physical iPhone.
