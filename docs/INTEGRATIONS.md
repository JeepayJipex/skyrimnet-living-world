# Integration discovery

Inspected **2026-10-19**. **Documented** means supported by an upstream document/source declaration; **installed** means inspected on disk; **historical** means observed in an existing log. None of these means Living World has executed the integration in-game.

## Version baseline and evidence

The SkyrimNet baseline is tag [`vbeta27`](https://github.com/MinLL/SkyrimNet-GamePlugin/tree/vbeta27), commit `c53cb30e108503a27b71f8e98b146a1124b790ea`. The installed `Source/Scripts/SkyrimNetApi.psc` matches that tag after CRLF/LF normalization. The latest existing `SkyrimNet.log` reports `0-27-0-0`, core build `beta27-release @ 3443b3a8a553`, and public assets `c53cb30e1085`. The core build ID is not the public assets commit.

Installed manifests in the directories recorded by `modDirectories.*` in the ignored `config.local.json` report IntelEngine **3.5.1**, SeverActions **4.5.0**, AgencyEngine **0.11.1**, Relationships **2.0.1**, Kinship **1.9.8**, and M.A.R.A.S. **0.11.0**. All seven mods were enabled in the inspected MO2 modlist; load-order files also enabled their available record plugins. This is a historical disk inspection, not a fresh successful load or a requirement to reproduce the original directory structure.

Public `main` branches are supplementary evidence. They can be newer or older than these installed packages; for example, the inspected SeverActions public README discusses 4.1 while the installed manifest says 4.5.0. Do not transfer API claims across versions without checking.

## SkyrimNet extension capabilities

| Capability | Verified contract and consequence |
|---|---|
| Content discovery | A mod ships `Data/SKSE/Plugins/SkyrimNet/external/<author>.<slug>/manifest.json` plus content roots. With an MO2 archive rooted at Data's contents, omit the leading `Data/`. Use a unique ID. [Migration guide][migration] |
| Content roots | Beta 27 documents `actions/*.yaml`, `triggers/*.yaml`, `prompts/**/*.prompt`, `knowledge/*.sknpack`, and other roots including `settings/`. Actions/triggers use a filename matching their `name`; `.yaml` is required. [Root reference][roots] |
| Load priority | Per-playthrough content and user overlays can override our files. Installed/external layers have user-controlled ordering. Do not write to `library/`, `overlay/`, or another mod's layer. Old loose `prompts/`, `config/actions/`, and `config/triggers/` paths are retired. [Migration guide][migration] |
| YAML actions | `questEditorId`, `scriptName`, `executionFunctionName`, ordered `parameterMapping`, and `eligibilityRules` connect dialogue decisions to quest-attached Papyrus functions. Verify quest bindings and exact parameters live. [Action workflow][actions] |
| Native Papyrus registration | `SkyrimNetApi.RegisterAction`, `RegisterDecorator`, `IsActionRegistered`, and `UnregisterAction` are declared. YAML is the smaller route for our quest actions. `ExecuteAction` explicitly bypasses eligibility/cooldowns, so it must not be treated as a validation boundary. [API source][api] |
| Triggers/events | YAML matches `eventCriteria` and produces a typed `response`, with audience, cooldown and probability controls. Documented events include `quest_stage`, `container_changed`, and `mod_event`; use the actual schema fields. Triggers are not a general inventory transaction language. [Trigger workflow][triggers] |
| Prompt templates | Inja `.prompt` templates support conditions, includes, blocks, and game-data decorators. A unique `prompts/submodules/character_bio/` contribution can add scoped context. A file at a shared relative path replaces that template. Inja is not fully Jinja2-compatible. [Prompt workflow][prompts] |
| Prompt-to-Papyrus reads | `RegisterDecorator(String decoratorID, String sourceScript, String functionName)` registers a global script function. Installed Relationships/Kinship use separate hidden scripts returning strings; confirm the return shape and current-actor/target behavior before implementing ours. [API source][api] |
| Outcomes and persistence | `RegisterPersistentEvent(String content, Actor originatorActor = None, Actor targetActor = None)` supplies persistent context without directly requesting a dialogue reaction. `AddWorldKnowledge` exists but is unnecessary for a single contract. `GetSaveUniqueID()` identifies a playthrough across multiple saves, not one save snapshot. [API source][api] |
| Debugging | Documented tools inspect loaded plugins, quests, script functions, decorators, event schemas, and prompt output. Validators include `validate_custom_action`, `validate_custom_trigger`, and `validate_prompt`. Runtime availability must be discovered through the live tool list. [Workflows][integration-workflow] |

The public repository contains assets, scripts, headers and documentation; it does not provide enough engine implementation to prove delivery acknowledgment, callback ordering, or database rollback semantics. No general-purpose contract persistence API was verified. Own the contract in our quest, and keep SkyrimNet's context as a derived view.

The API comments list package ModEvents, and the README mentions other lifecycle events. Do not copy their examples unquestioningly: the package comments contain a `RegisterForRegisterForModEvent` typo. Event signatures and registration/load behavior remain runtime checks; the first slice does not need package events.

## Feasibility matrix

All six integrations are **optional** for the first supply contract.

| Integration / installed version | Verified interface and possible use | Limits and conflicts | Decision |
|---|---|---|---|
| IntelEngine 3.5.1 | Installed YAML maps `GoToLocation` to quest `IntelEngine`, script `IntelEngine_Travel`; `CancelCurrentTask` maps to `IntelEngine_Core`. Scheduling, delivery, and fetch actions are present. Public Papyrus source exposes task management. | These are shipped action entry points, not a proven external task service. No stable task ID/completion acknowledgment contract was verified. Cancellation explicitly excludes scheduled tasks. Movement can conflict with followers, scenes, and other packages. | Defer until travel is needed; verify start/status/completion/cancel together before relying on tasks. |
| SeverActions 4.5.0 | Installed Papyrus action sources implement physical actions and economy. `SeverActions_Currency.TransferGold` returns the amount moved. Packaged `API/NATIVE_API.md` documents versioned C++ busy-state queries. | `TransferGold` can return less than requested; its optional conjure mode has settings-dependent semantics. A callable helper is not a versioned economic transaction contract. Native busy APIs would require C++, unjustified here. Follow, travel, schedule and enterprise ownership overlap. | Use vanilla inventory calls for the fixed quest. Revisit optional ledger/economy interoperability separately. |
| AgencyEngine 0.11.1 | Tag v0.11.1 documents custom lenses: prompts extending `agencyengine_impulse_base.prompt`, configured through its Lenses UI. Custom prompts can ship in our external bundle. | Focuses on followers/party proposals. A proposal or semantic resolution is not physical fulfillment. Seven lens slots, four shipped. No public goal-injection/transaction-completion API was verified; its Papyrus bridge events are internal coordination. Additional lenses spend LLM requests. | Later optional initiative input. Living World must still validate and execute each activity. |
| Relationships 2.0.1 | Installed bridge registers `get_romance` and `romance_physical_ok`. The author explicitly permits reading documented StorageUtil keys and `SNRom_Bond` ranks and calling decorators. | Primarily player-to-NPC bonds, not a general NPC-to-NPC social graph. Do not write its points or force tier changes. Installed behavior differs from newer upstream releases. | Later read-only context; neutral fallback when absent. |
| Kinship 1.9.8 | Installed bridge registers `get_kinship`, `kinship_is_child`, and `kinship_is_parent`. README explicitly documents readable `SNKin_IsPlayerChild`, `SNKin_ChildrenByPlayer`, and `SNKin_PlayerChildTotal` keys. | The roster covers the player's children and their parentage, not every family in Skyrim. Do not interpret an unknown result as proof of no kinship. Internal JSON/index mappings are not our contract. | Later family context; preserve unknown values. |
| M.A.R.A.S. 0.11.0 | Installed `Scripts/Source/MARAS.psc` declares native `IsNPCStatus`, `GetStatusCount`, `GetPermanentAffection`, and `RegisterCandidate`. Public upstream documents Papyrus/native interoperability. | Read-only status is feasible; its current upstream model must not be assumed for installed 0.11.0. Marriage eligibility and changes belong to M.A.R.A.S. Household packages can conflict with travel. | Later guarded status reads. No relationship mutations in the supply slice. |

Source locations for reproducing the installed checks are relative to each mod's configured root. See [local configuration](../README.md#local-development-configuration); do not assume a particular MO2 mod-folder name.

| Local configuration key | Paths relative to that directory |
|---|---|
| `modDirectories.skyrimNet` | `Source/Scripts/SkyrimNetApi.psc` |
| `modDirectories.intelEngine` | `SKSE/Plugins/SkyrimNet/external/galanx.intelengine/actions/`: `gotolocation.yaml`, `cancelcurrenttask.yaml`, and schedule/delivery definitions |
| `modDirectories.severActions` | `Source/Scripts/SeverActions_Currency.psc`; `SKSE/Plugins/SeverActions/API/NATIVE_API.md` |
| `modDirectories.agencyEngine` | `SKSE/Plugins/SkyrimNet/external/cleanestpoison.agencyengine/`: manifest, settings schema and prompts |
| `modDirectories.relationships` | `Source/Scripts/SNRom_Bridge.psc`; `Source/Scripts/SNRom_Decorators.psc`; `Docs/SkyrimNet Relationships/README.md` |
| `modDirectories.kinship` | `Source/Scripts/SNKin_Bridge.psc`; `Source/Scripts/SNKin_Decorators.psc`; `Docs/SkyrimNet Kinship/README.md` |
| `modDirectories.maras` | `Scripts/Source/MARAS.psc` |

The inspected IntelEngine package has compiled scripts but no Papyrus sources; the installed AgencyEngine bridge scripts are also compiled. Live signatures remain essential.

These files were read, not modified or copied into the repository. Source-available projects may restrict redistribution; use interfaces and require the original mod instead of bundling its implementation.

## MCP availability

Beta 27's [README][core-readme] documents an MCP server on **8889** and the dashboard on **8080**. The existing 2026-10-19 log records MCP startup on localhost:8889. Current bounded TCP probes, repeated outside the network sandbox, could not connect to either port. No SkyrimSE process was observed in the process query.

This establishes historical support, not current service availability. No MCP handshake, `tools/list`, validator call, or Codex configuration was performed. The endpoint path and transport must be confirmed when the isolated test session is running; a port number alone is insufficient to construct a working configuration. See TESTING.md for the connection gate.

## Open risks and decisions

| Priority | Risk or unknown | Required resolution |
|---|---|---|
| P0 | Partial inventory transfer, duplicate action dispatch, save during settlement | Test guarded transitions and recovery with exact item/gold deltas. Do not claim atomicity. |
| P0 | Persistent dialogue events may outlive an earlier-save rollback | Test both saves in the same playthrough; derive current facts from the quest. Do not automatically replay payments or completion events. |
| P0 | Test profile exists, but shared-output isolation and runtime validation remain unverified | Verify external configuration/output isolation, a disposable playthrough, and MO2 virtual file winners before gameplay tests. |
| P1 | Installed scripts/binaries can differ from public branch examples | Pin sources, inspect loaded functions, and record the tested package versions. |
| P1 | Multiple owners of an NPC's behavior | Avoid movement in the first slice. Later integrations require explicit busy/ownership and completion contracts. |
| P1 | An LLM may choose an invalid action or claim an unperformed exchange | Validate in Papyrus and expose actual saved state; explicit player confirmation controls acceptance. |
| P1 | Optional plugin decorators can fail when absent or on unsupported actor contexts | Gate integration loading/rendering and test with each optional plugin absent. Do not assume a template branch fixes decorator discovery. |
| P2 | Prompt path collisions and shared external configuration | Use unique filenames and scoped content; inspect SkyrimNet layers and MO2 Overwrite. |

## Primary sources consulted

Use the installed package for compatibility decisions. These pinned public revisions record what was inspected, not a requirement to update any mod:

| Source | Inspected revision |
|---|---|
| [SkyrimNet public assets][core-readme] | `c53cb30e108503a27b71f8e98b146a1124b790ea` / vbeta27 |
| [SkyrimNet Plugins: schemas and authoring](https://github.com/MinLL/SkyrimNet-Plugins/tree/481471e5733aeeff923c6442b483b13238111bfd) | `481471e5733aeeff923c6442b483b13238111bfd`; not a Beta 27 runtime schema guarantee |
| [IntelEngine](https://github.com/galanx/IntelEngine-GamePlugin/tree/a42311f2f81e3776961f80fcf90396f064011955) | `a42311f2f81e3776961f80fcf90396f064011955` |
| [SeverActions](https://github.com/Severause/SeverActions/tree/ff4093050a0259b9c65e296fc17c53deb7ad1ce6) | `ff4093050a0259b9c65e296fc17c53deb7ad1ce6`; installed API docs take precedence |
| [AgencyEngine](https://github.com/cleanestpoison/AgencyEngine/tree/6c1d28d3f7c59a365e87573dfbe1dfb6e1cd755b) | `6c1d28d3f7c59a365e87573dfbe1dfb6e1cd755b` / v0.11.1 |
| [Relationships](https://github.com/deadohiosky48/SkyrimNet-Relationships/tree/f61814fb9f67f4dce029bae7e518bb3aec644778) | `f61814fb9f67f4dce029bae7e518bb3aec644778`; newer than installed baseline |
| [Kinship](https://github.com/deadohiosky48/SkyrimNet-Kinship/tree/0a4c4e7a56904a43eebb5ec9406e6c470d281c6c) | `0a4c4e7a56904a43eebb5ec9406e6c470d281c6c`; check installed declarations |
| [M.A.R.A.S.](https://github.com/tetherball88/maras/tree/37a2c82e739d614013fde6888911f8c2016180de) | `37a2c82e739d614013fde6888911f8c2016180de`; check installed 0.11.0 declarations |

[core-readme]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/README.md
[migration]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/MIGRATING_TO_BETA25.md
[roots]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/CONTENT_ROOTS.md
[actions]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/WORKFLOW_ACTIONS.md
[api]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/Source/Scripts/SkyrimNetApi.psc
[triggers]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/WORKFLOW_TRIGGERS.md
[prompts]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/WORKFLOW_PROMPTS.md
[integration-workflow]: https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/WORKFLOW_MOD_INTEGRATION.md
