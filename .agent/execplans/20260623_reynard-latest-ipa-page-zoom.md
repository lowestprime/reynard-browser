# Reynard latest IPA and Page Zoom

This ExecPlan follows the repository root `PLANS.md`. It must remain current as work proceeds.

## Purpose / Big Picture

Maintain a verified fork-only Reynard sideload build. The current phase rebases the fork's durable custom features onto upstream `0.5.0`/latest `upstream/main`, adds a host-scoped Google Docs desktop compatibility profile, and publishes a new verified unsigned IPA without reopening or replacing the closed upstream pull request.

## Success Criteria

- [x] The fork is synchronized with or verified against latest upstream `minh-ton/reynard-browser@main`.
- [x] GitHub Actions workflow `Build Latest Reynard IPA` completes successfully on `main`.
- [x] Artifact `Reynard-latest-main-ipa` is uploaded and downloaded locally.
- [x] Downloaded artifact contains `Reynard.ipa`.
- [x] IPA contents include `Payload/Reynard.app/Reynard` plus required app extensions.
- [x] Build identity is post-0.4.0 and not only public build `63836c3`.
- [x] Page Zoom supports zoom out, zoom in, reset, displayed percentage, per-site persistence where feasible, and a default/global zoom where feasible.
- [x] Page Zoom applies to the active tab without restarting the app.
- [x] Relevant local checks and final GitHub Actions build are run and recorded.

## Current State

Working directory: `C:\Users\Cooper\Desktop\reynard-browser`.

Branch: `main`, tracking `origin/main`.

Initial `git status --short --branch`:

```text
## main...origin/main
?? .codex/
```

## Verified Baseline IPA

- Patch commit: `5f2bfd48b5611b3601c0b2ff6db040b7d5320e57` (`ci: make Gecko checkpoint inspection pipefail-safe`).
- Archive-only workflow run: `28036622785`, `https://github.com/lowestprime/reynard-browser/actions/runs/28036622785`.
- Archive-only run result: success in `7m15s`.
- Archive job source checkout: `5f2bfd48b5611b3601c0b2ff6db040b7d5320e57`.
- Reused Gecko checkpoint: `gecko-dist-aarch64-apple-ios` from run `28002185987`.
- Uploaded artifact: `Reynard-latest-main-ipa`.
- Local downloaded artifact path: `C:\Users\Cooper\Downloads\Reynard-latest-main-28036622785\Reynard.ipa`.
- Workflow verification: `dist/Reynard.ipa` existed, was about `105M`, and had SHA-256 `a62f30094cdafe43e426823e961b0d2b98ed59e4f418de8ba3f9265c703b9aab`.
- Local verification command: `unzip -Z1 C:\Users\Cooper\Downloads\Reynard-latest-main-28036622785\Reynard.ipa`.
- Verified IPA entries:
  - `Payload/Reynard.app/Reynard`
  - `Payload/Reynard.app/PlugIns/Reynard Helper.appex/Info.plist`
  - `Payload/Reynard.app/PlugIns/OpenIn.appex/Info.plist`
- Build identity evidence: archive log showed `CURRENT_BUILD=5f2bfd4` and `CURRENT_PROJECT_VERSION=5f2bfd4`, so this is a post-0.4.0 build identity, not only public build `63836c3`.
- Page Zoom can begin from this verified baseline IPA. The full split `Build Latest Reynard IPA` workflow still has not been rerun after the pipefail-safe patch because the user explicitly prioritized archive-only reuse of the existing Gecko checkpoint.

## Page Zoom Implementation

Current implementation state:

- Reynard's tab/session/settings/menu architecture has been inspected. The feature is wired through the existing `SessionSettingsManager`, `GeckoSessionSettings`, address-bar page menu, and browsing settings screens.
- The page menu exposes `Page Zoom` controls for host-backed pages: zoom out, current percentage, zoom in, and reset to the configured default.
- Zoom levels are normalized to `50%, 75%, 85%, 100%, 115%, 125%, 150%, 175%, 200%, 250%, 300%`.
- Default zoom is stored under `Prefs.BrowsingSettings.defaultPageZoomPercent`.
- Site-specific overrides are stored under `Prefs.BrowsingSettings.pageZoomOverrides`, keyed by normalized host and matched through existing `DomainMatcher` behavior.
- Active-tab changes are applied immediately by sending updated `GeckoSessionSettings` to the selected `GeckoSession`.
- Durable Gecko source behavior is represented as a root-level patch: `patches/mobile/shared/modules/geckoview/GeckoViewSettings.sys.mjs.patch`. The patch applies `settings.pageZoom` to `browsingContext.fullZoom`.
- Local Windows validation has confirmed `git diff --check` for tracked changes and `git -C engine/firefox apply --check` for the Gecko patch. Swift/Xcode compilation is deferred to GitHub Actions because this Windows host does not provide `swift` or `xcodebuild`.

## Verified Page Zoom IPA

- Feature commit: `ac7c446aa4a8831579945e4d4cb49a33ce8cf670` (`feat(app): add page zoom controls`).
- Workflow run: `28038685786`, `https://github.com/lowestprime/reynard-browser/actions/runs/28038685786`.
- Run result: success in `26m51s`.
- Build job: `Build Gecko checkpoint`, job ID `82998916130`, success in `20m42s`.
- Archive job: `Archive IPA from Gecko checkpoint`, job ID `83003479854`, success in `5m52s`.
- Gecko checkpoint artifact: `gecko-dist-aarch64-apple-ios`, artifact ID `7826642917`, size `124047999` bytes, downloaded by the archive job with SHA-256 `ec43c3d1c73cd81329a8f1a8cb27b7a4722c5e14a7649f036a3867f72a4ef0fa`.
- IPA artifact: `Reynard-latest-main-ipa`, artifact ID `7826779137`, uploaded artifact zip size `107718673` bytes, uploaded artifact zip SHA-256 `4b75cd47758365e733580b2829234c75af61432d29c451678da1cab718b3be48`.
- Local downloaded IPA path: `C:\Users\Cooper\Downloads\Reynard-latest-main-28038685786\Reynard.ipa`.
- Local IPA size: `109612923` bytes.
- Local IPA SHA-256: `5ee4c3d7259ca22c7b1ce61c072da2a67c328b32137c24e58c02adae9c573291`.
- Local IPA verification with `unzip -Z1` found `3032` entries and confirmed:
  - `Payload/Reynard.app/Reynard`
  - `Payload/Reynard.app/PlugIns/Reynard Helper.appex/Info.plist`
  - `Payload/Reynard.app/PlugIns/OpenIn.appex/Info.plist`
- Workflow verification also found the main app binary, `Reynard Helper.appex`, and `OpenIn.appex`.
- Build identity evidence: archive log showed `CURRENT_BUILD = ac7c446` and `CURRENT_PROJECT_VERSION=ac7c446`, so the IPA is a post-0.4.0 build and not only public build `63836c3`.
- Acceleration evidence: `actions/cache/restore` restored a `2.44GB` sccache archive from run `28002185987`; `Build Gecko` reported `4645` cache hits, `71` misses, and `98.49%` hit rate. The `.sccache` directory was about `2.7G`; sccache reported `3 GiB` used with an `8 GiB` max.
- Checkpoint evidence: `engine/firefox/obj-aarch64-apple-ios/dist` was `299M` and uploaded as the `gecko-dist-aarch64-apple-ios` artifact before archive work began.

Recent commits include:

```text
3eb3881 Add Codex agent instructions for Reynard build automation
454565e Add Codex agent instructions for Reynard build automation
c0fa94f Expose wasm-ld for Gecko WASI linker
```

Latest inspected workflow failure:

- Run ID: `27987957678`
- URL: `https://github.com/lowestprime/reynard-browser/actions/runs/27987957678`
- Branch: `main`
- Head SHA: `c0fa94f22fc8022ed632ef877917688578d9705a`
- Failed step: `Install build dependencies`
- Exact failing line: `/opt/homebrew/opt/llvm/bin/wasm-ld --version`
- Exact error: `/opt/homebrew/opt/llvm/bin/wasm-ld: No such file or directory`
- Important preceding Homebrew caveat: `LLD is now provided in a separate formula: brew install lld`

## Constraints

- Do not use `engine/firefox` as the project root.
- Do not commit arbitrary durable changes inside `engine/firefox`; use root workflow, `tools/`, or `patches/`.
- Keep Apple/Xcode clang as `CC`, `CXX`, `HOST_CC`, and `HOST_CXX` unless logs prove a change is required.
- Use Homebrew LLVM/LLD only for WASM/WASI compiler/linker plumbing.
- Do not use unknown third-party IPAs as final success without verified provenance.
- Continue the build/log/patch loop autonomously until success or a real external blocker.
- If WASI linking still fails after explicit `lld` and one targeted repair, document the exact error before using `--without-wasm-sandboxed-libraries`.

## Progress

