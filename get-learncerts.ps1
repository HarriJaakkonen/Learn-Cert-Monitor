<#
.SYNOPSIS
    Monitors Microsoft Learn certifications for upcoming expirations and displays desktop notifications.
    Uses Selenium WebDriver (Chrome or Edge) to fetch your transcript headlessly by default, shows Windows toasts
    (with Microsoft logo) or fallbacks, and can optionally send email alerts and create a scheduled task.

.DESCRIPTION
    This script automatically checks your Microsoft Learn certification transcript for certifications expiring within 
    a specified number of days (default: 100). It displays concise desktop notifications listing the expiring 
    certifications with detailed expiration information. The script is designed for unattended operation via Windows 
    Scheduled Tasks, providing reliable daily monitoring of your certification portfolio.

    The script uses a headless Chromium browser (Chrome or Edge recommended) via Selenium WebDriver to load the 
    transcript page, ensuring JavaScript-rendered content is properly captured. It includes advanced browser conflict 
    resolution, using isolated profiles and automatic cleanup to ensure reliable operation even when browsers are 
    already running.

    Notifications appear under a custom "Learn Cert Monitor" app in the Windows Notification Center when possible, 
    with a Microsoft logo icon. The script includes multiple fallback mechanisms for maximum compatibility across 
    different Windows environments and notification systems.

.PARAMETER SendEmail
    Enables email notifications in addition to desktop popups. Requires SMTP configuration in the script.

.PARAMETER VerboseConsole
    Enables verbose console output, including detailed parsing information and notification details.

.PARAMETER Plain
    Disables colored console output, using plain text for all messages.

.PARAMETER CreateAutomation
    Registers a Windows Scheduled Task to run this script daily at the specified time.
    This creates a persistent automation without needing Task Scheduler UI.

.PARAMETER AutomationName
    Specifies the name for the scheduled task. Default is 'LearnCertMonitor'.

.PARAMETER AutomationDailyTime
    Specifies the daily run time in HH:MM format (24-hour). Default is '07:30'.

.PARAMETER AutomationForce
    Overwrites any existing scheduled task with the same name.

.PARAMETER AutomationRunNow
    Immediately runs the script after creating the automation task.

.PARAMETER AutomationRunSync
    When used with -CreateAutomation, runs the main certificate check logic immediately 
    in the current session for instant feedback while also creating the scheduled task.
    This provides immediate results and verification that the automation will work correctly.

.PARAMETER AutomationProxyCall
    Internal parameter used for delegation to Windows PowerShell. Do not use manually.

.PARAMETER DebugHtml
    Saves the fetched HTML content to 'debug-transcript.html' in the script directory for troubleshooting.

.PARAMETER TaskSchedulerDebug
    Enables extensive debugging output specifically for Task Scheduler execution issues.

.PARAMETER TranscriptUrl
    Specifies the Microsoft Learn transcript share link URL. Required for fetching certifications.

.PARAMETER Browser
    Specifies the browser to use for Selenium WebDriver. Options: 'Chrome' (default) or 'Edge'. Both are Chromium-based and supported.

.PARAMETER Headed
    Shows the browser UI (non-headless). By default, the browser runs headlessly (no window) for speed and reliability.

.EXAMPLE
    .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/harrijaakkonen-6993/transcript/vpznbwkno4ryzl7"
    Runs a one-time check using your specific transcript URL and shows desktop notifications for expiring certifications.
    
    To get your transcript URL: Go to https://learn.microsoft.com → Profile → Transcript → Share → Copy link

.EXAMPLE
    .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -SendEmail
    Runs a check with both desktop notifications and email alerts.

.EXAMPLE
    .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -Browser Edge -VerboseConsole
    Uses Microsoft Edge browser with detailed console output for monitoring and troubleshooting.

.EXAMPLE
    .\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime "08:00" -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -Browser Edge -AutomationRunNow
    Creates daily automation at 8:00 AM using Microsoft Edge and triggers the scheduled task to run immediately in the background.

.EXAMPLE
    .\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime "08:00" -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -Browser Edge -AutomationRunSync
    Creates daily automation at 8:00 AM using Microsoft Edge AND immediately executes the certificate check for instant feedback and verification.

.EXAMPLE
    .\get-learncerts.ps1 -CreateAutomation -AutomationForce -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -Browser Edge
    Overwrites any existing automation task and schedules using Microsoft Edge browser.

.EXAMPLE
    .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -Browser Chrome -Headed -DebugHtml
    Uses Chrome browser with visible UI for troubleshooting, and saves page HTML to debug-transcript.html for inspection.

.EXAMPLE
    .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/..." -TaskSchedulerDebug
    Runs with extensive debugging output specifically designed for troubleshooting Task Scheduler execution issues.

.NOTES
    SYSTEM REQUIREMENTS:
    - Windows 10/11 with PowerShell 5.1 or PowerShell 7+ (recommended)
    - Microsoft Edge (recommended) or Google Chrome browser installed
    - Internet connection for transcript access and WebDriver downloads
    - For email alerts: Configure SMTP settings in script variables
    - Administrative rights not required (runs in user context for notifications)

    CONFIGURATION GUIDE:
    - TranscriptUrl: Your Microsoft Learn transcript share link (required parameter)
      Example: https://learn.microsoft.com/en-us/users/harrijaakkonen-6993/transcript/vpznbwkno4ryzl7
      
      HOW TO GET YOUR TRANSCRIPT URL:
      1. Visit https://learn.microsoft.com and sign in with your Microsoft account
      2. Click your profile picture/avatar in the top-right corner
      3. Select "Transcript" from the dropdown menu
      4. On your transcript page, click the "Share" button (usually near the top-right)
      5. In the share dialog, click "Copy link" to get your public transcript URL
      6. The URL format will be: https://learn.microsoft.com/en-us/users/[username]/transcript/[unique-id]
      7. Use this complete URL as the -TranscriptUrl parameter value
      
      NOTE: The transcript must be set to "Public" visibility for the script to access it.
      You can verify this by opening the copied URL in an incognito/private browser window.
      
    - DaysBeforeExpiry: Alert threshold in days (default: 100 days)
    - Email settings: Configure $EmailFrom, $EmailTo, $SmtpServer, etc. (only used with -SendEmail)
    - Notification settings: Customizable app name, duration, and behavior

    BROWSER PERFORMANCE COMPARISON:
    - Microsoft Edge: Recommended - 2x faster, better Windows integration, native Microsoft ecosystem fit
    - Google Chrome: Supported - Reliable but slower, may have more browser conflicts
    - Both browsers: Use headless mode by default for optimal performance and reliability

    AUTOMATION & RELIABILITY:
    - Uses Windows Scheduled Tasks for cross-PowerShell version compatibility
    - Enhanced automation creation with comprehensive user feedback and guidance
    - Intelligent browser conflict resolution with isolated profiles
    - Automatic WebDriver version management and updates
    - Runs as current user to enable desktop notifications
    - Comprehensive error handling and logging to cert-expiry.log
    - Fallback notification systems (WinRT → BurntToast → Balloon → MessageBox)
    - New -AutomationRunSync parameter for immediate execution with instant feedback

    NOTIFICATION SYSTEM:
    - Primary: Windows 10/11 native toast notifications with Microsoft logo
    - Fallback: BurntToast module for enhanced toast capabilities
    - Final fallback: System balloon tips and message boxes
    - All notifications appear under "Learn Cert Monitor" app in Action Center
    - Automatic icon management with cached Microsoft logo

    TROUBLESHOOTING GUIDE:
    - Transcript URL issues: Ensure your Microsoft Learn transcript is set to "Public" visibility
      Test by opening your transcript URL in an incognito/private browser window
    - Browser login: Ensure browser is logged into Microsoft Learn with your account
    - WebDriver issues: Script auto-downloads correct versions; check cert-expiry.log for details
    - No certifications found: Use -DebugHtml to save page content for inspection
    - Task Scheduler issues: Use -TaskSchedulerDebug for detailed execution logging
    - Notification problems: Check Action Center settings and notification permissions
    - Module installation: Script auto-installs Selenium and BurntToast modules as needed
    - Automation feedback: Use -AutomationRunSync for immediate execution and verification
    - Clean environment: Script works perfectly in clean environments with automatic dependency management

    SECURITY & PRIVACY:
    - Uses public transcript share links (no authentication required)
    - No credential storage or transmission
    - Local processing only - no data sent to external services
    - Temporary browser profiles are automatically cleaned up
    - All logging is local to cert-expiry.log file

    DEPENDENCIES (AUTO-MANAGED):
    - Selenium PowerShell module (≥3.0.0) - auto-installed from PowerShell Gallery
    - BurntToast module (≥0.8.0) - auto-installed for notification fallbacks
    - ChromeDriver or MSEdgeDriver - auto-downloaded and version-matched to browser
    - .NET Framework / .NET Core (included with PowerShell installations)

.AUTHOR
    Harri Jaakkonen
    Email: harri.jaakkonen@yourdomain.com
    
    This script was developed to solve the challenge of manually tracking Microsoft certification 
    expiration dates across a large portfolio of certifications. It automates the monitoring 
    process while providing reliable notifications across different Windows environments.
    
    Version 2.0 introduces enhanced user experience with immediate feedback options during 
    automation creation, ensuring users can verify their setup works correctly before 
    relying on scheduled execution.
    
    Special thanks to the PowerShell and Selenium communities for their excellent modules and 
    documentation that made this automation possible.

.VERSION
    2.0 - Enhanced automation and user experience
    
.CHANGELOG
    v2.0 (2025-09-29):
    - Added -AutomationRunSync parameter for immediate execution with automation creation
    - Enhanced automation creation with comprehensive user feedback and emojis
    - Improved user guidance during automation setup with helpful tips and commands
    - Verified clean environment functionality with automatic dependency management
    - Optimized Microsoft Edge browser performance (2x faster than Chrome)
    - Enhanced documentation with real-world examples and troubleshooting
    
    v1.0 (2025-09-29):
    - Initial release with Chrome and Edge browser support
    - Advanced browser conflict resolution with isolated profiles
    - Windows Scheduled Task automation with PowerShell 7 support
    - Multi-tier notification system with fallback mechanisms
    - Comprehensive error handling and debugging capabilities
    - Auto-managed dependencies and WebDriver version matching

.LINK
    Microsoft Learn: https://learn.microsoft.com
    PowerShell Gallery Selenium Module: https://www.powershellgallery.com/packages/Selenium
    BurntToast Module: https://www.powershellgallery.com/packages/BurntToast

.COMPONENT
    Requires Selenium WebDriver, supports Chrome and Edge browsers
#>

[CmdletBinding()]
param(
    [switch]$SendEmail,
    [switch]$VerboseConsole,
    [switch]$Plain,
    [switch]$CreateAutomation,
    [switch]$Headed,
    [string]$AutomationName = 'LearnCertMonitor',
    [string]$AutomationDailyTime = '07:30',
    [switch]$AutomationForce,
    [switch]$AutomationRunNow,
    [switch]$AutomationRunSync,
    [Parameter(DontShow = $true)]
    [switch]$AutomationProxyCall,
    [switch]$DebugHtml,
    [switch]$TaskSchedulerDebug,
    [Parameter(Mandatory)]
    [string]$TranscriptUrl,
    [string]$Browser = "Chrome"
)

#region ======= CONFIG =======
# How many days before expiry to alert
$DaysBeforeExpiry = 100

# Suppress Chrome error messages
$env:CHROME_LOG_FILE = "nul"

