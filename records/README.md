# Milestone 1 record authoring specification

`LivingWorld.esp` was authored by the owner with Creation Kit 1.6.1378.1 on 2026-10-20. `Seq/LivingWorld.seq` was generated and verified with xEdit. The owner reports SSEEdit 4.1.5f found 0 errors across 3 records after accidental vanilla cell and Sigurd reference overrides were removed. These files are authored assets: do not regenerate or overwrite them through the build script.

The intended project-owned records and bindings are:

1. A start-game-enabled, never-completed quest with EditorID `LW_ContractController`, no objectives, stages, dialogue topics, AI packages, or NPC overrides. Attach `LW_ContractController` to the quest.
2. A Player reference alias on that quest, filled with the unique Player reference. Attach `LW_PlayerAlias` to the alias and set its `Controller` property to the quest's controller script. The alias exists only to receive `OnInit` and `OnPlayerLoadGame`.
3. A message-box record with EditorID `LW_ContractOfferMessage`, text `Sigurd offers 50 gold for 10 Firewood. Accept this contract?`, and buttons in this exact order: `Accept`, `Reject`. The resulting `Message.Show()` indexes must be 0 and 1. Do not use a notification-style message.

Fill controller properties in Creation Kit:

| Property | Record |
|---|---|
| `IssuerRef` | Sigurd's placed actor reference `Skyrim.esm:000CDD73`, not NPC base `000CDD72` |
| `Firewood` | `Skyrim.esm:0006F993` (`Firewood01`, MISC) |
| `OfferMessage` | `LW_ContractOfferMessage` |

The installed `Skyrim.esm` places Sigurd's reference in `WhiterunBelethorsGeneralGoods` (`CELL 000165B3`). The controller has no cell check, so his normal movements are not obstructed. Keep `Skyrim.esm` as the only record master unless an actual dependency proves necessary. Save the authored plugin here, inspect its records and masters in xEdit, and preserve it in Git. Do not flag it ESL until its record IDs and save behavior have been checked.

Run `pwsh -File ./scripts/gameplay.ps1 -Mode Compile` with the configured CK Papyrus compiler and matching installed vanilla, SKSE, and SkyrimNet Beta 27 declarations. Generated output goes to `build/Scripts/LW_*.pex`; do not commit PEX files or imported dependency sources. `-Mode Package` requires the ESP, SEQ, and three PEX files and verifies archive contents. CK/xEdit review and gameplay behavior remain separate evidence.