- [x] Goal objective read.
- [x] Root `AGENTS.md` read.
- [x] Root `PLANS.md` read.
- [x] CI-fix skill instructions read.
- [x] Latest workflow run and failed log inspected.
- [x] ExecPlan created.
- [x] First workflow patch applied for explicit Homebrew `lld` and `wasm-ld` lookup.
- [x] Workflow fix committed and pushed.
- [x] Workflow rerun started.
- [x] Workflow rerun completed with a new WASI runtime failure.
- [x] Second targeted WASI runtime patch applied.
- [x] Non-final run confirmed dependencies passed and reached `Build Gecko`.
- [x] Latest upstream `minh-ton/reynard-browser@main` merged.
- [x] Quick upstream/fork release audit completed; no clearly newer downloadable IPA was found.
- [x] Latest-main run `27994353614` completed Gecko and failed in Xcode archive signing.
- [x] Copy Gecko Stuff signing failure root cause identified.
- [x] Copy Gecko Stuff unsigned-archive fix committed and pushed as `49556ae`.
- [x] Unaccelerated rerun `28001189594` cancelled before another full Gecko rebuild.
- [x] Gecko build caching and checkpointing implemented and first rerun attempted.
- [x] Fast configure failure in run `28001837486` identified and patched.
- [x] Checkpointed workflow rerun succeeds through Gecko artifact upload.
- [x] IPA artifact downloaded and inspected.
- [x] Page Zoom architecture inspected.
- [x] Page Zoom implemented.
- [x] Final Page Zoom build and artifact verified.
- [x] Final outcome recorded.

## Surprises & Discoveries

- The latest failed run was still at commit `c0fa94f22fc8022ed632ef877917688578d9705a`, while local `main` has later AGENTS-only commits. The workflow bug remains in the current workflow file.
- Homebrew LLVM 22.1.7 on `macos-26` no longer provides `wasm-ld` under `/opt/homebrew/opt/llvm/bin`; Homebrew prints that LLD is a separate formula.
- Run `27993600431` proved the explicit `lld` patch worked: `command -v wasm-ld` returned `/opt/homebrew/opt/lld/bin/wasm-ld` and `wasm-ld --version` returned `Homebrew LLD 22.1.7`.
- The same run exposed the next WASI runtime dependency: `/opt/homebrew/opt/llvm/bin/clang --target=wasm32-unknown-wasi --sysroot=/opt/homebrew/share/wasi-sysroot /tmp/wasm-test.c -o /tmp/wasm-test.wasm` failed with `cannot open ... lib/wasm32-unknown-wasi/libclang_rt.builtins.a: No such file or directory`.
- Run `27993866717` passed `Install build dependencies`, `Update Gecko source`, `Apply Gecko patches`, `Build idevice FFI`, and `Force Gecko to use Xcode ld64`; it reached `Build Gecko` before being intentionally canceled because the fork had not yet merged latest upstream main.
- After `git fetch upstream main`, `upstream/main...HEAD` was `9 13`, proving the fork was missing nine upstream commits. The upstream head was `0fcee2c40f8629c50a9481419dfb9184c75c0236` (`Hide tab bar when in iPad 1/3 split screen`).
- `git merge upstream/main --no-edit` completed without conflicts and produced merge commit `6190269606d3c09e97b70db08a9f85ecaf1d861e`; `git merge-base --is-ancestor upstream/main HEAD` then confirmed upstream is contained in the fork.
- Run `27994353614` uses head SHA `b37d9a14ce07b3e01e65891cb8ab2e808e74984e`, which includes the upstream merge and the build-plan update. The job passed dependency installation, Gecko source checkout, patch application, idevice FFI, and ld64 patching, then remained in `Build Gecko` for more than two hours with no live logs exposed by `gh`.
- A quick GitHub release/fork audit found upstream releases only through `0.4.0`, and sampled recent forks did not expose newer release assets. No third-party IPA has better provenance than completing this fork's workflow.
- Run `27994353614` proved the Gecko build now completes, then failed in `Build Reynard app archive` after 3h6m47s. The first real archive error was in `PhaseScriptExecution Copy Gecko Stuff`: `Apple Development: no identity found`, followed by `Command PhaseScriptExecution failed with a nonzero exit code`.
- The failing script was `browser/Scripts/AddGecko.sh`. It used `SIGN_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:-${EXPANDED_CODE_SIGN_IDENTITY_NAME:-Apple Development}}"` and invoked `codesign` unconditionally, even though the workflow archive command passed `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""`.
- Run `28001189594` was started from commit `49556ae` but was cancelled at about 10m27s before entering a long Gecko rebuild. This preserves GitHub runner time while acceleration/checkpointing is added.
- Run `28001837486` validated the new workflow shape through dependency install, `actions/cache/restore`, Gecko source checkout, patches, idevice FFI, and ld64 detection patching. It failed quickly in `Build Gecko` configure before a long rebuild.
- The first real error in run `28001837486` was `mozbuild.configure.options.InvalidOptionError: MOZ_LINKER takes 0 values`. The generated `.mozconfig` already had `--enable-linker=ld64`; the problem was leaving the `MOZ_LINKER=ld64` environment variable visible to Firefox configure.
- Run `28038685786` validated the final Page Zoom build through the full split workflow. Gecko completed in about nine minutes after restoring sccache, the Gecko dist checkpoint was uploaded, the archive job consumed that checkpoint, and `Reynard-latest-main-ipa` uploaded successfully.

## Decision Log

- Decision: Install Homebrew `lld` explicitly and find `wasm-ld` through `command -v`.
  - Reason: The failing log proves `wasm-ld` is missing from the LLVM formula path, and Homebrew says to install `lld`.
  - Evidence: Run `27987957678`, `Install build dependencies`, `/opt/homebrew/opt/llvm/bin/wasm-ld: No such file or directory`.
  - Consequence: The workflow keeps Apple clang for iOS/macOS while exposing LLD only to WASM wrapper commands and the WASM link preflight.
- Decision: Install Homebrew `wasi-runtimes` and pass its resource dir through the WASM wrappers.
  - Reason: The next failed log shows `wasm-ld` is now available but clang lacks WASI Compiler-RT builtins. Homebrew describes `wasi-runtimes` as the Compiler-RT and libc++ runtimes for WASI.
  - Evidence: Run `27993600431`, `Install build dependencies`, `wasm-ld --version` succeeded, then clang failed opening `libclang_rt.builtins.a`.
  - Consequence: The next run is the one further targeted WASI repair allowed before falling back to `--without-wasm-sandboxed-libraries` if WASI still fails.
- Decision: Cancel run `27993866717` and merge upstream before continuing.
  - Reason: A successful artifact from that run would not have satisfied the latest-main requirement because upstream/main was not contained in the fork.
  - Evidence: `git rev-list --left-right --count upstream/main...HEAD` returned `9 13`.
  - Consequence: The next workflow run must use a merged commit after `6190269606d3c09e97b70db08a9f85ecaf1d861e`.
- Decision: Make `browser/Scripts/AddGecko.sh` skip Gecko artifact signing for unsigned archives.
  - Reason: The workflow intentionally builds an unsigned SideStore IPA and already passes Xcode signing suppression flags; the copy script must not invent `Apple Development` when no identity exists.
  - Evidence: Run `27994353614`, `Build Reynard app archive`, `Apple Development: no identity found`.
  - Consequence: Local signed Xcode builds can still sign Gecko artifacts when Xcode provides an identity, while CI unsigned archives can proceed to IPA packaging.
- Decision: Stop rerunning the monolithic workflow and add caching/checkpointing before the next build.
  - Reason: Run `27994353614` already proved the expensive Gecko compile passes; repeating it for every archive-stage failure creates a 2.5-3 hour feedback loop.
  - Evidence: Run `28001189594` was only about ten minutes old when cancelled, while `27994353614` spent roughly 2h53m in `Build Gecko` before the later archive failure.
  - Consequence: The next workflow run must include `sccache`, a saved Gecko dist checkpoint, and an archive job/path that can retry IPA packaging without rebuilding Gecko.
- Decision: Consume and unset `MOZ_LINKER` inside `tools/development/build-gecko.sh`.
  - Reason: The script needs `MOZ_LINKER` to write durable `.mozconfig`, but Firefox configure rejects the environment variable when it remains set.
  - Evidence: Run `28001837486`, `Build Gecko`, `InvalidOptionError: MOZ_LINKER takes 0 values`.
  - Consequence: The workflow can still set `MOZ_LINKER=ld64`, while `mach build` only sees the supported `--enable-linker=ld64` configure option.
- Decision: Reuse the Gecko checkpoint from run `28002185987` and repair archive checkpoint inspection only.
  - Reason: Run `28002185987` completed `Build Gecko checkpoint` and uploaded `gecko-dist-aarch64-apple-ios`; rebuilding Gecko would waste the artifact and reintroduce the slow feedback loop.
  - Evidence: The archive job downloaded the checkpoint, `engine/firefox/obj-aarch64-apple-ios/dist/bin` existed, `engine/firefox/toolkit/mozapps/extensions/default-theme` existed, and `du -sh engine/firefox/obj-aarch64-apple-ios/dist` reported about `414M`.
  - Evidence: First-run `sccache` was cold/low-value: restore missed, post-build `sccache -s` showed `Cache hits 0`, `Cache misses 4716`, and the cache directory was about `2.7G`.
  - Evidence: The archive job then failed after the nonessential diagnostic listing `find engine/firefox/obj-aarch64-apple-ios/dist -maxdepth 2 | head -100` under `set -euo pipefail`.
  - Consequence: The next action is an archive-only rerun from `run_id=28002185987` after making the diagnostic listing pipefail-safe; Page Zoom remains deferred until the baseline IPA artifact is verified.

## Build Acceleration Objective

Baseline timing evidence:

- Run `27994353614`: total job time was 3h6m52s.
- `Build Gecko` started at `2026-06-23T01:01:27Z`; `Build Reynard app archive` started at `2026-06-23T03:54:26Z`, so the successful Gecko step took about 2h53m wall time on the free `macos-26` runner.
- The first post-Gecko failure was archive-stage signing in `browser/Scripts/AddGecko.sh`, proving archive and IPA debugging should not require another full Gecko compile.
- Run `28001189594` was cancelled at about 10m27s before the long Gecko build repeated.

