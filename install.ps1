param(
    [string]$Version = "",
    [string]$InstallDir = "",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoModifyPath,
    [switch]$Uninstall,
    [switch]$NoAnimation,
    [switch]$Yes,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
} catch {}
Set-StrictMode -Version Latest

$AppName = "NEXFLEX"
$BinName = "nexflex.exe"
$Repo = "Mohammedsayeed-builder/NEXFLEX-tui"
$Creator = "Mohammed Sayeed"
$DefaultInstallDir = Join-Path $env:LOCALAPPDATA "Programs\NEXFLEX\bin"

# ---------------------------------------------------------------------------
# Output capabilities: VT sequences, truecolor -> 256 -> plain, Unicode -> ASCII
# ---------------------------------------------------------------------------
$ESC = [char]27
$script:CursorHidden = $false

function Enable-VirtualTerminal {
    try {
        if (-not ("Nexflex.ConsoleMode" -as [type])) {
            Add-Type -Namespace Nexflex -Name ConsoleMode -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
"@
        }
        $handle = [Nexflex.ConsoleMode]::GetStdHandle(-11)
        $mode = [uint32]0
        if ([Nexflex.ConsoleMode]::GetConsoleMode($handle, [ref]$mode)) {
            $newMode = $mode -bor 0x0004
            return [Nexflex.ConsoleMode]::SetConsoleMode($handle, $newMode)
        }
    } catch {
        return $false
    }
    return $false
}

$script:IsTTY = $true
try { $script:IsTTY = -not [Console]::IsOutputRedirected } catch { $script:IsTTY = $true }
$script:IsCI = [bool]($env:CI -or $env:GITHUB_ACTIONS)
$script:Unicode = $true
try { $script:Unicode = ([Console]::OutputEncoding.WebName -match "utf") } catch { $script:Unicode = $true }
$script:VtEnabled = $false
if ($script:IsTTY) { $script:VtEnabled = Enable-VirtualTerminal }

$script:ColorMode = "plain"
if ($script:VtEnabled -and -not $env:NO_COLOR) {
    if (($env:COLORTERM -in @("truecolor", "24bit")) -or $env:WT_SESSION -or $env:TERM_PROGRAM) {
        $script:ColorMode = "truecolor"
    } else {
        $script:ColorMode = "256"
    }
}

$script:Anim = $false
if ($script:IsTTY -and $script:VtEnabled -and -not $NoAnimation -and -not $script:IsCI -and -not $env:NO_COLOR) {
    $script:Anim = $true
}
# Escape hatch for terminals or CI setups that want the animation anyway.
if ($env:NEXFLEX_FORCE_ANIM -and -not $NoAnimation) {
    $script:VtEnabled = $true
    $script:Anim = $true
    if ($script:ColorMode -eq "plain") { $script:ColorMode = "256" }
}

$C = @{ Reset=""; Bold=""; Dim=""; Mauve=""; Blue=""; Sapphire=""; Lavender=""; Teal=""; Green=""; Yellow=""; Red=""; Text=""; Subtext=""; Muted="" }
if ($script:ColorMode -eq "truecolor") {
    $C.Reset = "$ESC[0m"; $C.Bold = "$ESC[1m"; $C.Dim = "$ESC[2m"
    $C.Mauve = "$ESC[38;2;203;166;247m"; $C.Blue = "$ESC[38;2;137;180;250m"
    $C.Sapphire = "$ESC[38;2;116;199;236m"; $C.Lavender = "$ESC[38;2;180;190;254m"
    $C.Teal = "$ESC[38;2;148;226;213m"; $C.Green = "$ESC[38;2;166;227;161m"
    $C.Yellow = "$ESC[38;2;249;226;175m"; $C.Red = "$ESC[38;2;243;139;168m"
    $C.Text = "$ESC[38;2;205;214;244m"; $C.Subtext = "$ESC[38;2;166;173;200m"
    $C.Muted = "$ESC[38;2;108;112;134m"
} elseif ($script:ColorMode -eq "256") {
    $C.Reset = "$ESC[0m"; $C.Bold = "$ESC[1m"; $C.Dim = "$ESC[2m"
    $C.Mauve = "$ESC[38;5;183m"; $C.Blue = "$ESC[38;5;111m"
    $C.Sapphire = "$ESC[38;5;117m"; $C.Lavender = "$ESC[38;5;147m"
    $C.Teal = "$ESC[38;5;116m"; $C.Green = "$ESC[38;5;151m"
    $C.Yellow = "$ESC[38;5;223m"; $C.Red = "$ESC[38;5;211m"
    $C.Text = "$ESC[38;5;252m"; $C.Subtext = "$ESC[38;5;145m"
    $C.Muted = "$ESC[38;5;242m"
}

