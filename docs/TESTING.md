# Development tools and validation

## Phase 0.5 - Current content smoke test

Build, manual MO2 installation, activation, dashboard/log verification, removal, and troubleshooting are documented in [SMOKE_TEST.md](SMOKE_TEST.md).

Executed offline: the manifest passes the pinned official JSON Schema; bundle identity/version and the exact literal prompt pass project checks; only the two expected source files are accepted; generated ZIP names and content hashes match the sources. Repeated packaging produces the same ZIP hash. Negative checks reject missing manifest fields, wrong identity, invalid release version, extra payload, and template expressions.

The validator requires PowerShell 7.4+. Its first explicit `-FetchSchema` run downloads a checksum-pinned schema into ignored `.local/validation/`; subsequent runs and packaging work offline. This literal-only prompt needs no YAML parser or Node packages. No full Inja parser was executed offline.

**Runtime accepted, owner-reported on 2026-10-20:** the plugin loaded with its prompt present; after uninstalling, SkyrimNet marked its retained listing as missing and offered Forget. Files were reported correctly removed. Optional Inja/MCP validation and using Forget were not separately reported. See [the acceptance record](SMOKE_TEST.md#manual-acceptance-result---2026-10-20). The Papyrus, record-editing, and gameplay test requirements below apply to later milestones, not Phase 0.5.

## Availability on 2026-10-19

| Tool or facility | Observed status | Role |
|---|---|---|
| Git | `2.43.0.windows.1`; repository initialized on `main` | Source and documentation history |
| PowerShell and ripgrep | Available and used | File checks, packaging later, log inspection |
| Node.js | `v24.13.0` | Optional development-only YAML/schema checks; no Node runtime in the mod |
| YAML / JSON Schema packages | `yaml`, `js-yaml`, and `ajv` not resolvable from this workspace | Install explicitly only when content validation is introduced |
| Python | Windows alias and `py` launcher found; `py --list-paths` reports no installed Python | Not required for the proposed minimum |
| MO2 | 2.5.2; local executable recorded as `mo2.executable` | Virtual Data directory, profiles, isolated package testing |
| Creation Kit | No executable found in inspected game/mod/tool locations; the existing MO2 executable entry points to a missing file | Author quest/message records and attach scripts |
| Papyrus compiler | Neither `PapyrusCompiler` nor `papyrus` on PATH; no compiler found in inspected game/mod/tool locations | Compile `.psc` source to `.pex` bytecode |
| xEdit | Both existing MO2 executable entries point to missing files | Check records, masters, conflicts, and light-plugin eligibility |
| Spriggit | Not found on PATH | Optional future text serialization of ESP records; not required now |
| SkyrimNet dashboard / MCP | Neither 8080 nor 8889 reachable in bounded probes | Live validation requires the game/plugin to be running |

Searches covered PATH, the two known game roots, relevant MO2 mods and configured tools, a local tools directory, and the development area. A missing result is not proof that a tool is absent from every disk location. No software was installed. These are historical observations from the inspected development machine, not requirements or automatic detection results for a new checkout. Recheck availability using your own `config.local.json`.

## Manual setup

1. Complete the [local configuration setup](../README.md#local-development-configuration). In MO2, create a dedicated test profile (suggested name: **Living World Test**) with profile-local saves and INIs, then record its name in `mo2.testProfile`. Start a new disposable game. Preserve existing gameplay profiles; `mo2.currentProfile` is only an informational snapshot and may itself name the test profile.
2. Inventory shared outputs before launch. MO2 Overwrite is shared across profiles, and SkyrimNet's overlays/settings may be shared too. Use a separate test output mod and profile-specific enabled content; if the existing list cannot isolate mutable files, use a separate test instance. Do not move or delete the player's existing Overwrite data. Profile-local saves alone do not solve this.
3. Obtain [Skyrim Special Edition: Creation Kit from Steam](https://store.steampowered.com/app/1946180/Skyrim_Special_Edition_Creation_Kit/). Check its compatibility with the pinned runtime before installation. Follow the [MO2 CK guide](https://github.com/ModOrganizer2/modorganizer/wiki/Skyrim-Creation-Kit-SE-and-MO2) and [executable configuration guide](https://github.com/ModOrganizer2/modorganizer/wiki/Executables-window). Keep authored records and scripts in the workspace; capture CK output in a dedicated test mod/staging location rather than the live game Data directory.
4. Obtain one Papyrus compiler. CK supplies the conventional toolchain; SkyrimNet Beta 27 also documents [papyrus-compiler 2025.03.18](https://github.com/russo-2025/papyrus-compiler/releases/tag/2025.03.18). Its upstream command uses `papyrus.exe -nocache -h headers -i Source/Scripts -output Scripts`. This is an upstream example, not a command ready to run in this empty source tree. Pin the chosen compiler and supply vanilla/SKSE headers, the appropriate flags file if required, and the exact Beta 27 `SkyrimNetApi.psc`. Additional imports are required only for APIs actually used. Do not redistribute dependency sources.
5. Obtain [xEdit from its official releases](https://github.com/TES5Edit/TES5Edit/releases), add a valid executable to MO2, and use Skyrim SE mode. Validate only our new records and their dependencies; do not clean or resave the full modlist.
6. For future offline YAML checks, use a pinned parser and JSON Schema validator. The [SkyrimNet Plugins validator suite](https://github.com/MinLL/SkyrimNet-Plugins/blob/481471e5733aeeff923c6442b483b13238111bfd/TESTING.md) uses Node >=20, `js-yaml` and `ajv`. Its tests validate hub infrastructure and are not tests of this mod. Pin reviewed schemas and compare them with Beta 27; a newer hub schema is not an authoritative replacement for the installed runtime validator.

Creation Kit records can initially be maintained as one authored ESP in Git. [Spriggit 0.40.0](https://github.com/Mutagen-Modding/Spriggit/releases/tag/0.40.0), used by SkyrimNet's own build, is an optional later way to represent records as reviewable text. Do not add it until record diffing justifies the tool.

## Live MCP connection gate

Profile setup follow-up (2026-10-19): the owner created the profile recorded in `mo2.testProfile`. Read-only inspection confirmed the profile directory and `LocalSaves=true` / `LocalSettings=true` in its `settings.ini`. Its saves directory already contains files; profile creation does not establish a new disposable playthrough. Start a new test game and leave existing saves untouched. Shared external files and runtime behavior remain unverified. No MO2 files or saves were changed by this check.

The current session did not establish a service connection. Historical logs show MCP successfully starting on localhost:8889, while the installed `WebServer.yaml` specifies dashboard host `127.0.0.1`, port `8080`.

When the user launches the isolated profile through SKSE:

1. Read startup logs and verify SkyrimNet version, loaded content layers, and effective ports.
2. Check local reachability, then confirm the MCP endpoint path and transport from the running service/current documentation. Do not guess `/mcp` or `/sse` from the port number.
3. Complete MCP initialization and `tools/list` before configuring a development client. Record the actual URL/transport and tool schemas; no Codex configuration is recommended as already working.
4. Start with read-only tools documented by Beta 27: `get_plugins`, `get_quests`, `get_quest_scripts`, `get_quest_script_functions`, `get_decorators`, and event-schema inspection. Names shown in workflow docs have client-specific prefixes; use the server's actual returned names.
5. Validate owned content with `validate_custom_action`, `validate_custom_trigger`, and `validate_prompt` when available. Render prompts with real actor context and confirm missing optional integrations are handled.

`execute_quest_function`, console commands, memory editing, reload tools, and game-state writes are not read-only checks. Use them only within an authorized isolated test. A successful YAML parse cannot prove a quest is loaded or a script function works.

## Validation layers for implementation

| Layer | What it establishes | What it cannot establish |
|---|---|---|
| Offline content checks | YAML/JSON parses; required fields, names and package paths match pinned schemas | Live decorator availability or correct game effects |
| Papyrus compilation | Syntax/types/imports accepted; `.pex` generated | Correct properties, quest initialization, or save behavior |
| xEdit record inspection | Valid masters, script bindings, intended records, no accidental overrides | Successful runtime calls or AI compatibility |
| SkyrimNet validators and rendering | Installed engine accepts content and resolves its current context | Correct item transfer or durable payment protection |
| In-game scenarios | Visible effects, inventory/gold deltas, lifecycle and save/load behavior | Compatibility with every untested modlist |

Package later into a staging directory rooted at Data's contents: the owned ESP, `Scripts/*.pex`, and `SKSE/Plugins/SkyrimNet/external/<author>.<slug>/` content. Include only files produced/owned by Living World; no upstream DLLs, logs, settings, or saves. Review the archive's file list before importing it into MO2, and inspect virtual file winners after enabling it. FOMOD is unnecessary for a single configuration.

## Manual acceptance scenarios for the complete slice

Record runtime/mod versions, build revision, starting save, issuer/item IDs, item and gold counts before/after, expected state, actual state, and relevant sanitized log excerpts. **None of these gameplay scenarios has run in Phase 0.**

| Scenario | Required observation |
|---|---|
| Offer and reject | Exact English terms shown; rejection has no inventory/gold cost; unrelated NPC cannot issue the contract |
| Accept, save, full exit, reload | One accepted contract with unchanged terms; actions/decorators work after load |
| Deliver too few items | No items removed, no gold granted, contract stays accepted |
| Deliver exact quantity | Required count removed/transferred, exact reward added, completion recorded |
| Deliver excess quantity | Only required goods removed; surplus preserved |
| Repeat/race delivery requests | One settlement and one payment; no duplicate event-driven execution |
| Save/load during settlement | Tested recovery from every reachable partial step; no extra reward or silent loss |
| Cancel, reject, or fail | Terminal state blocks delivery/payment; issuer death/unavailability follows a documented policy |
| LLM or context publication unavailable | No false completion; successful payment cannot repeat because notification failed |
| Dialogue after completion | Issuer receives confirmed facts; wording does not invent extra items, payments or obligations |
| Reload earlier test save | Inventory, gold, and contract agree with that save; stale SkyrimNet context does not override them |
| Start another disposable game | No contract, reward, or outcome inherited from the other playthrough |
| Optional mods absent/present | Contract remains usable without each optional mod; no script-resolution errors or competing actions |
| Busy issuer / another quest / combat | Invalid execution rejected; no displacement of existing scene/package ownership |

Use a minimal dependency profile for initial verification and a separate compatibility run with the target ecosystem enabled. Do not uninstall dependencies from an established save to simulate absence. Restart Skyrim for record/compiled-script changes; only use hot reload for content types the installed service explicitly supports.

## Logs and Phase 0 checks actually executed

Read `SkyrimNet.log` inside the locally configured `skseLogsDirectory`. Its usual location is the user's Documents folder under `My Games/Skyrim Special Edition/SKSE`, but Documents may be redirected. The log inspected in Phase 0 provides build identity and earlier MCP startup evidence. SkyrimNet's dashboard offers logs, event monitoring, prompt/request inspection and traces when running. Papyrus logging may be enabled in the test profile's INI for script diagnostics; a Papyrus log is not a complete crash diagnosis. Do not publish provider credentials or private dialogue from logs.

Executed discovery checks:

- Workspace/parent instruction inspection: workspace initially empty; no existing Git repository or applicable AGENTS.md found.
- Git/Node/Python command checks and YAML package resolution checks: results listed above.
- Read-only MO2 profile, manifest, script, executable-version, and selected log inspection.
- Official GitHub tag/tree/document retrieval, including all six integration projects and the plugin-hub schemas.
- Beta 27 API comparison: installed and tagged text match after line-ending normalization.
- Bounded TCP probes for 8080/8889: sandbox attempt was blocked; an authorized external retry also did not connect. No handshake or semantic runtime test occurred.
- Repository initialization on `main` and documentation/link/whitespace checks performed during bootstrap review.

**Not executed:** Papyrus compilation, project YAML/prompt validation, ESP/ESL checks, packaging/deployment, new game launch, inventory/reward tests, or save/load tests. There is no automated gameplay test suite yet. Historical log success is not a Phase 0 runtime test result.
