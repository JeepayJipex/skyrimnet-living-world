# Milestone 1: fixed offer with persistent choice

**Status (2026-10-20):** the owner authored `records/LivingWorld.esp` with Creation Kit 1.6.1378.1, generated `records/Seq/LivingWorld.seq` with xEdit, and reported SSEEdit 4.1.5f validation with 0 errors across 3 records after removing accidental vanilla overrides. The three scripts compiled with 0 errors and warnings. The gameplay archive can now be built offline. Live SkyrimNet integration and in-game save/load acceptance remain pending, so PR #2 stays Draft. The Phase 0.5 smoke-test bundle remains independent.

## Behavior and save ownership

Sigurd's placed reference `Skyrim.esm:000CDD73` is the only issuer. The fixed terms are 10 Firewood (`Skyrim.esm:0006F993`) for 50 gold. This milestone only records an offer response; it has no delivery or payment path. The quest script holds an initialized flag, state, item, quantity, reward, and offer-attempt counter in the game save. SkyrimNet prompts and memories are derived context.

The quest starts enabled. Its `OnInit` initializes a new contract once. The Player reference alias `OnInit` calls `Bootstrap(False)` and `OnPlayerLoadGame` calls `Bootstrap(True)`. Bootstrap ensures required properties exist and registers the two decorators. On load, Accepted and Rejected remain unchanged. A saved Offered state is treated as an interrupted message: its attempt token is invalidated and state returns to Available, permitting a new explicit offer. A stale `Message.Show()` return must match both Offered state and its token before any choice is recorded. Result `-1` or any value other than 0/1 returns to Available and records neither acceptance nor rejection. The ordering of resumed Papyrus stacks and the Player alias load callback still requires an in-game interruption test.

The global decorator script obtains the controller through the installed SKSE `Quest.GetQuest(string editorId)`, then casts it to `LW_ContractController`. Its functions take one `Actor` and return `String`, matching the installed SkyrimNet Beta 27 `RegisterDecorator` declaration and the standalone global decorator pattern in installed integration sources. `lw_can_offer_contract` returns `eligible` only when the exact placed actor is valid and the save state is Available; the action's eligibility rule compares that string. The Beta 27 action workflow documents eligibility against the decorator registry, but **custom decorator use by the installed action engine is not live-confirmed**. If MCP validation or runtime rejects it, remove that YAML eligibility condition, retain the same action, and rely on the authoritative actor/state guard in `RequestOffer`. The action description must continue to direct only Sigurd to offer. Do not make an optional mod a dependency to solve eligibility.

The prompt submodule calls `lw_contract_context(actorUUID)`, which returns an empty string for all other actors and current quest facts for Sigurd. It does not use persistent events. Loading an older save should therefore restore the prior contract view even if SkyrimNet's separate memories still contain newer dialogue; test and correct any contradictory rendering before acceptance.

## Evidence and unresolved integration gates

| Evidence level | Result |
|---|---|
| Inspected on disk | Both configured Skyrim executables report 1.6.1170.0; `Skyrim.esm` contains Sigurd base `000CDD72`, placed reference `000CDD73`, Belethor's shop cell `000165B3`, and Firewood `0006F993`. |
| Installed source | SkyrimNet Beta 27 declares `RegisterDecorator(String, String, String)` and actor UUID passing; installed SKSE `Quest.psc` declares `Quest.GetQuest(string editorId)`. Vanilla-style actor, quest, game, and distance signatures were checked in installed SKSE headers. |
| Earlier log / owner report | A prior log reports SkyrimNet `0-27-0-0`; the owner accepted Phase 0.5 content loading and removal on 2026-10-20. |
| Owner-reported manual toolchain | Creation Kit 1.6.1378.1 authored the quest/message/alias and bound properties; SSEEdit 4.1.5f found 0 errors across 3 records after cleanup; xEdit generated and verified the SEQ; all three Papyrus scripts compiled with 0 errors and warnings. The authored ESP and SEQ are preserved in Git. |
| Executed offline in this update | The configured CK Papyrus compiler built the three scripts using installed vanilla/CK, SKSE, and SkyrimNet Beta 27 sources with 0 errors and warnings. Packaging checks ESP, SEQ, and PEX presence and ZIP hashes. |
| Unavailable live | Game, dashboard, MCP tool list, loaded quest bindings, decorator return behavior, action eligibility, prompt rendering, message outcome, save/reload, and inventory/gold checks. |