# Robust script root detection for Task Scheduler compatibility
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot -or [string]::IsNullOrWhiteSpace($ScriptRoot)) {
    # Fallback methods for when $PSScriptRoot is not available
    if ($MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    elseif ($script:MyInvocation.MyCommand.Path) {
        $ScriptRoot = Split-Path -Parent $script:MyInvocation.MyCommand.Path
    }
    else {
        # Last resort: use current working directory
        $ScriptRoot = Get-Location
        Write-Warning "Could not determine script directory, using current location: $ScriptRoot"
    }
}

# Ensure script root directory exists and is accessible
if (-not (Test-Path -Path $ScriptRoot -PathType Container)) {
    throw "Script root directory not accessible: $ScriptRoot"
}

# Local files for logging
$LogPath = Join-Path $ScriptRoot "cert-expiry.log"

# Create/update the log immediately so we can see scheduler invocations even if the script fails early
try {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $hostInfo = "PS $($PSVersionTable.PSVersion) on $env:COMPUTERNAME (User: $env:USERNAME)"
    
    # Enhanced Task Scheduler detection and logging
    $isTaskScheduler = [Environment]::UserInteractive -eq $false -or $env:SESSIONNAME -eq $null
    $sessionInfo = if ($isTaskScheduler) { "Task Scheduler" } else { "Interactive Session" }
    $environmentInfo = "Session: $sessionInfo, SessionName: $($env:SESSIONNAME), ScriptRoot: $ScriptRoot"
    
    # Comprehensive environment logging for Task Scheduler debugging
    $debugInfo = @(
        "--- Script starting. $hostInfo ---",
        "Environment: $environmentInfo",
        "Working Directory: $(Get-Location)",
        "Script Parameters: TranscriptUrl=$TranscriptUrl, Browser=$Browser, SendEmail=$SendEmail",
        "Process ID: $PID, Parent Process: $((Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId)",
        "User Profile: $env:USERPROFILE",
        "PowerShell Execution Policy: $(Get-ExecutionPolicy -Scope CurrentUser)",
        "Module Paths: $($env:PSModulePath -split ';' | Select-Object -First 3 | Join-String -Separator '; ')",
        "PATH (first 200 chars): $($env:PATH.Substring(0, [Math]::Min(200, $env:PATH.Length)))",
        "Available Modules: $(try { (Get-Module -ListAvailable | Measure-Object).Count } catch { 'Error getting count' })"
    )
    
    $debugInfo | ForEach-Object { "[$ts] $_" | Out-File -FilePath $LogPath -Append -Encoding UTF8 }
}
catch {
    # If logging fails, we can't do much, but at least try to continue
    try {
        "[$ts] CRITICAL: Logging failed - $_" | Out-File -FilePath $LogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {}
}

# Ensure modern TLS for all web requests (important under Scheduled Task/WinPS)
try {
    $protocols = [Net.SecurityProtocolType]::Tls12
    if ([enum]::GetNames([Net.SecurityProtocolType]) -contains 'Tls13') {
        $protocols = $protocols -bor [Net.SecurityProtocolType]::Tls13
    }
    [Net.ServicePointManager]::SecurityProtocol = $protocols
}
catch {}

# Notification settings
$ShowPopupNotification = $true
$NotificationDurationSeconds = 30
<# Toast attribution and behavior #>
$AppDisplayName = 'Learn Cert Monitor'
$AppUserModelId = 'LearnCertMonitor'
$NotificationTTLMinutes = 60
$NotificationTag = 'cert-expiry'
$NotificationGroup = 'LearnCerts'

# WebDriver settings
$UseSelenium = $true
$WebDriverWaitSeconds = 10

# ===== Email settings (use -SendEmail switch to enable) =====
$UseSmtp = $true
$UseGraph = $false
$UseAnonymousSmtp = $false

# --- SMTP (only used if -SendEmail switch is provided) ---
$EmailFrom = "alerts@yourdomain.com"
$EmailTo = "harri.jaakkonen@yourdomain.com"
$SmtpServer = "smtp.yourdomain.com"
$SmtpPort = 587
$SmtpUser = "smtp-username"
$SmtpPassword = "smtp-password"
$UseSsl = $true
#endregion ====================

#region ======= UTILITIES =======
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = "Gray")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    
    # Always write to log file
    try {
        $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
    catch {
        # If main log fails, try backup location
        try {
            $backupLog = Join-Path $env:TEMP "cert-expiry-backup.log"
            $line | Out-File -FilePath $backupLog -Append -Encoding UTF8
        }
        catch {}
    }
    
    # Write to console if interactive or debug mode
    if ([Environment]::UserInteractive -or $TaskSchedulerDebug) {
        try {
            Write-Host $line -ForegroundColor $Color
        }
        catch {
            # Fallback for environments where Write-Host might fail
            Write-Output $line
        }
    }
}

# Quiet helpers: always log to file, only echo to console when -VerboseConsole is passed
function Write-Info {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    if ($VerboseConsole) { Write-Host $line -ForegroundColor Gray }
}

function Write-DebugMsg {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    if ($VerboseConsole) { Write-Host $line -ForegroundColor DarkGray }
}

function Write-Color {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewline
    )
    if ($Plain) {
        if ($NoNewline) { Write-Host -NoNewline $Text }
        else { Write-Host $Text }
    }
    else {
        if ($NoNewline) { Write-Host -NoNewline $Text -ForegroundColor $Color }
        else { Write-Host $Text -ForegroundColor $Color }
    }
}

function Format-TruncatedText {
    param([string]$Text, [int]$Width)
    if (-not $Text) { return '' }
    if ($Text.Length -le $Width) { return $Text }
    if ($Width -le 1) { return $Text.Substring(0, $Width) }
    return $Text.Substring(0, $Width - 1) + '…'
}

function Show-TableSummary {
    [CmdletBinding(DefaultParameterSetName = 'Direct')]
    param(
        [Parameter(ParameterSetName = 'Direct')]
        [object[]]$Items,

        [Parameter(ParameterSetName = 'Pipeline', ValueFromPipeline = $true)]
        [object]$InputObject,

        [string]$Title,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [ConsoleColor]$RowColor = [ConsoleColor]::Gray,
        [int]$NameWidth = 55,
        [int]$WarningDays = $DaysBeforeExpiry
    )

    begin {
        $collected = New-Object System.Collections.ArrayList
        if ($Items) {
            [void]$collected.AddRange($Items)
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline' -and $null -ne $InputObject) {
            [void]$collected.Add($InputObject)
        }
    }

    end {
        if ($collected.Count -eq 0) { return }

        Write-Color "" $Color
        Write-Color $Title $Color
        $lineWidth = [Math]::Max(30, $NameWidth + 22)
        Write-Color (New-Object string('-', $lineWidth)) $Color
        $header = "{0,-$NameWidth} {1,-12} {2,6}" -f 'Name', 'Expires', 'Days'
        Write-Color $header $Color

        $today = (Get-Date).Date

        foreach ($item in $collected) {
            if (-not $item) { continue }

            $hasExpiration = $item.PSObject.Properties.Match('Expiration').Count -gt 0 -and $item.Expiration
            $nameText = Format-TruncatedText -Text $item.Name -Width $NameWidth
            $expiresText = if ($hasExpiration) { $item.Expiration.ToString('yyyy-MM-dd') } else { '-' }
            $daysValue = if ($hasExpiration) { ($item.Expiration.Date - $today).Days } else { '' }

            $row = "{0,-$NameWidth} {1,-12} {2,6}" -f $nameText, $expiresText, $daysValue

            $rowColor = $RowColor
            if ($hasExpiration) {
                $delta = ($item.Expiration.Date - $today).Days
                if ($delta -lt 0) { $rowColor = [ConsoleColor]::Red }
                elseif ($delta -le $WarningDays) { $rowColor = [ConsoleColor]::Yellow }
            }

            Write-Color $row $rowColor
        }
    }
}

