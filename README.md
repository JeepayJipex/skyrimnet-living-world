# SkyrimNet Living World

A gameplay expansion for Skyrim Special Edition in which NPC goals lead to activities, persistent outcomes, and new opportunities. The player can participate, influence events, or leave NPCs to their lives.

**Status: Phase 0 accepted; Phase 0.5 complete with owner-confirmed runtime loading, prompt availability, and uninstall detection on 2026-10-20. Gameplay is not implemented.** The first planned slice is a fixed NPC supply contract: offer, accept or reject, deliver items, receive gold, and make the confirmed outcome available to later dialogue.

All development artifacts and gameplay text are English. This repository is the development workspace; the game and Mod Organizer 2 installation are deployment targets.

## Target and observed environment

Inspection date: **2026-10-19**. Disk inspection and earlier-session logs establish the baseline below; no game was launched for Phase 0.

| Component | Baseline |
|---|---|
| Platform | Windows 11, supplied by the project owner |
| Skyrim | SE/AE runtime **1.6.1170.0**, verified on both discovered executables |
| Mod manager | MO2 **2.5.2**; executable configured by `mo2.executable` |
| Managed game | `SkyrimSE.exe` inside `gameRoot`; selected MO2 game executable |
| Steam game | Installation directory configured by `steamGameRoot`; may differ from the managed game root |
| SkyrimNet | **Beta 27**; existing log reports `0-27-0-0`, public assets revision `c53cb30e1085` |
| Current profile | Recorded locally as `mo2.currentProfile`; profile-local saves and settings were enabled |
| Development profile | Created by the owner and recorded locally as `mo2.testProfile`; profile-local saves and settings verified. Shared-output isolation and a disposable playthrough still require verification. |
| Live validation | Ports `127.0.0.1:8080` and `127.0.0.1:8889` were unreachable during inspection |

SkyrimNet is the required integration. IntelEngine, SeverActions, AgencyEngine, Relationships, Kinship, and M.A.R.A.S. are optional for the planned first slice. Their installed versions and usable interfaces are recorded in [INTEGRATIONS.md](docs/INTEGRATIONS.md).

Keep SkyrimNet's own Beta 27 prerequisites: a runtime-compatible SKSE installation, Address Library, PapyrusUtil, powerofthree's Papyrus Extender and Tweaks, and the UI/runtime dependencies in its [versioned README](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/README.md). These remain upstream requirements, even when Living World does not call them directly. Do not upgrade the modlist as part of setup without checking compatibility.

## Start here

1. Read [VISION.md](docs/VISION.md) for the proposed architecture and [AGENTS.md](AGENTS.md) for working rules.
2. Follow [Phase 0.5 build and manual MO2 smoke-test instructions](docs/SMOKE_TEST.md). This requires PowerShell 7.4+ and SkyrimNet Beta 27; Creation Kit and Papyrus are unnecessary for this phase.
3. Verify external discovery, the diagnostic prompt, and removal in the isolated profile. Record the results; offline validation does not establish runtime acceptance.
4. Before gameplay work, complete the later [toolchain and isolation setup](docs/TESTING.md) and obtain explicit approval for **Milestone 1** in [ROADMAP.md](docs/ROADMAP.md). Missing CK/Papyrus/xEdit tooling does not block the content smoke test.

Phase 0.5 provides `scripts/validate.ps1` and `scripts/package.ps1`. First run validation with `-FetchSchema` to cache the pinned official manifest schema, then validate/package offline. The resulting `dist/LivingWorld-SmokeTest-0.0.1.zip` contains only the manifest and a standalone diagnostic prompt. Installation through MO2 is manual.

## Local development configuration

Machine-specific paths and profile names belong in **`config.local.json`**, which Git ignores. The published [config.example.json](config.example.json) contains the same keys with empty values. JSON can be read directly by PowerShell and Node without a dotenv dependency.

For a new checkout, create the local file once from PowerShell at the repository root:

```powershell
if (-not (Test-Path -LiteralPath './config.local.json')) {
    Copy-Item -LiteralPath './config.example.json' -Destination './config.local.json'
}
$localConfig = Get-Content -LiteralPath './config.local.json' -Raw | ConvertFrom-Json
```

Fill in absolute paths using forward slashes (or escaped backslashes in JSON). `null` means unknown or unavailable; it never grants permission to select another location. Values are literal: environment variables and `~` are not expanded.

| Key | Meaning |
|---|---|
| `gameRoot` / `steamGameRoot` | Managed game directory and Steam installation directory; each contains `SkyrimSE.exe` |
| `mo2.executable` | Full path to `ModOrganizer.exe` |
| `mo2.modsDirectory`, `mo2.profilesDirectory`, `mo2.overwriteDirectory` | Effective directories from MO2 settings; do not assume they sit beside the executable |
| `mo2.currentProfile` | Informational snapshot of the existing profile; never an implicit deployment target |
| `mo2.testProfile` | Name of an isolated profile, set only after it has been created and verified |
| `skseLogsDirectory` | Actual SKSE log directory; accounts for redirected Documents folders |
| `modDirectories.*` | Each installed mod's Data-content root; folder names are chosen locally by the mod manager/user |
| `tools.*` | Full executable paths for Creation Kit, the Papyrus compiler, and xEdit once available |

These are development-machine settings, not SkyrimNet configuration or files to ship with the mod. No build/deployment script consumes them yet. Future tooling must read this file, validate the keys it needs, and report missing values rather than guessing paths. Keep personal paths and profile names out of shared documentation, scripts, and examples.

## Repository guide

| File | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | Rules for future coding sessions |
| [config.example.json](config.example.json) | Portable template for ignored local machine settings |
| [docs/VISION.md](docs/VISION.md) | Player experience, minimal architecture, state ownership |
| [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) | Verified extension points, source references, integration matrix and risks |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Small milestones and approval gates |
| [docs/TESTING.md](docs/TESTING.md) | Toolchain, setup, actual checks, and future in-game acceptance tests |
| [docs/SMOKE_TEST.md](docs/SMOKE_TEST.md) | Phase 0.5 build, installation, runtime verification, troubleshooting and removal |

`content/` holds our Data-content layout, currently `SKSE/Plugins/SkyrimNet/external/livingworld.smoke-test/`. Packaging omits the `content/` wrapper. Do not ship into SkyrimNet's managed `library/` or override its core files. See the [Beta 27 packaging guidance](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/vbeta27/docs/modding/MIGRATING_TO_BETA25.md).
