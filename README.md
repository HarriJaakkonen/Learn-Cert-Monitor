# 🎓 Microsoft Learn Certificate Monitor

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0-orange.svg)](CHANGELOG.md)

**Never miss a Microsoft certification renewal deadline again!** 🚀

This PowerShell automation script monitors your Microsoft Learn certification transcript and sends beautiful desktop notifications for upcoming expirations. Set it up once and forget about it - your certifications are automatically monitored daily.

![Certificate Monitor Screenshot](assets/notification-preview.png)

## ✨ Key Features

### 🔔 **Smart Notifications**
- **Windows Toast Notifications** with Microsoft logo
- **Multiple fallback systems** (BurntToast → Balloon → MessageBox)
- **Custom notification center** integration ("Learn Cert Monitor" app)
- **Configurable alert thresholds** (default: 100 days before expiration)

### 🤖 **Automated Monitoring**
- **Daily scheduled execution** via Windows Task Scheduler
- **Headless browser automation** using Selenium WebDriver
- **Browser conflict resolution** with isolated profiles
- **Auto-dependency management** - works in clean environments
- **Enhanced user feedback** during automation setup

### 🚀 **Performance & Reliability**
- **Microsoft Edge optimized** (2x faster than Chrome)
- **Advanced error handling** with comprehensive logging
- **Cross-PowerShell compatibility** (5.1+ and 7+)
- **No admin rights required** (runs in user context)
- **Automatic WebDriver downloads** with version matching

### 💡 **User Experience**
- **Instant feedback** with `-AutomationRunSync` parameter
- **Comprehensive documentation** with troubleshooting guide
- **Clean environment support** with automatic setup
- **Verbose logging** for debugging and monitoring

## 🚀 Quick Start