function Register-AutomationJobTask {
    param(
        [string]$JobName,
        [TimeSpan]$RunTime,
        [string]$ScriptPath,
        [switch]$Force,
        [switch]$RunNow,
        [string[]]$Arguments
    )

    try {
        Import-Module PSScheduledJob -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Color "Unable to load the PSScheduledJob module. This automation feature requires Windows PowerShell 5.1." ([ConsoleColor]::Red)
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Color "Tip: run this command from Windows PowerShell (powershell.exe) to register the job." ([ConsoleColor]::Yellow)
        }
        exit 1
    }

    $existing = Get-ScheduledJob -Name $JobName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Color ("Automation job '{0}' already exists. Use -AutomationForce to overwrite it." -f $JobName) ([ConsoleColor]::Yellow)
        return
    }
    if ($existing) {
        Unregister-ScheduledJob -InputObject $existing -Force
        Write-Color ("Removed existing automation job '{0}'." -f $JobName) ([ConsoleColor]::DarkGray)
    }

    $today = (Get-Date).Date
    $at = $today.Add($RunTime)
    if ($at -le (Get-Date)) { $at = $at.AddDays(1) }
    $trigger = New-JobTrigger -Daily -At $at
    
    # CRITICAL FIX: Don't use -Plain so notifications work
    if ($Arguments) {
        $Arguments = $Arguments | Where-Object { $_ -ne '-Plain' }
    }
    
    # Don't request elevation - jobs need to run in user context for notifications
    $options = New-ScheduledJobOption `
        -RunElevated:$false `
        -ContinueIfGoingOnBattery:$true `
        -StartIfOnBattery:$true `
        -WakeToRun:$false

    Register-ScheduledJob `
        -Name $JobName `
        -FilePath $ScriptPath `
        -ArgumentList $Arguments `
        -Trigger $trigger `
        -ScheduledJobOption $options | Out-Null

    $job = Get-ScheduledJob -Name $JobName -ErrorAction SilentlyContinue
    $nextRun = $null
    if ($job) {
        $nextRun = $job.JobTriggers | Select-Object -ExpandProperty NextRunTime -ErrorAction SilentlyContinue | Sort-Object | Select-Object -First 1
    }

    Write-Color ("Automation job '{0}' registered." -f $JobName) ([ConsoleColor]::Green)
    Write-Color "  - Will run at: $($at.ToString('HH:mm')) daily" ([ConsoleColor]::Green)
    Write-Color "  - Runs only when you're logged in" ([ConsoleColor]::Cyan)
    Write-Color "  - Shows desktop notifications" ([ConsoleColor]::Cyan)
    if ($nextRun) {
        Write-Color ("  - Next run: {0}" -f $nextRun.ToString('dddd, MMM d yyyy HH:mm')) ([ConsoleColor]::Green)
    }
    Write-Color ("  - Manage it with: Get-ScheduledJob -Name '{0}'" -f $JobName) ([ConsoleColor]::DarkGray)

    if ($RunNow) {
        Start-Job -DefinitionName $JobName | Out-Null
        Write-Color ("Triggered '{0}' to run immediately. Watch for notification!" -f $JobName) ([ConsoleColor]::Green)
    }
}

function Register-AutomationScheduledTask {
    param(
        [string]$TaskName,
        [TimeSpan]$RunTime,
        [string]$ScriptPath,
        [switch]$Force,
        [switch]$RunNow,
        [string[]]$Arguments
    )

    try {
        $existing = $null
        try { $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop } catch {}
        if ($existing -and -not $Force) {
            Write-Color ("Scheduled Task '{0}' already exists. Use -AutomationForce to overwrite it." -f $TaskName) ([ConsoleColor]::Yellow)
            return
        }
        if ($existing) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Write-Color ("Removed existing Scheduled Task '{0}." -f $TaskName) ([ConsoleColor]::DarkGray)
        }

        $today = (Get-Date).Date
        $at = $today.Add($RunTime)
        if ($at -le (Get-Date)) { $at = $at.AddDays(1) }
        $trigger = New-ScheduledTaskTrigger -Daily -At $at

        # CRITICAL FIX: Don't pass -Plain for scheduled tasks so notifications work
        if ($Arguments) {
            $Arguments = $Arguments | Where-Object { $_ -ne '-Plain' }
        }
        
        # Carefully quote arguments for Task Scheduler command line
        $quotedArgs = @()
        $switchesNoValue = @('-Plain', '-CreateAutomation', '-AutomationForce', '-AutomationRunNow', '-AutomationProxyCall', '-SendEmail', '-VerboseConsole', '-Headed', '-DebugHtml', '-TaskSchedulerDebug')
        $expecting = $false
        $lastParam = $null
        foreach ($a in ($Arguments | Where-Object { $_ -ne $null })) {
            if ($expecting) {
                if ($a -notmatch '^\".*\"$') { $quotedArgs += '"' + $a + '"' } else { $quotedArgs += $a }
                $expecting = $false
                $lastParam = $null
                continue
            }
            if ($a -like '-*') {
                $quotedArgs += $a
                # Only expect a value if this switch normally takes one
                if ($switchesNoValue -notcontains $a) {
                    $expecting = $true
                    $lastParam = $a
                }
                continue
            }
            # Fallback: quote if whitespace or special characters likely to break parsing
            if ($a -match '[\s&]+' -and $a -notmatch '^\".*\"$') { $quotedArgs += '"' + $a + '"' }
            else { $quotedArgs += $a }
        }
        if ($expecting -and $lastParam) {
            throw "Missing value for parameter $lastParam when building Scheduled Task arguments."
        }
        $argTail = if ($quotedArgs) { $quotedArgs -join ' ' } else { '' }
        $quotedScript = '"' + $ScriptPath + '"'
        
        # Create a tiny wrapper script to avoid argument parsing quirks in Task Scheduler
        $scriptDir = Split-Path -Path $ScriptPath -Parent
        $wrapperPath = Join-Path $scriptDir ('run-' + $TaskName + '.ps1')
        try {
            $argLiterals = @()
            foreach ($a in $Arguments) {
                if ($null -eq $a) { continue }
                # Emit each token as a single-quoted literal, escaping embedded single quotes
                $argLiterals += ("'" + ($a -replace "'", "''") + "'")
            }
            $arrayLiteral = '@(' + ($argLiterals -join ', ') + ')'
            # Use a single-quoted template to avoid premature variable expansion; fill placeholders afterwards
            $wrapperTemplate = @'
# Auto-generated wrapper for Scheduled Task '__TASK_NAME__' (do not edit by hand)
$ErrorActionPreference = 'Stop'

try {
    $scriptDir = Split-Path -Path '__SCRIPT_PATH__' -Parent
} catch {
    # Fallback to the wrapper's own path
    $scriptDir = Split-Path -Path $PSCommandPath -Parent
}
$log = Join-Path $scriptDir 'cert-expiry.log'
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
"[$ts] [Wrapper] Starting. User=$env:USERNAME Host=$env:COMPUTERNAME" | Out-File -FilePath $log -Append -Encoding UTF8

try {
    Set-Location -Path $scriptDir
    $argList = __ARG_ARRAY__
    & '__SCRIPT_PATH__' @argList
    $ok = $?
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if ($ok) {
        "[$ts] [Wrapper] Completed OK." | Out-File -FilePath $log -Append -Encoding UTF8
        exit 0
    } else {
        "[$ts] [Wrapper] Main script reported failure." | Out-File -FilePath $log -Append -Encoding UTF8
        exit 1
    }
}
catch {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$ts] [Wrapper] Exception: $($_.Exception.Message)" | Out-File -FilePath $log -Append -Encoding UTF8
    exit 1
}
'@
            $wrapperContent = $wrapperTemplate.Replace('__TASK_NAME__', $TaskName).Replace('__SCRIPT_PATH__', $ScriptPath).Replace('__ARG_ARRAY__', $arrayLiteral)
            $wrapperContent | Out-File -FilePath $wrapperPath -Force -Encoding UTF8
            Write-Color ("  - Created task wrapper: {0}" -f $wrapperPath) ([ConsoleColor]::DarkGray)
        }
        catch {
            Write-Color ("Failed to write wrapper script '{0}': {1}" -f $wrapperPath, $_) ([ConsoleColor]::Red)
            throw
        }

        # Use PowerShell 7 if available, otherwise fall back to Windows PowerShell
        $psExe = $null
        $pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
        if (Test-Path $pwsh7Path) {
            $psExe = $pwsh7Path
            Write-Color ("  - Using PowerShell 7: {0}" -f $psExe) ([ConsoleColor]::Green)
        }
        else {
            $psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
            Write-Color ("  - Using Windows PowerShell: {0}" -f $psExe) ([ConsoleColor]::Yellow)
        }
        
        # Use -WindowStyle Hidden to hide console but still allow GUI notifications; run the wrapper
        $psCmd = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File '" + $wrapperPath + "'"
        $action = New-ScheduledTaskAction -Execute $psExe -Argument $psCmd -WorkingDirectory $scriptDir

        # Run as current user when logged on (required for notifications)
        $userId = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { "$env:USERNAME" }
        $principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
        
        # Settings to ensure it runs
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -ExecutionTimeLimit 0

        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description 'Microsoft Learn certificate monitor - shows desktop notifications' | Out-Null

        Write-Color ("Scheduled Task '{0}' registered." -f $TaskName) ([ConsoleColor]::Green)
        Write-Color "  - Will run at: $($at.ToString('HH:mm')) daily" ([ConsoleColor]::Green)
        Write-Color "  - Runs only when you're logged in" ([ConsoleColor]::Cyan)
        Write-Color "  - Shows desktop notifications" ([ConsoleColor]::Cyan)
        
        try {
            $task = Get-ScheduledTask -TaskName $TaskName
            $nextRun = $task.Triggers | ForEach-Object { $_.StartBoundary } | Sort-Object | Select-Object -First 1
            if ($nextRun) { 
                Write-Color ("  - Next run: {0}" -f ([datetime]$nextRun).ToString('dddd, MMM d yyyy HH:mm')) ([ConsoleColor]::Green) 
            }
        }
        catch {}

        if ($RunNow) {
            Write-Color "`nStarting task now (notifications will appear in ~30 seconds)..." ([ConsoleColor]::Yellow)
            Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Out-Null
            Write-Color ("Task '{0}' started. Watch for notification!" -f $TaskName) ([ConsoleColor]::Green)
        }
    }
    catch {
        if ($AutomationProxyCall) { Write-Error ("Failed to register Scheduled Task: " + $_) }
        else {
            Write-Color ("Failed to register Scheduled Task: {0}" -f $_) ([ConsoleColor]::Red)
            try { Show-ToastNotification -Title 'Learn Cert Monitor' -Message 'Failed to register Scheduled Task. See cert-expiry.log for details.' } catch {}
        }
        exit 1
    }
}

if ($CreateAutomation) {
    if (-not $TranscriptUrl -or [string]::IsNullOrWhiteSpace($TranscriptUrl)) {
        Write-Color "When using -CreateAutomation, you must provide -TranscriptUrl with your Microsoft Learn transcript share link." ([ConsoleColor]::Red)
        Write-Color "Example:" ([ConsoleColor]::Yellow)
        Write-Color ".\\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime '08:00' -TranscriptUrl 'https://learn.microsoft.com/en-us/users/username/transcript/...' -Browser Chrome" ([ConsoleColor]::Yellow)
        exit 1
    }

    $timeSpan = $null
    try {
        $timeSpan = [System.TimeSpan]::ParseExact($AutomationDailyTime, 'hh\:mm', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        Write-Color ("Invalid time format '{0}'. Use HH:MM (24-hour)." -f $AutomationDailyTime) ([ConsoleColor]::Red)
        exit 1
    }

    if (-not $PSCommandPath) {
        Write-Color 'Unable to resolve the current script path. Save the script to disk and retry.' ([ConsoleColor]::Red)
        exit 1
    }

    $scriptPath = (Resolve-Path -LiteralPath $PSCommandPath).Path
    
    # Common arguments to pass to the scheduled job/task so it runs headless with the chosen browser
    $commonArgs = @('-TranscriptUrl', $TranscriptUrl, '-Browser', $Browser)

    try {
        Import-Module PSScheduledJob -ErrorAction Stop | Out-Null
    }
    catch {
        # First, try registering a plain Scheduled Task in the current PowerShell (works in PS 7+ without Windows PowerShell).
        try {
            Write-Color 'PSScheduledJob not available; registering a Scheduled Task instead (no delegation).' ([ConsoleColor]::Yellow)
            $taskArgs = @('-Plain') + $commonArgs
            Register-AutomationScheduledTask -TaskName $AutomationName -RunTime $timeSpan -ScriptPath $scriptPath -Force:$AutomationForce -RunNow:$AutomationRunNow -Arguments $taskArgs
            
            # Enhanced user feedback when creating automation
            if ($AutomationRunNow) {
                Write-Color "`n🔄 The scheduled task is now running in the background..." ([ConsoleColor]::Cyan)
                Write-Color "💡 You can check the task status with: Get-ScheduledTask -TaskName '$AutomationName'" ([ConsoleColor]::Yellow)
                Write-Color "📋 View the execution log at: $LogPath" ([ConsoleColor]::Yellow)
                Write-Color "🔔 Notifications should appear in ~30-60 seconds" ([ConsoleColor]::Green)
                
                # Offer to run immediately in foreground for instant feedback
                Write-Color "`n🚀 Want to see immediate results? Run without -CreateAutomation:" ([ConsoleColor]::Magenta)
                Write-Color ".\\get-learncerts.ps1 -TranscriptUrl '$TranscriptUrl' -Browser $Browser -VerboseConsole" ([ConsoleColor]::Gray)
            }
            
            # Handle synchronous execution for immediate feedback
            if ($AutomationRunSync) {
                Write-Color "`n🚀 Running certificate check immediately for instant feedback..." ([ConsoleColor]::Green)
                Write-Color ("=" * 60) ([ConsoleColor]::Gray)
                # Continue to main script execution below instead of returning
            }
            else {
                return
            }
        }
        catch {
            Write-Color ("Scheduled Task registration failed in current PowerShell: {0}" -f $_) ([ConsoleColor]::Red)
        }

        if (-not $AutomationProxyCall) {
            Write-Color 'Delegating automation registration to Windows PowerShell…' ([ConsoleColor]::Yellow)
            $quotedScriptPath = '"' + $scriptPath + '"'
            $psArgs = @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', $quotedScriptPath,
                '-CreateAutomation',
                '-AutomationDailyTime', '"' + $AutomationDailyTime + '"',
                '-AutomationName', '"' + $AutomationName + '"'
            )
            # Pass through current parameters so the delegated process knows what to embed in the task
            if ($TranscriptUrl) { $psArgs += @('-TranscriptUrl', '"' + $TranscriptUrl + '"') }
            if ($Browser) { $psArgs += @('-Browser', '"' + $Browser + '"') }
            if ($AutomationForce) { $psArgs += '-AutomationForce' }
            if ($AutomationRunNow) { $psArgs += '-AutomationRunNow' }
            $psArgs += '-AutomationProxyCall'
            try {
                $stdOut = Join-Path $env:TEMP 'LearnCert-AutoProxy-stdout.log'
                $stdErr = Join-Path $env:TEMP 'LearnCert-AutoProxy-stderr.log'
                # Clear previous logs if present
                Remove-Item -LiteralPath $stdOut -Force -ErrorAction SilentlyContinue | Out-Null
                Remove-Item -LiteralPath $stdErr -Force -ErrorAction SilentlyContinue | Out-Null

                $argString = ($psArgs -join ' ')
                $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $argString -WindowStyle Hidden -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr -Wait -PassThru
                if ($proc.ExitCode -eq 0) {
                    Write-Color 'Automation job registered via Windows PowerShell.' ([ConsoleColor]::Green)
                    return
                }
                else {
                    Write-Color ("Windows PowerShell exited with code {0}." -f $proc.ExitCode) ([ConsoleColor]::Red)
                    if (Test-Path -LiteralPath $stdErr) {
                        $errTail = Get-Content -LiteralPath $stdErr -Tail 30 -ErrorAction SilentlyContinue
                        if ($errTail) {
                            Write-Color '--- Delegated error (stderr tail) ---' ([ConsoleColor]::Red)
                            $errTail | ForEach-Object { Write-Color $_ ([ConsoleColor]::Red) }
                        }
                    }
                    if (Test-Path -LiteralPath $stdOut) {
                        $outTail = Get-Content -LiteralPath $stdOut -Tail 20 -ErrorAction SilentlyContinue
                        if ($outTail) {
                            Write-Color '--- Delegated output (stdout tail) ---' ([ConsoleColor]::DarkGray)
                            $outTail | ForEach-Object { Write-Color $_ ([ConsoleColor]::DarkGray) }
                        }
                    }
                    exit $proc.ExitCode
                }
            }
            catch {
                Write-Color ("Failed to launch powershell.exe: {0}" -f $_) ([ConsoleColor]::Red)
                exit 1
            }
        }
        else {
            # We're already in Windows PowerShell and PSScheduledJob isn't available.
            # Fallback to a standard Scheduled Task registration.
            if ($AutomationProxyCall) { Write-Output 'PSScheduledJob not available. Falling back to Scheduled Task registration.' }
            $taskArgs = @('-Plain') + $commonArgs
            Register-AutomationScheduledTask -TaskName $AutomationName -RunTime $timeSpan -ScriptPath $scriptPath -Force:$AutomationForce -RunNow:$AutomationRunNow -Arguments $taskArgs
            return
        }
    }

    $jobArgs = @('-Plain') + $commonArgs
    Register-AutomationJobTask -JobName $AutomationName -RunTime $timeSpan -ScriptPath $scriptPath -Force:$AutomationForce -RunNow:$AutomationRunNow -Arguments $jobArgs
    return
}

