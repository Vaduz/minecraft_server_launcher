<#
  Minecraft Java Edition – PowerShell Auto‑Update & Launch Script
  ----------------------------------------------------------------
  · Installs OpenJDK 21 with winget if no Java runtime is found.
  · Downloads the latest release (or a user‑specified version) only when
    the server JAR is missing. The version manifest is fetched **only**
    when required (i.e. no version argument or a download is needed).
  · EULA handling:
      ‑ Pass -Eula yes/true to auto‑accept; otherwise an interactive prompt.
  · Defaults: latest release, 16 GB heap, nogui.
#>

Param(
    [string]$Version   = "",      # e.g. "1.20.4" – empty means latest
    [string]$MinMemory = "16G",   # -Xms
    [string]$MaxMemory = "16G",   # -Xmx
    [switch]$Gui,                  # start with GUI when present
    [string]$Eula      = ""       # "yes" / "true" → auto‑accept EULA
)

Set-Location -Path $PSScriptRoot
Write-Host "=== Minecraft Server Auto‑Updater & Launcher ===" -ForegroundColor White

# ----------------------------------------------------------------
# Java runtime: install OpenJDK 21 automatically if missing
# ----------------------------------------------------------------
function Install-Java {
    $java = Get-Command java -ErrorAction SilentlyContinue
    if ($java) {
        Write-Host "Java found : $($java.Source)" -ForegroundColor Green
        return
    }

    Write-Host "Java not found. Installing OpenJDK 21 via winget …" -ForegroundColor Yellow
    try {
        winget install --id Microsoft.OpenJDK.21 -e --accept-package-agreements --accept-source-agreements
        Write-Host "OpenJDK 21 installed. Refreshing PATH …" -ForegroundColor Green
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep 2
    } catch {
        Write-Host "[ERROR] Failed to install Java: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }

    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Java runtime still not available." -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }
}

# ----------------------------------------------------------------
# Manifest download helper (called only when needed)
# ----------------------------------------------------------------
function Get-Manifest {
    $url = 'https://launchermeta.mojang.com/mc/game/version_manifest.json'
    Write-Host "Fetching manifest: $url"
    try {
        return Invoke-RestMethod -UseBasicParsing $url
    } catch {
        Write-Host "[ERROR] Failed to download manifest: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }
}

# ----------------------------------------------------------------
# Ensure that the server JAR exists; download if missing.
# Manifest is fetched lazily when required.
# ----------------------------------------------------------------
function Ensure-ServerJar {
    param([string]$Version, [object]$Manifest)

    $jarName = "minecraft_server-$Version.jar"
    if (Test-Path $jarName) {
        Write-Host "=> $jarName already exists." -ForegroundColor Cyan
        return $jarName
    }

    if (-not $Manifest) { $Manifest = Get-Manifest }

    Write-Host "=> $jarName not found. Downloading …" -ForegroundColor Yellow
    $entry = $Manifest.versions | Where-Object id -eq $Version
    if (-not $entry) {
        Write-Host "[ERROR] Version $Version not present in manifest." -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }

    try {
        $meta = Invoke-RestMethod -UseBasicParsing $entry.url
        $url  = $meta.downloads.server.url
        Write-Host "Download URL   : $url"
        Invoke-WebRequest -Uri $url -OutFile $jarName -UseBasicParsing
        $size = (Get-Item $jarName).Length
        Write-Host "Download complete: $jarName ($size bytes)." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to download JAR: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }

    return $jarName
}

# ----------------------------------------------------------------
# EULA processing
# ----------------------------------------------------------------
function Ensure-Eula {
    param([string]$Path, [bool]$AutoAccept)

    $needsAcceptance = $true
    if (Test-Path $Path) {
        $needsAcceptance = -not (Get-Content $Path | Where-Object { $_ -match '^[\s#]*eula\s*=\s*true' })
    }

    if ($needsAcceptance) {
        if (-not $AutoAccept) {
            Write-Host "You must agree to the Minecraft EULA (https://aka.ms/MinecraftEULA)." -ForegroundColor Yellow
            $answer = Read-Host "Type 'yes' to accept / any other key to abort"
            if ($answer.ToLower() -notin @('y','yes')) {
                Write-Host "EULA not accepted. Aborting." -ForegroundColor Red
                Read-Host "Press Enter to exit"; exit 1
            }
        } else {
            Write-Host "Auto‑accepting EULA due to command‑line flag." -ForegroundColor Cyan
        }

        $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss K')
        @(
            "# By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).",
            "# Accepted via script on $timestamp",
            "eula=true"
        ) | Set-Content -Path $Path -Encoding ASCII
        Write-Host "EULA written to $Path" -ForegroundColor Green
    }

    if (-not (Get-Content $Path | Where-Object { $_ -match '^[\s#]*eula\s*=\s*true' })) {
        Write-Host "[ERROR] eula.txt does not contain eula=true after update." -ForegroundColor Red
        Read-Host "Press Enter to exit"; exit 1
    }
}

# =====================  Main Flow  =====================
Install-Java
$manifest   = $null
$targetVersion = ""

if ([string]::IsNullOrWhiteSpace($Version)) {
    $manifest = Get-Manifest
    $targetVersion = $manifest.latest.release
} else {
    $targetVersion = $Version.Trim()
}

Write-Host "Using version : $targetVersion" -ForegroundColor Cyan
$jarName = Ensure-ServerJar -Version $targetVersion -Manifest $manifest

$eulaFile = Join-Path $PSScriptRoot 'eula.txt'
$accept   = ($Eula) -and ($Eula.ToLower() -in @('yes','true'))
Ensure-Eula -Path $eulaFile -AutoAccept:$accept

# ---------------  Launch Server  ----------------
$javaArgs = @("-Xms$MinMemory", "-Xmx$MaxMemory", "-jar", $jarName)
if (-not $Gui) { $javaArgs += "-nogui" }

Write-Host "`n--- Launching Server ---" -ForegroundColor Magenta
Write-Host "java $($javaArgs -join ' ')" -ForegroundColor DarkGray

& java @javaArgs

Write-Host "`nServer process ended." -ForegroundColor Yellow
Read-Host "Press Enter to close this window."
