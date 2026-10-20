#requires -Version 7.4
[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Package')]
    [string] $Mode = 'Validate'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bundle = 'SKSE/Plugins/SkyrimNet/external/livingworld.core'
$contentRoot = Join-Path $root 'gameplay/content'
$sourceRoot = Join-Path $root 'Source/Scripts'
$manifestPath = Join-Path $contentRoot "$bundle/manifest.json"
$actionPath = Join-Path $contentRoot "$bundle/actions/LW_OfferContract.yaml"
$promptPath = Join-Path $contentRoot "$bundle/prompts/submodules/character_bio/0390_lw_contract.prompt"
$sourceNames = @('LW_ContractController.psc', 'LW_PlayerAlias.psc', 'LW_ContractDecorators.psc')
$contentNames = @(
    "$bundle/manifest.json",
    "$bundle/actions/LW_OfferContract.yaml",
    "$bundle/prompts/submodules/character_bio/0390_lw_contract.prompt"
)

function Assert-RegularDirectory([string] $path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Expected a regular directory: $path"
    }
}

function Assert-ExactFiles([string] $base, [string[]] $names) {
    Assert-RegularDirectory $base
    $actual = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $base -Recurse -Force)) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Links and junctions are not allowed: $($item.FullName)"
        }
        if (-not $item.PSIsContainer) {
            $actual += [IO.Path]::GetRelativePath($base, $item.FullName).Replace('\', '/')
        }
    }
    $different = @(Compare-Object -ReferenceObject ($names | Sort-Object) -DifferenceObject ($actual | Sort-Object))
    if ($different.Count -ne 0) {
        throw "File allowlist mismatch under $base`: $($different | Out-String)"
    }
}

function Assert-Match([string] $value, [string] $pattern, [string] $label) {
    if ($value -cnotmatch $pattern) { throw "Missing or changed $label" }
}

Assert-ExactFiles $contentRoot $contentNames
Assert-ExactFiles $sourceRoot $sourceNames

$schemaPath = Join-Path $root '.local/validation/manifest.schema.json'
$schemaHash = 'A3B26A5E135B37DD4A5DF2208752E35092693AB8C54C970FBC9B3B74697854BF'
if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
    throw 'Pinned manifest schema cache is missing. Run: pwsh -File ./scripts/validate.ps1 -FetchSchema'
}
if ((Get-Item -LiteralPath $schemaPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'The schema cache must be a regular file.'
}
if ((Get-FileHash -LiteralPath $schemaPath -Algorithm SHA256).Hash -cne $schemaHash) {
    throw 'Pinned manifest schema checksum mismatch.'
}
$manifestText = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8
if (-not (Test-Json -Json $manifestText -SchemaFile $schemaPath -ErrorAction Stop)) {
    throw 'Gameplay manifest failed the pinned schema.'
}
$manifest = $manifestText | ConvertFrom-Json
if ($manifest.id -cne 'livingworld.core' -or $manifest.author -cne 'livingworld' -or
    $manifest.type -cne 'bundle' -or $manifest.version -cne '0.1.0' -or
    $manifest.min_skyrimnet_version -cne '0.27.0') {
    throw 'Gameplay bundle identity, type, version, or Beta 27 minimum changed.'
}

$action = Get-Content -LiteralPath $actionPath -Raw -Encoding utf8
Assert-Match $action '(?m)^name: LW_OfferContract\r?$' 'action name'
Assert-Match $action '(?m)^questEditorId: LW_ContractController\r?$' 'quest EditorID'
Assert-Match $action '(?m)^scriptName: LW_ContractController\r?$' 'action script'
Assert-Match $action '(?m)^executionFunctionName: RequestOffer\r?$' 'action entry point'
Assert-Match $action '(?m)^  - type: speaker\r?$' 'speaker-only parameter mapping'
Assert-Match $action '(?m)^      - decoratorName: lw_can_offer_contract\r?$' 'eligibility decorator'
Assert-Match $action '(?m)^        expectedValue: eligible\r?$' 'eligibility result'
if ($action -match '(?m)^\s*- type: (dynamic|static)\b|^eventString:|^\s*value:') {
    throw 'The action must not accept LLM terms or publish an outcome event.'
}

$prompt = Get-Content -LiteralPath $promptPath -Raw -Encoding utf8
Assert-Match $prompt 'lw_contract_context\(actorUUID\)' 'read-only context call'
$controller = Get-Content -LiteralPath (Join-Path $sourceRoot 'LW_ContractController.psc') -Raw -Encoding utf8
$decorators = Get-Content -LiteralPath (Join-Path $sourceRoot 'LW_ContractDecorators.psc') -Raw -Encoding utf8
$alias = Get-Content -LiteralPath (Join-Path $sourceRoot 'LW_PlayerAlias.psc') -Raw -Encoding utf8
foreach ($pair in @(
    @($controller, 'Scriptname LW_ContractController extends Quest', 'quest controller'),
    @($controller, 'Int _savedQuantity = 0', 'saved quantity'),
    @($controller, '_savedQuantity = 10', 'fixed quantity'),
    @($controller, '_savedReward = 50', 'fixed reward'),
    @($controller, 'akSpeaker != IssuerRef', 'placed-reference check'),
    @($controller, '_state = 1', 'Offered transition'),
    @($controller, '_activeAttempt != thisAttempt', 'stale response guard'),
    @($controller, 'ElseIf choice == 1', 'explicit rejection only'),
    @($decorators, 'Quest.GetQuest("LW_ContractController")', 'quest lookup'),
    @($alias, 'Event OnInit()', 'alias initialization'),
    @($alias, 'Event OnPlayerLoadGame()', 'alias load callback')
)) {
    if (-not $pair[0].Contains($pair[1])) { throw "Missing $($pair[2])" }
}
if ($controller -match '(?i)\b(RemoveItem|AddItem|RegisterPersistentEvent|MoveTo|SetFactionRank)\s*\(') {
    throw 'Milestone 1 controller contains an out-of-scope economic or movement call.'
}
Write-Host 'PASS: gameplay manifest schema, exact source/content allowlists, and fixed contract source checks.'
Write-Host 'NOT CHECKED by this command: SkyrimNet YAML rendering, Papyrus compilation, ESP/xEdit review, and live gameplay.'

if ($Mode -eq 'Validate') { return }

$configPath = Join-Path $root 'config.local.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw 'Gameplay packaging requires ignored config.local.json with the configured tool paths.'
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
foreach ($name in @('creationKit', 'papyrusCompiler', 'xEdit')) {
    $path = $config.tools.$name
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Gameplay packaging blocked: tools.$name is not configured to an existing executable."
    }
}
$pluginPath = Join-Path $root 'records/LivingWorld.esp'
if (-not (Test-Path -LiteralPath $pluginPath -PathType Leaf)) {
    throw 'Gameplay packaging blocked: authored records/LivingWorld.esp is missing.'
}
$packageFiles = @([pscustomobject]@{ RelativePath = 'LivingWorld.esp'; FullName = $pluginPath })
foreach ($name in $sourceNames) {
    $pex = Join-Path $root ('build/Scripts/' + $name.Replace('.psc', '.pex'))
    if (-not (Test-Path -LiteralPath $pex -PathType Leaf)) {
        throw "Gameplay packaging blocked: compiled output is missing for $name."
    }
    if ((Get-Item -LiteralPath $pex).LastWriteTimeUtc -lt (Get-Item -LiteralPath (Join-Path $sourceRoot $name)).LastWriteTimeUtc) {
        throw "Gameplay packaging blocked: compiled output is older than $name."
    }
    $packageFiles += [pscustomobject]@{ RelativePath = 'Scripts/' + $name.Replace('.psc', '.pex'); FullName = $pex }
}
foreach ($name in $contentNames) {
    $packageFiles += [pscustomobject]@{ RelativePath = $name; FullName = (Join-Path $contentRoot $name) }
}