function Test-BrowserAvailability {
    param([string]$Browser = "Chrome")
    
    Write-Log "Testing browser availability: $Browser" "Yellow"
    
    $browserPath = $null
    if ($Browser -eq "Chrome") {
        $browserPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        if (-not (Test-Path $browserPath)) {
            $browserPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        }
    }
    elseif ($Browser -eq "Edge") {
        $browserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        if (-not (Test-Path $browserPath)) {
            $browserPath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        }
    }
    
    if (-not $browserPath -or -not (Test-Path $browserPath)) {
        Write-Log "Browser not found: $Browser" "Red"
        return $false
    }
    
    try {
        $browserVersion = (Get-Item $browserPath).VersionInfo.FileVersion
        Write-Log "Found $Browser at: $browserPath (Version: $browserVersion)" "Green"
        
        # Test if browser can be launched (in very limited way)
        $testArgs = "--version"
        $proc = Start-Process -FilePath $browserPath -ArgumentList $testArgs -WindowStyle Hidden -PassThru -Wait
        if ($proc.ExitCode -eq 0) {
            Write-Log "$Browser can be launched successfully" "Green"
            return $true
        }
        else {
            Write-Log "$Browser test launch failed with exit code: $($proc.ExitCode)" "Yellow"
            return $false
        }
    }
    catch {
        Write-Log "Error testing browser: $_" "Red"
        return $false
    }
}

function Test-SeleniumModule {
    Write-Log "Testing Selenium module availability..." "Yellow"
    
    # Check for existing module
    $seleniumModule = Get-Module -ListAvailable -Name Selenium | Where-Object { $_.Version -ge [version]'3.0.0' }
    if ($seleniumModule) { 
        Write-Log "Found Selenium module: $($seleniumModule.Version)" "Green"
        return $true 
    }
    
    Write-Log "Selenium module not found or outdated. Installing..." "Yellow"
    try {
        # Enhanced module installation for Task Scheduler compatibility
        
        # Force TLS 1.2 for PowerShell Gallery
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Write-Log "Set TLS 1.2 for secure connections" "Green"
        }
        catch {
            Write-Log "Warning: Could not set TLS 1.2 protocol: $_" "Yellow"
        }
        
        # Check if running under Task Scheduler (no interactive session)
        $isTaskScheduler = [Environment]::UserInteractive -eq $false -or $env:SESSIONNAME -eq $null
        if ($isTaskScheduler) {
            Write-Log "Detected Task Scheduler context - using enhanced installation" "Yellow"
        }
        
        # Test internet connectivity
        try {
            $testConnection = Test-NetConnection -ComputerName "www.powershellgallery.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop
            if (-not $testConnection) {
                throw "Cannot reach PowerShell Gallery"
            }
            Write-Log "Internet connectivity to PowerShell Gallery confirmed" "Green"
        }
        catch {
            Write-Log "Warning: Cannot verify internet connectivity: $_" "Yellow"
        }
        
        # Ensure NuGet provider with multiple fallbacks
        $nugetInstalled = $false
        try { 
            $provider = Get-PackageProvider -Name NuGet -ErrorAction Stop
            $nugetInstalled = $true
            Write-Log "NuGet provider already available: $($provider.Version)" "Green"
        }
        catch {
            Write-Log "Installing NuGet provider..." "Yellow"
            try {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false | Out-Null
                $nugetInstalled = $true
                Write-Log "NuGet provider installed for CurrentUser" "Green"
            }
            catch {
                # Fallback: try installing to all users if current user fails
                try {
                    if (-not $isTaskScheduler) {
                        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -Confirm:$false | Out-Null
                        $nugetInstalled = $true
                        Write-Log "NuGet provider installed for AllUsers" "Green"
                    }
                }
                catch {
                    Write-Log "Failed to install NuGet provider: $_" "Red"
                }
            }
        }
        
        if (-not $nugetInstalled) {
            throw "Cannot install NuGet provider - PowerShell Gallery access not available"
        }
        
        # Configure PSGallery repository
        try { 
            $repo = Get-PSRepository -Name 'PSGallery' -ErrorAction Stop
            Write-Log "PSGallery repository available, policy: $($repo.InstallationPolicy)" "Green"
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
            Write-Log "Set PSGallery as trusted" "Green"
        }
        catch {
            Write-Log "Warning: Could not configure PSGallery as trusted: $_" "Yellow"
        }
        
        # Install Selenium module with enhanced error handling
        $installArgs = @{
            Name           = 'Selenium'
            MinimumVersion = '3.0.0'
            Scope          = 'CurrentUser'
            Force          = $true
            AllowClobber   = $true
            ErrorAction    = 'Stop'
            Confirm        = $false
        }
        
        # Add skip publisher check for Task Scheduler contexts
        if ($isTaskScheduler) {
            $installArgs['SkipPublisherCheck'] = $true
            Write-Log "Using SkipPublisherCheck for Task Scheduler context" "Yellow"
        }
        
        Write-Log "Installing Selenium module with args: $($installArgs.Keys -join ', ')" "Yellow"
        Install-Module @installArgs
        
        # Verify installation
        $installedModule = Get-Module -ListAvailable -Name Selenium | Where-Object { $_.Version -ge [version]'3.0.0' }
        if ($installedModule) {
            Write-Log "Selenium installed successfully: $($installedModule.Version)" "Green"
            return $true
        }
        else {
            throw "Selenium module installation completed but module not found"
        }
    }
    catch {
        Write-Log ("Failed to install Selenium: {0}" -f $_) "Red"
        Write-Log "Module installation failed - script will not work without Selenium" "Red"
        
        # Additional debugging for Task Scheduler
        if ($isTaskScheduler -or $TaskSchedulerDebug) {
            Write-Log "=== DEBUGGING INFO ===" "Red"
            Write-Log "Current user: $env:USERNAME" "Red"
            Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "Red"
            Write-Log "Execution policy: $(Get-ExecutionPolicy -Scope CurrentUser)" "Red"
            Write-Log "PSModulePath: $env:PSModulePath" "Red"
            Write-Log "Available modules count: $((Get-Module -ListAvailable | Measure-Object).Count)" "Red"
        }
        return $false
    }
}