### Prerequisites
- **Windows 10/11** with PowerShell 5.1 or PowerShell 7+ (recommended)
- **Microsoft Edge** (recommended) or **Google Chrome** browser
- **Internet connection** for transcript access and WebDriver downloads
- **Public Microsoft Learn transcript** (see [Getting Your Transcript URL](#getting-your-transcript-url))

### Basic Usage

1. **Get your Microsoft Learn transcript URL** (see instructions below)
2. **Run a one-time check:**
   ```powershell
   .\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/[username]/transcript/[id]"
   ```

3. **Set up daily automation with instant verification:**
   ```powershell
   .\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime "08:00" -TranscriptUrl "https://learn.microsoft.com/en-us/users/[username]/transcript/[id]" -Browser Edge -AutomationRunSync
   ```

That's it! The script handles everything else automatically. 🎉

## 📋 Getting Your Transcript URL

Your Microsoft Learn transcript must be **public** for the script to access it:

1. **Visit** [learn.microsoft.com](https://learn.microsoft.com) and sign in
2. **Click your profile picture** in the top-right corner
3. **Select "Transcript"** from the dropdown menu
4. **Click the "Share" button** (usually near the top-right)
5. **Click "Copy link"** to get your public transcript URL
6. **Verify accessibility** by opening the URL in an incognito/private browser window

The URL format will be: `https://learn.microsoft.com/en-us/users/[username]/transcript/[unique-id]`

## 🛠️ Installation & Setup

### Automatic Installation (Recommended)
The script automatically installs all required dependencies:
- **Selenium PowerShell module** (≥3.0.0)
- **BurntToast module** (≥0.8.0) for enhanced notifications
- **WebDriver binaries** (ChromeDriver or MSEdgeDriver)

No manual setup required! Just run the script and it handles everything.

### Manual Module Installation (Optional)
If you prefer to install modules manually:
```powershell
Install-Module -Name Selenium -MinimumVersion 3.0.0 -Scope CurrentUser
Install-Module -Name BurntToast -MinimumVersion 0.8.0 -Scope CurrentUser
```

## 📖 Usage Examples

### One-Time Check
```powershell
# Basic check with desktop notifications
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123"

# With verbose output for troubleshooting
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -VerboseConsole -Browser Edge

# With email notifications (requires SMTP configuration)
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -SendEmail
```

### Automation Setup
```powershell
# Create daily automation at 8:00 AM with immediate verification
.\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime "08:00" -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -Browser Edge -AutomationRunSync

# Create automation that runs immediately in background
.\get-learncerts.ps1 -CreateAutomation -AutomationDailyTime "07:30" -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -Browser Edge -AutomationRunNow

# Overwrite existing automation
.\get-learncerts.ps1 -CreateAutomation -AutomationForce -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -Browser Edge
```

### Debugging & Troubleshooting
```powershell
# Save page HTML for inspection
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -DebugHtml

# Show browser UI (non-headless) for visual debugging
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -Headed -VerboseConsole

# Enhanced Task Scheduler debugging
.\get-learncerts.ps1 -TranscriptUrl "https://learn.microsoft.com/en-us/users/username/transcript/abc123" -TaskSchedulerDebug
```

## ⚙️ Configuration

### Parameters Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-TranscriptUrl` | **Required.** Your Microsoft Learn transcript share link | - |
| `-Browser` | Browser to use: `Chrome` or `Edge` | `Chrome` |
| `-SendEmail` | Enable email notifications (requires SMTP config) | `False` |
| `-VerboseConsole` | Enable detailed console output | `False` |
| `-CreateAutomation` | Create Windows Scheduled Task for daily monitoring | `False` |
| `-AutomationDailyTime` | Daily run time in HH:MM format (24-hour) | `07:30` |
| `-AutomationRunSync` | Run check immediately when creating automation | `False` |
| `-AutomationRunNow` | Trigger automation task immediately (background) | `False` |
| `-AutomationForce` | Overwrite existing automation task | `False` |
| `-Headed` | Show browser UI (non-headless mode) | `False` |
| `-DebugHtml` | Save fetched HTML for troubleshooting | `False` |

### Email Configuration
To enable email notifications, edit these variables in the script:
```powershell
$EmailFrom = "alerts@yourdomain.com"
$EmailTo = "your.email@domain.com"
$SmtpServer = "smtp.yourdomain.com"
$SmtpPort = 587
$SmtpUser = "smtp-username"
$SmtpPassword = "smtp-password"
$UseSsl = $true
```

### Alert Threshold
Modify the expiration warning threshold:
```powershell
$DaysBeforeExpiry = 100  # Alert X days before expiration
```

## 🏆 Browser Performance Comparison

| Browser | Performance | Integration | Recommendation |
|---------|-------------|-------------|----------------|
| **Microsoft Edge** | 🚀 **2x faster** | ✅ Native Windows | ⭐ **Recommended** |
| **Google Chrome** | 🐌 Slower | ⚠️ May have conflicts | ✅ Supported |

**Pro Tip:** Use Microsoft Edge for best performance and Windows integration!

## 🔧 Troubleshooting

### Common Issues

**📋 "No certifications found"**
- Verify your transcript URL is correct and public
- Test URL in incognito/private browser window
- Use `-DebugHtml` to save page content for inspection
- Ensure you're logged into Microsoft Learn in your browser

**🔔 "Notifications not appearing"**
- Check Windows Notification Settings
- Verify "Learn Cert Monitor" app permissions in Action Center
- Try running script with `-VerboseConsole` for detailed output

**🤖 "WebDriver issues"**
- Script auto-downloads correct WebDriver versions
- Check `cert-expiry.log` for detailed error messages
- Ensure browser is installed and up-to-date

**⏰ "Scheduled task not running"**
- Use `-TaskSchedulerDebug` for enhanced logging
- Verify task runs only when user is logged in
- Check Task Scheduler for error details

**📦 "Module installation failed"**
- Ensure internet connectivity to PowerShell Gallery
- Try running as different user or check execution policy
- Use manual installation commands listed above

### Debug Logging
All operations are logged to `cert-expiry.log` in the script directory:
```powershell
# View recent log entries
Get-Content "cert-expiry.log" -Tail 50
```

## 🏗️ Architecture

### Technology Stack
- **PowerShell 5.1+** - Core scripting engine
- **Selenium WebDriver 3.0+** - Browser automation
- **Windows Task Scheduler** - Automated execution
- **WinRT/BurntToast** - Notification systems
- **Microsoft Edge/Chrome** - Web browser engines

### Security & Privacy
- ✅ **Uses public transcript URLs** (no authentication required)
- ✅ **No credential storage** or transmission
- ✅ **Local processing only** - no data sent to external services
- ✅ **Temporary browser profiles** automatically cleaned up
- ✅ **All logging is local** to cert-expiry.log file

### Dependencies (Auto-Managed)
The script automatically manages all dependencies:
- **Selenium PowerShell Module** (≥3.0.0)
- **BurntToast Module** (≥0.8.0)
- **ChromeDriver/MSEdgeDriver** binaries
- **.NET Framework/.NET Core** (included with PowerShell)

## 📝 Changelog

### Version 2.0 (2025-09-29)
- ✨ Added `-AutomationRunSync` parameter for immediate execution
- 🎨 Enhanced automation creation with comprehensive user feedback
- 📖 Improved user guidance with helpful tips and emojis
- ✅ Verified clean environment functionality
- ⚡ Optimized Microsoft Edge performance (2x faster than Chrome)
- 📚 Enhanced documentation with real-world examples

### Version 1.0 (2025-09-29)
- 🎉 Initial release with Chrome and Edge support
- 🛠️ Advanced browser conflict resolution
- ⏰ Windows Scheduled Task automation
- 🔔 Multi-tier notification system
- 🔍 Comprehensive error handling and debugging
- 📦 Auto-managed dependencies

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with clear description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Harri Jaakkonen**
- LinkedIn: [Connect with me](https://linkedin.com/in/harrijaakkonen)

## 🙏 Acknowledgments

Special thanks to:
- **PowerShell Community** for excellent modules and documentation
- **Selenium Project** for robust browser automation capabilities
- **Microsoft Learn Team** for providing public transcript functionality
- **Contributors** who help improve this project

---

## ⭐ Star This Project

If this tool helps you stay on top of your Microsoft certifications, please consider giving it a star! ⭐

**Never miss a renewal deadline again!** 🎯