macOS-only stages:

- Final `xcodebuild archive`, iPhoneOS SDK usage, `xcrun`, app-extension validation, `ldid` IPA packaging, and all direct use of Xcode must stay on a macOS runner.
- Gecko iOS target compilation currently depends on Apple/Xcode clang for host/target paths and must remain on macOS unless a separate toolchain experiment proves otherwise.

Cacheable/checkpointable stages:

- Gecko C/C++/Rust object compilation can use local `sccache` on the macOS runner.
- The `sccache` directory is capped at `8G` and keyed by runner OS/arch, `engine/release.txt`, the workflow file, `tools/development/build-gecko.sh`, and patch hashes.
- `engine/firefox/obj-aarch64-apple-ios/dist` plus `engine/firefox/toolkit/mozapps/extensions/default-theme` is uploaded as short-retention artifact `gecko-dist-aarch64-apple-ios` after a successful Gecko build.

WSL2 feasibility:

- The user's ThinkPad has i7-12800H, 14 cores / 20 logical processors, 64 GB RAM, and NVMe SSD, so it is a strong candidate for a Linux `sccache-dist` worker for compatible compile actions.
- WSL2 must not run Xcode, iPhoneOS SDK, `xcrun`, signing, or IPA packaging.
- WSL2 distributed compilation is not considered working until `sccache --dist-status` and `sccache -s` show useful distributed compilations. If distributed compilations remain zero, WSL acceleration has not worked.
- Tailscale or equivalent network setup would require user-provided credentials/secrets. Exact likely GitHub secrets, if pursued later, are `SCCACHE_DIST_AUTH_TOKEN`, `TAILSCALE_AUTHKEY`, and a server address/port value such as `SCCACHE_DIST_SCHEDULER_URL`; these are not guessed or added in this pass.

Exact workflow/script changes:

- `tools/development/build-gecko.sh` now honors `MOZ_BUILD_JOBS`, `MOZ_LINKER`, `WASI_SYSROOT`, and executable `SCCACHE_BIN`, writes matching `.mozconfig` options, runs `./mach build -j "$MOZ_BUILD_JOBS"`, and prints `sccache -s` before/after.
- `.github/workflows/build-latest-reynard-ipa.yml` is split into `build-gecko` and `archive-ipa` jobs.
- `build-gecko` installs `sccache`, restores/saves `.sccache`, builds Gecko, records cache size/statistics, and uploads `gecko-dist-aarch64-apple-ios`.
- `archive-ipa` downloads `gecko-dist-aarch64-apple-ios`, rebuilds idevice FFI, archives with `REYNARD_UNSIGNED_ARCHIVE=1`, creates/verifies the IPA, and uploads `Reynard-latest-main-ipa`.
- `.github/workflows/archive-reynard-ipa-from-gecko-dist.yml` is a manual archive-only diagnostic workflow with a required `run_id` input that downloads a prior Gecko checkpoint artifact.

Validation commands:

```powershell
bash -n tools/development/build-gecko.sh
bash -n tools/release/build-app.sh
bash -n browser/Scripts/AddGecko.sh
git diff --check
gh workflow run "Build Latest Reynard IPA" --repo lowestprime/reynard-browser --ref main
gh run watch <RUN_ID> --repo lowestprime/reynard-browser
gh run view <RUN_ID> --repo lowestprime/reynard-browser --log-failed
gh run download <RUN_ID> --repo lowestprime/reynard-browser --name gecko-dist-aarch64-apple-ios --dir "$env:USERPROFILE\Desktop\reynard-gecko-dist-latest"
gh workflow run "Archive Reynard IPA From Gecko Dist" --repo lowestprime/reynard-browser --ref main -f run_id=<RUN_ID>
```

Rollback path:

- If `sccache` breaks configure/build, remove the `CCACHE=$SCCACHE_BIN` `.mozconfig` option and keep the split checkpoint artifact.
- If the Gecko dist artifact is too large or incomplete, keep local `sccache` and temporarily merge the archive job back into the Gecko job while recording the artifact size/failure.
- If archive-only download cannot find the run artifact, rerun the main checkpoint workflow once to produce a fresh `gecko-dist-aarch64-apple-ios` artifact and use that run ID.
- If cache restore/save causes eviction/thrashing, reduce `SCCACHE_CACHE_SIZE` below `8G` or narrow restore keys; do not cache the full Firefox object directory without measured size evidence.

## Feature-Complete UX Batch After Page Zoom Release

Historical purpose: continue from the verified Page Zoom prerelease and add the next native UX/functionality batch. The previous prerelease remains immutable evidence for the Page Zoom baseline. The former upstream pull request is now closed and is not an active delivery path.

Current verified source state:

- Local branch: `main`, tracking `origin/main`.
- Upstream PR: `https://github.com/minh-ton/reynard-browser/pull/153`.
- PR source: `lowestprime:main`.
- PR base: `minh-ton:main`.
- PR state checked after release: open, non-draft, mergeable.
- Local `HEAD`: `6f2a03d44c51bd36cc7a836dbd94a5ee33559392` (`docs: record verified Page Zoom IPA build`).
- Verified app-code release commit: `ac7c446aa4a8831579945e4d4cb49a33ce8cf670`.
- Verified release: `https://github.com/lowestprime/reynard-browser/releases/tag/reynard-page-zoom-2026-06-23`.
- Verified run: `28038685786`.
- Verified artifact: `Reynard-latest-main-ipa`.
- Verified local IPA: `C:\Users\Cooper\Downloads\Reynard-latest-main-28038685786\Reynard.ipa`.
- Verified SHA-256: `5ee4c3d7259ca22c7b1ce61c072da2a67c328b32137c24e58c02adae9c573291`.

Feature classification:

- A. Page Zoom refinement: native-app UI/settings logic unless new Gecko behavior is discovered. Expected build path: archive-only using the `gecko-dist-aarch64-apple-ios` checkpoint from run `28038685786`.
- B. Keyboard/page-content behavior: native UIKit/GeckoView layout and lifecycle logic unless focused-input geometry from Gecko is required. Expected build path: archive-only.
- C. Background/session preservation and stability: native lifecycle/session/preferences/JIT-state handling with manual physical-device validation for OS/JIT behavior. Expected build path: archive-only.
- D. Bookmark/history import/export/sync: native app data/storage/UI work. Real Firefox Sync is out of scope unless existing account/protocol support is discovered. Expected build path: archive-only.
- E. Address bar autocomplete: native address bar suggestions sourced from local bookmarks/history/open tabs/common URL parsing/search fallback. Expected build path: archive-only.
- F. OLED jet-black theme and accent customization: native settings/theme/accent/resource work. Expected build path: archive-only.

Progress for this continuation:

- [x] New goal objective file read.
- [x] Root `AGENTS.md` reread.
- [x] Root `PLANS.md` reread.
- [x] Existing ExecPlan reread.
- [x] Local branch and upstream PR source checked.
- [x] Existing Page Zoom, keyboard, lifecycle/session, bookmark/history, address bar, and theme code inspected.
- [x] Page Zoom slider refinement implemented.
- [x] Keyboard/page-content behavior improved.
- [x] Background/session preservation improvements implemented.
- [x] Bookmark/history import/export entry points implemented or documented where unsupported.
- [x] Address bar autocomplete implemented.
- [x] OLED black theme and accent customization implemented.
- [x] Local static checks passed.
- [x] Archive-only workflow run completed using an existing Gecko checkpoint, or exact evidence recorded for why a full checkpoint run was required.
- [x] New IPA downloaded and verified.
- [x] New fork prerelease published without overwriting `reynard-page-zoom-2026-06-23`.
- [x] Historical upstream PR state recorded. The PR is now closed; no reopen, replacement PR, comment, review request, or upstream merge action is permitted.

Implemented native-only changes in this continuation:

- Page Zoom: the address-bar page menu now opens a persistent Page Zoom sheet with a slider, zoom out, reset, zoom in, live percent display, and live `GeckoSessionSettings` refresh. Slider mapping/clamping is centralized in `PageZoomLevel`.
- Keyboard/page content: focused-input relocation clamps Gecko focused-input ratios and uses actual keyboard/content intersection, avoiding unnecessary shifts for non-overlapping/floating keyboard frames.
- Background/session preservation: app and scene lifecycle notifications now capture the visible tab thumbnail, flush tab/session state, reactivate the selected Gecko session, refresh chrome/navigation state, and reapply page zoom on foreground.
- Bookmark/history transfer: bookmarks can be imported from Firefox/Netscape-style HTML and exported to HTML; history can be imported/exported as local CSV with privacy confirmations. This is local transfer only and does not claim Firefox Sync.
- Address bar autocomplete: suggestions now always include local common-domain/URL fallback completions, search-engine suggestions are opt-in in Search settings and debounced, and private browsing no longer surfaces regular history matches.
- Appearance: Appearance settings now include theme mode, OLED Black, and accent color choices; app windows/chrome/settings/library surfaces apply the selected theme/accent without restart.

Archive-only validation attempt:

- Run `28058053384` used archive-only workflow `Archive Reynard IPA From Gecko Dist` at commit `7fe5048ecbbbe89873970a144aed0d7e07de53c3` with Gecko checkpoint run `28038685786`.
- The checkpoint path was proven: checkout, archive dependency install, Gecko dist artifact download, checkpoint inspection, and idevice FFI all succeeded without a Gecko rebuild.
- The archive failed in `Build Reynard app archive` with Xcode exit `65`.
- First real source error: `ContentView.swift:184` attempted to call `min(max(bottomRatio, 0), 1)` where `GeckoSession.focusedInputBottomRatio()` returns `CGFloat?`.
- Fix: handle `nil` focused-input geometry by clearing/resetting focused-input relocation, then clamp only non-optional ratios.
- Repeated local validation after the fix: `git diff --check`, `bash -n tools/development/build-gecko.sh`, `bash -n tools/release/build-app.sh`, and `bash -n browser/Scripts/AddGecko.sh` all returned zero.

Final feature-complete UX IPA validation:

- Final commit: `240928640a1adbab8f9353cc07f35563f10a922b` (`fix(app): handle missing focused input metrics`).
- Successful archive-only workflow run: `28058553866`, `https://github.com/lowestprime/reynard-browser/actions/runs/28058553866`.
- Run result: success in `4m26s`.
- Reused Gecko checkpoint: `gecko-dist-aarch64-apple-ios` from run `28038685786`.
- Archive job source checkout: `240928640a1adbab8f9353cc07f35563f10a922b`.
- Uploaded artifact: `Reynard-latest-main-ipa`.
- Local downloaded IPA: `C:\Users\Cooper\Downloads\Reynard-latest-main-28058553866\Reynard.ipa`.
- Local IPA size: `109647473` bytes.
- Local IPA SHA-256: `6c73eb30b8307f82768ad13a20b169ea2ab334e5fea8d37d731d7b2b47593961`.
- `unzip -tq` passed with no compressed-data errors.
- ZIP inspection found `3032` entries and `0` duplicate paths.
- Required packaged entries were present:
  - `Payload/Reynard.app/Reynard`
  - `Payload/Reynard.app/PlugIns/Reynard Helper.appex/Info.plist`
  - `Payload/Reynard.app/PlugIns/OpenIn.appex/Info.plist`
  - `Payload/Reynard.app/Frameworks/GeckoView.framework/GeckoView`
- `CFBundleVersion` was `2409286` for the main app, `Reynard Helper.appex`, and `OpenIn.appex`; `CFBundleShortVersionString` was `0.4.0`.
- Main app, helper extension, OpenIn extension, and GeckoView binaries had Mach-O 64-bit little-endian headers.
- Feature string scan found `Page Zoom`, `Zoom Out`, `Zoom In`, `Reset`, `OLED Black`, `Search Suggestions`, `Local Suggestions`, `Import Bookmarks`, `Export Bookmarks`, `Site override`, `Firefox/Netscape`, and `Reynard-History.csv`. `Import History` and `Export History` did not appear as plain UTF-8/UTF-16 byte strings even though the history CSV code path compiled and the history CSV filename was present.
- New fork prerelease: `https://github.com/lowestprime/reynard-browser/releases/tag/reynard-feature-complete-ux-2026-06-23`.
- Release assets:
  - `Reynard.ipa`, size `109647473`, digest `sha256:6c73eb30b8307f82768ad13a20b169ea2ab334e5fea8d37d731d7b2b47593961`.
  - `Reynard.ipa.sha256`, size `77`, digest `sha256:55dfcce7e25e8b0df1adf1b4467c1c18ca19cd0a2301a31c02466148e2f95fff`.
- Upstream PR `https://github.com/minh-ton/reynard-browser/pull/153` remains open, non-draft, and mergeable with head `240928640a1adbab8f9353cc07f35563f10a922b`.

Build strategy:

- Avoid Gecko edits for this batch unless inspection proves they are necessary.
- Reuse a valid `gecko-dist-aarch64-apple-ios` artifact from run `28038685786` through the archive-only workflow for native-only changes.
- If that checkpoint is expired or unavailable, record the exact artifact lookup/download failure and run the checkpointed full workflow once.
- Do not leave a long full Gecko build running as passive polling work; if a long build is unavoidable, record a handoff in this ExecPlan.

Validation gates for this continuation:

- `git diff --check`.
- `bash -n tools/development/build-gecko.sh`.
- `bash -n tools/release/build-app.sh`.
- `bash -n browser/Scripts/AddGecko.sh`.
- YAML parse checks for workflow files if changed.
- `git -C engine/firefox apply --check <patch>` only if a Gecko patch changes.
- GitHub Actions archive/build run.
- Download produced `Reynard.ipa`.
- `unzip -tq` on the IPA.
- Verify main app, `Reynard Helper.appex`, `OpenIn.appex`, and `GeckoView.framework/GeckoView` are packaged.
- Verify feature strings/symbols for new UI where possible.
- Verify main app and extension build versions match the expected short SHA.
- Record new IPA SHA-256.

Manual physical-device validation that must not be claimed without evidence:

- Install the new unsigned IPA through the intended sideload flow.
- Page Zoom slider and plus/minus controls at 75%, 100%, 150%, and 200%.
- Focus text inputs, textareas, contenteditable fields, and forms with the keyboard visible at 75%, 100%, 150%, and 200%.
- Background app for 1 minute and return.
- Background app for 10+ minutes and return.
- Switch between several tabs after resume.
- Resume with JIT disabled.
- Resume with JIT previously enabled.
- Low-memory or forced relaunch if testable.
- Verify pages, tabs, zoom, theme/accent, and navigation state remain stable.

## Keyboard Obstruction Regression Fix

Purpose: repair the remaining real-device regression where bottom-fixed page composers and focused page inputs can stay hidden behind the iOS keyboard and Reynard bottom chrome on the latest feature-complete IPA. This is a targeted native-only continuation; Page Zoom, bookmark/history transfer, autocomplete, theme work, and release plumbing should not be reimplemented except where validation requires it.

User evidence to preserve:

- `https://chatgpt.com`: the ChatGPT input composer/page content remains partly hidden behind the iOS keyboard and/or bottom browser chrome when the keyboard opens.
- `https://gemini.google.com`: the Gemini bottom composer is visible with the keyboard closed, but keyboard open leaves page composer/content obscured instead of repositioned into the visible viewport.
- This affects bottom-fixed modern web-app composers, not only ordinary scrollable form fields.
- The prior focused-input relocation batch is incomplete because it depends on Gecko focused-input geometry and resets when that geometry is nil.

Current inspected implementation:

- `BrowserViewController.keyboardFrameWillChange(_:)` computes keyboard overlap and only calls `ContentView.relocateFocusedInput(above:)` for page keyboard events.
- `ContentView.relocateFocusedInput(above:)` asks Gecko for `focusedInputBottomRatio()` and translates the content with `focusedInputOffset` when a focused editable metric exists.
- If Gecko returns nil focused-input geometry, `ContentView` resets focused-input relocation, so bottom-fixed SPA composers get no fallback.
- The normal phone content bottom is anchored to `browserChrome.bottomToolbarTopAnchor`; when the software keyboard covers the bottom of the app, that anchor can still sit underneath the keyboard, leaving the Gecko viewport too tall for bottom-fixed page UI.

Fix design:

- Keep the change native-only so the archive-only workflow can reuse Gecko checkpoint run `28038685786`.
- Add a real page viewport bottom inset to `ContentView` and drive it from the actual intersection between the root view, current content view frame, and keyboard frame.
- Treat focused-input metrics as a secondary correction. Values above `1.0` are allowed because Gecko's patch reports a viewport-relative bottom ratio up to `2.0`; values above `1.0` mean the focused editable is below the currently visible viewport.
- Keep native address bar/search keyboard behavior separate: when the native address bar is focused, reset page keyboard avoidance and keep docking the address bar above the keyboard.
- Recompute keyboard avoidance on keyboard show/hide/frame changes, layout changes, foreground restore, and Page Zoom preference changes.

Manual test checklist for the fixed IPA:

- Gemini keyboard closed: bottom composer visible.
- Gemini keyboard open: composer remains above keyboard and bottom chrome.
- ChatGPT keyboard open: composer remains above keyboard and bottom chrome.
- Repeat at 75%, 100%, 150%, and 200% page zoom.
- Rotate device if feasible.
- Background/foreground after keyboard use.
- JIT disabled.
- JIT previously enabled if available.
- Native address bar editing still works.
- Autocomplete overlay still works.
- Page Zoom sheet stays open while pressing plus/minus or moving the slider.

Implementation outcome:

- Keyboard fix commit: `9a0fd763b7b1a88cabca93e75cd47411798bc6bd` (`fix(app): avoid keyboard-obscured page composers`).
- Native-only code changes:
  - `browser/Reynard/Client/Interface/BrowserViewController.swift` now computes keyboard avoidance from the root view, safe-area bottom inset, keyboard frame, and a pre-avoidance content reference frame.
  - `browser/Reynard/Client/Interface/ContentView/ContentView.swift` now applies a real page viewport bottom inset before using Gecko focused-input metrics as a secondary correction.
- Local validation:
  - `git diff --check` passed.
  - `bash -n tools/development/build-gecko.sh` passed.
  - `bash -n tools/release/build-app.sh` passed.
  - `bash -n browser/Scripts/AddGecko.sh` passed.
  - `swift` and `xcodebuild` were unavailable on the Windows host, so Swift compilation was validated by GitHub Actions.
