#requires -Version 7.4
[CmdletBinding()]
param(
    [string] $ContentRoot = (Join-Path $PSScriptRoot '../content'),
    [switch] $FetchSchema,
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$bundlePath = 'SKSE/Plugins/SkyrimNet/external/livingworld.smoke-test'
$expectedFiles = @(
    "$bundlePath/manifest.json",
    "$bundlePath/prompts/living_world_smoke_test.prompt"
)
$schemaRevision = '232d5e902356595b4a70d97ad04cae03a93e69c3'
$schemaHash = 'A3B26A5E135B37DD4A5DF2208752E35092693AB8C54C970FBC9B3B74697854BF'
$schemaUrl = "https://raw.githubusercontent.com/MinLL/SkyrimNet-Plugins/$schemaRevision/schemas/manifest.schema.json"
$schemaDirectory = Join-Path $repositoryRoot '.local/validation'
$schemaPath = Join-Path $schemaDirectory 'manifest.schema.json'

# Reject redirected output directories before downloading the local schema cache.
foreach ($directory in @((Join-Path $repositoryRoot '.local'), $schemaDirectory)) {
    if (Test-Path -LiteralPath $directory) {
        $item = Get-Item -LiteralPath $directory -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Expected a regular directory: $directory"
        }
    }
}

if ($FetchSchema) {
    New-Item -ItemType Directory -Path $schemaDirectory -Force | Out-Null
    $downloadPath = Join-Path $schemaDirectory 'manifest.schema.download'
    try {
        Invoke-WebRequest -Uri $schemaUrl -OutFile $downloadPath
        if ((Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash -cne $schemaHash) {
            throw 'Downloaded manifest schema does not match the pinned SHA256.'
        }
        Move-Item -LiteralPath $downloadPath -Destination $schemaPath -Force
        Write-Host "Cached official manifest schema at revision $schemaRevision."
    }
    finally {
        if (Test-Path -LiteralPath $downloadPath) {
            Remove-Item -LiteralPath $downloadPath
        }
    }
}

if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
    throw 'Manifest schema cache is missing. Run: pwsh -File ./scripts/validate.ps1 -FetchSchema (requires network once).'
}
if ((Get-Item -LiteralPath $schemaPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'The schema cache must be a regular file.'
}
if ((Get-FileHash -LiteralPath $schemaPath -Algorithm SHA256).Hash -cne $schemaHash) {
    throw 'Cached schema checksum mismatch. Re-fetch with ./scripts/validate.ps1 -FetchSchema.'
}

$root = Get-Item -LiteralPath $ContentRoot -Force
if (-not $root.PSIsContainer -or ($root.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'ContentRoot must be a regular directory.'
}
$items = @(Get-ChildItem -LiteralPath $root.FullName -Recurse -Force)
$allowedDirectories = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($relativePath in $expectedFiles) {
    $parent = $relativePath
    while ($parent.Contains('/')) {
        $parent = $parent.Substring(0, $parent.LastIndexOf('/'))
        [void] $allowedDirectories.Add($parent)
    }
}
$files = @()
foreach ($item in $items) {
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Links and junctions are not allowed in the payload: $($item.Name)"
    }
    $relativePath = [IO.Path]::GetRelativePath($root.FullName, $item.FullName).Replace('\', '/')
    if ($item.PSIsContainer) {
        if (-not $allowedDirectories.Contains($relativePath)) {
            throw "Unexpected payload directory: $relativePath"
        }
    }
    else {
        if ($expectedFiles -cnotcontains $relativePath) {
            throw "Unexpected payload file: $relativePath"
        }
        $files += [pscustomobject]@{ RelativePath = $relativePath; FullName = $item.FullName }
    }
}
if ($files.Count -ne $expectedFiles.Count) {
    throw 'The smoke-test payload must contain exactly the manifest and diagnostic prompt.'
}

$manifestPath = Join-Path $root.FullName $expectedFiles[0]
$manifestText = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8
if (-not (Test-Json -Json $manifestText -SchemaFile $schemaPath -ErrorAction Stop)) {
    throw 'Manifest failed the official JSON Schema validation.'
}
$manifest = $manifestText | ConvertFrom-Json
if ($manifest.id -cne 'livingworld.smoke-test' -or $manifest.author -cne 'livingworld' -or $manifest.type -cne 'bundle') {
    throw 'Manifest id, author, and type must match this smoke-test bundle.'
}
if ($manifest.version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
    throw 'Use a MAJOR.MINOR.PATCH release version without leading zeros for this smoke test.'
}
if ($manifest.min_skyrimnet_version -cne '0.27.0') {
    throw 'This smoke test targets SkyrimNet Beta 27 (0.27.0).'
}

# This deliberately supports only the literal diagnostic entry, not arbitrary Inja syntax.
$prompt = [IO.File]::ReadAllText((Join-Path $root.FullName $expectedFiles[1])).Replace("`r`n", "`n")
if ($prompt -cne "LW_SMOKE_TEST_OK: Living World content bundle is available.`n") {
    throw 'Diagnostic prompt must contain only the expected literal marker and a final newline.'
}

Write-Host 'PASS: pinned official manifest schema, bundle identity/version, exact two-file payload, and literal diagnostic prompt.'
Write-Host 'Runtime discovery and Inja engine validation still require the manual SkyrimNet test.'
if ($PassThru) {
    [pscustomobject]@{ Manifest = $manifest; Files = @($files | Sort-Object RelativePath) }
}
