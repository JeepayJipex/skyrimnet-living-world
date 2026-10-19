# Vision and minimal architecture

## Gameplay purpose

NPCs should pursue goals, cooperate, compete, organize activities, and react to lasting outcomes. The player may help, interfere, or ignore them. An intention only becomes an outcome when the game confirms the corresponding action.

Living World owns activity rules and lifecycle state. It should reuse supported dialogue, movement, social, and action systems without duplicating their responsibilities. The boundaries in INTEGRATIONS.md supersede the original ecosystem hypotheses.

## First complete playable slice

A fixed NPC offers a fixed supply contract. The player explicitly accepts or rejects it. Acceptance survives save/load. At delivery, game code verifies the required item count, transfers or consumes the goods, issues actual gold, and records completion. Future dialogue receives the confirmed result.

Use one ordinary stackable commodity, one issuer, one quantity, one reward, and one contract instance. Choose and verify the exact records during implementation. Defer dynamic selection, deadlines, NPC travel, simulated markets, and NPC-to-NPC contracts.

The first slice must eventually support rejection, cancellation, failure, duplicate delivery attempts, and save/load. It is a foundation for later activity types; do not build a general quest generator first.

## Proposed smallest architecture

This is a design recommendation, not an implemented or tested system.

| Piece | Responsibility |
|---|---|
| One project-owned quest record | Holds the persistent contract controller and fixed actor/item properties. A Skyrim quest can act as a persistent script host without a journal storyline. |
| Papyrus controller (`.psc`, compiled to `.pex`) | Validates requests, records consent and state, changes inventory, prevents repeated settlement, and exposes a small callable surface. Papyrus is Skyrim's gameplay scripting language. |
| One explicit confirmation message | Lets the player accept/reject the exact terms using Skyrim's native message UI. An NPC or LLM cannot accept on the player's behalf. |
| SkyrimNet action YAML | Lets the fixed issuer request our quest functions; eligibility limits when an action is offered. The controller repeats critical checks. |
| Scoped prompt submodule and read-only decorator | Supplies current contract facts from game-save state to the issuer's dialogue. Register through `SkyrimNetApi.RegisterDecorator` and verify rendering in Beta 27. |
| Confirmed outcome event | Calls `SkyrimNetApi.RegisterPersistentEvent` after successful settlement so the outcome can inform dialogue. Its notification state is separate from payment state. |

An ESP stores the quest/message records and script attachments. An ESL flag can make a qualifying small ESP use the light-plugin space; it is not required for the first build. Decide and validate the flag and FormIDs before creating long-lived test saves. A player reference alias may be added if needed for save-load registration; it is a handle to the player inside the quest, not an NPC AI package.

No Living World DLL, server, database, custom menu framework, or continuous worker is justified by this slice. Existing SkyrimNet LLM services remain upstream dependencies. Use native item APIs for the fixed exchange; optional SeverActions economy behavior is a separate later feature.

## State and consequences

Proposed states: `Available -> Offered -> Accepted -> Settling -> Completed`, with `Rejected`, `Cancelled`, and `Failed` terminal outcomes where allowed. These are project design names, not SkyrimNet APIs.

Persist contract terms, state, and settlement progress on the quest's Papyrus instance. Treat save/load verification as a release gate. Do not use prompt variables, a text bio, or a shared JSON file as the payment ledger.

Settlement must revalidate the issuer, player, proximity, active state, fixed item form, and quantity. Reserve the transition before side effects, use `GetItemCount`, `RemoveItem`, and `AddItem`, and verify inventory/gold changes. Start with a fixed quest-funded reward (actual gold added to inventory); do not silently depend on an NPC's purse or a merchant's restock system.

Papyrus calls can be interrupted or interleaved. A `Settling` state alone does not prove exactly-once payment. Define and test partial-progress recovery before release; never blindly repeat a reward on load. Failure to publish dialogue context must not undo or repeat a successful payment.

SkyrimNet's playthrough identity spans multiple saves. The inspected API does not establish that persistent events roll back with an older `.ess` save. Reconstruct current contract facts from the quest on load, avoid re-emitting completion on every load, and test earlier-save rollback explicitly. If stale memories still contradict current state, the slice is not ready for release.

## Compatibility and success

Do not move the issuer or alter existing NPC records, factions, packages, merchant stock, or relationships for the first slice. Add only the records needed to host our behavior.

Success means the player can see the offer, choose freely, observe exact inventory and gold changes, reload, and receive consistent later dialogue. A well-written promise from an NPC is insufficient. Broader autonomy begins only after this foundation passes its manual tests.
