#requires -Version 7.4
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$validated = & (Join-Path $PSScriptRoot 'validate.ps1') -PassThru
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $repositoryRoot 'dist'
if (Test-Path -LiteralPath $outputDirectory) {
    $item = Get-Item -LiteralPath $outputDirectory -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'dist must be a regular directory inside the repository.'
    }
}
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$archivePath = Join-Path $outputDirectory "LivingWorld-SmokeTest-$($validated.Manifest.version).zip"
$temporaryPath = Join-Path $outputDirectory ([guid]::NewGuid().ToString('N') + '.zip.tmp')

try {
    $stream = [IO.File]::Open($temporaryPath, [IO.FileMode]::CreateNew)
    try {
        $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($file in $validated.Files) {
                $entry = $zip.CreateEntry($file.RelativePath, [IO.Compression.CompressionLevel]::Optimal)
                # Fixed metadata makes repeated builds from identical bytes reproducible.
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

    # Inspect the actual archive; ZIP entry names must match the Data-content layout.
    $zip = [IO.Compression.ZipFile]::OpenRead($temporaryPath)
    try {
        if ($zip.Entries.Count -ne $validated.Files.Count) { throw 'Unexpected ZIP entry count.' }
        foreach ($file in $validated.Files) {
            $entry = $zip.GetEntry($file.RelativePath)
            if ($null -eq $entry) { throw "Missing ZIP entry: $($file.RelativePath)" }
            $entryStream = $entry.Open()
            try { $archiveHash = (Get-FileHash -InputStream $entryStream -Algorithm SHA256).Hash }
            finally { $entryStream.Dispose() }
            if ($archiveHash -cne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
                throw "ZIP content differs from source: $($file.RelativePath)"
            }
            Write-Host "ZIP: $($entry.FullName)"
        }
    }
    finally { $zip.Dispose() }

    Move-Item -LiteralPath $temporaryPath -Destination $archivePath -Force
    Write-Host "Created: $archivePath"
    Write-Host "SHA256: $((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash)"
    Write-Host 'Install manually in MO2. Runtime acceptance is pending.'
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath }
}
