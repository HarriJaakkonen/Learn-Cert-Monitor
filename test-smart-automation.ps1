# Smart Automation Test Script
# This tests if Smart automation can work without the syntax errors

Write-Host "🧠 Smart Automation Test" -ForegroundColor Cyan
Write-Host "=" * 50

# Step 1: Test activity detection directly
Write-Host "`n🔍 Step 1: Testing activity detection..." -ForegroundColor Yellow

try {
    Add-Type -TypeDefinition '
        using System;
        using System.Runtime.InteropServices;
        public class Win32Activity {
            [DllImport("user32.dll")]
            public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
            
            public struct LASTINPUTINFO {
                public uint cbSize;
                public uint dwTime;
            }
        }
    ' -ErrorAction SilentlyContinue
    
    $lastInputInfo = New-Object Win32Activity+LASTINPUTINFO
    $lastInputInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lastInputInfo)
    
    if ([Win32Activity]::GetLastInputInfo([ref]$lastInputInfo)) {
        $tickCount = [Environment]::TickCount
        $idleTime = ($tickCount - $lastInputInfo.dwTime) / 1000 / 60
        
        Write-Host "✅ Activity detection works!" -ForegroundColor Green
        Write-Host "   User idle time: $([math]::Round($idleTime, 1)) minutes" -ForegroundColor White
        
        $isActive = $idleTime -lt 10
        Write-Host "   User is: $(if($isActive){'ACTIVE ✅'}else{'IDLE 😴'})" -ForegroundColor $(if ($isActive) { 'Green' }else { 'Yellow' })
    }
}
catch {
    Write-Host "❌ Activity detection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 2: Test time-based triggers
Write-Host "`n⏰ Step 2: Testing time-based triggers..." -ForegroundColor Yellow

$currentTime = Get-Date
$currentTimeString = $currentTime.ToString("HH:mm")
$testTimes = @($currentTimeString, $currentTime.AddMinutes(1).ToString("HH:mm"), $currentTime.AddMinutes(2).ToString("HH:mm"))

Write-Host "   Current time: $currentTimeString" -ForegroundColor White
Write-Host "   Test notification times: $($testTimes -join ', ')" -ForegroundColor White

foreach ($testTime in $testTimes) {
    if ($currentTimeString -eq $testTime) {
        Write-Host "   ✅ Time match found for $testTime" -ForegroundColor Green
        break
    }
}

# Step 3: Test state management
Write-Host "`n💾 Step 3: Testing state management..." -ForegroundColor Yellow

$stateFile = Join-Path $env:TEMP "smart-test-state.json"
$testState = @{
    LastNotifications = @(
        @{
            Date      = (Get-Date).Date.ToString("yyyy-MM-dd")
            Time      = $currentTimeString
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    )
}

try {
    $testState | ConvertTo-Json | Set-Content $stateFile
    $readState = Get-Content $stateFile | ConvertFrom-Json
    Write-Host "✅ State management works!" -ForegroundColor Green
    Write-Host "   State file: $stateFile" -ForegroundColor White
    Write-Host "   Last notification: $($readState.LastNotifications[0].Timestamp)" -ForegroundColor White
}
catch {
    Write-Host "❌ State management failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Test notification execution (the actual problem area)
Write-Host "`n🔔 Step 4: Testing notification execution..." -ForegroundColor Yellow

Write-Host "   Testing subprocess notification..." -ForegroundColor White
$scriptPath = "C:\Repos\Learn-Cert-Monitor\get-learncerts-api.ps1"
$arguments = @("-ExecutionPolicy", "Bypass", "-File", $scriptPath, "-ShareCode", "ABC123XYZ")

# Test with different window styles
$windowStyles = @("Normal", "Minimized", "Hidden")

foreach ($style in $windowStyles) {
    Write-Host "   Testing with WindowStyle: $style" -ForegroundColor Gray
    
    try {
        $process = Start-Process "pwsh.exe" -ArgumentList $arguments -WindowStyle $style -PassThru
        $process.WaitForExit(15000)  # Wait max 15 seconds
        
        if ($process.HasExited) {
            $exitCode = $process.ExitCode
            if ($exitCode -eq 0) {
                Write-Host "   ✅ ${style}: Success (Exit code: $exitCode)" -ForegroundColor Green
            }
            else {
                Write-Host "   ❌ ${style}: Failed (Exit code: $exitCode)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "   ⚠️ ${style}: Timeout (still running)" -ForegroundColor Yellow
            $process.Kill()
        }
    }
    catch {
        Write-Host "   ❌ ${style}: Error - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep 2
}

# Step 5: Create a working Smart automation script
Write-Host "`n🛠️ Step 5: Creating simplified Smart automation..." -ForegroundColor Yellow

$workingSmartScript = @"
# Simplified Smart Automation - No Syntax Errors
# Generated: $(Get-Date)

Write-Host "🧠 Smart Monitor Started: `$(Get-Date)" -ForegroundColor Cyan

# Configuration
`$MainScript = "C:\Repos\Learn-Cert-Monitor\get-learncerts-api.ps1"
`$ShareCode = "ABC123XYZ"
`$StateFile = Join-Path `$env:TEMP "smart-monitor-simple.json"

# Simple activity check
function Test-Activity {
    try {
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Activity { [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref Info plii); public struct Info { public uint cbSize; public uint dwTime; } }' -ErrorAction SilentlyContinue
        `$info = New-Object Activity+Info
        `$info.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf(`$info)
        if ([Activity]::GetLastInputInfo([ref]`$info)) {
            `$idle = ([Environment]::TickCount - `$info.dwTime) / 1000 / 60
            return `$idle -lt 10
        }
    } catch { return `$true }
    return `$true
}

# Main loop - run for 5 minutes (10 cycles of 30 seconds)
for (`$i = 1; `$i -le 10; `$i++) {
    `$time = Get-Date -Format "HH:mm"
    Write-Host "Cycle `$i/10 - Time: `$time" -ForegroundColor White
    
    # Trigger every 2 minutes for testing
    if (`$i % 4 -eq 0) {  # Every 4th cycle (2 minutes)
        if (Test-Activity) {
            Write-Host "✅ User active - triggering notification" -ForegroundColor Green
            Start-Process "pwsh.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`$MainScript", "-ShareCode", "`$ShareCode" -WindowStyle Minimized
        } else {
            Write-Host "😴 User idle - skipping notification" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep 30
}

Write-Host "🏁 Smart Monitor Test Completed" -ForegroundColor Cyan
"@

$smartScriptPath = "smart-test.ps1"
Set-Content -Path $smartScriptPath -Value $workingSmartScript

Write-Host "✅ Created simplified Smart automation: $smartScriptPath" -ForegroundColor Green

# Step 6: Test the simplified Smart automation
Write-Host "`n🚀 Step 6: Testing simplified Smart automation..." -ForegroundColor Yellow
Write-Host "   This will run for 5 minutes with notifications every 2 minutes" -ForegroundColor White
Write-Host "   Starting in 5 seconds..." -ForegroundColor Cyan

Start-Sleep 5

Write-Host "🎯 Running Smart automation test..." -ForegroundColor Green
Start-Process "pwsh.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", $smartScriptPath -WindowStyle Normal

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "✅ Smart automation test launched" -ForegroundColor Green
Write-Host "✅ Should show notifications every 2 minutes when you're active" -ForegroundColor Green
Write-Host "✅ Test will run for 5 minutes total" -ForegroundColor Green
Write-Host "✅ Watch for notification windows to appear" -ForegroundColor Green

Write-Host "`n⏰ You should see notifications at:" -ForegroundColor Yellow
for ($i = 1; $i -le 3; $i++) {
    $notifyTime = (Get-Date).AddMinutes($i * 2)
    Write-Host "   $($notifyTime.ToString('HH:mm:ss'))" -ForegroundColor White
}