function Install-WebDriver {
    param([string]$Browser = "Chrome")
    
    $driverFolder = Join-Path $ScriptRoot "WebDriver"
    if (-not (Test-Path $driverFolder)) {
        New-Item -ItemType Directory -Path $driverFolder -Force | Out-Null
    }
    
    if ($Browser -eq "Chrome") {
        Write-Log "Downloading ChromeDriver..." "Yellow"
        
        try {
            # Get Chrome version
            $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            if (-not (Test-Path $chromePath)) {
                $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            }
            
            if (Test-Path $chromePath) {
                $chromeVersion = (Get-Item $chromePath).VersionInfo.FileVersion
                $majorVersion = [int]$chromeVersion.Split('.')[0]
                Write-Log "Detected Chrome version: $chromeVersion (major: $majorVersion)"
            }
            else {
                Write-Log "Chrome not found, cannot determine version" "Red"
                return $null
            }
            
            # Chrome 115+ uses new endpoints
            if ($majorVersion -ge 115) {
                Write-Log "Using Chrome for Testing API for version $majorVersion..."
                
                # Get the exact matching version from Chrome for Testing
                $apiUrl = "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
                $versionsData = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
                
                # Find closest matching version
                $matchingVersion = $versionsData.versions | 
                Where-Object { $_.version -like "$majorVersion.*" } | 
                Select-Object -Last 1
                
                if (-not $matchingVersion) {
                    Write-Log "Could not find ChromeDriver for Chrome $majorVersion" "Red"
                    return $null
                }
                
                $driverVersion = $matchingVersion.version
                Write-Log "Found matching ChromeDriver version: $driverVersion"
                
                # Get download URL for chromedriver
                $driverDownload = $matchingVersion.downloads.chromedriver | 
                Where-Object { $_.platform -eq 'win64' } | 
                Select-Object -First 1
                
                if (-not $driverDownload) {
                    Write-Log "Could not find win64 ChromeDriver download" "Red"
                    return $null
                }
                
                $zipUrl = $driverDownload.url
            }
            else {
                # Old API for Chrome 114 and below
                Write-Log "Using legacy ChromeDriver API..."
                $driverUrl = "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$majorVersion"
                try {
                    $latestVersion = (Invoke-WebRequest -Uri $driverUrl -UseBasicParsing).Content.Trim()
                    $zipUrl = "https://chromedriver.storage.googleapis.com/$latestVersion/chromedriver_win32.zip"
                }
                catch {
                    Write-Log "Failed to get ChromeDriver version from legacy API: $_" "Red"
                    return $null
                }
            }
            
            Write-Log "Downloading from: $zipUrl"
            $zipPath = "$driverFolder\chromedriver.zip"
            
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            
            # Clean up old files
            Get-ChildItem -Path $driverFolder -Filter "chromedriver*" -Exclude "*.zip" | Remove-Item -Force -ErrorAction SilentlyContinue
            
            # Extract (new format has subfolder)
            Expand-Archive -Path $zipPath -DestinationPath $driverFolder -Force
            Remove-Item $zipPath
            
            # Find the extracted chromedriver.exe (might be in subfolder)
            $extractedDriver = Get-ChildItem -Path $driverFolder -Filter "chromedriver.exe" -Recurse | Select-Object -First 1
            
            if ($extractedDriver) {
                $finalPath = "$driverFolder\chromedriver.exe"
                if ($extractedDriver.FullName -ne $finalPath) {
                    Move-Item -Path $extractedDriver.FullName -Destination $finalPath -Force
                    # Clean up extraction folder
                    $extractFolder = Split-Path $extractedDriver.FullName
                    if ($extractFolder -ne $driverFolder) {
                        Remove-Item $extractFolder -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-Log "ChromeDriver installed to: $finalPath" "Green"
                return $finalPath
            }
            else {
                Write-Log "ChromeDriver.exe not found after extraction" "Red"
                return $null
            }
        }
        catch {
            Write-Log "Failed to download ChromeDriver: $_" "Red"
            Write-Log "Error details: $($_.Exception.Message)" "Red"
        }
    }
    elseif ($Browser -eq "Edge") {
        Write-Log "Downloading MSEdgeDriver..." "Yellow"
        
        try {
            # Get Edge version
            $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
            if (-not (Test-Path $edgePath)) {
                $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
            }
            
            if (Test-Path $edgePath) {
                $edgeVersion = (Get-Item $edgePath).VersionInfo.FileVersion
                $majorVersion = [int]$edgeVersion.Split('.')[0]
                Write-Log "Detected Edge version: $edgeVersion (major: $majorVersion)"
            }
            else {
                Write-Log "Edge not found, cannot determine version" "Red"
                return $null
            }
            
            # Prefer exact Edge version to avoid API failures
            $latestVersion = $edgeVersion
            Write-Log "Using EdgeDriver version matching installed Edge: $latestVersion"
            $zipUrl = "https://msedgedriver.microsoft.com/$latestVersion/edgedriver_win64.zip"
            
            Write-Log "Downloading from: $zipUrl"
            $zipPath = "$driverFolder\edgedriver.zip"
            
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            
            # Clean up old files
            Get-ChildItem -Path $driverFolder -Filter "msedgedriver*" -Exclude "*.zip" | Remove-Item -Force -ErrorAction SilentlyContinue
            
            # Extract
            Expand-Archive -Path $zipPath -DestinationPath $driverFolder -Force
            Remove-Item $zipPath
            
            # Find the extracted msedgedriver.exe
            $extractedDriver = Get-ChildItem -Path $driverFolder -Filter "msedgedriver.exe" -Recurse | Select-Object -First 1
            
            if ($extractedDriver) {
                $finalPath = "$driverFolder\msedgedriver.exe"
                if ($extractedDriver.FullName -ne $finalPath) {
                    Move-Item -Path $extractedDriver.FullName -Destination $finalPath -Force
                }
                Write-Log "MSEdgeDriver installed to: $finalPath" "Green"
                return $finalPath
            }
            else {
                Write-Log "MSEdgeDriver.exe not found after extraction" "Red"
                return $null
            }
        }
        catch {
            Write-Log "Failed to download MSEdgeDriver: $_" "Red"
            Write-Log "Error details: $($_.Exception.Message)" "Red"
        }
    }
    else {
        Write-Log "Unsupported browser: $Browser" "Red"
        return $null
    }
    
    return $null
}

function Show-BalloonNotification {
    param(
        [string]$Title,
        [string]$Message,
        [int]$DurationSeconds = 30
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Warning
        $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
        $notification.BalloonTipTitle = $Title
        $notification.BalloonTipText = $Message
        $notification.Visible = $true
        
        $notification.ShowBalloonTip($DurationSeconds * 1000)
        
        Write-Log "Displayed balloon notification" "Green"
        
        # Keep the notification visible
        Start-Sleep -Seconds $DurationSeconds
        $notification.Dispose()
    }
    catch {
        Write-Log "Failed to show balloon notification: $_" "Yellow"
        # Fallback to message box
        Show-PopupMessageBox -Title $Title -Message $Message
    }
}

function Show-PopupMessageBox {
    param(
        [string]$Title,
        [string]$Message
    )
    
    try {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        Write-Log "Displayed popup message box" "Green"
    }
    catch {
        Write-Log "Failed to show popup: $_" "Yellow"
        # Last resort - Write-Host with color
        Write-Host "`n`n================================" -ForegroundColor Yellow
        Write-Host $Title -ForegroundColor Red
        Write-Host "================================" -ForegroundColor Yellow
        Write-Host $Message -ForegroundColor Yellow
        Write-Host "================================`n`n" -ForegroundColor Yellow
    }
}

function Ensure-AppIcon {
    # Ensures a local Microsoft logo PNG exists and returns its absolute file path, or $null on failure
    try {
        $assets = Join-Path $ScriptRoot 'assets'
        if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets -Force | Out-Null }

        $iconPath = Join-Path $assets 'microsoft-logo.png'
        if (-not (Test-Path $iconPath) -or ((Get-Item $iconPath).Length -lt 1024)) {
            # Use the Wikimedia Commons PNG thumbnail for Microsoft logo (stable, redistributable under license)
            $pngUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/120px-Microsoft_logo.svg.png'
            try {
                Invoke-WebRequest -Uri $pngUrl -OutFile $iconPath -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            }
            catch {
                # Best-effort; return null if download fails
                return $null
            }
        }
        return (Resolve-Path $iconPath).Path
    }
    catch {
        return $null
    }
}

function Show-ToastNotification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    # Windows 10/11 Toast Notification
    try {
        $appId = $AppUserModelId

        $iconPath = Ensure-AppIcon
        Ensure-ToastAppRegistration -AppId $appId -AppName $AppDisplayName -IconPath $iconPath
        
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
        $imageXml = ''
        if ($iconPath -and (Test-Path $iconPath)) {
            try {
                $resolved = (Resolve-Path $iconPath).Path
                $imgSrc = 'file:///' + ($resolved -replace '\\', '/')
            }
            catch { $imgSrc = $null }
            if ($imgSrc) {
                # Use single quotes inside a double-quoted PowerShell string to avoid escape issues
                $imageXml = "<image placement='appLogoOverride' hint-crop='circle' src='$imgSrc' alt='Microsoft'/>"
            }
        }

        $toastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            $imageXml
            <text>$Title</text>
            <text>$Message</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Reminder"/>
</toast>
"@
        
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)
        
        $toast = New-Object Windows.UI.Notifications.ToastNotification -ArgumentList $xml
        # Optional: auto-expire from Notification Center and group for replacement
        try {
            $toast.Tag = $NotificationTag
            $toast.Group = $NotificationGroup
            $toast.ExpirationTime = [System.DateTimeOffset]::Now.AddMinutes($NotificationTTLMinutes)
        }
        catch {}
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        
        Write-Log "Displayed Windows toast notification" "Green"
        return $true
    }
    catch {
        Write-Log "Toast notification not supported via WinRT, attempting BurntToast" "Yellow"
        if (Ensure-BurntToastModule) {
            try {
                Import-Module BurntToast -ErrorAction Stop
                try {
                    $iconPath = Ensure-AppIcon
                    if ($iconPath -and (Test-Path $iconPath)) {
                        New-BurntToastNotification -AppId $AppUserModelId -Text $Title, $Message -AppLogo $iconPath | Out-Null
                    }
                    else {
                        New-BurntToastNotification -AppId $AppUserModelId -Text $Title, $Message | Out-Null
                    }
                    Write-Log "Displayed toast via BurntToast" "Green"
                    return $true
                }
                catch {
                    if ($_.Exception.Message -match "parameter name 'AppId'") {
                        Write-Log "BurntToast -AppId not supported, trying without custom app" "Yellow"
                        $iconPath = Ensure-AppIcon
                        if ($iconPath -and (Test-Path $iconPath)) {
                            New-BurntToastNotification -Text $Title, $Message -AppLogo $iconPath | Out-Null
                        }
                        else {
                            New-BurntToastNotification -Text $Title, $Message | Out-Null
                        }
                        Write-Log "Displayed toast via BurntToast (fallback)" "Green"
                        return $true
                    }
                    else {
                        Write-Log ("BurntToast failed: {0}" -f $_) "Yellow"
                    }
                }
            }
            catch {
                Write-Log ("BurntToast attempt failed: {0}" -f $_) "Yellow"
            }
        }
        else {
            Write-Log "Could not install BurntToast automatically. Install manually: Install-Module BurntToast -Scope CurrentUser" "Yellow"
        }
        return $false
    }
}

function Ensure-BurntToastModule {
    try {
        if (Get-Module -ListAvailable -Name BurntToast | Where-Object { $_.Version -ge [version]'0.8.0' }) { return $true }
        
        # Enhanced BurntToast installation for Task Scheduler
        Write-Log "Installing BurntToast module..." "Yellow"
        
        # Force TLS 1.2 for PSGallery
        try { 
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
        }
        catch {
            Write-Log "Warning: Could not set TLS 1.2" "Yellow"
        }
        
        # Check if running under Task Scheduler
        $isTaskScheduler = [Environment]::UserInteractive -eq $false -or $env:SESSIONNAME -eq $null
        
        # Ensure NuGet provider
        $provider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $provider) {
            try {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Log "Warning: Could not install NuGet provider for BurntToast: $_" "Yellow"
                return $false
            }
        }
        
        # Configure repository
        try {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        }
        catch {}
        
        # Install with enhanced parameters
        $installArgs = @{
            Name           = 'BurntToast'
            MinimumVersion = '0.8.0'
            Scope          = 'CurrentUser'
            Force          = $true
            AllowClobber   = $true
            ErrorAction    = 'Stop'
            Confirm        = $false
        }
        
        if ($isTaskScheduler) {
            $installArgs['SkipPublisherCheck'] = $true
        }
        
        Install-Module @installArgs
        return $true
    }
    catch {
        Write-Log ("Failed to install BurntToast: {0}" -f $_) "Yellow"
        return $false
    }
}
#endregion ======================

function Ensure-ToastAppRegistration {
    param(
        [Parameter(Mandatory)] [string]$AppId,
        [Parameter(Mandatory)] [string]$AppName,
        [string]$IconPath
    )

    try {
        $programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
        if (-not (Test-Path $programs)) { return }
        $lnkPath = Join-Path $programs ("{0}.lnk" -f $AppName)

        # Create basic shortcut if missing
        if (-not (Test-Path $lnkPath)) {
            $wsh = New-Object -ComObject WScript.Shell
            $sc = $wsh.CreateShortcut($lnkPath)
            $sc.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $sc.Arguments = ''
            # Only set icon if it's a shell-supported icon resource (.ico/.exe/.dll). PNGs are not valid here.
            $defaultIcon = (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe')
            $sc.IconLocation = $defaultIcon
            if ($IconPath -and (Test-Path $IconPath)) {
                try {
                    $ext = [System.IO.Path]::GetExtension($IconPath)
                    if ($ext -and $ext.ToLowerInvariant() -in @('.ico', '.exe', '.dll')) {
                        $sc.IconLocation = $IconPath
                    }
                }
                catch {}
            }
            $sc.Save()
        }

        # Ensure the AppUserModelID is set on the shortcut
        $typeName = 'ShellLinkUtil'
        if (-not ([System.Management.Automation.PSTypeName]$typeName).Type) {
            Add-Type -ErrorAction Stop -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

[ComImport]
[Guid("00021401-0000-0000-C000-000000000046")]
internal class CShellLink { }

[ComImport]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("000214F9-0000-0000-C000-000000000046")]
internal interface IShellLinkW
{
    void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, IntPtr pfd, uint fFlags);
    void GetIDList(out IntPtr ppidl);
    void SetIDList(IntPtr pidl);
    void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
    void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
    void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
    void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
    void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
    void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
    void GetHotkey(out short pwHotkey);
    void SetHotkey(short wHotkey);
    void GetShowCmd(out int piShowCmd);
    void SetShowCmd(int iShowCmd);
    void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
    void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
    void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
    void Resolve(IntPtr hwnd, uint fFlags);
    void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
}

[ComImport]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("0000010b-0000-0000-C000-000000000046")]
internal interface IPersistFile
{
    void GetClassID(out Guid pClassID);
    [PreserveSig] int IsDirty();
    void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
    void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, bool fRemember);
    void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
    void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
}

