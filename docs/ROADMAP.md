# Roadmap

Only Phase 0 is authorized and complete. Every milestone below requires explicit approval before implementation. Stop after its acceptance criteria have been checked; record unavailable checks honestly.

## Phase 0 - Discovery and bootstrap

Delivered: versioned source research, installed-package inspection, integration boundaries, a minimal architecture proposal, toolchain gaps, testing guidance, and a documentation-only Git repository.

No gameplay, integrations, test profile, deployment, or new software installation was performed.

## Setup gate for Milestone 1

- Profile creation complete: the owner created the profile recorded locally as `mo2.testProfile`; its directory and enabled local saves/settings were verified on 2026-10-19. A new disposable playthrough remains to be verified.
- Resolve shared Overwrite/configuration isolation and repair/install CK, a Papyrus compiler, and xEdit manually as described in TESTING.md.
- Verify Beta 27 in that session, establish the MCP transport/endpoint, and inspect available tools and quest/script bindings.
- Select one fixed issuer and one ordinary commodity; verify English names, plugin-relative FormIDs, existing quest involvement, and availability in the profile.
- Choose a unique content ID and record prefix. This gate does not authorize gameplay beyond the next approved milestone.

## Milestone 1 - A fixed NPC offers a persistent contract

**Player result:** the issuer proposes exact terms; the player can explicitly accept or reject. Acceptance survives saving and restarting the game.

Smallest scope: one quest controller, the necessary record bindings and confirmation message, one scoped SkyrimNet offer action, and current-state dialogue context. Use a deterministic invocation during development to distinguish dispatch failures from LLM selection failures, then verify the NPC can choose the offer through dialogue. Keep inventory and gold unchanged in this milestone.

Acceptance criteria:

- Our external content layer and quest load without replacing core/third-party content.
- The fixed NPC exposes the offer; unrelated NPCs cannot create it.
- Player confirmation records accepted or rejected state. Repeated offers cannot overwrite acceptance or create duplicate instances.
- Accepted state and fixed terms survive save, full exit, and reload. Loading an earlier test save restores its earlier contract state.
- Prompt context reports the actual state; actions and decorators resolve after reload.

## Milestone 2 - Exact delivery and one reward

**Player result:** the issuer accepts the required goods and pays the fixed gold amount.

Scope: delivery request, game-state validation, inventory removal/transfer, fixed quest-funded gold, guarded settlement, and a confirmed outcome event. No travel, random pricing, or optional economy adapter.

Acceptance criteria:

- Insufficient goods change neither inventory nor gold and leave the contract active.
- Valid delivery changes item and gold counts by exactly the agreed amounts, then marks completion.
- Repeated or concurrent requests cannot issue another reward.
- Save/load and interrupted settlement tests establish a recovery policy before the milestone is accepted.
- Event-publication failure cannot cause another payment. Dialogue can read completion from saved state.

## Milestone 3 - Complete the first playable lifecycle

**Player result:** the contract can be cancelled or fail clearly, and later dialogue remains consistent with the game.

Scope: cancellation, issuer unavailability/death policy, rejection/no-reoffer policy, recovery diagnostics, and isolated MO2 packaging. Do not add a deadline unless separately approved.

Acceptance criteria:

- Cancelled/failed/rejected contracts cannot deliver or pay. Cancellation before delivery has no inventory cost.
- The complete TESTING.md scenario table passes, including older-save rollback, another new game, LLM failure, and optional plugins absent.
- A reload does not publish completion repeatedly or import another playthrough's state.
- The package contains only owned files and creates no unintended overrides. Record tested runtime/mod versions and manual results.

Completion of Milestones 1-3 is the first playable supply-contract slice. Milestone 1 alone is not that complete slice.

## Later candidates - investigate before approval

1. Select from a small validated issuer/item pool while retaining deterministic contract rules.
2. Add an optional AgencyEngine proposal lens if its party scope fits the desired behavior.
3. Add IntelEngine movement only after verifying task completion, cancellation and ownership interfaces.
4. Read social/family context through optional Relationships, Kinship and M.A.R.A.S. interfaces.
5. Explore NPC-to-NPC contracts and persistent consequences that create new opportunities.

Reassess player value and ecosystem overlap before each candidate. Do not prebuild a scheduler, event bus, generic adapter framework, or simulated economy.
