# Working rules

## Scope and language

- Read README.md and the relevant docs before changing the project. Phase 0 is accepted. Phase 0.5 authorizes only the content smoke-test pipeline; runtime acceptance is pending manual testing. Milestone 1 gameplay requires explicit approval.
- Use English exclusively for code, identifiers, comments, documentation, commits, prompts, configuration values, dialogue, quests, UI, errors, and fixtures. Use Skyrim's English names.
- Explain Skyrim concepts for an experienced TypeScript developer who is new to Papyrus, Creation Kit, and mod records.
- Prioritize observable gameplay and maintainable code. Every phase needs a concrete result and evidence appropriate to that result.
- Do not implement later milestones merely because they appear on the roadmap. Stop after the authorized milestone and request approval for the next one.

## Evidence and integration

- Target Skyrim 1.6.1170 and SkyrimNet Beta 27 until the owner approves a change. Verify installed versions again when implementation starts.
- Never invent APIs, Papyrus functions, events, decorators, or schemas. Cite authoritative, versioned documentation or installed source; confirm loaded quest/script bindings and signatures through live inspection when available.
- Label evidence as documented, inspected on disk, observed in an earlier log, or executed live. A source declaration is not a successful integration test.
- Recheck the exact installed version before adopting newer upstream functionality. Consult docs/INTEGRATIONS.md for the baseline and unresolved contracts.
- Extend supported interfaces. Never modify SkyrimNet core or third-party sources, write their internal databases, or commandeer their state.
- Optional integrations must degrade gracefully. A missing optional plugin must not prevent contract completion. Avoid hard script types or ESP masters that silently make an optional integration mandatory.
- A readable function or internal ModEvent is not automatically a stable public API. Do not trigger another mod's maintenance, debug, or UI events as a substitute for a supported contract.
- Give NPC movement to one owner at a time. Never clear another mod's packages or force travel over an active quest, scene, or task. The first slice needs no movement packages.

## Implementation boundaries

- Prefer SkyrimNet content, Papyrus, and the smallest necessary Creation Kit records. Introduce C++/SKSE code only for a demonstrated gap.
- No external backend, database, agent framework, or runtime TypeScript service without a concrete requirement and approval.
- Use project-owned names, such as an `LW_` prefix, and a unique external content plugin ID. Avoid replacing shared prompt paths; prefer scoped submodules.
- Treat LLM output as a proposed action. Validate actors, state, quantities, proximity, and player consent in deterministic game code before changing inventory or issuing rewards.
- Game-save state owns the contract. Dialogue, memories, and an LLM's claim of success cannot complete it or authorize payment.
- Design duplicate calls, re-entry, partial settlement, save/load, cancellation, and failure before releasing economic actions. Do not assume Papyrus inventory calls form an atomic transaction.
- Prefer events and bounded callbacks over polling. Avoid extra LLM calls when game state already provides the answer.
- For Phase 0.5, keep exactly the manifest and standalone diagnostic prompt under `content/`. No automatic inclusion, actions, triggers, Papyrus, ESP/ESL, or native plugin. Run the local validation/package scripts; installation in MO2 remains manual. See docs/SMOKE_TEST.md.

## Workspace and player data

- Read machine-specific paths from the ignored `config.local.json`; `config.example.json` documents its keys. Never hardcode personal paths, mod folder names, or profile names in shared artifacts. Keep the template and documentation synchronized when adding keys.
- Treat `null` settings as unavailable. Validate required paths before use; never infer a deployment target from `mo2.currentProfile` or substitute it for a missing `mo2.testProfile`. Local configuration does not authorize deployment.
- Develop in this repository, never inside Skyrim or MO2's installed mod folders. Installed files may be inspected read-only.
- Never edit, clean, overwrite, or migrate existing player saves. Use a new disposable playthrough in an isolated MO2 test profile.
- Profile-local saves and INIs do not isolate every mod's external files. Check shared SkyrimNet content/configuration and MO2 Overwrite before testing; use dedicated test outputs or a separate instance when required.
- Package only project-owned files. Inspect the archive before any authorized deployment. Preserve unrelated mods and files.
- Do not silently install software. Check availability first; document missing tools and manual installation instructions.
- Do not commit credentials, user configurations, saves, logs, dependency headers, third-party binaries, or generated packages. Preserve authored ESP/ESL records in version control when introduced; do not blanket-ignore them.

## Development cycle

1. Identify one gameplay behavior and its acceptance criteria.
2. Verify the necessary interfaces and propose the smallest implementation.
3. Implement only the authorized behavior.
4. Run applicable automated checks, reporting exactly what ran and what failed or remained unavailable.
5. Package for the isolated profile and provide clear manual steps when packaging is in scope.
6. Observe inventory, gold, saved state, and actual NPC behavior; dialogue alone is insufficient evidence.
7. Fix issues within the milestone, record verified outcomes and risks, and stop for approval before advancing.

Do not label static source scans as behavior tests or claim in-game success without executing the scenario. Changes to test-profile setup, deployment, or runtime state must stay within the user's authorization.


## Git and Pull Request Workflow

- Never develop directly on main.
- Create one feature branch per approved milestone.
- Keep each PR focused on a single milestone.
- Use clear English commit messages and PR descriptions.
- Run available validation before opening a PR.
- Clearly distinguish automated checks from pending in-game tests.
- Include testing instructions and known limitations in every PR.
- Do not merge PRs automatically.
- Do not begin the next milestone before the current one is approved.
- Update relevant documentation as part of each milestone.