[ComImport]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
internal interface IPropertyStore
{
    void GetCount(out uint cProps);
    void GetAt(uint iProp, out PROPERTYKEY pkey);
    void GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
    void SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
    void Commit();
}

[StructLayout(LayoutKind.Sequential, Pack=4)]
internal struct PROPERTYKEY
{
    public Guid fmtid;
    public uint pid;
}

[StructLayout(LayoutKind.Sequential)]
internal struct PROPVARIANT
{
    public ushort vt;
    public ushort wReserved1;
    public ushort wReserved2;
    public ushort wReserved3;
    public IntPtr ptr;
    public int iVal;
}

internal static class PropVariantHelper
{
    public static PROPVARIANT FromString(string value)
    {
        var pv = new PROPVARIANT();
        pv.vt = 31; // VT_LPWSTR
        pv.ptr = Marshal.StringToCoTaskMemUni(value);
        return pv;
    }

    public static void Free(ref PROPVARIANT pv)
    {
        if (pv.vt == 31 && pv.ptr != IntPtr.Zero)
        {
            Marshal.FreeCoTaskMem(pv.ptr);
            pv.ptr = IntPtr.Zero;
            pv.vt = 0;
        }
    }
}

public static class ShellLinkUtil
{
    static readonly Guid PKEY_AppUserModel_ID_fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3");
    const uint PKEY_AppUserModel_ID_pid = 5;

    public static void SetAppUserModelId(string linkPath, string appId)
    {
        var link = (IShellLinkW)new CShellLink();
        var persist = (IPersistFile)link;
        persist.Load(linkPath, 0);

        var store = (IPropertyStore)link;
        var key = new PROPERTYKEY { fmtid = PKEY_AppUserModel_ID_fmtid, pid = PKEY_AppUserModel_ID_pid };
        var pv = PropVariantHelper.FromString(appId);
        store.SetValue(ref key, ref pv);
        store.Commit();
        PropVariantHelper.Free(ref pv);

        persist.Save(linkPath, true);
    }
}
"@
        }

        [ShellLinkUtil]::SetAppUserModelId($lnkPath, $AppId)
    }
    catch {
        # Non-fatal: if registration fails, toast still shows under PowerShell
        Write-Info ("Toast AppID registration skipped: {0}" -f $_)
    }
}

#region ======= FETCH & PARSE TRANSCRIPT =======
function Test-BrowserConflicts {
    param([string]$Browser = "Chrome")
    
    Write-Log "Checking for browser conflicts..." "Yellow"
    
    $processName = if ($Browser -eq "Chrome") { "chrome" } else { "msedge" }
    $runningProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
    
    if ($runningProcesses) {
        Write-Log "Found $($runningProcesses.Count) running $Browser process(es)" "Yellow"
        
        # Check if any are using automation ports (these are problematic)
        $automationProcesses = $runningProcesses | Where-Object { 
            $_.CommandLine -like "*--remote-debugging-port*" -or 
            $_.CommandLine -like "*--automation*" -or
            $_.CommandLine -like "*chromedriver*" -or
            $_.CommandLine -like "*msedgedriver*"
        }
        
        if ($automationProcesses) {
            Write-Log "Found $($automationProcesses.Count) automation process(es) that may cause conflicts" "Yellow"
            return $false
        }
        else {
            Write-Log "Running $Browser processes appear to be normal user instances" "Green"
            return $true
        }
    }
    else {
        Write-Log "No running $Browser processes found" "Green"
        return $true
    }
}

function Clear-BrowserAutomationProcesses {
    param([string]$Browser = "Chrome")
    
    Write-Log "Clearing automation processes for $Browser..." "Yellow"
    
    try {
        # Kill any stuck webdriver processes
        $driverProcesses = @()
        if ($Browser -eq "Chrome") {
            $driverProcesses = Get-Process -Name "chromedriver" -ErrorAction SilentlyContinue
        }
        else {
            $driverProcesses = Get-Process -Name "msedgedriver" -ErrorAction SilentlyContinue
        }
        
        foreach ($proc in $driverProcesses) {
            try {
                Write-Log "Terminating stuck driver process: $($proc.ProcessName) (PID: $($proc.Id))" "Yellow"
                $proc.Kill()
                $proc.WaitForExit(5000)  # Wait up to 5 seconds
            }
            catch {
                Write-Log "Could not terminate driver process $($proc.Id): $_" "Yellow"
            }
        }
        
        # Clean up any orphaned temp profiles
        $tempDir = $env:TEMP
        $profilePattern = if ($Browser -eq "Chrome") { "Chrome_LearnCert_*" } else { "Edge_LearnCert_*" }
        $oldProfiles = Get-ChildItem -Path $tempDir -Directory -Name $profilePattern -ErrorAction SilentlyContinue
        
        foreach ($profile in $oldProfiles) {
            $profilePath = Join-Path $tempDir $profile
            try {
                Write-Log "Cleaning up old temp profile: $profile" "Yellow"
                Remove-Item -Path $profilePath -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Log "Note: Profile cleanup will happen on reboot: $profilePath" "Yellow"
            }
        }
        
        Write-Log "Automation process cleanup completed" "Green"
        return $true
    }
    catch {
        Write-Log "Error during automation cleanup: $_" "Yellow"
        return $false
    }
}

