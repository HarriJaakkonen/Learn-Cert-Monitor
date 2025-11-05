<#
.SYNOPSIS
    Monitors Microsoft Learn certifications for upcoming expirations (macOS variant).

.DESCRIPTION
    Cross-platform PowerShell (pwsh) version tailored for macOS. Uses the Microsoft Learn
    transcript share API to check for expiring certifications and shows native macOS
    notifications via `osascript`.

    This script intentionally does not modify or call any Windows-specific APIs and
    is provided alongside `get-learncerts-api.ps1` without changing it.

.PARAMETER TranscriptUrl
    Microsoft Learn transcript share URL. Example: https://learn.microsoft.com/.../transcript/ABC123XYZ

.PARAMETER ShareCode
    Share code extracted from the transcript URL (ABC123XYZ)

.PARAMETER Days
    Number of days ahead to consider a certification as "expiring" (default: 100)

.PARAMETER CreateAutomation
    Create a LaunchAgent in ~/Library/LaunchAgents to run this script at login (optional).

.PARAMETER AutomationMethod
    Currently supports: "LaunchAgent" or "Remove" (to remove the LaunchAgent)

.PARAMETER VerboseConsole
    Show additional output to console

.EXAMPLE
    pwsh ./get-learncerts-api-macos.ps1 -ShareCode ABC123XYZ

.EXAMPLE
    pwsh ./get-learncerts-api-macos.ps1 -ShareCode ABC123XYZ -CreateAutomation -AutomationMethod LaunchAgent
#>

[CmdletBinding(DefaultParameterSetName = 'Manual')]
param(
    [Parameter(ParameterSetName = 'Manual')]
    [Parameter(ParameterSetName = 'Automation')]
    [string]$TranscriptUrl,

    [Parameter(ParameterSetName = 'Manual')]
    [Parameter(ParameterSetName = 'Automation')]
    [string]$ShareCode,

    [int]$Days = 100,

    [switch]$CreateAutomation,

    [ValidateSet('LaunchAgent', 'Remove')]
    [string]$AutomationMethod = 'LaunchAgent',

    [switch]$VerboseConsole
)

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    if ($script:VerboseConsole) { Write-Host $Message -ForegroundColor $Color }
}

function Extract-ShareCodeFromUrl {
    param([string]$Url)
    if (-not $Url) { return $null }
    try {
        $uri = [Uri]$Url
        $segments = $uri.Segments | ForEach-Object { $_.Trim('/') } | Where-Object { $_ -ne '' }
        return $segments[-1]
    }
    catch {
        return $null
    }
}

function Get-TranscriptJson {
    param([string]$code)
    if (-not $code) { throw 'No share code provided' }
    $url = "https://learn.microsoft.com/api/profiles/transcript/share/$code"
    Write-Log "Fetching transcript JSON from $url"
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        if (-not $resp) { throw 'API returned empty response' }
        return $resp
    }
    catch {
        throw "Failed to fetch transcript from $url : $($_.Exception.Message)"
    }
}

function Get-CertificationsFromJson {
    param([object]$json)
    # The JSON may contain certifications at different paths; try common locations
    if (-not $json) { return @() }
    if ($json.certifications) { return $json.certifications }
    if ($json.transcript -and $json.transcript.certifications) { return $json.transcript.certifications }
    if ($json.achievements) { return $json.achievements }
    if ($json.transcript -and $json.transcript.achievements) { return $json.transcript.achievements }
    return @()
}

function Parse-ExpirationDate {
    param($cert)
    # Try a series of common fields
    $fields = @('expirationDate', 'dateExpires', 'expires', 'expiredAt', 'expiry')
    foreach ($f in $fields) {
        if ($cert.PSObject.Properties.Name -contains $f) {
            $val = $cert.$f
            if ($val) {
                try { return [DateTime]::Parse($val) } catch { }
            }
        }
    }
    # Some records have nested objects
    if ($cert.issued && $cert.issued.expires) {
        try { return [DateTime]::Parse($cert.issued.expires) } catch { }
    }
    return $null
}

function Show-Notification-Mac {
    param([string]$Title, [string]$Body)
    if (-not $Title) { $Title = 'Learn Cert Monitor' }
    if (-not $Body) { $Body = '' }
    # Use osascript to show native macOS notification
    # Escape single quotes for AppleScript by doubling them
    $escapedBody = $Body -replace "'", "''"
    $escapedTitle = $Title -replace "'", "''"
    $script = "display notification '$escapedBody' with title '$escapedTitle'"
    try {
        & osascript -e $script
    }
    catch {
        # Fallback to console
        Write-Host "[notification] $Title - $Body"
    }
}

