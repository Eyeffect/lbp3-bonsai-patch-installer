param([string]$PortDirArg = "")

# ---------------------------------------------------------------------------
# LBP3 Bonsai online patch installer / updater for littlebigplanet3-pc (Windows)
# Double-click the .bat file next to this script. Run it again any time to
# auto-update: it downloads the patch, compares its SHA-256 to the installed
# copy, and only reinstalls when the file actually changed.
# ---------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgUrl    = Join-Path $scriptDir "patch-source.txt"
$cfgPort   = Join-Path $scriptDir "port-path.txt"
$cfgHash   = Join-Path $scriptDir "installed-hash.txt"
$tmpZip    = Join-Path $env:TEMP "lbp3-bonsai-patch-update.zip"
$stage     = Join-Path $env:TEMP "lbp3-bonsai-patch-stage"

# Link captured from the Discord attachment. Discord signs this URL, so it can
# expire. If it does, the script asks you to paste a fresh "Copy link" from
# Discord and remembers it for next time.
$defaultUrl = "https://cdn.discordapp.com/attachments/1544884611962900520/1556048296441675886/lbp3-128-online.zip?backend=b2&ex=6b000c27&is=6afebaa7&hm=637539edd70aa65719534795c9c2d84445e29388efe16da36477236ce7dad389"

function Head($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }
function Good($text) { Write-Host $text -ForegroundColor Green }
function Info($text) { Write-Host $text -ForegroundColor Gray }
function Warn($text) { Write-Host $text -ForegroundColor Yellow }
function Die($text) { Write-Host "`nERROR: $text" -ForegroundColor Red; throw $text }
function SaveText($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function ReadText($path) { if (Test-Path -LiteralPath $path) { (Get-Content -LiteralPath $path -Raw).Trim() } else { "" } }
function Get-TitleIds($doc) {
    @($doc.Patch.TitleID.ID | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.InnerText } })
}

function Find-Port($arg) {
    if ($arg) {
        try {
            $p = (Resolve-Path -LiteralPath $arg -ErrorAction Stop).Path
            if (Test-Path (Join-Path $p "LittleBigPlanet 3.exe")) { return $p }
        } catch { }
    }
    $saved = ReadText $cfgPort
    if ($saved -and (Test-Path (Join-Path $saved "LittleBigPlanet 3.exe"))) { return $saved }

    $candidates = @(
        "D:\lbp3-pc",
        "C:\lbp3-pc",
        "C:\Games\LittleBigPlanet 3 PC",
        (Join-Path $env:USERPROFILE "Downloads\lbp3-pc"),
        (Join-Path $env:USERPROFILE "Desktop\lbp3-pc"),
        (Join-Path $env:USERPROFILE "Downloads\littlebigplanet3-pc")
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path (Join-Path $c "LittleBigPlanet 3.exe"))) { return $c }
    }

    Head "Find your game"
    Info "Could not find the installation automatically."
    Info "Tip: drag the folder containing 'LittleBigPlanet 3.exe' onto the .bat file."
    $p = Read-Host "Paste the full folder path here"
    $p = $p.Trim('"', ' ')
    if (-not $p) { Die "No folder was entered." }
    if (-not (Test-Path (Join-Path $p "LittleBigPlanet 3.exe"))) { Die "That folder does not contain 'LittleBigPlanet 3.exe'." }
    return (Resolve-Path -LiteralPath $p).Path
}

function Fetch-Patch($source, $destination) {
    if ($source -match '^https?://') {
        Invoke-WebRequest -Uri $source -OutFile $destination -UseBasicParsing -TimeoutSec 90
    } else {
        if (-not (Test-Path -LiteralPath $source)) { Die "Local file not found: $source" }
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}

function Check-Zip($zip) {
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $result = @()
        foreach ($entry in $archive.Entries) {
            if ($entry.Length -le 0 -or $entry.FullName -notlike "*.xml") { continue }
            $reader = [IO.StreamReader]::new($entry.Open())
            $raw = $reader.ReadToEnd()
            $reader.Dispose()
            try { [xml]$doc = $raw } catch { Die "Invalid XML inside the download: $($entry.FullName)" }
            $ids = Get-TitleIds $doc
            if ($ids -notcontains "CUSA00473") { continue }
            foreach ($meta in @($doc.Patch.Metadata)) {
                $elf = [string]$meta.AppElf
                $ver = [string]$meta.AppVer
                $name = [string]$meta.Name
                if ($elf -and $elf -ine "eboot.bin") { continue }
                if ($ver -and $ver -ne "01.28") { continue }
                if (-not $name) { continue }
                if (@($meta.PatchList.Line).Count -eq 0) { continue }
                $result += $name
            }
        }
        if ($result.Count -eq 0) { Die "The download has no patch for CUSA00473 v01.28 / eboot.bin." }
        return $result
    } finally { $archive.Dispose() }
}

