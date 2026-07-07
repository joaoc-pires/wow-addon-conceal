$ErrorActionPreference = "Stop"

$AddonFolder = Join-Path $PSScriptRoot "..\Conceal"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReleaseJsonPath = Join-Path $RepoRoot "release.json"

function Show-ErrorPopup($message) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($message, "Package Addon Error", "OK", "Error") | Out-Null
}

try {
    if (-not (Test-Path $AddonFolder)) {
        throw "Addon folder not found: $AddonFolder"
    }

    $tocPath = Join-Path $AddonFolder "Conceal.toc"
    if (-not (Test-Path $tocPath)) {
        throw "TOC file not found: $tocPath"
    }
    $tocText = Get-Content $tocPath -Raw

    if ($tocText -notmatch '(?m)^##\s*Version:\s*(.+)$') {
        throw "Could not find Version in $tocPath"
    }
    $version = $Matches[1].Trim()

    if ($tocText -notmatch '(?m)^##\s*Interface:\s*(.+)$') {
        throw "Could not find Interface in $tocPath"
    }
    $interfaces = $Matches[1].Trim() -split '\s*,\s*'

    $zipName = "Conceal-$version.zip"
    $zipPath = Join-Path $RepoRoot $zipName

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path $AddonFolder -DestinationPath $zipPath

    $release = Get-Content $ReleaseJsonPath -Raw | ConvertFrom-Json
    $release.releases[0].version = $version
    $release.releases[0].filename = $zipName
    $release.releases[0].metadata = @($interfaces | ForEach-Object {
        [PSCustomObject]@{ flavor = "mainline"; interface = [int]$_ }
    })

    $json = $release | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($ReleaseJsonPath, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))

    Write-Host "Created $zipPath and updated release.json"
}
catch {
    Show-ErrorPopup $_.Exception.Message
    exit 1
}