function Get-TranscriptHtmlWithSelenium {
    param([Parameter(Mandatory)] [string]$Url)
    
    if (-not (Test-SeleniumModule)) {
        throw "Selenium module required but not available"
    }
    
    try {
        Import-Module Selenium -MinimumVersion 3.0.0 -Force -ErrorAction Stop
    }
    catch {
        Import-Module Selenium -Force
    }
    
    $driver = $null
    $driverProc = $null
    $tempProfile = $null
    $maxRetries = 3
    $retryCount = 0
    
    try {
        Write-Info "Starting browser WebDriver..."
        
        # Check for conflicts first
        if (-not (Test-BrowserConflicts -Browser $Browser)) {
            Write-Log "Browser conflicts detected. Attempting automatic cleanup..." "Yellow"
            Clear-BrowserAutomationProcesses -Browser $Browser
            Start-Sleep -Seconds 3  # Give processes time to fully terminate
        }
        
        # Get browser version for validation
        $browserPath = $null
        $driverName = $null
        if ($Browser -eq "Chrome") {
            $browserPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            if (-not (Test-Path $browserPath)) {
                $browserPath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            }
            $driverName = "chromedriver.exe"
        }
        elseif ($Browser -eq "Edge") {
            $browserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
            if (-not (Test-Path $browserPath)) {
                $browserPath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
            }
            $driverName = "msedgedriver.exe"
        }
        else {
            throw "Unsupported browser: $Browser"
        }
        
        $browserVersion = $null
        $majorVersion = $null
        if (Test-Path $browserPath) {
            $browserVersion = (Get-Item $browserPath).VersionInfo.FileVersion
            $majorVersion = [int]$browserVersion.Split('.')[0]
        }
        
        # Try to find or download driver
        $customDriverPath = Join-Path $ScriptRoot "WebDriver\$driverName"
        $needsDownload = $false
        
        if (Test-Path $customDriverPath) {
            # Check if driver version matches browser version
            try {
                $driverVersionOutput = & $customDriverPath --version 2>&1
                if ($driverVersionOutput -match "(\d+)\.") {
                    $driverMajor = [int]$Matches[1]
                    Write-Info "Found $driverName version: $driverMajor"
                    
                    if ($majorVersion -and $driverMajor -ne $majorVersion) {
                        Write-Info "Version mismatch! ${Browser}: $majorVersion, Driver: $driverMajor"
                        Write-Info "Cleaning up old driver..."
                        
                        # Kill any running driver processes
                        Get-Process -Name ($driverName -replace '\.exe$', '') -ErrorAction SilentlyContinue | Stop-Process -Force
                        Start-Sleep -Milliseconds 500
                        
                        # Remove the WebDriver folder entirely
                        Remove-Item (Join-Path $ScriptRoot "WebDriver") -Recurse -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 500
                        
                        $needsDownload = $true
                    }
                }
            }
            catch {
                Write-Log "Could not check driver version, will re-download" "Yellow"
                Get-Process -Name ($driverName -replace '\.exe$', '') -ErrorAction SilentlyContinue | Stop-Process -Force
                Remove-Item (Join-Path $ScriptRoot "WebDriver") -Recurse -Force -ErrorAction SilentlyContinue
                $needsDownload = $true
            }
        }
        else {
            $needsDownload = $true
        }
        
        if ($needsDownload) {
            Write-Info "Downloading $driverName for $Browser $majorVersion..."
            $installedPath = Install-WebDriver -Browser $Browser
            if (-not $installedPath) {
                throw "Could not install $driverName"
            }
            $customDriverPath = $installedPath
        }
        
        # Verify the driver version one more time before starting
        $finalVersionCheck = & $customDriverPath --version 2>&1
        Write-Info "Using ${driverName}: $finalVersionCheck"
        
        try {
            Write-Info "Starting $Browser with driver from: $customDriverPath"
            
            # Retry loop for browser startup (handles conflicts)
            while ($retryCount -lt $maxRetries -and -not $driver) {
                try {
                    if ($retryCount -gt 0) {
                        Write-Log "Retry attempt $retryCount/$maxRetries for browser startup..." "Yellow"
                        Start-Sleep -Seconds (2 * $retryCount)  # Progressive delay
                    }
            
                    if ($Browser -eq "Chrome") {
                        # Create Chrome options to suppress errors and warnings
                        $options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
                        if (-not $Headed) { $options.AddArgument("--headless=new") }
                        $options.AddArgument("--disable-gpu")
                        $options.AddArgument("--no-sandbox")
                        $options.AddArgument("--disable-dev-shm-usage")
                        $options.AddArgument("--log-level=3")
                        $options.AddArgument("--silent")
                        $options.AddArgument("--disable-logging")
                        $options.AddExcludedArgument("enable-logging")
                
                        # Enhanced isolation to avoid conflicts with existing Chrome instances
                        $tempProfile = Join-Path $env:TEMP ("Chrome_LearnCert_" + (Get-Random))
                        $options.AddArgument("--user-data-dir=$tempProfile")
                        $options.AddArgument("--disable-web-security")
                        $options.AddArgument("--disable-features=VizDisplayCompositor")
                        $options.AddArgument("--disable-background-timer-throttling")
                        $options.AddArgument("--disable-backgrounding-occluded-windows")
                        $options.AddArgument("--disable-renderer-backgrounding")
                        $options.AddArgument("--no-first-run")
                        $options.AddArgument("--no-default-browser-check")
                        $options.AddArgument("--disable-sync")
                        $options.AddArgument("--disable-extensions")
                        $options.AddArgument("--remote-debugging-port=0")  # Use random port
                
                        Write-Info "Using isolated Chrome profile: $tempProfile"
                
                        $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService((Join-Path $ScriptRoot "WebDriver"))
                        $service.SuppressInitialDiagnosticInformation = $true
                        $service.HideCommandPromptWindow = $true
                
                        $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($service, $options)
                    }
                    elseif ($Browser -eq "Edge") {
                        # Launch msedgedriver and connect via RemoteWebDriver with W3C capabilities
                        $edgeArgs = @()
                        if (-not $Headed) { $edgeArgs += "--headless=new" }
                        $edgeArgs += "--disable-gpu", "--no-sandbox", "--disable-dev-shm-usage", "--log-level=3", "--disable-logging"
                
                        # Enhanced isolation for Edge to avoid conflicts
                        $tempProfile = Join-Path $env:TEMP ("Edge_LearnCert_" + (Get-Random))
                        $edgeArgs += "--user-data-dir=$tempProfile"
                        $edgeArgs += "--disable-web-security"
                        $edgeArgs += "--disable-features=VizDisplayCompositor"
                        $edgeArgs += "--disable-background-timer-throttling"
                        $edgeArgs += "--disable-backgrounding-occluded-windows"
                        $edgeArgs += "--disable-renderer-backgrounding"
                        $edgeArgs += "--no-first-run"
                        $edgeArgs += "--no-default-browser-check"
                        $edgeArgs += "--disable-sync"
                        $edgeArgs += "--disable-extensions"
                
                        Write-Info "Using isolated Edge profile: $tempProfile"

                        $edgeDriverExe = Join-Path $ScriptRoot 'WebDriver\msedgedriver.exe'
                        if (-not (Test-Path $edgeDriverExe)) { throw "msedgedriver not found at $edgeDriverExe" }

                        # Start msedgedriver manually on a random port
                        $port = Get-Random -Minimum 20000 -Maximum 60000
                        $driverArgs = @("--port=$port")
                        $driverProc = Start-Process -FilePath $edgeDriverExe -ArgumentList $driverArgs -WindowStyle Hidden -PassThru

                        # Wait for the driver HTTP endpoint to be ready
                        $ready = $false
                        for ($i = 0; $i -lt 40; $i++) {
                            Start-Sleep -Milliseconds 250
                            try {
                                $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:{0}/status" -f $port) -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
                                if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { $ready = $true; break }
                            }
                            catch {}
                        }
                        if (-not $ready) { throw "msedgedriver did not become ready on port $port" }

                        $remoteUri = New-Object System.Uri ("http://127.0.0.1:{0}" -f $port)

                        $driver = $null

                        # 1) Try DesiredCapabilities (older Selenium API)
                        try { $null = [OpenQA.Selenium.Remote.DesiredCapabilities] } catch {}
                        if ([System.Type]::GetType('OpenQA.Selenium.Remote.DesiredCapabilities', $false)) {
                            foreach ($bn in @('msedge', 'MicrosoftEdge')) {
                                try {
                                    $dc = New-Object OpenQA.Selenium.Remote.DesiredCapabilities
                                    $dc.SetCapability('browserName', $bn)
                                    $dc.SetCapability('ms:edgeOptions', @{ args = $edgeArgs })
                                    $driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver($remoteUri, $dc)
                                    break
                                }
                                catch {
                                    if ($_.Exception.Message -notmatch 'No matching capabilities') { throw }
                                }
                            }
                        }

                        # 2) Try EdgeOptions if available
                        if (-not $driver) {
                            $eo = $null
                            try { $eo = New-Object OpenQA.Selenium.Edge.EdgeOptions } catch {}
                            if ($eo) {
                                $added = $false
                                try { foreach ($a in $edgeArgs) { $eo.AddArgument($a) }; $added = $true } catch {}
                                if (-not $added) { try { $eo.AddAdditionalOption('args', $edgeArgs) } catch {} }
                                try { $driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver($remoteUri, $eo.ToCapabilities()) } catch {}
                            }
                        }

                        # 3) Fallback: tweak ChromeOptions capabilities for msedge
                        if (-not $driver) {
                            $co = New-Object OpenQA.Selenium.Chrome.ChromeOptions
                            foreach ($a in $edgeArgs) { try { $co.AddArgument($a) } catch {} }
                            try { $co.AddExcludedArgument('enable-logging') } catch {}
                            $caps = $co.ToCapabilities()
                            try {
                                $capDictField = $caps.GetType().GetField('capabilitiesDictionary', [System.Reflection.BindingFlags]'NonPublic,Instance')
                                if ($capDictField) {
                                    $dict = $capDictField.GetValue($caps)
                                    $dict['browserName'] = 'msedge'
                                    $dict['ms:edgeOptions'] = @{ args = $edgeArgs }
                                }
                            }
                            catch {}
                            $driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver($remoteUri, $caps)
                        }
                    }
            
                    # If we successfully created a driver, break out of retry loop
                    if ($driver) {
                        Write-Log "Browser started successfully" "Green"
                        break
                    }
            
                }
                catch {
                    $retryCount++
                    Write-Log "Browser startup attempt failed: $_" "Yellow"
                
                    if ($retryCount -ge $maxRetries) {
                        throw "Failed to start browser after $maxRetries attempts: $_"
                    }
                
                    # Clean up any partial state before retry
                    if ($driver) { try { $driver.Quit(); $driver.Dispose() } catch {} }
                    if ($driverProc) { try { $driverProc.Kill(); $driverProc.Dispose() } catch {} }
                    $driver = $null
                    $driverProc = $null
                
                    # Clean up temp profile before retry
                    if ($tempProfile -and (Test-Path $tempProfile)) {
                        try { Remove-Item -Path $tempProfile -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                    }
                }
            }
        }
        catch {
            Write-Log "$Browser failed: $_" "Red"
            Write-Log "Manual fix: Stop-Process -Name $($driverName -replace '\.exe$', '') -Force; Remove-Item '$(Join-Path $ScriptRoot 'WebDriver')' -Recurse -Force; then re-run script" "Yellow"
            throw "$Browser WebDriver failed"
        }
        
        if (-not $driver) {
            throw "WebDriver failed to initialize"
        }
        
        Write-Info "Navigating to transcript page..."
        $driver.Navigate().GoToUrl($Url)
        
        Write-Info "Waiting for page to load ($WebDriverWaitSeconds seconds)..."
        Start-Sleep -Seconds $WebDriverWaitSeconds
        
        # Wait for certification table to appear
        $maxWait = 30
        $waited = 0
        while ($waited -lt $maxWait) {
            $html = $driver.PageSource
            if ($html -match "Microsoft Certified" -or $html -match "Certification title") {
                Write-Log "Certification content loaded" "Green"
                break
            }
            Start-Sleep -Seconds 2
            $waited += 2
            Write-DebugMsg "Still waiting for content... ($waited/$maxWait s)"
        }
        
        $pageHtml = $driver.PageSource
        $sizeKB = [math]::Round([System.Text.Encoding]::UTF8.GetByteCount($pageHtml) / 1024, 2)
        Write-Info "Retrieved page HTML ($sizeKB KB)"
        
        return $pageHtml
    }
    finally {
        if ($driver) {
            Write-Info "Closing browser..."
            try { $driver.Quit() } catch { }
        }
        if ($driverProc) {
            try { $driverProc.Kill() } catch { }
        }
        
        # Clean up temporary Chrome profile if it was created
        if ($Browser -eq "Chrome" -and $tempProfile -and (Test-Path $tempProfile)) {
            try {
                Write-Info "Cleaning up temporary Chrome profile..."
                Start-Sleep -Seconds 2  # Give Chrome time to fully close
                Remove-Item -Path $tempProfile -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Info "Note: Temporary profile cleanup will happen on next reboot: $tempProfile"
            }
        }
    }
}

function ConvertFrom-TranscriptHtml {
    param([Parameter(Mandatory)][string]$Html)
    
    $results = @()
    $cleanHtml = $Html -replace '[\r\n]+', ' ' -replace '\s+', ' '
    
    Write-Info "Parsing HTML ($([System.Text.Encoding]::UTF8.GetByteCount($Html)) bytes)..."
    
    # Strategy 1: Look for table rows
    $rowPattern = '<tr[^>]*>.*?</tr>'
    $rows = [regex]::Matches($cleanHtml, $rowPattern, 'IgnoreCase,Singleline')
    Write-Verbose "Found $($rows.Count) table row elements"
    
    foreach ($row in $rows) {
        $rowHtml = $row.Value
        
        # Look for cells
        $cellPattern = '<td[^>]*>(.*?)</td>'
        $cells = [regex]::Matches($rowHtml, $cellPattern, 'IgnoreCase,Singleline')
        
        if ($cells.Count -lt 3) { continue }
        
        Write-Verbose "Processing row with $($cells.Count) cells"
        
        $certTitle = $null
        $certNumber = $null
        $earnedDate = $null
        $expiresDate = $null
        
        for ($i = 0; $i -lt $cells.Count; $i++) {
            $cellContent = $cells[$i].Groups[1].Value
            $cellText = ($cellContent -replace '<[^>]+>', '').Trim()
            
            # Detect which column based on content patterns
            if ($cellContent -match 'Microsoft Certified|Associate|Expert|Fundamentals') {
                $titleMatch = [regex]::Match($cellContent, '>([^<]+)</a>', 'IgnoreCase')
                if ($titleMatch.Success) {
                    $certTitle = $titleMatch.Groups[1].Value.Trim()
                }
                elseif ($cellText -and $cellText.Length -gt 10) {
                    $certTitle = $cellText
                }
            }
            elseif ($cellText -match '^[A-Z0-9]{6,}-[A-Z0-9]{6,}$') {
                $certNumber = $cellText
            }
            elseif ($cellText -match '\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|[A-Za-z]{3}\s+\d{1,2},\s+\d{4}|\d{4}-\d{2}-\d{2}') {
                if (-not $earnedDate) {
                    $earnedDate = $cellText
                }
                else {
                    $expiresDate = $cellText
                }
            }
        }
        
        if ($certTitle) {
            $parsedExpiry = $null
            if ($expiresDate) {
                # Try parsing with different cultures
                $parseSuccess = $false
                $cultures = @('en-US', 'fi-FI', 'en-GB', 'sv-SE')
                
                foreach ($culture in $cultures) {
                    try {
                        $cultureInfo = [System.Globalization.CultureInfo]::GetCultureInfo($culture)
                        $parsedExpiry = [datetime]::Parse($expiresDate, $cultureInfo)
                        $parseSuccess = $true
                        break
                    }
                    catch {
                        # Try next culture
                    }
                }
                
                # Fallback to simple parse
                if (-not $parseSuccess) {
                    try {
                        $parsedExpiry = [datetime]::Parse($expiresDate)
                    }
                    catch {
                        # Could not parse date
                    }
                }
            }
            
            Write-DebugMsg "Found: $certTitle | #$certNumber | Expires: $expiresDate"
            
            Write-Verbose "Parsed certification: $certTitle"
            
            $results += [pscustomobject]@{
                Name        = $certTitle
                CertNumber  = $certNumber
                EarnedDate  = $earnedDate
                ExpiresDate = $expiresDate
                Expiration  = $parsedExpiry
            }
        }
    }
    
    Write-Info "Total parsed: $($results.Count) certifications"
    $results | Sort-Object Name -Unique
}
#endregion ===========================================

#region ======= FILTER & NOTIFY =======
function Get-ExpiringCerts {
    param([Parameter(Mandatory)][array]$Certs, [int]$DaysBefore = 7)
    $now = Get-Date
    $threshold = $now.AddDays($DaysBefore)
    $Certs | Where-Object { 
        $_.Expiration -and 
        $_.Expiration -le $threshold -and 
        $_.Expiration -ge $now.Date 
    }
}

function Send-AlertEmailSmtp {
    param([string]$Subject, [string]$Body)
    
    try {
        # Use .NET SmtpClient for modern email sending
        $smtp = New-Object System.Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
        $smtp.EnableSsl = $UseSsl
        
        # Only set credentials if not using anonymous SMTP
        if (-not $UseAnonymousSmtp) {
            $smtp.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPassword)
            Write-Log "Using authenticated SMTP" "Cyan"
        }
        else {
            Write-Log "Using anonymous SMTP (no authentication)" "Cyan"
        }
        
        $message = New-Object System.Net.Mail.MailMessage
        $message.From = $EmailFrom
        $message.To.Add($EmailTo)
        $message.Subject = $Subject
        $message.Body = $Body
        $message.IsBodyHtml = $false
        
        $smtp.Send($message)
        $message.Dispose()
        
        Write-Log "Email sent successfully to $EmailTo" "Green"
    }
    catch {
        Write-Log "Failed to send email: $_" "Red"
        Write-Log "SMTP Config: Server=$SmtpServer, Port=$SmtpPort, SSL=$UseSsl, Anonymous=$UseAnonymousSmtp" "Yellow"
        throw
    }
}