- Archive-only workflow run: `28077200523`, `https://github.com/lowestprime/reynard-browser/actions/runs/28077200523`.
- Run result: success in `7m46s`.
- Reused Gecko checkpoint: `gecko-dist-aarch64-apple-ios` from run `28038685786`; no full Gecko rebuild was triggered.
- Uploaded artifact: `Reynard-latest-main-ipa`.
- Local downloaded IPA: `C:\Users\Cooper\Downloads\Reynard-latest-main-28077200523\Reynard.ipa`.
- Local IPA size: `109647702` bytes.
- Local IPA SHA-256: `a9e6f147312444cb1c834913f6fe9b71716690d49fc15ef085235c7cdb65c972`.
- `unzip -tq` passed with no compressed-data errors.
- ZIP/plist/Mach-O inspection found `3032` entries, `0` duplicate paths, required app/extensions/GeckoView entries, `CFBundleVersion` `9a0fd76` for the main app and extensions, and arm64 Mach-O headers.
- Marker scan found Page Zoom, OLED Black, search/local suggestions, bookmark import/export, history CSV, and the new `pageViewportBottomInset` symbol marker.
- New fork prerelease: `https://github.com/lowestprime/reynard-browser/releases/tag/reynard-keyboard-avoidance-fix-2026-06-24`.
- Release assets:
  - `Reynard.ipa`, size `109647702`, digest `sha256:a9e6f147312444cb1c834913f6fe9b71716690d49fc15ef085235c7cdb65c972`.
  - `Reynard.ipa.sha256`, size `77`, digest `sha256:5d76a1c74da7b43a211a746cc59d4d28ababd5eae9f21003b6137ec294083a22`.
- Upstream PR `https://github.com/minh-ton/reynard-browser/pull/153` remained open, non-draft, and mergeable when inspected after pushing the keyboard fix.
- Remaining unknown: real iPhone ChatGPT/Gemini keyboard behavior is not claimed fixed until the user installs this IPA and manually verifies the checklist above.

## Custom Accent Color Follow-Up

Purpose: add full user-selectable accent color customization on top of the verified keyboard-fix release without touching Gecko or rebuilding Gecko.

Baseline:

- Keyboard-fix app-code commit: `9a0fd763b7b1a88cabca93e75cd47411798bc6bd`.
- Release-record head before this work: `9f5a19a85c8da45b306033166ec580eb49f36e4b`.
- Keyboard-fix prerelease: `reynard-keyboard-avoidance-fix-2026-06-24`.
- Successful archive-only run: `28077200523`.
- Parent PR `https://github.com/minh-ton/reynard-browser/pull/153` was open, non-draft, mergeable, and sourced from `lowestprime:main`.

Target behavior:

- Preserve preset accents: High Contrast, Blue, Orange, Green, and Purple.
- Add a Custom accent row with a visible square preview and current hex value.
- Support native `UIColorPickerViewController` on iOS 14+ with alpha disabled.
- Support manual hex entry for `#RRGGBB` and `RRGGBB`.
- Persist both the selected accent mode and custom hex color.
- Apply custom accent immediately through existing `BrowserAppearance.accentColor` consumers.
- Reject invalid, transparent, or low-contrast custom colors with user-visible feedback while keeping High Contrast available as a fallback.

Implementation plan:

- Extend `BrowserAccentColor` with a `custom` case, preset list, normalized custom hex helper, and lightweight contrast validation against light, dark, and OLED Black backgrounds.
- Add `Prefs.AppearanceSettings.customAccentHex` with default `#007AFF`.
- Update `AppearancePreferencesViewController` to show preset rows plus a Custom row, present the system color picker where available, present a hex entry alert, and reload immediately after custom changes.
- Keep this native-only and validate with the archive-only workflow using Gecko checkpoint run `28038685786`.

Implementation outcome:

- Custom accent app-code commit: `e3c2624e4b9628e2f042aebd8adeb22012779a31` (`feat(app): add custom accent colors`).
- Files changed:
  - `browser/Reynard/Client/Interface/Appearance/BrowserAppearance.swift`
  - `browser/Reynard/Client/Preferences/BrowserPreferences.swift`
  - `browser/Reynard/Client/Interface/Library/Settings/Sections/General/Appearance/AppearancePreferencesViewController.swift`
- Local validation:
  - `git diff --check` passed.
  - `bash -n tools/development/build-gecko.sh` passed.
  - `bash -n tools/release/build-app.sh` passed.
  - `bash -n browser/Scripts/AddGecko.sh` passed.
- Archive-only workflow run: `28080748345`, `https://github.com/lowestprime/reynard-browser/actions/runs/28080748345`.
- Run result: success in `7m37s`.
- Reused Gecko checkpoint: `gecko-dist-aarch64-apple-ios` from run `28038685786`; no full Gecko rebuild was triggered.
- Uploaded artifact: `Reynard-latest-main-ipa`.
- Local downloaded IPA: `C:\Users\Cooper\Downloads\Reynard-latest-main-28080748345\Reynard.ipa`.
- Local IPA size: `109652723` bytes.
- Local IPA SHA-256: `c53caab3fe6d857b7c9a0328d70290b0df2e35f707ec869505853cbe82dcae46`.
- `unzip -tq` passed with no compressed-data errors.
- ZIP/plist/Mach-O inspection found `3032` entries, `0` duplicate paths, required app/extensions/GeckoView entries, `CFBundleVersion` `e3c2624` for the main app and extensions, and arm64 Mach-O headers.
- Marker scan found `Custom`, `Custom Accent`, `Custom Accent Hex`, `Choose Custom Color`, `#RRGGBB`, `Invalid Accent Color`, all preset accent names, `customAccent`, `AppearanceSettings`, `OLED Black`, and `Page Zoom`.
- New fork prerelease: `https://github.com/lowestprime/reynard-browser/releases/tag/reynard-custom-accent-color-2026-06-24`.
- Release assets:
  - `Reynard.ipa`, size `109652723`, digest `sha256:c53caab3fe6d857b7c9a0328d70290b0df2e35f707ec869505853cbe82dcae46`.
  - `Reynard.ipa.sha256`, size `77`, digest `sha256:bdb475a409e2dfdbdba2e6feafb7c6594eb57d5d07255f6fc03cb55a20b495f8`.
- Remaining manual validation: install the IPA on iPhone and check Appearance > Accent presets plus Custom, picker, hex entry, persistence, theme coverage, Page Zoom, and the keyboard fix.

## Background Resume Black Tab Regression Fix

Purpose: fix a high-priority native lifecycle regression where returning to Reynard after using other apps can leave tabs black, non-interactive, or missing. This is a native resume/session-state repair only; Page Zoom remains implemented and must be preserved, and no Gecko rebuild should be triggered unless the archive-only path proves insufficient.

Regression evidence and current state:

- Parent PR `https://github.com/minh-ton/reynard-browser/pull/153` is still open, non-draft, mergeable, and sourced from `lowestprime:main`.
- Current fork head before this fix is `2aaa124ead814b9dbd9466bedd527127a04f4c06`, which records the custom accent IPA release.
- Existing lifecycle hooks save tab state on scene/app resign active, background, memory warning, and termination, but the tab store writes normal state asynchronously.
- `SceneDelegate.sceneDidDisconnect` does not flush browser state.
- Foreground restore currently reactivates the selected Gecko session and reapplies chrome, Page Zoom, layout, and keyboard avoidance, but it does not distinguish a closed/crashed/detached/non-renderable session from a healthy session.
- `TabManagerImplementation.onCrash` and `onKill` currently remove the crashed/killed tab, matching the reported "lost tabs" failure mode.
- JIT can remain volatile across backgrounding; this fix must keep non-JIT browsing usable by replacing or reloading broken tab sessions from persisted URLs instead of leaving black content.

Targeted implementation:

- Make lifecycle tab-state flushes synchronous so the last selected-tab and open-tab snapshot is durable before iOS background suspension.
- Save on scene disconnect in addition to existing app and scene lifecycle notifications.
- Preserve tabs on Gecko crash/kill by replacing the tab's Gecko session in place, keeping the tab ID, URL, title, privacy mode, navigation history, Page Zoom/site settings, and UI selection.
- On foreground, ensure the selected tab exists, has an open Gecko session, is activated, is attached to the visible content view, and has page settings reapplied.
- If the selected content view is detached, zero-sized, hidden, or non-interactive after foreground layout, reattach it; if it still cannot render, replace the selected session once from the persisted URL as a conservative black-tab recovery path.
- Reapply theme/accent, Page Zoom, keyboard avoidance, and browser layout after recovery.

Validation plan:

- Run `git diff --check`.
- Run `bash -n tools/development/build-gecko.sh`.
- Run `bash -n tools/release/build-app.sh`.
- Run `bash -n browser/Scripts/AddGecko.sh`.
- Use the archive-only workflow with the existing valid Gecko checkpoint, download the IPA, run `unzip -tq`, verify app/extensions/GeckoView entries, confirm `CFBundleVersion` equals the short app commit SHA, and calculate SHA-256.
- Publish a fork prerelease for the background resume fix. The historical upstream PR is closed and requires no further action.
- Manual device validation remains required for long iOS 26.6 background/resume behavior, JIT enabled/disabled behavior, and true black-frame compositor recovery on a physical iPhone.

## Fork-Only Upstream 0.5.0 Sync and Google Docs Compatibility

This section supersedes earlier references to an upstream merge path. Work from this point forward is fork-only. Parent pull request `minh-ton/reynard-browser#153` is closed and must not be reopened, replaced, commented on, reviewed, or merged.

### Upstream release evidence