function Extract-PatchFiles($zip, $folder) {
    Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $folder)
    return @(Get-ChildItem -LiteralPath $folder -Recurse -File | Where-Object {
        $_.Extension -ieq ".xml" -or $_.Name -ieq "files.json"
    })
}

function Get-EnabledKeys($installDir) {
    $keys = @()
    foreach ($xml in (Get-ChildItem -LiteralPath $installDir -File -Filter *.xml)) {
        [xml]$doc = Get-Content -LiteralPath $xml.FullName -Raw
        $ids = Get-TitleIds $doc
        if ($ids -notcontains "CUSA00473") { continue }
        $filesJson = Join-Path $installDir "files.json"
        $map = $null
        if (Test-Path -LiteralPath $filesJson) {
            try { $map = ((Get-Content -LiteralPath $filesJson -Raw).TrimStart([char]0xFEFF) | ConvertFrom-Json) } catch { }
        }
        foreach ($meta in @($doc.Patch.Metadata)) {
            $elf = [string]$meta.AppElf
            $ver = [string]$meta.AppVer
            if ($elf -and $elf -ine "eboot.bin") { continue }
            if ($ver -and $ver -ne "01.28") { continue }
            $label = $xml.Name
            if ($map) {
                foreach ($prop in $map.PSObject.Properties) {
                    $serials = @($prop.Value)
                    if ($serials -contains "CUSA00473" -and $prop.Name -ieq $xml.Name) {
                        $label = "$($xml.Directory.Name)/$($prop.Name)"
                        break
                    }
                }
            }
            $keys += "$label/$($meta.Name)"
        }
    }
    return $keys
}

function Set-IniValue($path, $key, $value) {
    $lines = @()
    if (Test-Path -LiteralPath $path) { $lines = @(Get-Content -LiteralPath $path) }
    $out = New-Object System.Collections.Generic.List[string]
    $found = $false
    $pattern = '^\s*' + [regex]::Escape($key) + '\s*='
    foreach ($line in $lines) {
        if ($line -match $pattern) { $out.Add("$key=$value"); $found = $true }
        else { $out.Add($line) }
    }
    if (-not $found) { $out.Add("$key=$value") }
    [IO.File]::WriteAllLines($path, $out, [Text.UTF8Encoding]::new($false))
}