$dist = Join-Path $root 'dist'
if (Test-Path -LiteralPath $dist) { Assert-RegularDirectory $dist }
else { New-Item -ItemType Directory -Path $dist | Out-Null }
$archivePath = Join-Path $dist 'LivingWorld-Milestone1-0.1.0.zip'
$temporaryPath = Join-Path $dist ([guid]::NewGuid().ToString('N') + '.zip.tmp')
try {
    $stream = [IO.File]::Open($temporaryPath, [IO.FileMode]::CreateNew)
    try {
        $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($file in $packageFiles) {
                $entry = $zip.CreateEntry($file.RelativePath, [IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
                $target = $entry.Open()
                try {
                    $bytes = [IO.File]::ReadAllBytes($file.FullName)
                    $target.Write($bytes, 0, $bytes.Length)
                }
                finally { $target.Dispose() }
            }
        }
        finally { $zip.Dispose() }
    }
    finally { $stream.Dispose() }

    $zip = [IO.Compression.ZipFile]::OpenRead($temporaryPath)
    try {
        if ($zip.Entries.Count -ne $packageFiles.Count) { throw 'Unexpected gameplay ZIP entry count.' }
        foreach ($file in $packageFiles) {
            $entry = $zip.GetEntry($file.RelativePath)
            if ($null -eq $entry) { throw "Missing gameplay ZIP entry: $($file.RelativePath)" }
            $entryStream = $entry.Open()
            try { $archiveHash = (Get-FileHash -InputStream $entryStream -Algorithm SHA256).Hash }
            finally { $entryStream.Dispose() }
            if ($archiveHash -cne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
                throw "Gameplay ZIP content differs from source: $($file.RelativePath)"
            }
            Write-Host "ZIP: $($entry.FullName)"
        }
    }
    finally { $zip.Dispose() }
    Move-Item -LiteralPath $temporaryPath -Destination $archivePath -Force
    Write-Host "Created: $archivePath"
    Write-Host "SHA256: $((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash)"
    Write-Host 'Creation Kit, xEdit, SkyrimNet MCP, and game behavior still require separate verification.'
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath }
}