- Official release: tag `0.5.0`, release name `0.5.0 alpha`, published `2026-06-28T14:21:07Z`.
- Release URL: `https://github.com/minh-ton/reynard-browser/releases/tag/0.5.0`.
- Release API target: `main`; annotated tag resolves to commit `b0eef93f551949bf094e3f783e318d0513bdea45` (`Bump version to 0.5.0`).
- Full compare `0.4.0...0.5.0`: `118` commits and `677` files changed with `58,065` insertions and `22,511` deletions. The compare base is `63836c3e4b19924f77d01bc99e612abf75157712` (`Bump version to 0.4.0`).
- Release assets:
  - `Reynard-Jailbroken.ipa`, `107,753,796` bytes, SHA-256 `5c9f28ee6b9939ec1088812d35d67187e378bfef2ecb3382702894345e01c2f5`.
  - `Reynard-TrollStore.tipa`, `107,753,796` bytes, SHA-256 `5c9f28ee6b9939ec1088812d35d67187e378bfef2ecb3382702894345e01c2f5`.
  - `Reynard.ipa`, `107,730,428` bytes, SHA-256 `154b0dc9dc2a9c206ef5d4d52407cea5f21dd4de73000705a631c3ed23bec494`.
- Release notes add WebRTC, W3C touch events, Vietnamese input, iOS 27 JIT enablement, text selection/copying, ProMotion/adaptive refresh, Gecko-backed Page Zoom, camera/microphone/location/motion permissions, autoplay controls, search suggestions and local bookmark/history suggestions, a configurable Homepage, Clear Browsing Data, and expanded settings.
- Release fixes include iPad split-screen layout, tab switching/deletion/new-tab behavior, DDI/JIT stability for iOS 26+, network transition recovery, add-on popup transfer, rich-text clipboard encoding, inherited website mode for previews, new-tab content display, favorite-folder moves, and multiple tab bar/history/fullscreen/address-bar UI defects.
- Engine: `FIREFOX_152_0_2_RELEASE` at Firefox commit `e784efd49da7cd69805f55f3353b65ff430441a1`.

Major compare commits relevant to this fork:

- `1e9b510` adds web-content text selection.
- `9f10393` adds camera/microphone and WebRTC support.
- `cb6d029` fixes rich-text clipboard HTML encoding.
- `a2449cf` fixes redirect links opened in new tabs.
- `a400fb9` adds Vietnamese input and older-iOS selection cleanup.
- `fbef9ce`, `c1010c8`, and `ad864ae` repair JIT memory, notification, iOS 26/27 TXM, and writable-alias behavior.
- `17538a3`, `495583f`, and `4ced63b` add and stabilize provider/history/bookmark/tab address-bar suggestions and domain completion.
- `6e1255b` performs the large maintainability refactor that the custom code must now target.
- `668b0b0` adds CADisplayLink Vsync; `5f2fdad` adds network-change detection; `75eca8f` adds content-process prelaunch.
- `573968d` moves the engine and patch set to Firefox `152.0.2`.
- `366d9de` repairs focused-input keyboard relocation after the engine update.
- `750824c` plus `03047a0` implement upstream Page Zoom UI, persistence, session settings, and Gecko patches.
- `b0eef93` sets version `0.5.0`.

### Chosen upstream base

- `upstream/main` is selected at `43de07bcd904a30682a2de2540a0a09e8019f65d`.
- It is exactly one commit ahead of tag `0.5.0`: `43de07b Remove outdated JIT enablement instruction and update TrollStore build installation notice to match the latest release`.
- Reason: the commit contains current installation/JIT guidance, no destabilizing app or engine change, and satisfies the requirement to synchronize with the latest parent state while retaining the official `0.5.0` code as the application baseline.
- Clean fork branch: `fork/0.5.0-custom-sideload`, created directly from `upstream/main`. Historical fork branch `main` remains at `03ded2a9cd2dcd0dbfdda696b86d3a02c399d47e` and must not be deleted.
- The new base changes `engine/release.txt`, the Firefox gitlink, and the patch tree relative to the historical fork, so pre-0.5.0 Gecko checkpoint artifacts are not ABI/input-equivalent and cannot be reused for the final build.

### Functional-equivalence review

| Custom feature/change | Files/commits in historical fork | Upstream 0.5.0/main equivalent? | Keep / drop / partially port | Reason | Validation method |
| --- | --- | --- | --- | --- | --- |
| Checkpointed unsigned IPA CI | `7eef535` through `5f2bfd4`; `.github/workflows/build-latest-reynard-ipa.yml`, archive-only workflow, `tools/`, `AddGecko.sh` | No; upstream only has `update_source.yml` | Keep | Required for repeatable unsigned SideStore builds, sccache, Gecko dist checkpointing, archive-only diagnostics, and release verification | YAML parse, shell syntax, full split workflow, artifact verification |
| Page Zoom core and UI | `ac7c446`, `7fe5048`; old Page Zoom controls/store/patch | Yes for Gecko `fullZoom`, per-site SQLite settings, global default, plus/minus/reset, percentage, and persistent action bar; no slider | Partially port | Prefer upstream's newer integrated storage/session/action-bar design; add only the missing persistent slider behavior | Xcode build, IPA markers, manual slider/step/reset/persistence checks |
| Keyboard avoidance | `2409286`, `9a0fd76`; `BrowserViewController.swift`, `ContentView.swift` | Partial; upstream has focused-input geometry relocation but returns to zero when metrics are unavailable | Partially port | Keep upstream's engine-era fix and add the real viewport-bottom inset fallback for bottom-fixed ChatGPT/Gemini/Docs editors | Xcode build and physical keyboard/zoom/rotation checks |
| Background resume and black-tab recovery | `03ded2a`; scene, browser, tab manager/store, content host files | No; scene lifecycle callbacks are empty and upstream `onCrash`/`onKill` remove tabs | Keep, adapted | Prevent state loss and replace broken sessions in place while preserving the 0.5.0 tab/homepage refactor | Xcode build, IPA markers, background/JIT/non-JIT physical checks |
| Bookmark/history import/export | `7fe5048`; `BrowsingDataTransfer.swift`, bookmark/history controllers and stores | No import/export implementation found | Keep, adapted | User-owned HTML/CSV transfer remains unique fork functionality | Xcode build, marker scan, round-trip/manual privacy confirmation checks |
| Address-bar autocomplete | `7fe5048`, `2409286`; search view model, local completion, user data search, search prefs | Partial and mostly superseded; upstream has provider choice, bookmarks/history/open tabs, domain completion, and settings, but still queries eagerly and exposes regular history in private mode | Partially port | Retain upstream ranking/UI/provider architecture; add local common-domain fallback, debounce/opt-in remote calls, and private-history filtering only | Xcode build, search behavior and network opt-in/manual private-mode checks |
| OLED Black and accent customization | `e3c2624`; `BrowserAppearance.swift`, appearance preferences/prefs | Partial; upstream has system/light/dark appearance but no OLED or accent selection | Keep, adapted | Extend upstream `AppAppearanceController` instead of restoring the older parallel appearance stack | Xcode build, IPA markers, immediate/persistence/manual contrast checks |
| Supporting preferences/lifecycle/notifications | `7fe5048`, `03ded2a`, `e3c2624` | Partial | Partially port | Add only keys and hooks required by retained behavior and Google Docs; do not duplicate upstream 0.5.0 settings | Compile, marker scan, persistence/manual checks |

### Google Docs compatibility design

- Implement this as native-only session configuration unless build evidence proves a Gecko patch is necessary.
- Extend `UserAgentPolicy` with an exact/subdomain `docs.google.com` compatibility rule that returns the existing desktop Firefox/Linux UA and allows desktop viewport mode.
- Add `Prefs.CompatibilitySettings.useGoogleDocsDesktopCompatibility`, registered `true` by default, and a switch titled `Use desktop compatibility for Google Docs` in Compatibility settings.
- The host rule is evaluated every time `SessionSettingsManager` creates settings for a URL, so navigation, new tabs, reloads, and restored sessions automatically receive it without globally forcing desktop mode.
- Do not apply the rule to all Google sites. Add `drive.google.com` only if a document-entry redirect requires it and evidence shows the Docs host rule alone is insufficient.
- Reuse upstream Gecko clipboard/text-selection support and the `cb6d029` UTF-8 rich-text fix. Do not add injected JavaScript or claim parity beyond what iOS/Gecko/Google allow.
- Validate that keyboard viewport insets and Page Zoom continue to apply to Docs. Physical-device testing remains authoritative for long-document scrolling, editor selection, keyboard interactions, and Markdown clipboard paste.

### Implementation on the 0.5.0 base