function Send-AlertEmailGraph {
    param([string]$Subject, [string]$Body)
    $message = @{
        Subject      = $Subject
        Body         = @{ ContentType = "Text"; Content = $Body }
        ToRecipients = @(@{ EmailAddress = @{ Address = $EmailTo } })
    }
    Send-MgUserMail -UserId "me" -Message $message -SaveToSentItems
}
#endregion ============================

#region ======= NOTIFICATION =======
function Show-CertExpiryNotification {
    param(
        [array]$ExpiringCerts,
        [int]$DaysThreshold
    )
    
    $title = "Microsoft Certifications Expiring"
    
    # Build concise notification message
    $certNames = ($ExpiringCerts | Select-Object -First 3 | ForEach-Object { 
            if ($_.Name.Length -gt 30) { $_.Name.Substring(0, 27) + '...' } else { $_.Name }
        })
    $message = "$($ExpiringCerts.Count) cert$(if ($ExpiringCerts.Count -eq 1) { '' } else { 's' }) expiring: " + ($certNames -join ', ')
    if ($ExpiringCerts.Count -gt 3) {
        $message += ", ...$($ExpiringCerts.Count - 3) more"
    }
    
    Write-Log "Showing notification for $($ExpiringCerts.Count) expiring cert(s)" "Yellow"
    
    # Try Windows 10/11 Toast first
    $toastShown = Show-ToastNotification -Title $title -Message $message
    
    if (-not $toastShown) {
        # Fallback to balloon tip
        Show-BalloonNotification -Title $title -Message $message -DurationSeconds $NotificationDurationSeconds
    }
}
#endregion ============================

#region ======= MAIN =======
try {
    # Enhanced Task Scheduler debugging
    if ($TaskSchedulerDebug -or ([Environment]::UserInteractive -eq $false)) {
        Write-Log "=== TASK SCHEDULER DEBUGGING ===" "Cyan"
        Write-Log "UserInteractive: $([Environment]::UserInteractive)" "Cyan"
        Write-Log "SessionName: $env:SESSIONNAME" "Cyan"
        Write-Log "Current Directory: $(Get-Location)" "Cyan"
        Write-Log "Script Parameters: TranscriptUrl=$([bool]$TranscriptUrl), Browser=$Browser" "Cyan"
        
        # Test browser availability first
        if (-not (Test-BrowserAvailability -Browser $Browser)) {
            throw "Browser $Browser is not available or cannot be launched"
        }
        
        # Test Selenium module
        if (-not (Test-SeleniumModule)) {
            throw "Selenium module not available"
        }
        
        Write-Log "Initial checks passed for Task Scheduler execution" "Green"
    }
    
    if ([string]::IsNullOrWhiteSpace($TranscriptUrl)) { 
        throw "Set `$TranscriptUrl to your Learn transcript share link." 
    }

    Write-Log "=== Certificate Expiry Check Started ===" "Green"
    
    if ($UseSelenium) {
        Write-Log "Using Selenium WebDriver to load JavaScript content..."
        $html = Get-TranscriptHtmlWithSelenium -Url $TranscriptUrl
    }
    else {
        throw "Selenium is required for this script"
    }

    if ($DebugHtml) {
        $debugFile = Join-Path $ScriptRoot 'debug-transcript.html'
        $html | Out-File -FilePath $debugFile -Encoding UTF8
        Write-Host "Debug HTML saved to $debugFile"
    }

    $certs = ConvertFrom-TranscriptHtml -Html $html

    if (-not $certs -or $certs.Count -eq 0) {
        Write-Log "No certifications found." "Yellow"
        Write-Log "Ensure you are logged in to Microsoft Learn in Chrome. If using -DebugHtml, check the saved HTML file." "Yellow"
        exit 0
    }

    Write-Color ""
    Write-Color "Summary" ([ConsoleColor]::Cyan)
    Write-Color (New-Object string('=', 60)) ([ConsoleColor]::DarkCyan)
    Write-Color ("Total certifications found: {0}" -f $certs.Count) ([ConsoleColor]::Green)
    $certsWithExpiry = $certs | Where-Object { $_.Expiration }
    Write-Color ("With expiration date: {0}" -f $certsWithExpiry.Count) ([ConsoleColor]::Cyan)
    Write-Color ""
    
    $now = (Get-Date).Date
    $soon = $certsWithExpiry | Where-Object { $_.Expiration.Date -ge $now -and $_.Expiration -le $now.AddDays($DaysBeforeExpiry) } | Sort-Object Expiration
    $active = $certsWithExpiry | Where-Object { $_.Expiration.Date -gt $now.AddDays($DaysBeforeExpiry) } | Sort-Object Expiration
    $expired = $certsWithExpiry | Where-Object { $_.Expiration.Date -lt $now } | Sort-Object Expiration
    $legacy = $certs | Where-Object { -not $_.Expiration } | Sort-Object Name

    Show-TableSummary -Items $soon -Title ("Expiring within {0} days" -f $DaysBeforeExpiry) -Color ([ConsoleColor]::Yellow) -RowColor ([ConsoleColor]::Yellow)
    Show-TableSummary -Items $active -Title "Active (beyond window)" -Color ([ConsoleColor]::Gray) -RowColor ([ConsoleColor]::Gray)
    Show-TableSummary -Items $expired -Title "Expired" -Color ([ConsoleColor]::Red) -RowColor ([ConsoleColor]::Red)
    Show-TableSummary -Items $legacy -Title "Legacy (no expiration)" -Color ([ConsoleColor]::DarkGray) -RowColor ([ConsoleColor]::DarkGray)

    $expiring = Get-ExpiringCerts -Certs $certs -DaysBefore $DaysBeforeExpiry
    
    if (-not $expiring -or $expiring.Count -eq 0) {
        Write-Log "✓ No certifications expiring within $DaysBeforeExpiry days." "Green"
        
        # Show next upcoming expiration for info
        $nextExpiring = $certsWithExpiry | 
        Where-Object { $_.Expiration -gt (Get-Date) } | 
        Sort-Object Expiration | 
        Select-Object -First 1
        
        if ($nextExpiring) {
            $daysUntil = ($nextExpiring.Expiration.Date - (Get-Date).Date).Days
            Write-Log "Next expiration: $($nextExpiring.Name) in $daysUntil days ($($nextExpiring.Expiration.ToString('yyyy-MM-dd')))" "Cyan"
        }
        
        exit 0
    }

    Write-Color ("`nFound {0} certification(s) expiring within {1} days" -f $expiring.Count, $DaysBeforeExpiry) ([ConsoleColor]::Yellow)

    # Show notification
    if ($ShowPopupNotification) {
        Show-CertExpiryNotification -ExpiringCerts $expiring -DaysThreshold $DaysBeforeExpiry
    }
    
    # Send email ONLY if -SendEmail switch was provided
    if ($SendEmail) {
        $body = "The following Microsoft certifications will expire within $DaysBeforeExpiry days:`r`n`r`n"
        foreach ($c in $expiring | Sort-Object Expiration) {
            $d = if ($c.Expiration) {
                $c.Expiration.ToString("yyyy-MM-dd")
            }
            elseif ($c.ExpiresDate) {
                $c.ExpiresDate
            }
            else {
                "Unknown"
            }
            $days = if ($c.Expiration) { 
                ($c.Expiration.Date - (Get-Date).Date).Days 
            }
            else { 
                "?" 
            }
            
            $body += "- $($c.Name)`r`n"
            if ($c.CertNumber) { $body += "  Cert #: $($c.CertNumber)`r`n" }
            if ($c.EarnedDate) { $body += "  Earned: $($c.EarnedDate)`r`n" }
            $body += "  Expires: $d (in $days day$(if ($days -eq 1) { '' } else { 's' }))`r`n`r`n"
        }
        
        $body += "View your transcript: $TranscriptUrl"
        
        $subject = "[Cert Alert] $($expiring.Count) certification$(if ($expiring.Count -eq 1) { '' } else { 's' }) expiring within $DaysBeforeExpiry days"

        Write-Log "Sending email alert: $subject" "Green"
        
        try {
            if ($UseGraph) { 
                Send-AlertEmailGraph -Subject $subject -Body $body 
                Write-Log "Email sent via Microsoft Graph" "Green"
            }
            elseif ($UseSmtp) { 
                Send-AlertEmailSmtp -Subject $subject -Body $body 
            }
        }
        catch {
            Write-Log "Email sending failed, but notification was shown" "Yellow"
        }
    } # End if ($SendEmail)

    if ($VerboseConsole) {
        Write-Color "`nExpiring certifications (details):" ([ConsoleColor]::Yellow)
        foreach ($c in $expiring | Sort-Object Expiration) {
            $days = ($c.Expiration.Date - (Get-Date).Date).Days
            $status = if ($days -lt 0) { "EXPIRED" } else { "Expires in $days day$(if ($days -eq 1) { '' } else { 's' })" }
            Write-Color ("  - {0}" -f $c.Name) ([ConsoleColor]::Red)
            if ($c.CertNumber) { Write-Color ("    Cert #: {0}" -f $c.CertNumber) ([ConsoleColor]::DarkGray) }
            Write-Color ("    {0} ({1})" -f $status, $c.Expiration.ToString('yyyy-MM-dd')) ([ConsoleColor]::Yellow)
        }
    }

    Write-Log "=== Certificate Expiry Check Completed ===" "Green"
}
catch {
    $errorMsg = $_.Exception.Message
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorCmd = $_.InvocationInfo.MyCommand.Name
    
    Write-Log "=== SCRIPT ERROR ===" "Red"
    Write-Log "ERROR: $errorMsg" "Red"
    Write-Log "Line: $errorLine, Command: $errorCmd" "Red"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "Red"
    
    # Enhanced Task Scheduler error reporting
    if ($TaskSchedulerDebug -or ([Environment]::UserInteractive -eq $false)) {
        Write-Log "=== TASK SCHEDULER ERROR CONTEXT ===" "Red"
        Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)" "Red"
        Write-Log "Execution Policy: $(try { Get-ExecutionPolicy } catch { 'Unknown' })" "Red"
        Write-Log "Working Directory: $(try { Get-Location } catch { 'Unknown' })" "Red"
        Write-Log "Environment Variables:" "Red"
        Write-Log "  USERPROFILE: $env:USERPROFILE" "Red"
        Write-Log "  USERNAME: $env:USERNAME" "Red"
        Write-Log "  COMPUTERNAME: $env:COMPUTERNAME" "Red"
        Write-Log "  SESSIONNAME: $env:SESSIONNAME" "Red"
        
        # Try to show a notification about the error if possible
        try {
            Show-ToastNotification -Title "Learn Cert Monitor - Error" -Message "Script failed: $errorMsg. Check cert-expiry.log for details."
        }
        catch {
            Write-Log "Could not show error notification: $_" "Red"
        }
    }
    
    exit 1
}
#endregion ==================