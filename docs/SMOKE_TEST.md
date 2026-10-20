# Phase 0.5 - External content smoke test

**Status: Phase 0.5 complete. Offline validation/packaging passed; the owner confirmed runtime loading, prompt availability, and uninstall detection on 2026-10-20.** Milestone 1 is not authorized.

## Manual acceptance result - 2026-10-20

Evidence: the owner's report from their manual MO2/runtime test, not a new agent-run game session or log inspection.

- SkyrimNet loaded the plugin successfully, and its diagnostic prompt was present.
- After uninstalling the MO2 mod, SkyrimNet correctly marked the retained plugin listing as **missing** and offered a **Forget** button. The owner reported that the involved files had been removed correctly; the listing was retained rather than silently discarded.
- This confirms bundle discovery, content availability, and uninstall detection. A retained missing listing is registry metadata, not active installed content. The owner did not report pressing Forget or separately running the optional Inja/MCP validator.

Runtime acceptance for Phase 0.5 is complete on this evidence. The instructions below remain available for repeating the test.

The extension ID is **`livingworld.smoke-test`**, version **`0.0.1`**, with author namespace `livingworld` and minimum SkyrimNet version `0.27.0`. This is a project namespace for an external bundle, not a registered Plugin Hub account. The ID was absent from the public hub index checked on 2026-10-19. Its prompt filename was absent from the installed Beta 27 base content.

The only content entry is a standalone, literal prompt:

```text
LW_SMOKE_TEST_OK: Living World content bundle is available.
```

It is outside automatically included character/submodule paths. Nothing calls it from gameplay, and it contains no template expressions, actors, events, actions, or external-mod references. Inspecting it needs no LLM request. No notification or NPC dialogue is expected when the bundle loads.

## Build locally