$script:RowColors = @($C.Mauve, $C.Blue, $C.Sapphire, $C.Teal, $C.Green, $C.Lavender)
$script:OkMark = if ($script:Unicode) { [char]0x2714 } else { "OK" }
$script:FailMark = if ($script:Unicode) { [char]0x2716 } else { "!!" }
$script:InfoMark = if ($script:Unicode) { [char]0x2139 } else { "i" }

$script:ArtUnicode = @(
    "███╗   ██╗███████╗██╗  ██╗███████╗██╗     ███████╗██╗  ██╗",
    "████╗  ██║██╔════╝╚██╗██╔╝██╔════╝██║     ██╔════╝╚██╗██╔╝",
    "██╔██╗ ██║█████╗   ╚███╔╝ █████╗  ██║     █████╗   ╚███╔╝ ",
    "██║╚██╗██║██╔══╝   ██╔██╗ ██╔══╝  ██║     ██╔══╝   ██╔██╗ ",
    "██║ ╚████║███████╗██╔╝ ██╗██║     ███████╗███████╗██╔╝ ██╗",
    "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝"
)
$script:ArtAscii = @(
    " _   _ _______  _______ _     _______  __",
    "| \ | | ____\ \/ /  ___| |   | ____\ \/ /",
    "|  \| |  _|  \  /| |_  | |   |  _|  \  /",
    "| |\  | |___ /  \|  _| | |___| |___ /  \",
    "|_| \_|_____/_/\_\_|   |_____|_____/_/\_\"
)
$script:Art = $script:ArtUnicode
$script:ArtWidth = 58

function Hide-Cursor {
    if ($script:Anim -and -not $script:CursorHidden) {
        [Console]::Out.Write("$ESC[?25l")
        $script:CursorHidden = $true
    }
}

function Restore-Cursor {
    if ($script:CursorHidden) {
        [Console]::Out.Write("$ESC[?25h")
        $script:CursorHidden = $false
    }
}

# Restore the cursor on any terminating error, and on Ctrl+C.
trap {
    Restore-Cursor
    Write-Host "  $($C.Red)$($script:FailMark)$($C.Reset) $_"
    exit 1
}
try {
    [Console]::add_CancelKeyPress([ConsoleCancelEventHandler]{
        param($sender, $eventArgs)
        [Console]::Out.Write([string][char]27 + "[?25h")
    })
} catch {}

function Select-Art {
    param([int]$Cols)
    if ($script:Unicode) {
        $script:Art = $script:ArtUnicode
        $script:ArtWidth = 58
    } else {
        $script:Art = $script:ArtAscii
        $script:ArtWidth = 42
    }
}

function Get-GlitchedLines {
    param([int]$Percent)
    $chars = "01#$%&@*+=<>/"
    $out = @()
    foreach ($line in $script:Art) {
        $sb = New-Object System.Text.StringBuilder
        foreach ($ch in $line.ToCharArray()) {
            if ($ch -ne " " -and (Get-Random -Maximum 100) -lt $Percent) {
                [void]$sb.Append($chars[(Get-Random -Maximum $chars.Length)])
            } else {
                [void]$sb.Append($ch)
            }
        }
        $out += $sb.ToString()
    }
    return ,$out
}