try {
    Head "LBP3 Bonsai online patch installer / updater"
    Info "Works on any existing littlebigplanet3-pc installation. Run again to auto-update."

    $port = Find-Port $PortDirArg
    Good "Game: $port"

    # --- Patch source link -------------------------------------------------
    $source = ReadText $cfgUrl
    if (-not $source) { $source = $defaultUrl; SaveText $cfgUrl $source }
    Head "Patch download link"
    Info "Saved link: $source"
    Info "If Discord says the link expired: right-click the zip in Discord > Copy link."
    $change = Read-Host "Press Enter to use this link, or type L to paste a new one"
    if ($change -ieq "L") {
        $newSource = (Read-Host "Paste the new link, or the full path to the local zip").Trim('"', ' ')
        if (-not $newSource) { Die "No link entered." }
        $source = $newSource
        SaveText $cfgUrl $source
        Good "New link saved for future updates."
    }

    # --- Download ----------------------------------------------------------
    Head "Downloading patch"
    $downloaded = $false
    for ($attempt = 1; $attempt -le 3 -and -not $downloaded; $attempt++) {
        try {
            Fetch-Patch $source $tmpZip
            $downloaded = $true
        } catch {
            Warn "Download failed: $($_.Exception.Message)"
            if ($attempt -eq 3) { Die "Could not download the patch. Check the link and try again." }
            $fresh = (Read-Host "Paste a fresh Discord 'Copy link' URL (or press Enter to retry)").Trim('"', ' ')
            if ($fresh) { $source = $fresh; SaveText $cfgUrl $source; Info "Saved. Retrying..." }
        }
    }
    $names = Check-Zip $tmpZip
    foreach ($n in $names) { Good "Verified patch: $n" }
    $newHash = (Get-FileHash -LiteralPath $tmpZip -Algorithm SHA256).Hash
    Info "SHA-256: $newHash"

    $installDir = Join-Path (Join-Path $port "data\patches") "bonsai-online"
    $backup = $null
    $oldHash = ReadText $cfgHash
    if ($oldHash -eq $newHash -and (Test-Path -LiteralPath $installDir)) {
        Good "Already up to date. No files changed."
    } else {
        Head "Installing patch"
        $files = Extract-PatchFiles $tmpZip $stage
        if ((@($files | Where-Object { $_.Extension -ieq ".xml" })).Count -eq 0 -or
            (@($files | Where-Object { $_.Name -ieq "files.json" })).Count -eq 0) {
            Die "The download must contain an .xml patch and files.json."
        }
        if (Test-Path -LiteralPath $installDir) {
            $backup = Join-Path (Split-Path $installDir -Parent) ("bonsai-online.backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
            Move-Item -LiteralPath $installDir -Destination $backup
            Info "Old patch backed up to: $backup"
        }
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null
        foreach ($f in $files) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $installDir $f.Name) -Force }
        SaveText $cfgHash $newHash
        Good "Patch installed to: $installDir"
    }

    # --- Enable the patch --------------------------------------------------
    Head "Enabling patch"
    $destRoot = Split-Path $installDir -Parent
    New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
    $newKeys = Get-EnabledKeys $installDir
    if ($newKeys.Count -eq 0) { Die "Could not determine the patch name for patches.json." }

    $patchJson = Join-Path $port "data\patches.json"
    $existing = @{ enabled = @(); disabled = @() }
    if (Test-Path -LiteralPath $patchJson) {
        try {
            $parsed = (Get-Content -LiteralPath $patchJson -Raw).TrimStart([char]0xFEFF) | ConvertFrom-Json
            if ($parsed.enabled)  { $existing.enabled  = @($parsed.enabled) }
            if ($parsed.disabled) { $existing.disabled = @($parsed.disabled) }
        } catch { Warn "Existing patches.json could not be read; starting fresh." }
    }
    $allEnabled = @($existing.enabled) + $newKeys | Select-Object -Unique
    # Drop stale entries for the same patch (old folder name or loose file).
    $patchNames = @($newKeys | ForEach-Object { ($_ -split '/')[-1] })
    $allEnabled = @($allEnabled | Where-Object {
        $k = $_
        -not ($patchNames | Where-Object { $k.EndsWith("/" + $_) -and $newKeys -notcontains $k })
    })
    $allDisabled = @($existing.disabled) | Where-Object { $allEnabled -notcontains $_ }
    $json = @{ enabled = @($allEnabled); disabled = @($allDisabled) } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($patchJson, $json, [Text.UTF8Encoding]::new($false))
    foreach ($k in $newKeys) { Good "Enabled: $k" }

    # --- Online settings ---------------------------------------------------
    Head "Online settings"
    $ini = Join-Path $port "data\lbp3.ini"
    if (-not (Test-Path -LiteralPath $ini)) { Die "lbp3.ini not found in data folder." }
    $id = ""
    $match = Select-String -LiteralPath $ini -Pattern '^\s*online_id\s*=\s*(.*)$' | Select-Object -Last 1
    if ($match) { $id = $match.Matches[0].Groups[1].Value.Trim() }
    if ($id -match '^[A-Za-z0-9_-]{3,16}$') {
        Info "Current Bonsai username (online_id): $id"
        $newId = (Read-Host "Press Enter to keep it, or type a different username").Trim()
        if ($newId) { $id = $newId }
    }
    while ($id -notmatch '^[A-Za-z0-9_-]{3,16}$') {
        Warn "online_id is missing or invalid (3-16 letters/numbers/_/-)."
        $id = (Read-Host "Enter your Bonsai username").Trim()
    }
    Set-IniValue $ini "online_id" $id
    Set-IniValue $ini "lbp3_online" "1"
    Good "lbp3_online=1, online_id=$id"

    # A backup folder still containing files.json would be auto-enabled by the
    # launcher (patches with isEnabled="true" are picked up from every folder).
    if ($backup -and (Test-Path -LiteralPath $backup)) {
        $backupIndex = Join-Path $backup "files.json"
        if (Test-Path -LiteralPath $backupIndex) {
            Rename-Item -LiteralPath $backupIndex -NewName "files.json.bak" -Force
            Info "Backup disabled (kept at $backup)."
        }
    }

    SaveText $cfgPort $port

    Head "Done"
    Good "1. Start LittleBigPlanet 3 and press Play."
    Good "2. If you get a 403: on the Bonsai website enable 'Allow IP Authentication' and approve the login request."
    Good "3. Run this installer again any time to auto-update the patch."
    Info "When the Discord link expires, choose L and paste a fresh 'Copy link'."
} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