Installed API source alone does not prove runtime dispatch. Before marking this milestone ready, use live SkyrimNet MCP `get_plugins`, `get_quests`, `get_quest_scripts`, `get_quest_script_functions`, `get_decorators`, `validate_custom_action`, and `validate_prompt` with the actual advertised schemas. Verify `RequestOffer(Actor)` and both global decorator signatures. Then render the prompt for Sigurd and another NPC. Do not use state-changing MCP calls for discovery.

## Toolchain and package steps

1. Keep local tool paths in ignored `config.local.json`: `tools.papyrusCompiler` is the CK `PapyrusCompiler.exe`; `tools.papyrusFlags` is the installed `TESV_Papyrus_Flags.flg`; `tools.papyrusImportDirectories` lists installed SKSE, SkyrimNet Beta 27, and vanilla/CK source directories. The build script adds this project's `Source/Scripts` first. Record the separate CK and xEdit executable paths for manual review when available. No dependency sources are packaged or committed.
2. Run `pwsh -File ./scripts/gameplay.ps1 -Mode Validate`. If the pinned manifest schema cache is missing, run `pwsh -File ./scripts/validate.ps1 -FetchSchema` once, then rerun. Validation checks the manifest schema, owned file allowlist, and selected action/source invariants. It does **not** parse YAML with SkyrimNet or validate records.
3. Run `pwsh -File ./scripts/gameplay.ps1 -Mode Compile` to rebuild all three PEX files in `build/Scripts/` from local installed headers. The command publishes outputs only after all three compile successfully; it does not change the authored ESP or SEQ. Recheck records with CK/xEdit whenever those files change.
4. Run `pwsh -File ./scripts/gameplay.ps1 -Mode Package`. The command first validates source, checks the authored ESP, SEQ, and three current nonempty PEX files, then builds a Data-rooted ZIP and verifies every entry hash. It does not invoke CK/xEdit or prove their review succeeded. Review the ZIP before installing it through MO2.
5. Exit Skyrim, select the configured isolated test profile, and check shared SkyrimNet configuration and MO2 Overwrite. If shared outputs cannot be isolated, use a separate MO2 instance. Import `dist/LivingWorld-Milestone1-0.1.0.zip` as a separate mod, enable its ESP and external content layer in this profile only, and verify MO2 virtual file winners for `LivingWorld.esp`, `SEQ/LivingWorld.seq`, and the three scripts. Start a new disposable playthrough through SKSE; do not use or modify existing saves.

## Manual acceptance checklist

Record the game and SkyrimNet versions, plugin revision, save names, actor/item IDs, state, Firewood count, gold count, and relevant sanitized logs.

1. With a new disposable save, speak to Sigurd about supplies or work. Verify the exact native message and 0=`Accept`, 1=`Reject`. Confirm unrelated NPCs cannot change state even if the action is attempted.
2. While the message is pending, cause repeated action attempts in the disposable test and verify only one offer can decide. For invalid or failed message results, verify state returns to Available without recording rejection.
3. Reject and verify Rejected state and matching dialogue context. Confirm Firewood and gold are unchanged. Reload a pre-offer test save for the accept path.
4. Accept once. Verify duplicates cannot replace Accepted. Save, fully exit, reload, and verify Accepted and the same item/quantity/reward in controller state and rendered dialogue.
5. Load the older pre-offer save. Verify Available returns and prompt context follows that save, despite any newer SkyrimNet dialogue memory. Test a saved/interrupted Offered state where the engine permits one, and verify stale callbacks cannot accept or reject it.
6. Confirm no inventory/gold changes throughout, no NPC travel/package displacement, and no Papyrus or SkyrimNet binding errors. Repeat with optional integrations absent in a separate minimal profile or instance, without removing them from an existing save.

Any failure in compilation, xEdit review, live MCP validation, message handling, or save/load keeps the PR Draft. Delivery and payment are Milestone 2 and are not implemented here.