- CI commit `1a59aef` restores the split `build-gecko`/`archive-ipa` workflow, manual archive-only workflow, sccache restore/save, Gecko dist checkpoint artifact, unsigned archive flags, and conditional Gecko artifact signing.
- App commit `97b54a0` ports only missing custom behavior onto upstream's refactored application architecture.
- Warning-cleanup commit `7431983` preserves behavior while removing three custom-code Swift concurrency diagnostics found during the first final archive audit.
- Upstream Page Zoom storage, `PageZoomSettingManager`, `SiteSettingsStore`, Gecko patch, action bar, and settings panes are retained. The action bar now also exposes a live discrete slider without introducing the historical parallel zoom store.
- Keyboard handling now shrinks the actual page viewport to the keyboard intersection and uses Gecko focused-input geometry only as a bounded secondary correction.
- Tab persistence can synchronously flush on lifecycle events. Scene/app lifecycle hooks save state, foreground recovery restores or rebuilds the selected session, and crash/kill callbacks replace sessions in place instead of removing tabs.
- Bookmark HTML and history CSV import/export are available with local-file privacy confirmations. The transfer code does not claim Firefox Sync.
- Upstream search ranking/providers/bookmark/history/tab results remain authoritative. The fork adds local common-domain completion, a `180 ms` provider debounce, provider suggestions disabled by default, and regular-history suppression in private browsing.
- Upstream `AppAppearance` now includes `oledBlack`; `BrowserAppearance` adds preset/custom accents, native color picking, hex entry, contrast validation, immediate application, and OLED-aware surfaces.
- Google Docs compatibility is native-only. `UserAgentPolicy` matches only `docs.google.com` and subdomains, supplies the desktop Firefox/Linux UA, and forces desktop user-agent and viewport modes through `GeckoSessionSettings`. `CompatibilityPreferencesViewController` exposes `Use desktop compatibility for Google Docs`, default enabled. No Gecko patch or injected JavaScript was added.
- The Firefox submodule checkout was reconciled to upstream's gitlink `e784efd49da7cd69805f55f3353b65ff430441a1`; the worktree does not carry arbitrary direct Firefox edits.

Local validation completed before push:

```powershell
bash -n tools/development/build-gecko.sh
bash -n tools/release/build-app.sh
bash -n browser/Scripts/AddGecko.sh
python -c "import pathlib,yaml; files=['.github/workflows/build-latest-reynard-ipa.yml','.github/workflows/archive-reynard-ipa-from-gecko-dist.yml']; [yaml.safe_load(pathlib.Path(f).read_text(encoding='utf-8')) for f in files]"
git diff --check
git diff --name-only --diff-filter=U
```

All listed checks returned zero and both workflow files parsed as YAML. Swift and `xcodebuild` are unavailable on the Windows host, so source compilation must be established by the macOS GitHub Actions archive job. A fresh full checkpointed workflow is mandatory because `engine/release.txt`, the Firefox gitlink, and the patch tree differ from the historical checkpoint inputs.

### Progress for this sync

- [x] Goal objective, root guidance, `PLANS.md`, and current ExecPlan read.
- [x] Upstream remotes/tags fetched with prune.
- [x] Official `0.5.0` release metadata, assets, and full compare inspected.
- [x] Post-tag upstream main inspected and exact base selected.
- [x] Clean fork-only branch created from selected upstream base.
- [x] Functional-equivalence matrix recorded before porting.
- [x] Checkpointed build and archive workflows ported to the 0.5.0 base.
- [x] Missing custom features integrated without duplicating upstream equivalents.
- [x] Google Docs desktop compatibility profile implemented.
- [x] Local/static validation complete.
- [x] Fresh Gecko checkpoint and IPA build complete for the 0.5.0 inputs.
- [x] IPA downloaded, structurally verified, hashed, and marker-checked.
- [x] Fork-only prerelease published with unsigned IPA and checksum.

### Final 0.5.0 fork release evidence

- Full split workflow run `28337672838` succeeded at commit `5fb213e09f339e9084f813980fbd71296292849c`. It built Firefox `152.0.2`, uploaded `gecko-dist-aarch64-apple-ios`, consumed that checkpoint in the archive job, and uploaded `Reynard-latest-main-ipa`.
- The post-build sccache report showed `5,253` compile requests, `4,735` executions, `3,930` cache hits, `786` misses, an `83.33%` hit rate, a `4 GiB` cache size, and an `8 GiB` maximum. No distributed compilations were used or claimed.
- The first final archive contained no errors. Three avoidable warnings in custom code were removed by replacing actor-isolated function references with inheriting closures and avoiding optional synthesized equality from the background bookmark import path.
- Archive-only workflow run `28344020417` then succeeded in `4m42s` at final app commit `74319832e8d9d48fabeba8158e05e74a36b4c059`, proving that archive-stage iterations can reuse the prior Gecko checkpoint without rebuilding Gecko.
- The final artifact `Reynard-latest-main-ipa` is artifact ID `7941166120`, artifact digest `sha256:6b17311e1e1cda01e2b551080b2653118f5b6fdd20667d3d176f5440845bbb5f`, and expires `2026-07-13T02:06:19Z`.
- Downloaded IPA: `C:\Users\Cooper\Downloads\Reynard-0.5.0-custom-sideload-28344020417\Reynard.ipa`, `110,129,352` bytes, SHA-256 `1eff27f276977e3a8804b5040e45946ba33552c3066ad3e98c6aa2c57e75d828`.
- IPA verification passed: ZIP integrity, `3,032` unique entries, main app plus both extensions and GeckoView/XUL, app/helper/share version `0.5.0` build `7431983`, `21` valid arm64 Mach-O files, no signature directory or provisioning profile, and all selected custom-feature markers.
- Fork prerelease: `https://github.com/lowestprime/reynard-browser/releases/tag/reynard-0.5.0-custom-sideload-2026-06-28`. GitHub's release-asset digest for `Reynard.ipa` matches the locally verified SHA-256. The release also includes `Reynard.ipa.sha256`.
- No upstream pull request, merge request, review, comment, or merge action was created or modified.

## Google Docs Interaction and Theme Live-Apply Regression Fix

Purpose: repair two real-device regressions on top of the verified fork-only `0.5.0` custom sideload release without broadening scope or changing the upstream delivery policy. The target outcome is a new unsigned fork prerelease where long Google Docs documents are practically scrollable/editable within Gecko's iOS limits and appearance changes no longer cover or detach the active web content.

Verified starting point:

- Branch `fork/0.5.0-custom-sideload` is at documentation head `a79ae332e9bf8002e4df254d5086dd9132ed1900`; released app commit is `74319832e8d9d48fabeba8158e05e74a36b4c059`.
- Full checkpoint run `28337672838` produced the compatible Firefox `152.0.2` Gecko dist; archive-only run `28344020417` produced the installed IPA.
- The Google Docs compatibility layer is currently native session policy only: host-scoped desktop Firefox/Linux user agent plus Gecko desktop user-agent and viewport modes. The device result proves UA/viewport configuration alone is insufficient.
- Device evidence: the desktop Docs UI renders, but vertical swipes do not move the document canvas or reliably navigate a long document. Editing and selection are not seamless, and Markdown paste remains incomplete.
- Device evidence: tapping Docs elements can open the keyboard unexpectedly; an additional black bar appears above it, substantial document content is obscured, and tap-outside focus/dismissal is inconsistent.
- Device evidence: selecting System, Day, Night, or OLED appearance can replace the visible browser with a solid black or white screen until the app is force-closed and reopened. Persistence works after relaunch, so this is a live apply, hierarchy, layout, or reattachment regression.

Success criteria:

- [ ] Ordinary vertical pans over a long `docs.google.com` editor scroll the document without browser chrome stealing the gesture.
- [ ] Docs keyboard show/hide uses the actual visible content viewport, leaves no extra black obstruction, and restores layout without a blank region.
- [ ] Docs text editing, caret/selection, copy, plain-text paste, and Markdown-text paste use Gecko/native clipboard support where available; unsupported Google/iOS behavior is documented without overclaiming.
- [ ] Page Zoom at `75%`, `100%`, `150%`, and `200%` remains compatible with the Docs interaction fix.
- [ ] System, Day, Night, and OLED appearance changes apply immediately while the selected tab stays visible and interactive; the custom accent remains active.
- [ ] ChatGPT/Gemini keyboard avoidance, background recovery, Page Zoom, transfer, search, and checkpointed CI behavior remain intact.
- [ ] A final archive-only run succeeds unless a durable Gecko patch is proven necessary, and the resulting unsigned IPA is inspected, hashed, and published as a new fork prerelease.

Constraints and initial decisions:

- Keep all changes fork-only. Do not create, reopen, update, comment on, review, or merge an upstream pull request.
- Inspect the existing gesture, content hierarchy, keyboard inset, appearance notification, session attachment, clipboard, and Gecko event APIs before choosing a bridge.
- Prefer host-scoped native behavior. A `docs.google.com` content helper is allowed only when Gecko/native APIs cannot deliver wheel-style scrolling, and it must not inspect or log document contents or broadly intercept selection/editing.
- Do not edit `engine/firefox` directly. If Gecko behavior must change, represent it under `patches/`, record the exact reason, and run the full checkpointed workflow once.
- Reuse `gecko-dist-aarch64-apple-ios` from run `28337672838` when only app/native code changes.

Diagnosed causes and targeted implementation:

- The browser's chrome pan recognizers are attached to the address bar rather than the Gecko content surface, so chrome is not consuming ordinary Docs canvas swipes. The remaining mismatch is inside the desktop Docs interaction model: UA/viewport emulation loads the canvas UI, but touch motion does not provide the wheel-style input that the long-document editor expects.
- Add a one-finger vertical-pan recognizer only while the selected top-level URL matches the existing `docs.google.com` desktop-compatibility policy. It ignores horizontal intent, yields to long-press selection, leaves taps untouched, cancels the underlying touch sequence only after a vertical pan is recognized, and sends normalized coordinates/deltas to the selected Gecko session.
- Add a durable Gecko actor/module patch that rechecks the top-level Docs host, targets the element under the original pan point, and uses privileged `windowUtils.sendWheelEvent` input. A generic nearest-scrollable-ancestor fallback runs only if Gecko's wheel API throws. The helper does not use Docs selectors, inspect document text, or run on another host.
- Existing Gecko UIKit editable support already routes native copy, cut, paste, and select-all commands through Gecko and checks the iOS pasteboard. The fix preserves that pathway. Markdown clipboard contents can be pasted as text with their line breaks; rich Markdown-to-Google-Docs conversion remains controlled by Google and is not promised.
- The extra keyboard bar is caused by applying two page movements to Docs: the correct bottom constraint inset for the keyboard intersection followed by a focused-input translation derived from Docs' hidden editor element. Keep the actual viewport inset for Docs but disable only that secondary focused-input relocation; ChatGPT, Gemini, and other sites retain the existing relocation behavior.
- Appearance persistence was updated before `AppAppearanceController.apply`, while the browser notification could repaint chrome/content against the old trait collection and then trigger a second independent trait transition. Apply the new trait first, post one notification, reapply chrome/layout, and reattach the existing selected Gecko view only when detached without changing overlay visibility or reloading the tab.
- UIKit's Gecko host view resolved a new opaque system background during `traitCollectionDidChange` but did not request a new Gecko CoreAnimation transaction. Extend the durable `nsWindow.mm` patch to mark its layer for display on the main thread after the trait update, preventing the new black/white background from remaining above a stale Gecko layer.
- These actor and UIKit changes alter Gecko dist output, so the old checkpoint cannot contain the complete fix. Run one full checkpointed build, save the new dist artifact, and use archive-only reruns only for any subsequent Swift/archive corrections.

Progress:

- [x] Root `AGENTS.md`, `PLANS.md`, and current ExecPlan read.
- [x] Branch, worktree, and latest twelve commits inspected; only the pre-existing untracked `.codex/` directory is present.
- [x] Device regression evidence and native-first build decision recorded.
- [x] Relevant Docs/session/gesture/keyboard/clipboard and appearance/content hierarchy code inspected.
- [x] Root causes documented and targeted implementation completed.
- [x] Local/static checks pass: sequential LF Gecko patch application, `node --check` on both patched modules, all three requested shell syntax checks, and `git diff --check`.
- [ ] Final macOS archive-only or checkpointed workflow passes.
- [ ] IPA downloaded, inspected, hashed, and published in a new fork prerelease.

Active full-build handoff (2026-06-29):

- Implementation commit `ffe429291a04faf2fb4cde11d31f797f5ffc801a` is pushed to `origin/fork/0.5.0-custom-sideload`.
- Full checkpointed workflow run `28357388903` is `https://github.com/lowestprime/reynard-browser/actions/runs/28357388903` and is building that exact commit.
- Completed live stages: dependency installation, restore of the prior branch's approximately `4.1 GB` sccache, Firefox `152.0.2` source checkout, all Gecko patches (including both new Docs patches and the modified UIKit theme patch), idevice FFI, and ld64 detection setup.
- `Build Gecko` started at `2026-06-29T08:12:28Z`. The prior full run spent about `1h46m` in this stage even with an older cache; this run restored the newer cache from successful run `28337672838`, but acceleration must be judged from the final `sccache -s` output.
- Per the no-idle-poll requirement, do not start another full build and do not spend a session only watching this compile. Resume with `gh run view 28357388903 --repo lowestprime/reynard-browser --json status,conclusion,headSha,url,jobs`.
- If the run fails, retrieve `gh run view 28357388903 --repo lowestprime/reynard-browser --log-failed` and patch only the concrete failure. If it succeeds, inspect final sccache hits, download `Reynard-latest-main-ipa`, verify ZIP/plists/Mach-O/marker strings and build `ffe4292`, hash the IPA, then publish the new fork-only prerelease. No upstream PR action is permitted.

## Plan of Work

First repair `.github/workflows/build-latest-reynard-ipa.yml` so the dependency step installs `lld`, prepends `/opt/homebrew/opt/lld/bin:/opt/homebrew/opt/llvm/bin` for WASM-only wrapper commands, uses `command -v wasm-ld`, and validates a real WASM link using the Homebrew WASI sysroot. Commit, push, trigger the workflow, and inspect the result.

If the workflow fails, retrieve failed logs and the debug artifact if available, identify the exact failing lines, update this plan, patch the smallest root cause, commit, push, and rerun.

After the IPA workflow is green and the artifact is downloaded and inspected, inspect Reynard's tab/session/settings/menu/GeckoView architecture before implementing Page Zoom. Prefer Gecko/session preference support; add conservative fallback behavior only if the current iOS GeckoView layer lacks true page zoom. Then run local validation available on Windows and final GitHub Actions validation.

## Concrete Steps

Commands run so far:

```powershell
git status --short --branch
git log --oneline -10
gh auth status
gh run list --repo lowestprime/reynard-browser --workflow "Build Latest Reynard IPA" --limit 5
gh run view 27987957678 --repo lowestprime/reynard-browser --json databaseId,headSha,headBranch,conclusion,status,url,createdAt,updatedAt,event,workflowName,displayTitle
gh run view 27987957678 --repo lowestprime/reynard-browser --log-failed
```

Next commands:

```powershell
git diff --check
git diff -- .github/workflows/build-latest-reynard-ipa.yml .agent/execplans/20260623_reynard-latest-ipa-page-zoom.md
git add .github/workflows/build-latest-reynard-ipa.yml .agent/execplans/20260623_reynard-latest-ipa-page-zoom.md
git commit -m "ci: expose Homebrew lld for Gecko WASI"
git push origin main
gh workflow run "Build Latest Reynard IPA" --repo lowestprime/reynard-browser --ref main
gh run list --repo lowestprime/reynard-browser --workflow "Build Latest Reynard IPA" --limit 5
gh run watch <RUN_ID> --repo lowestprime/reynard-browser
```

Additional commands after first rerun:

```powershell
gh run view 27993600431 --repo lowestprime/reynard-browser --log-failed
gh run view 27993600431 --repo lowestprime/reynard-browser --json databaseId,headSha,headBranch,conclusion,status,url,createdAt,updatedAt,workflowName,jobs
gh run cancel 27993866717 --repo lowestprime/reynard-browser
git fetch upstream main
git merge-base --is-ancestor upstream/main HEAD
git rev-list --left-right --count upstream/main...HEAD
git merge upstream/main --no-edit
gh api repos/minh-ton/reynard-browser/releases --paginate --jq '.[] | {tag_name, name, published_at, target_commitish, assets: [.assets[] | {name, browser_download_url, size}]}'
gh api repos/minh-ton/reynard-browser/forks --paginate --jq '.[] | {full_name, pushed_at, default_branch, html_url}'
gh run view 27994353614 --repo lowestprime/reynard-browser --log-failed
gh run download 27994353614 --repo lowestprime/reynard-browser --name Reynard-build-debug --dir "$env:USERPROFILE\Desktop\reynard-build-debug-latest"
gh run cancel 28001189594 --repo lowestprime/reynard-browser
gh run view 28001837486 --repo lowestprime/reynard-browser --log-failed
gh run download 28001837486 --repo lowestprime/reynard-browser --name Reynard-build-debug-gecko --dir "$env:USERPROFILE\Desktop\reynard-build-debug-28001837486"
```

## Validation

Build validation:

- Workflow `Build Latest Reynard IPA` must complete successfully.
- Artifact `Reynard-latest-main-ipa` must exist for the successful run.
- Downloaded artifact must contain `Reynard.ipa`.
- `unzip -l Reynard.ipa` must show the main app and required extensions.

Feature validation:

- Local static/build checks available on Windows must pass or be documented if unavailable.
- Final GitHub Actions build after Page Zoom must upload a fresh IPA artifact.
- Physical iPhone checks for iOS 26.6 Developer Beta 2, SideStore, LocalDevVPN, and JIT/TXM remain manual unless the device is available.

## Recovery / Fallbacks

If explicit `lld` still cannot expose `wasm-ld`, inspect `brew --prefix lld`, `ls /opt/homebrew/opt/lld/bin`, and `command -v wasm-ld` from the failed run logs or debug artifact, then patch the wrapper path once.

If WASI compile succeeds but link fails after that targeted repair, switch Gecko mozconfig generation from `--with-wasi-sysroot=/opt/homebrew/share/wasi-sysroot` to `--without-wasm-sandboxed-libraries` and record the exact log lines that justify the fallback.

If later app archive or IPA creation fails, retrieve `Reynard-build-debug` and inspect Xcode logs, `dist`, `browser/Configuration/Reynard.xcconfig`, and app extension packaging before patching.

## Outcomes & Retrospective

- What changed: the workflow now uses sccache restore/save and a Gecko dist checkpoint; Reynard now has Page Zoom controls in the address-bar page menu, default zoom settings, per-host zoom persistence, and a GeckoView patch that applies `pageZoom` through `browsingContext.fullZoom`.
- What passed: local static checks, Gecko patch application check, the final `Build Latest Reynard IPA` GitHub Actions workflow, artifact upload, artifact download, IPA hash verification, and IPA payload checks.
- What failed or remains unknown: no current build failure. Physical iOS 26.6 / iPhone 15 Pro Max JIT/TXM behavior and hands-on Page Zoom UX remain device checks.
- Artifact/run/commit identifiers: feature commit `ac7c446aa4a8831579945e4d4cb49a33ce8cf670`; successful run `28038685786`; IPA artifact `Reynard-latest-main-ipa` ID `7826779137`; local IPA `C:\Users\Cooper\Downloads\Reynard-latest-main-28038685786\Reynard.ipa`.
- Recommended next action: install the verified IPA on the target device and manually check JIT/TXM behavior plus Page Zoom controls on several sites.