function Check-Expirations {
    param([string]$code)
    $json = Get-TranscriptJson -code $code
    $certs = Get-CertificationsFromJson -json $json
    if (-not $certs -or $certs.Count -eq 0) {
        Write-Log "No certifications found in transcript" 'Yellow'
        return
    }

    $now = (Get-Date)
    foreach ($c in $certs) {
        $title = $c.title ? $c.title : ($c.certificationName ? $c.certificationName : ($c.name ? $c.name : ($c.id ? $c.id : 'Certification')))
        $exp = Parse-ExpirationDate -cert $c
        if (-not $exp) { Write-Log "Could not determine expiration for $title" 'DarkYellow'; continue }
        $daysLeft = ([int](([TimeSpan]::FromTicks(($exp - $now).Ticks)).TotalDays))
        Write-Log "$title expires on $exp ($daysLeft days left)" 'Gray'
        if ($daysLeft -le $Days) {
            $body = "Expires in $daysLeft day(s) — $title (Expires: $($exp.ToString('yyyy-MM-dd')))"
            Show-Notification-Mac -Title "Certificate expiring: $title" -Body $body
        }
    }
}

function Ensure-LaunchAgent {
    param([string]$plistName, [string]$scriptPath, [string[]]$argumentList)
    $homeDir = $env:HOME
    $launchDir = Join-Path $homeDir 'Library/LaunchAgents'
    if (-not (Test-Path $launchDir)) { New-Item -ItemType Directory -Path $launchDir | Out-Null }
    $plistPath = Join-Path $launchDir "$plistName.plist"

    $programArgs = @('pwsh', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) + $argumentList
    $programArgsXml = $programArgs | ForEach-Object { "        <string>$_</string>" } | Out-String

    $plist = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$plistName</string>
	<key>ProgramArguments</key>
	<array>
$programArgsXml	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<false/>
	<key>StandardOutPath</key>
	<string>$homeDir/Library/Logs/$plistName.out</string>
	<key>StandardErrorPath</key>
	<string>$homeDir/Library/Logs/$plistName.err</string>
</dict>
</plist>
"@

    Set-Content -Path $plistPath -Value $plist -Encoding UTF8
    Write-Log "Created LaunchAgent at $plistPath" 'Green'
    try { & launchctl load $plistPath } catch { Write-Log "Could not load LaunchAgent: $($_.Exception.Message)" 'Yellow' }
}

function Remove-LaunchAgent {
    param([string]$plistName)
    $homeDir = $env:HOME
    $plistPath = Join-Path $homeDir "Library/LaunchAgents/$plistName.plist"
    if (Test-Path $plistPath) {
        try { & launchctl unload $plistPath } catch { }
        Remove-Item $plistPath -Force
        Write-Log "Removed LaunchAgent $plistPath" 'Green'
    }
    else {
        Write-Log "No LaunchAgent found at $plistPath" 'Yellow'
    }
}

# Main entry
if ($CreateAutomation) {
    if (-not $ShareCode) { $ShareCode = Extract-ShareCodeFromUrl -Url $TranscriptUrl }
    if (-not $ShareCode) { Write-Host "ShareCode or TranscriptUrl is required for automation setup"; exit 1 }
    $plistName = 'com.user.LearnCertMonitor'
    $scriptFullPath = (Resolve-Path -Path $PSCommandPath).Path
    $argList = @('-ShareCode', $ShareCode)

    if ($AutomationMethod -eq 'Remove') {
        Remove-LaunchAgent -plistName $plistName
        Write-Host "Removed LaunchAgent (if present)"; exit 0
    }

    Ensure-LaunchAgent -plistName $plistName -scriptPath $scriptFullPath -argumentList $argList
    Write-Host "LaunchAgent created. It will run at user login."; exit 0
}

# Normal run
if (-not $ShareCode) { $ShareCode = Extract-ShareCodeFromUrl -Url $TranscriptUrl }
if (-not $ShareCode) { Write-Host "Please provide -ShareCode or -TranscriptUrl"; exit 1 }

try {
    Check-Expirations -code $ShareCode
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

exit 0