if ($Help) {
    Write-Host @"
NEXFLEX Installer (Windows PowerShell)

USAGE:
    irm https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.ps1 | iex
    .\install.ps1 [OPTIONS]

OPTIONS:
    -Version <tag>       Install a specific version (e.g. v0.1.14)
    -InstallDir <path>   Install binary to a custom directory
    -Force               Reinstall even if already at the latest version
    -DryRun              Perform preflight checks without writing files
    -NoModifyPath        Do not modify User PATH environment variable
    -Uninstall           Uninstall NEXFLEX from your system
    -Help                Show this help message
"@
    return
}

function Write-Step { param([string]$Message) Write-Host "  > " -ForegroundColor Cyan -NoNewline; Write-Host $Message }
function Write-Success { param([string]$Message) Write-Host "  + " -ForegroundColor Green -NoNewline; Write-Host $Message }
function Write-Warn { param([string]$Message) Write-Host "  ! " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
function Write-Err { param([string]$Message) Write-Host "  x " -ForegroundColor Red -NoNewline; Write-Host $Message }

if ($Version -and $Version[0] -ne "v") {
    $Version = "v$Version"
}

function Get-UserPathRaw {
    param([ref]$Kind)
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
    if (-not $key) { return "" }
    try {
        $raw = $key.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        try { $Kind.Value = $key.GetValueKind("Path") } catch { $Kind.Value = [Microsoft.Win32.RegistryValueKind]::ExpandString }
        return [string]$raw
    } finally {
        $key.Close()
    }
}

function Set-UserPathRaw {
    param([string]$NewPath, [Microsoft.Win32.RegistryValueKind]$ValueKind)
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    if (-not $key) { return }
    try { $key.SetValue("Path", $NewPath, $ValueKind) } finally { $key.Close() }
}
function Broadcast-EnvironmentChange {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethods'.Type)) {
            Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@ -ErrorAction SilentlyContinue
        }
        [UIntPtr]$result = [UIntPtr]::Zero
        [Win32.NativeMethods]::SendMessageTimeout(
            [IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
    } catch {}
}

function Add-ToUserPath {
    param([string]$Directory)
    $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    $raw = Get-UserPathRaw -Kind ([ref]$kind)
    $segments = @($raw -split ";" | Where-Object { $_ })
    if ($segments -notcontains $Directory.TrimEnd("\")) {
        $joined = if ($raw.Trim()) { "$raw;$Directory" } else { $Directory }
        Set-UserPathRaw -NewPath $joined -ValueKind $kind
        Broadcast-EnvironmentChange
        return $true
    }
    return $false
}

function Remove-FromUserPath {
    param([string[]]$Directories)
    $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    $raw = Get-UserPathRaw -Kind ([ref]$kind)
    if (-not $raw) { return $false }
    $normalized = @($Directories | ForEach-Object { $_.TrimEnd("\").ToLowerInvariant() })
    $kept = @($raw -split ";" | Where-Object { $_ -and ($normalized -notcontains $_.TrimEnd("\").ToLowerInvariant()) })
    if ($kept.Count -eq @($raw -split ";" | Where-Object { $_ }).Count) { return $false }
    Set-UserPathRaw -NewPath ($kept -join ";") -ValueKind $kind
    Broadcast-EnvironmentChange
    return $true
}

function Get-TerminalCols {
    $Cols = 80
    try {
        if ($Host.UI.RawUI.WindowSize.Width -gt 0) {
            $Cols = $Host.UI.RawUI.WindowSize.Width
        }
    } catch {
        $Cols = 80
    }
    return $Cols
}

function Print-Art {
    param([string[]]$Lines, [string[]]$Colors, [int]$Pad)
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line.Length -lt $script:ArtWidth) { $line = $line.PadRight($script:ArtWidth) }
        $prefix = if ($Pad -gt 0) { " " * $Pad } else { "" }
        if ($Colors -and $Colors[$i]) {
            [Console]::Out.WriteLine("$prefix$($Colors[$i])$line$($C.Reset)")
        } else {
            [Console]::Out.WriteLine("$prefix$line")
        }
    }
}

function Print-Header {
    $Cols = Get-TerminalCols
    Select-Art -Cols $Cols
    $Pad = [Math]::Max(0, [int][Math]::Floor(($Cols - $script:ArtWidth) / 2))
    $Sub = "Created by $Creator"
    $SubPad = [Math]::Max(0, [int][Math]::Floor(($Cols - $Sub.Length) / 2))

    if (-not $script:Anim) {
        if (-not $script:IsTTY) {
            Write-Host "$AppName installer - Created by $Creator"
            return
        }
        Print-Art -Lines $script:Art -Colors $null -Pad $Pad
        Write-Host ((" " * $SubPad) + $Sub)
        Write-Host ""
        return
    }

    Hide-Cursor
    $rows = $script:Art.Count

    # Phase 1 - decode/glitch to clean
    $thresholds = @(92, 62, 32, 10)
    for ($t = 0; $t -lt $thresholds.Count; $t++) {
        $frame = Get-GlitchedLines -Percent $thresholds[$t]
        Print-Art -Lines $frame -Colors $script:RowColors -Pad $Pad
        if ($t -lt $thresholds.Count - 1) {
            [Console]::Out.Write("$ESC[$($rows)A")
            Start-Sleep -Milliseconds 110
        }
    }

    # Phase 2 - gradient sweep
    for ($shift = 0; $shift -lt 4; $shift++) {
        $colors = @()
        for ($i = 0; $i -lt $rows; $i++) {
            if ($shift -eq 3) { $colors += $C.Mauve }
            else { $colors += $script:RowColors[($i + $shift) % $script:RowColors.Count] }
        }
        Print-Art -Lines $script:Art -Colors $colors -Pad $Pad
        if ($shift -lt 3) {
            [Console]::Out.Write("$ESC[$($rows)A")
            Start-Sleep -Milliseconds 70
        }
    }

    Write-Host ((" " * $SubPad) + $C.Sapphire + $C.Bold + $Sub + $C.Reset)
    Write-Host ""
    Restore-Cursor
}

function Write-Strip {
    param([int]$Current, [string]$State = "run")
    $segments = @()
    for ($i = 1; $i -le 5; $i++) {
        if ($i -lt $Current) { $seg = if ($script:Unicode) { "▓▓▓" } else { "###" } }
        elseif ($i -eq $Current) {
            switch ($State) {
                "done" { $seg = if ($script:Unicode) { "▓▓▓" } else { "###" } }
                "fail" { $seg = if ($script:Unicode) { "×××" } else { "!!!" } }
                default { $seg = if ($script:Unicode) { "▒▒▒" } else { "~~~" } }
            }
        } else { $seg = if ($script:Unicode) { "░░░" } else { "   " } }
        $segments += $seg
    }
    $sep = if ($script:Unicode) { "│" } else { "|" }
    $bar = $segments -join $sep
    if ($script:Unicode) {
        Write-Host "  $($C.Sapphire)▐$bar▌$($C.Reset)"
    } else {
        Write-Host "  [$bar]"
    }
}

function Start-Step {
    param([int]$Index, [string]$Label)
    $script:StepIndex = $Index
    $script:StepLabel = $Label
    if ($script:Anim) {
        Write-Strip -Current $Index -State "run"
    } else {
        Write-Host "  [$Index/5] $Label..." -NoNewline
    }
}

function Complete-Step {
    param([string]$Label)
    if ($script:Anim) {
        [Console]::Out.Write("$ESC[K")
        Write-Strip -Current $script:StepIndex -State "done"
    } else {
        Write-Host " done"
    }
    Write-Host "  $($C.Green)$($script:OkMark)$($C.Reset) $($C.Text)$Label$($C.Reset)"
}

function Fail-Step {
    param([string]$Label, [string]$Reason)
    if ($script:Anim) {
        [Console]::Out.Write("$ESC[K")
        Write-Strip -Current $script:StepIndex -State "fail"
    } else {
        Write-Host " failed"
    }
    Write-Host "  $($C.Red)$($script:FailMark)$($C.Reset) $($C.Text)$Label$($C.Reset)"
    if ($Reason) { Write-Host "    $($C.Muted)$Reason$($C.Reset)" }
}

function Invoke-SpinnerJob {
    param([string]$Label, [scriptblock]$Action, [object[]]$Arguments)
    if (-not $script:Anim) { return (& $Action @Arguments) }
    $job = Start-Job -ScriptBlock $Action -ArgumentList $Arguments
    $frames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $i = 0
    while ($job.State -eq "Running" -or $job.State -eq "NotStarted") {
        $f = $frames[$i % $frames.Count]
        [Console]::Out.Write("`r$ESC[K  $($C.Sapphire)$f$($C.Reset) $($C.Text)$Label$($C.Reset)")
        Start-Sleep -Milliseconds 80
        $i++
    }
    [Console]::Out.Write("`r$ESC[K")
    $jobErrors = @()
    $result = Receive-Job -Job $job -ErrorAction SilentlyContinue -ErrorVariable jobErrors
    $failed = ($job.State -ne "Completed")
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    if ($failed) {
        $reason = ($jobErrors | Out-String).Trim()
        if (-not $reason) { $reason = "the background step did not complete" }
        throw $reason
    }
    return $result
}

function Do-Uninstall {
    Print-Header
    Write-Step "Uninstalling $AppName..."
    
    $Found = $false
    $TargetDirs = @(
        $DefaultInstallDir,
        "$env:LOCALAPPDATA\NEXFLEX"
    )

    foreach ($Dir in $TargetDirs) {
        $Exe = Join-Path $Dir $BinName
        if (Test-Path $Exe) {
            try {
                $RunningProcesses = Get-Process -Name "nexflex" -ErrorAction SilentlyContinue
                if ($RunningProcesses) {
                    $RunningProcesses | Stop-Process -Force
                    Start-Sleep -Seconds 1
                }
                Remove-Item -Path $Exe -Force -ErrorAction SilentlyContinue
                Write-Success "Removed $Exe"
                $Found = $true
            } catch {
                Write-Warn "Could not remove $Exe"
            }
        }
    }

    if ($Found) {
        $Removed = Remove-FromUserPath -Directories @($DefaultInstallDir, "$env:LOCALAPPDATA\NEXFLEX\bin")
        Write-Success "$AppName was successfully uninstalled."
        if ($Removed) {
            Write-Success "Removed stale entry from User PATH."
        }
    } else {
        Write-Warn "No installed binary of $BinName was found."
    }
    return
}

if ($Uninstall) {
    Do-Uninstall
    return
}

Print-Header

$Architecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($Architecture -eq "ARM64") {
    $ArchLabel = "Windows/arm64"
    $ArchiveName = "NEXFLEX_Windows_arm64.zip"
    $PlatformName = "Windows (arm64)"
} elseif ($Architecture -eq "AMD64") {
    $ArchLabel = "Windows/x64"
    $ArchiveName = "NEXFLEX_Windows_x64.zip"
    $PlatformName = "Windows (x64)"
} else {
    Write-Err "Unsupported Windows architecture: $Architecture"
    return
}

Write-Step "Resolving release version..."

$TargetVersion = $Version
if (-not $TargetVersion) {
    try {
        $Request = [System.Net.WebRequest]::Create("https://github.com/$Repo/releases/latest")
        $Request.AllowAutoRedirect = $false
        $Response = $Request.GetResponse()
        $Location = $Response.Headers["Location"]
        if ($Location) {
            $TargetVersion = $Location.Split("/")[-1].Trim()
        }
        $Response.Close()
    } catch {
        try {
            $ReleaseJson = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "MovieBox-Installer" } -UseBasicParsing
            $TargetVersion = $ReleaseJson.tag_name.Trim()
        } catch {
            Write-Err "Failed to contact GitHub for latest release. Please check your internet connection."
            return
        }
    }
}

if (-not $TargetVersion) {
    Write-Err "Could not resolve latest release version from GitHub."
    return
}

Write-Success "Environment ready ($PlatformName, $TargetVersion)"

$EffectiveInstallDir = if ($InstallDir) { $InstallDir } else { $DefaultInstallDir }
$ExePath = Join-Path $EffectiveInstallDir $BinName

if (Test-Path $ExePath) {
    if (-not $Force) {
        $IsInteractive = [Environment]::UserInteractive -and (-not [Console]::IsInputRedirected)
        if ($IsInteractive) {
            Write-Host ""
            Write-Warn "$AppName is already installed at $ExePath"
            Write-Host "  What would you like to do?"
            Write-Host "    1) Reinstall / Update to latest version"
            Write-Host "    2) Uninstall"
            Write-Host "    3) Cancel"
            Write-Host ""
            $Choice = Read-Host "  Enter choice [1-3] (default 1)"
            if ($Choice -eq "2") {
                Do-Uninstall
                return
            } elseif ($Choice -eq "3") {
                Write-Success "No changes made. Exiting."
                return
            }
        } else {
            try {
                $CurrentVerOutput = (& $ExePath --version 2>&1 | Out-String)
                if ($CurrentVerOutput -match "nexflex\s+([\d\.]+)") {
                    $CurrentVer = "v" + $matches[1]
                    if ($CurrentVer -eq $TargetVersion) {
                        Write-Success "NEXFLEX $TargetVersion is already installed at $ExePath. Use -Force to reinstall."
                        return
                    }
                }
            } catch {}
        }
    }
}

if ($DryRun) {
    Start-Step -Index 1 -Label "Detecting platform"
    Complete-Step "Target package: $ArchiveName"
    $DryBase = if ($env:NEXFLEX_RELEASE_URL) { $env:NEXFLEX_RELEASE_URL.TrimEnd("/") } else { "https://github.com/$Repo/releases/download/$TargetVersion" }
    Write-Host "  Dry run - nothing was written."
    Write-Host "  Source: $DryBase/$ArchiveName"
    Write-Host "  Install path: $ExePath"
    Write-Host ""
    return
}

Start-Step -Index 1 -Label "Detecting platform"
Complete-Step "Platform detected: $ArchLabel -> $ArchiveName"
Write-Host "  $($C.Muted)·$($C.Reset) Resolving release version..."
Write-Host "  $($C.Green)$($script:OkMark)$($C.Reset) $($C.Text)Release: $TargetVersion$($C.Reset)"

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("nexflex-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$ZipFile = Join-Path $TempDir $ArchiveName
$ChecksumFile = Join-Path $TempDir "SHA256SUMS"
if ($env:NEXFLEX_RELEASE_URL) {
    $BaseUrl = $env:NEXFLEX_RELEASE_URL.TrimEnd("/")
} else {
    $BaseUrl = "https://github.com/$Repo/releases/download/$TargetVersion"
}
$Url = "$BaseUrl/$ArchiveName"

try {
    Start-Step -Index 2 -Label "Downloading $ArchiveName"
    $download = {
        param($u, $z, $c)
        $ProgressPreference = "SilentlyContinue"
        # Windows PowerShell 5.1 cannot fetch file:// URIs with Invoke-WebRequest,
        # so local mirrors (used by CI and by NEXFLEX_RELEASE_URL) are copied.
        function Get-Artifact {
            param([string]$From, [string]$To)
            if ($From -match '^file:') {
                Copy-Item -LiteralPath ([uri]$From).LocalPath -Destination $To -Force
            } else {
                Invoke-WebRequest -Uri $From -OutFile $To -UseBasicParsing
            }
        }
        Get-Artifact -From $u -To $z
        Get-Artifact -From $c -To "$z.SHA256SUMS"
    }
    try {
        Invoke-SpinnerJob -Label "Downloading $ArchiveName" -Action $download -Arguments @($Url, $ZipFile, "$BaseUrl/SHA256SUMS") | Out-Null
        Move-Item -Path "$ZipFile.SHA256SUMS" -Destination $ChecksumFile -Force -ErrorAction SilentlyContinue
        try { Unblock-File -Path $ZipFile -ErrorAction SilentlyContinue } catch {}
        Complete-Step "Downloaded $ArchiveName"
    } catch {
        Fail-Step "Download failed" "$_"
        throw
    }

    Start-Step -Index 3 -Label "Verifying SHA256 checksum"
    $ChecksumLine = Get-Content $ChecksumFile | Where-Object { $_ -match "\s+$([regex]::Escape($ArchiveName))$" } | Select-Object -First 1
    if (-not $ChecksumLine) {
        Fail-Step "Verification failed" "SHA256SUMS has no entry for $ArchiveName"
        throw "Release checksum is missing for $ArchiveName."
    }
    $ExpectedHash = ($ChecksumLine -split "\s+")[0].Trim().ToUpper()
    $ActualHash = (Get-FileHash -Path $ZipFile -Algorithm SHA256).Hash.Trim().ToUpper()
    if ($ActualHash -ne $ExpectedHash) {
        Fail-Step "Verification failed" "expected $ExpectedHash, got $ActualHash"
        throw "Checksum verification failed."
    }
    Complete-Step "Checksum verified against SHA256SUMS"

    Start-Step -Index 4 -Label "Installing to $EffectiveInstallDir"
    if (-not (Test-Path $EffectiveInstallDir)) {
        New-Item -ItemType Directory -Force -Path $EffectiveInstallDir | Out-Null
    }

    $RunningProcesses = Get-Process -Name "nexflex" -ErrorAction SilentlyContinue
    if ($RunningProcesses) {
        $RunningProcesses | Stop-Process -Force
        Start-Sleep -Seconds 1
    }

    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force
    $ExtractedExe = Join-Path $TempDir $BinName
    if (-not (Test-Path $ExtractedExe)) {
        throw "Binary not found in archive."
    }

    try { Unblock-File -Path $ExtractedExe -ErrorAction SilentlyContinue } catch {}
    Move-Item -Path $ExtractedExe -Destination $ExePath -Force
    try { Unblock-File -Path $ExePath -ErrorAction SilentlyContinue } catch {}
    try {
        $SmokeOutput = (& $ExePath --version 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Verification note: $SmokeOutput"
        }
    } catch {
        Write-Warn "Verification note: $_"
    }
    Complete-Step "Installed $ExePath"
} catch {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Err "Installation failed: $_"
    return
} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

$PathModified = $false
if (-not $NoModifyPath) {
    if (Add-ToUserPath -Directory $EffectiveInstallDir) {
        $PathModified = $true
    }
    # Refresh this session from the registry so `nexflex` works immediately,
    # without opening a new window.
    try {
        $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:PATH = (@($MachinePath, $UserPath) | Where-Object { $_ }) -join ";"
    } catch {
        if (@($env:PATH -split ";") -notcontains $EffectiveInstallDir.TrimEnd("\")) {
            $env:PATH = "$env:PATH;$EffectiveInstallDir"
        }
    }
    if (@($env:PATH -split ";") -notcontains $EffectiveInstallDir.TrimEnd("\")) {
        $env:PATH = "$env:PATH;$EffectiveInstallDir"
    }
}

Start-Step -Index 5 -Label "Checking for a media player"
$PlayerDetected = ""
if ((Get-Command "mpv" -ErrorAction SilentlyContinue) -or (Test-Path "C:\Program Files\mpv\mpv.exe") -or (Test-Path "C:\Program Files\MPV Player\mpv.exe") -or (Test-Path "C:\mpv\mpv.exe") -or (Test-Path "$env:LOCALAPPDATA\Programs\mpv\mpv.exe")) {
    $PlayerDetected = "mpv"
} elseif ((Get-Command "vlc" -ErrorAction SilentlyContinue) -or (Test-Path "C:\Program Files\VideoLAN\VLC\vlc.exe") -or (Test-Path "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe") -or (Test-Path "$env:LOCALAPPDATA\Programs\VLC\vlc.exe")) {
    $PlayerDetected = "VLC"
}
if ($PlayerDetected) {
    Complete-Step "Player ready: $PlayerDetected"
} else {
    Complete-Step "No player found yet (mpv recommended)"
}

# Optional mpv install - only with consent.
if (-not $PlayerDetected -and $script:IsTTY) {
    $MpvCommand = ""
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $MpvCommand = "scoop install mpv"
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        $MpvCommand = "winget install --id shinchiro.mpv --silent --accept-package-agreements --accept-source-agreements"
    }
    if ($MpvCommand) {
        $Answer = "n"
        if ($Yes) {
            $Answer = "y"
        } else {
            $Answer = Read-Host "  $($script:InfoMark) mpv was not found. Install it now with '$MpvCommand'? [y/N]"
        }
        if ($Answer -match "^(y|yes)$") {
            try {
                $mpvJob = {
                    param($cmd)
                    $ProgressPreference = "SilentlyContinue"
                    Invoke-Expression $cmd
                }
                Invoke-SpinnerJob -Label "Installing mpv" -Action $mpvJob -Arguments @($MpvCommand) | Out-Null
                if (Get-Command mpv -ErrorAction SilentlyContinue) {
                    $PlayerDetected = "mpv"
                    Complete-Step "mpv installed"
                } else {
                    Write-Warn "mpv was not installed; install it later with: $MpvCommand"
                }
            } catch {
                Write-Warn "mpv was not installed; install it later with: $MpvCommand"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# NOW SHOWING
# ---------------------------------------------------------------------------
$Cols = Get-TerminalCols
$Inner = 46
$Pad = [Math]::Max(0, [int][Math]::Floor(($Cols - $Inner - 2) / 2))
$Lead = " " * $Pad
$Edge = [char]0x2551
$Rule = ([string][char]0x2550) * $Inner
$Divider = ([string][char]0x2500) * $Inner

$Rows = @("NOW SHOWING", "$AppName $TargetVersion", $ExePath)
if ($PlayerDetected) { $Rows += "Player: $PlayerDetected" }
$Rows += ""
$Rows += "Run: nexflex"
$Rows += "by $Creator"

Write-Host ""
if ($script:Unicode) {
    Write-Host "$Lead$($C.Mauve)$([char]0x2554)$Rule$([char]0x2557)$($C.Reset)"
    $first = $true
    foreach ($Row in $Rows) {
        if ($first) {
            $Text = $Row.PadRight($Inner - 4)
            Write-Host "$Lead$($C.Mauve)$Edge$($C.Reset)  $($C.Bold)$($C.Yellow)$Text$($C.Reset)  $($C.Mauve)$Edge$($C.Reset)"
            Write-Host "$Lead$($C.Mauve)$([char]0x255F)$Divider$([char]0x2562)$($C.Reset)"
            $first = $false
            continue
        }
        if ($Row -eq "Run: nexflex") {
            $Text = $Row.PadRight($Inner - 4)
            Write-Host "$Lead$($C.Mauve)$Edge$($C.Reset)  $($C.Green)$Text$($C.Reset)  $($C.Mauve)$Edge$($C.Reset)"
            Write-Host "$Lead$($C.Mauve)$([char]0x255F)$Divider$([char]0x2562)$($C.Reset)"
            continue
        }
        $Text = if ($Row.Length -gt $Inner - 4) { "..." + $Row.Substring($Row.Length - ($Inner - 7)) } else { $Row }
        $Text = $Text.PadRight($Inner - 4)
        Write-Host "$Lead$($C.Mauve)$Edge$($C.Reset)  $($C.Subtext)$Text$($C.Reset)  $($C.Mauve)$Edge$($C.Reset)"
    }
    Write-Host "$Lead$($C.Mauve)$([char]0x255A)$Rule$([char]0x255D)$($C.Reset)"
} else {
    Write-Host "$Lead+$("-" * $Inner)+"
    foreach ($Row in $Rows) { Write-Host ("$Lead|  " + $Row.PadRight($Inner - 2) + "|") }
    Write-Host "$Lead+$("-" * $Inner)+"
}
Write-Host ""

if ($PathModified) {
    Write-Host "  $($script:InfoMark) In existing terminal windows, restart the window or run:" -ForegroundColor Cyan
    Write-Host "      & `"$ExePath`"" -ForegroundColor White
    Write-Host ""
}

Restore-Cursor