Use **PowerShell 7.4 or later** (`pwsh`); the workflow was executed with 7.6.5. Windows PowerShell 5.1 is insufficient. If needed, install PowerShell manually from its [official releases](https://github.com/PowerShell/PowerShell/releases). No Papyrus compiler, Creation Kit, ESP/ESL, native plugin, Node package, or local machine configuration is needed for this phase.

Run from the repository root:

```powershell
# Once per checkout: download the pinned schema into an ignored local cache.
pwsh -File ./scripts/validate.ps1 -FetchSchema

# Subsequent validation and packaging work offline with that cache.
pwsh -File ./scripts/validate.ps1
pwsh -File ./scripts/package.ps1
```

The first command requires network access. Without a cache, validation stops with instructions; normal validation never silently downloads anything. The schema is stored in `.local/validation/manifest.schema.json`, excluded from Git and the archive. Its SHA256 is checked before every validation.

Packaging validates first, writes exactly the two allowed files, then reopens the ZIP and verifies entry names and SHA256 against the sources. File ordering and ZIP timestamps are fixed for repeatable builds. Unexpected payload files/directories and links are rejected. Output is **`dist/LivingWorld-SmokeTest-0.0.1.zip`**; the script prints its SHA256. A failed build may leave an older successful archive in `dist`; install only after a successful packaging command.

The archive is rooted at Data's contents, with no extra `content/`, project, or `Data/` wrapper:

```text
SKSE/Plugins/SkyrimNet/external/livingworld.smoke-test/
  manifest.json
  prompts/living_world_smoke_test.prompt
```

Only these two Living World files are shipped. Documentation, scripts, schema cache, local configuration, and generated diagnostics stay outside the archive.

## Manual MO2 installation and activation

1. Exit Skyrim. Select the isolated profile named by `mo2.testProfile` in your ignored `config.local.json`.
2. In MO2, choose **Install a new mod from an archive** and select `dist/LivingWorld-SmokeTest-0.0.1.zip` from this workspace.
3. Create a separate mod named **Living World - Content Smoke Test**. Do not merge it into SkyrimNet or an existing mod. If MO2 shows a manual file tree, the chosen Data-content root must have `SKSE` directly beneath it.
4. Enable this mod in MO2's left pane only in the test profile. There is no ESP/ESL to enable in the right pane. Keep SkyrimNet Beta 27 and its existing prerequisites enabled.
5. In MO2's virtual Data view, confirm both files appear beneath `SKSE/Plugins/SkyrimNet/external/livingworld.smoke-test/`, supplied by the new smoke-test mod. No file conflict is expected.
6. Launch Skyrim through the test profile's SKSE executable. Use a new disposable game; leave existing saves untouched. Observe a fresh startup so cached content cannot substitute for external discovery.

MO2 profile selection does not by itself isolate shared Overwrite/configuration. Keep this test to content inspection; do not edit prompts, publish to the Hub, import the bundle into the user overlay, or change unrelated plugin settings.

## Runtime verification

1. Open SkyrimNet's dashboard (normally `http://127.0.0.1:8080`; use the effective configured address if different).
2. Open **Plugins > Installed Plugins**. Find **Living World - Content Smoke Test**, ID `livingworld.smoke-test`, version `0.0.1`, with an **External** badge. Confirm it is enabled and has no rejection/error. If a prior per-plugin toggle persists, enable this bundle there.
3. In **Prompts**, search for **`living_world_smoke_test.prompt`** and inspect it read-only. Confirm the exact `LW_SMOKE_TEST_OK` message above. Where the UI shows a source/layer, it must resolve from `livingworld.smoke-test`. If the dashboard offers a template validation/render preview, record that result too; do not invoke an LLM generation action.
4. Read the newly appended startup section of `SkyrimNet.log` in `skseLogsDirectory`. Search for `livingworld.smoke-test`, `ContentLayer`, `warning`, and `rejected`. Existing Beta 27 logs demonstrate scanner messages shaped like `Scanned external layer '<id>' ... <count> entries, <count> issues`. For this bundle, expect **one content entry and zero issues**; this is an expectation, not an observed Living World log result. Debug-level scanner messages may be hidden by the effective log settings, so the enabled External row plus the resolved prompt are the primary checks.
5. Record the game version, SkyrimNet build, archive SHA256, discovered bundle version, resolved prompt text, and any warnings. Report these results before marking runtime acceptance complete.

If MCP is already connected, the documented `validate_prompt` tool can additionally validate this file. Use the actual advertised tool schema. Offline validation checks literal text and manifest structure; it does **not** execute SkyrimNet's Inja parser. A successful offline build alone cannot establish discovery or engine acceptance.

## Removal test

1. Exit Skyrim and disable **Living World - Content Smoke Test** in MO2's left pane. Restart through the test profile.
2. Verify the bundle no longer supplies active content and the diagnostic prompt is no longer available from its external layer. In the owner's accepted test, SkyrimNet retained a **missing** plugin row with a **Forget** button after uninstalling. The row may remain even though the bundle files have been removed; absence from the listing is not required for a successful uninstall. Check the current active layers/startup, not historical log lines.
3. Confirm no new startup scan loads this external layer. Other mods should remain enabled. After this check, the smoke-test mod can be removed through MO2 by selecting only its separate mod entry.

The package introduces no save records or scripts. Removal is by disabling/removing its two files through MO2. Never delete SkyrimNet's registry, overlays, configuration, or another mod's files to remove this test. If an overlay copy was created accidentally, diagnose that separate layer before making any changes.

The dashboard's **Forget** action is optional listing cleanup after uninstall detection. It was offered during the accepted test, but using it was not reported or required for acceptance.

## Troubleshooting

| Symptom | Check |
|---|---|
| No External row | Correct profile and enabled MO2 mod; `SKSE` at archive root; folder ID exactly equals manifest ID; full game restart; current startup errors |
| Rejected manifest | Run local validation; inspect the dashboard rejection reason; verify actual runtime is Beta 27 and bytes match the packaged files |
| Bundle present, prompt absent | Content scan issues; exact lowercase `.prompt` extension; prompt filters; layer priority and duplicate ID/version copies; search the full filename |
| Prompt has different text/source | A user overlay or another layer wins; inspect provenance without editing/deleting shared content |
| No scanner message | Read the correct session/log directory and effective log level; use dashboard discovery and resolved content as evidence |
| Dashboard unreachable | Confirm SkyrimNet loaded, its web service started, and the effective address/port; the ZIP does not configure or start that service |
| Cache missing/checksum mismatch | Re-run `validate.ps1 -FetchSchema`; a changed upstream response is rejected rather than accepted silently |
| Plugin remains listed as missing after uninstall | Expected behavior observed in the owner's test: files can be correctly removed while registry metadata remains. The offered Forget action is optional listing cleanup. |

## Verified sources and offline results

- Beta 27 public assets: [`c53cb30e108503a27b71f8e98b146a1124b790ea`](https://github.com/MinLL/SkyrimNet-GamePlugin/tree/c53cb30e108503a27b71f8e98b146a1124b790ea).
- [External layout, manifest fields, startup discovery and removal](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/MIGRATING_TO_BETA25.md), [supported content roots](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/CONTENT_ROOTS.md), and [prompt syntax/validation](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/WORKFLOW_PROMPTS.md).
- Official [manifest schema at revision `232d5e902356595b4a70d97ad04cae03a93e69c3`](https://github.com/MinLL/SkyrimNet-Plugins/blob/232d5e902356595b4a70d97ad04cae03a93e69c3/schemas/manifest.schema.json), dated before the Beta 27 assets commit. SHA256: `A3B26A5E135B37DD4A5DF2208752E35092693AB8C54C970FBC9B3B74697854BF`. Its selected fields were cross-checked against the manifest example in the tagged Beta 27 docs; it is a hub schema, not a substitute for runtime discovery.
- The managed executable still reports 1.6.1170.0. Existing logs still identify SkyrimNet `0-27-0-0` / public assets `c53cb30e1085`. These were read-only checks, not a new game launch.
- Executed: schema validation, bundle identity/version and literal-prompt checks, two-file payload allowlist, ZIP path/content verification, repeated-build hash comparison, and rejection checks for malformed manifest metadata, wrong identity/version, extra payload, and template expressions.
- Owner-reported manual results on 2026-10-20: installation/runtime loading, diagnostic prompt availability, and uninstall detection passed. The retained missing listing and offered Forget button were observed. No automatic installation was performed by the agent.
- Not separately verified: the optional Inja/MCP validation and the Forget action. No fresh agent-run game session or raw runtime-log review was performed for this acceptance update.
