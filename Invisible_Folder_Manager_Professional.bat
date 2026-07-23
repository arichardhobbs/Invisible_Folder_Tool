@echo off
setlocal EnableExtensions DisableDelayedExpansion
color 0F
title Invisible Folder Manager

rem ============================================================================
rem Invisible Folder Manager - Professional Clean Edition v7.4
rem
rem - Windows 10 and Windows 11 (Windows PowerShell 5.1).
rem - Permanent default parent: C:\ProgramData\ProductIFT\
rem - Creates a folder named with Unicode U+2800 and gives it a transparent icon.
rem - Changing location automatically moves an existing invisible folder.
rem - Supports Hide, Reveal/Repair, Open, Restore, Convert, Move, and Copy Address.
rem - Self-elevates through Windows UAC.
rem - Fully offline: no downloads, URLs, web requests, or external packages.
rem - Cosmetic concealment only. The folder contents are not encrypted.
rem ============================================================================

set "IFT_SELF=%~f0"
set "IFT_NATIVE_SYSTEM32=%SystemRoot%\System32"
if defined PROCESSOR_ARCHITEW6432 set "IFT_NATIVE_SYSTEM32=%SystemRoot%\Sysnative"
set "IFT_POWERSHELL=%IFT_NATIVE_SYSTEM32%\WindowsPowerShell\v1.0\powershell.exe"
set "IFT_CHOICE=%IFT_NATIVE_SYSTEM32%\choice.exe"
set "IFT_FLTMC=%IFT_NATIVE_SYSTEM32%\fltmc.exe"

if not exist "%IFT_POWERSHELL%" (
    echo.
    echo  ERROR: Windows PowerShell could not be found.
    echo  Expected: %IFT_POWERSHELL%
    echo  Press any key to close.
    pause >nul
    endlocal
    exit /b 1
)

if not exist "%IFT_CHOICE%" (
    echo.
    echo  ERROR: The Windows choice command could not be found.
    echo  Expected: %IFT_CHOICE%
    echo  Press any key to close.
    pause >nul
    endlocal
    exit /b 1
)

if not exist "%IFT_FLTMC%" (
    echo.
    echo  ERROR: The Windows Filter Manager command could not be found.
    echo  Expected: %IFT_FLTMC%
    echo  Press any key to close.
    pause >nul
    endlocal
    exit /b 1
)

rem Preserve the identity/profile of the user who launched the tool. This matters
rem when UAC elevation is approved with credentials for a different administrator.
if /i "%~1"=="--elevated" (
    set "IFT_ORIGINAL_LOCALAPPDATA_B64=%~2"
    set "IFT_ORIGINAL_USERPROFILE_B64=%~3"
    set "IFT_ORIGINAL_SID=%~4"
)

rem Require administrator rights. fltmc returns a nonzero status when not elevated.
"%IFT_FLTMC%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  Administrator permission is required.
    echo  Approve the Windows User Account Control prompt to continue.
    echo.
    "%IFT_POWERSHELL%" -NoLogo -NoProfile -Command ^
      "$ErrorActionPreference='Stop';" ^
      "try {" ^
      "  $enc=[Text.Encoding]::Unicode;" ^
      "  $local64=[Convert]::ToBase64String($enc.GetBytes($env:LOCALAPPDATA));" ^
      "  $profile64=[Convert]::ToBase64String($enc.GetBytes($env:USERPROFILE));" ^
      "  $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value;" ^
      "  Start-Process -FilePath $env:IFT_SELF -ArgumentList @('--elevated',$local64,$profile64,$sid) -Verb RunAs;" ^
      "} catch {" ^
      "  Write-Host ('Elevation failed: ' + $_.Exception.Message);" ^
      "  exit 1" ^
      "}"
    if errorlevel 1 (
        echo.
        echo  Administrator elevation was cancelled or failed.
        echo  Press any key to close.
        pause >nul
    )
    endlocal
    exit /b
)

title Invisible Folder Manager - Administrator - Offline

set "IFT_ACTION=Initialize"
call :RUN_EMBEDDED
if errorlevel 1 (
    echo.
    echo  Initialization failed. Review the message above.
    echo  Press any key to close.
    pause >nul
    endlocal
    exit /b 1
)
goto MENU

:RUN_EMBEDDED
"%IFT_POWERSHELL%" -NoLogo -NoProfile -Command ^
  "$raw=[IO.File]::ReadAllText($env:IFT_SELF);" ^
  "$marker='# POWERSHELL_SECTION_START';" ^
  "$index=$raw.LastIndexOf($marker,[StringComparison]::Ordinal);" ^
  "if($index -lt 0){Write-Error 'The embedded PowerShell section is missing.';exit 1};" ^
  "$script=$raw.Substring($index+$marker.Length);" ^
  "& ([ScriptBlock]::Create($script)) -Action $env:IFT_ACTION"
exit /b %errorlevel%

:MENU
cls
title Invisible Folder Manager - Administrator - Offline
set "IFT_ACTION=Menu"
call :RUN_EMBEDDED
if errorlevel 1 (
    echo.
    echo  WARNING: Live status could not be displayed.
    echo.
)
"%IFT_CHOICE%" /c 123456789 /n /m "  Select an option [1-9]: "

if errorlevel 9 goto END
if errorlevel 8 goto ACTION_ADDRESS
if errorlevel 7 goto ACTION_LOCATION
if errorlevel 6 goto ACTION_CONVERT
if errorlevel 5 goto ACTION_RESTORE
if errorlevel 4 goto ACTION_OPEN
if errorlevel 3 goto ACTION_REVEAL
if errorlevel 2 goto ACTION_HIDE
if errorlevel 1 goto ACTION_CREATE
goto MENU

:ACTION_CREATE
set "IFT_ACTION=Create"
set "IFT_SCREEN=CREATE FOLDER / SELECT LOCATION"
goto RUN_ACTION

:ACTION_HIDE
set "IFT_ACTION=Hide"
set "IFT_SCREEN=HIDE FOLDER"
goto RUN_ACTION

:ACTION_REVEAL
set "IFT_ACTION=Reveal"
set "IFT_SCREEN=REVEAL / REPAIR FOLDER"
goto RUN_ACTION

:ACTION_OPEN
set "IFT_ACTION=Open"
set "IFT_SCREEN=OPEN FOLDER"
goto RUN_ACTION

:ACTION_RESTORE
set "IFT_ACTION=Restore"
set "IFT_SCREEN=RESTORE VISIBLE FOLDER"
goto RUN_ACTION

:ACTION_CONVERT
set "IFT_ACTION=Convert"
set "IFT_SCREEN=CONVERT TO INVISIBLE"
goto RUN_ACTION

:ACTION_LOCATION
set "IFT_ACTION=Location"
set "IFT_SCREEN=LOCATION MANAGER"
goto RUN_ACTION

:ACTION_ADDRESS
set "IFT_ACTION=Address"
set "IFT_SCREEN=SHOW AND COPY ADDRESS"
goto RUN_ACTION

:RUN_ACTION
cls
title Invisible Folder Manager - %IFT_SCREEN%
call :RUN_EMBEDDED
set "IFT_RESULT=%errorlevel%"
echo.
echo ------------------------------------------------------------------------------
if "%IFT_RESULT%"=="0" (
    echo  Operation finished. Review the result above.
) else (
    echo  Operation reported an error. Review the message above.
)
echo  Press any key to return to the main menu.
echo ------------------------------------------------------------------------------
pause >nul
goto MENU

:END
endlocal
exit /b 0

# POWERSHELL_SECTION_START
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'Initialize',
        'Menu',
        'Create',
        'Hide',
        'Reveal',
        'Open',
        'Restore',
        'Convert',
        'Location',
        'Address'
    )]
    [string]$Action
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ScriptVersion = '7.4'
$DefaultLocation = 'C:\ProgramData\ProductIFT'
$DefaultLocationDisplay = 'C:\ProgramData\ProductIFT\'
$BlankName = [string][char]0x2800
$IconFileName = 'blank.ico'
$DesktopIniName = 'desktop.ini'
$MarkerFileName = '.ift-managed'
$MarkerText = 'InvisibleFolderManager.ManagedFolder.v7'
$IconBase64 = 'AAABAAIAEBAAAAAAIABLAAAAJgAAACAgAAAAACAAUwAAAHEAAACJUE5HDQoaCgAAAA1JSERSAAAAEAAAABAIBgAAAB/z/2EAAAASSURBVHicY2AYBaNgFIwCCAAABBAAAVU3WtAAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAAaSURBVHic7cEBAQAAAIIg/69uSEABAAAA7wYQIAABGUM07gAAAABJRU5ErkJggg=='
$IconBytes = [Convert]::FromBase64String($IconBase64)

$AttribExe = Join-Path $env:SystemRoot 'System32\attrib.exe'
$IcaclsExe = Join-Path $env:SystemRoot 'System32\icacls.exe'
$RobocopyExe = Join-Path $env:SystemRoot 'System32\robocopy.exe'
$ExplorerExe = Join-Path $env:SystemRoot 'explorer.exe'

function Get-PreservedString {
    param(
        [AllowEmptyString()][string]$Encoded,
        [Parameter(Mandatory = $true)][string]$Fallback
    )

    if ([string]::IsNullOrWhiteSpace($Encoded)) {
        return $Fallback
    }

    try {
        $value = [Text.Encoding]::Unicode.GetString(
            [Convert]::FromBase64String($Encoded)
        )

        if ([string]::IsNullOrWhiteSpace($value)) {
            return $Fallback
        }

        return $value
    }
    catch {
        return $Fallback
    }
}

$BaseLocalAppData = Get-PreservedString `
    -Encoded $env:IFT_ORIGINAL_LOCALAPPDATA_B64 `
    -Fallback $env:LOCALAPPDATA

$OriginalUserProfile = Get-PreservedString `
    -Encoded $env:IFT_ORIGINAL_USERPROFILE_B64 `
    -Fallback $env:USERPROFILE

$OriginalUserSid = $env:IFT_ORIGINAL_SID
if ([string]::IsNullOrWhiteSpace($OriginalUserSid) -or
    $OriginalUserSid -notmatch '^S-\d-(?:\d+-)+\d+$') {
    $OriginalUserSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}

# Make common environment-variable expansion refer to the launching user.
$env:LOCALAPPDATA = $BaseLocalAppData
$env:USERPROFILE = $OriginalUserProfile

function Invoke-AttribCommand {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$IgnoreFailure
    )

    & $AttribExe @Arguments | Out-Null
    $exitCode = $LASTEXITCODE

    if (($exitCode -ne 0) -and (-not $IgnoreFailure)) {
        throw "attrib.exe failed with exit code $exitCode."
    }

    return $exitCode
}

function Clear-PathAttributes {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    # Microsoft documents that Hidden/System should be cleared before changing
    # other attributes, so this is deliberately done in two steps.
    $null = Invoke-AttribCommand -Arguments @('-h', '-s', $Path)
    $code = Invoke-AttribCommand -Arguments @('-r', '-i', $Path) -IgnoreFailure

    if ($code -ne 0) {
        $null = Invoke-AttribCommand -Arguments @('-r', $Path)
    }
}

function Protect-PrivatePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $privateItem = Get-Item -LiteralPath $Path -Force
    if ($privateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "A protected private path is a reparse point and was rejected: $Path"
    }

    # Clear Hidden/System first because Windows requires those attributes to be
    # cleared before reliably changing other attributes.
    $null = Invoke-AttribCommand `
        -Arguments @('-h', '-s', $Path) `
        -IgnoreFailure

    # Not Content Indexed can be unsupported on some removable filesystems.
    $null = Invoke-AttribCommand -Arguments @('+i', $Path) -IgnoreFailure
    $null = Invoke-AttribCommand -Arguments @('+h', '+s', $Path)
}

function Set-FolderAppearanceAttributes {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$Hidden,
        [Parameter(Mandatory = $true)][bool]$System
    )

    Clear-PathAttributes -Path $Path
    $null = Invoke-AttribCommand -Arguments @('+r', $Path)

    $visibilityArguments = @()
    if ($Hidden) {
        $visibilityArguments += '+h'
    }
    if ($System) {
        $visibilityArguments += '+s'
    }

    if ($visibilityArguments.Count -gt 0) {
        $visibilityArguments += $Path
        $null = Invoke-AttribCommand -Arguments $visibilityArguments
    }
}

function Grant-OriginalUserModify {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $IcaclsExe -PathType Leaf)) {
        return
    }

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            $grant = '*' + $OriginalUserSid + ':(OI)(CI)M'
        }
        else {
            $grant = '*' + $OriginalUserSid + ':M'
        }

        & $IcaclsExe $Path '/grant' $grant '/c' '/q' | Out-Null
        # ACLs are not supported by every removable filesystem. Failure here is
        # non-fatal because the folder operation itself may still be valid.
    }
    catch {
        # Non-fatal.
    }
}

function Get-OpaqueStateDirectoryName {
    $seedText = $OriginalUserProfile.ToLowerInvariant() + '|ift-state-v4|local-only'
    $sha256 = [Security.Cryptography.SHA256]::Create()

    try {
        $seedBytes = [Text.Encoding]::UTF8.GetBytes($seedText)
        $hashBytes = $sha256.ComputeHash($seedBytes)
        $hashText = -join (
            $hashBytes | ForEach-Object { $_.ToString('x2') }
        )
        return '.' + $hashText.Substring(0, 32)
    }
    finally {
        $sha256.Dispose()
    }
}

$ConfigRoot = Join-Path $BaseLocalAppData (Get-OpaqueStateDirectoryName)
$LocationFile = Join-Path $ConfigRoot '.s1.dat'
$RestoredFile = Join-Path $ConfigRoot '.s2.dat'

# Migrate the descriptive state directory used by early versions.
$LegacyConfigRoot = Join-Path $BaseLocalAppData (
    [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String('SW52aXNpYmxlRm9sZGVyVG9vbA==')
    )
)
$LegacyLocationFile = Join-Path $LegacyConfigRoot (
    [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String('bG9jYXRpb24udHh0')
    )
)
$LegacyRestoredFile = Join-Path $LegacyConfigRoot (
    [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String('bGFzdC1yZXN0b3JlZC50eHQ=')
    )
)

function Protect-StateStore {
    if (Test-Path -LiteralPath $LocationFile -PathType Leaf) {
        Protect-PrivatePath -Path $LocationFile
    }

    if (Test-Path -LiteralPath $RestoredFile -PathType Leaf) {
        Protect-PrivatePath -Path $RestoredFile
    }

    if (Test-Path -LiteralPath $ConfigRoot -PathType Container) {
        Protect-PrivatePath -Path $ConfigRoot
    }
}

function Migrate-LegacyStateStore {
    if (-not (Test-Path -LiteralPath $LegacyConfigRoot -PathType Container)) {
        return
    }

    $legacyRootItem = Get-Item -LiteralPath $LegacyConfigRoot -Force
    if ($legacyRootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'The legacy state directory is a reparse point and was rejected.'
    }

    $pairs = @(
        @{ Old = $LegacyLocationFile; New = $LocationFile },
        @{ Old = $LegacyRestoredFile; New = $RestoredFile }
    )

    foreach ($pair in $pairs) {
        if (Test-Path -LiteralPath $pair.Old -PathType Leaf) {
            $legacyFileItem = Get-Item -LiteralPath $pair.Old -Force
            if ($legacyFileItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "A legacy state file is a reparse point: $($pair.Old)"
            }

            if (-not (Test-Path -LiteralPath $pair.New -PathType Leaf)) {
                $value = [IO.File]::ReadAllText($pair.Old)
                [IO.File]::WriteAllText(
                    $pair.New,
                    $value,
                    (New-Object Text.UTF8Encoding -ArgumentList $false)
                )
            }

            if (Test-Path -LiteralPath $pair.New -PathType Leaf) {
                Clear-PathAttributes -Path $pair.Old
                Remove-Item -LiteralPath $pair.Old -Force
            }
        }
    }

    $remaining = @(
        Get-ChildItem -LiteralPath $LegacyConfigRoot -Force -ErrorAction SilentlyContinue
    )

    if ($remaining.Count -eq 0) {
        Clear-PathAttributes -Path $LegacyConfigRoot
        Remove-Item -LiteralPath $LegacyConfigRoot -Force
    }
    else {
        Protect-PrivatePath -Path $LegacyConfigRoot
    }
}

function Ensure-ConfigRoot {
    if (-not (Test-Path -LiteralPath $ConfigRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $ConfigRoot -Force | Out-Null
        Grant-OriginalUserModify -Path $ConfigRoot
    }

    $configItem = Get-Item -LiteralPath $ConfigRoot -Force
    if ($configItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'The private state directory is a reparse point and was rejected.'
    }

    Migrate-LegacyStateStore
    Protect-StateStore
}

function Read-StateText {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "A private state file is a reparse point and was rejected: $Path"
    }

    return [IO.File]::ReadAllText($Path).Trim()
}

function Write-StateText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )

    Ensure-ConfigRoot

    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "The state path is not a file: $Path"
        }

        $stateItem = Get-Item -LiteralPath $Path -Force
        if ($stateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "A private state file is a reparse point and was rejected: $Path"
        }

        Clear-PathAttributes -Path $Path
    }

    $encoding = New-Object Text.UTF8Encoding -ArgumentList $false
    [IO.File]::WriteAllText($Path, $Value, $encoding)

    Grant-OriginalUserModify -Path $Path
    Protect-PrivatePath -Path $Path
    Protect-PrivatePath -Path $ConfigRoot
}

function Remove-StateFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $stateItem = Get-Item -LiteralPath $Path -Force
        if ($stateItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "A private state file is a reparse point and was rejected: $Path"
        }

        Clear-PathAttributes -Path $Path
        Remove-Item -LiteralPath $Path -Force
    }

    Protect-StateStore
}

function Save-Location {
    param([Parameter(Mandatory = $true)][string]$Path)
    Write-StateText -Path $LocationFile -Value $Path
}

function Save-RestoredPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    Write-StateText -Path $RestoredFile -Value $Path
}

function Get-SavedLocation {
    Ensure-ConfigRoot

    $saved = Read-StateText -Path $LocationFile
    if ([string]::IsNullOrWhiteSpace($saved)) {
        return $DefaultLocation
    }

    return $saved
}

function Assert-NoReparsePathChain {
    param([Parameter(Mandatory = $true)][string]$Path)

    $currentItem = Get-Item -LiteralPath $Path -Force -ErrorAction Stop

    while ($null -ne $currentItem) {
        if ($currentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw (
                'The selected path passes through a symbolic link, junction, ' +
                "or another reparse point: $($currentItem.FullName)"
            )
        }

        $currentItem = $currentItem.Parent
    }
}

function Get-NearestExistingParent {
    param([Parameter(Mandatory = $true)][string]$Path)

    $candidate = $Path

    while (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
        $parent = Split-Path -Path $candidate -Parent

        if ([string]::IsNullOrWhiteSpace($parent) -or
            (Test-SamePath -First $candidate -Second $parent)) {
            throw "No existing parent could be resolved for: $Path"
        }

        $candidate = $parent
    }

    return (Get-Item -LiteralPath $candidate -Force).FullName
}

function Normalize-ParentPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$CreateIfMissing
    )

    $value = [Environment]::ExpandEnvironmentVariables(
        $Path.Trim().Trim('"')
    )

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw 'No parent location was supplied.'
    }

    if ($value -eq '~') {
        $value = $env:USERPROFILE
    }
    elseif ($value.StartsWith('~\') -or $value.StartsWith('~/')) {
        $value = Join-Path $env:USERPROFILE $value.Substring(2)
    }

    $isDriveAbsolute = $value -match '^[A-Za-z]:[\\/]'
    $isUncAbsolute = $value -match '^\\\\[^\\/]+[\\/][^\\/]+'

    if ((-not $isDriveAbsolute) -and (-not $isUncAbsolute)) {
        throw (
            'Enter a complete folder path, such as C:\Folder or ' +
            '\\Server\Share\Folder.'
        )
    }

    $fullPath = [IO.Path]::GetFullPath($value)

    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        throw "The selected path is a file, not a folder: $fullPath"
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
        if (-not $CreateIfMissing) {
            throw "The selected parent location does not exist: $fullPath"
        }

        $existingParent = Get-NearestExistingParent -Path $fullPath
        Assert-NoReparsePathChain -Path $existingParent

        [IO.Directory]::CreateDirectory($fullPath) | Out-Null
        Grant-OriginalUserModify -Path $fullPath
        Write-Host "Created parent location: $fullPath" -ForegroundColor Green
    }

    Assert-NoReparsePathChain -Path $fullPath
    return (Get-Item -LiteralPath $fullPath -Force).FullName
}

function Resolve-CurrentLocation {
    $saved = Get-SavedLocation
    return Normalize-ParentPath -Path $saved
}

function Get-ComparablePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($fullPath)

    while (($fullPath.Length -gt $root.Length) -and
           ($fullPath.EndsWith('\') -or $fullPath.EndsWith('/'))) {
        $fullPath = $fullPath.Substring(0, $fullPath.Length - 1)
    }

    return $fullPath
}

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    $firstPath = Get-ComparablePath -Path $First
    $secondPath = Get-ComparablePath -Path $Second

    return [string]::Equals(
        $firstPath,
        $secondPath,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Test-PathInsideFolder {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Folder
    )

    $candidatePath = Get-ComparablePath -Path $Candidate
    $folderPath = Get-ComparablePath -Path $Folder
    $prefix = $folderPath

    if ((-not $prefix.EndsWith('\')) -and
        (-not $prefix.EndsWith('/'))) {
        $prefix += [IO.Path]::DirectorySeparatorChar
    }

    return $candidatePath.StartsWith(
        $prefix,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Read-NumericChoice {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][int[]]$Allowed
    )

    $allowedText = ($Allowed | ForEach-Object { $_.ToString() }) -join ', '

    while ($true) {
        $raw = Read-Host $Prompt
        $number = 0

        if ([int]::TryParse($raw, [ref]$number) -and
            ($Allowed -contains $number)) {
            return $number
        }

        Write-Host "Enter one of these numbers only: $allowedText" `
            -ForegroundColor Yellow
    }
}

function Browse-ForFolder {
    param(
        [Parameter(Mandatory = $true)][string]$InitialPath,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $dialog = $null

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Description
        $dialog.SelectedPath = $InitialPath
        $dialog.ShowNewFolderButton = $true

        $result = $dialog.ShowDialog()

        if (($result -eq [System.Windows.Forms.DialogResult]::OK) -and
            (-not [string]::IsNullOrWhiteSpace($dialog.SelectedPath))) {
            return Normalize-ParentPath -Path $dialog.SelectedPath
        }

        Write-Host 'Folder selection was cancelled.' -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Host 'The folder browser could not be opened.' `
            -ForegroundColor Yellow
        Write-Host 'Choose the path-entry option instead.' `
            -ForegroundColor Yellow
        return $null
    }
    finally {
        if ($null -ne $dialog) {
            $dialog.Dispose()
        }
    }
}

function Choose-ParentLocation {
    param(
        [Parameter(Mandatory = $true)][string]$InitialPath,
        [Parameter(Mandatory = $true)][string]$Purpose
    )

    while ($true) {
        Write-Host ''
        Write-Host $Purpose -ForegroundColor Cyan
        Write-Host ('-' * $Purpose.Length) -ForegroundColor DarkCyan
        Write-Host "Current location: $InitialPath"
        Write-Host ''
        Write-Host '  [1] Browse and choose a folder'
        Write-Host '  [2] Enter a folder path'
        Write-Host '  [3] Cancel'
        Write-Host ''

        $method = Read-NumericChoice -Prompt 'Select [1-3]' -Allowed @(1, 2, 3)

        switch ($method) {
            1 {
                $selected = Browse-ForFolder `
                    -InitialPath $InitialPath `
                    -Description $Purpose

                if ($null -ne $selected) {
                    return $selected
                }
            }

            2 {
                Write-Host ''
                Write-Host 'Environment variables such as %USERPROFILE% are supported.'
                $entered = Read-Host 'Enter the parent folder path'

                if ([string]::IsNullOrWhiteSpace($entered)) {
                    Write-Host 'No path was entered.' -ForegroundColor Yellow
                    continue
                }

                try {
                    return Normalize-ParentPath `
                        -Path $entered `
                        -CreateIfMissing
                }
                catch {
                    Write-Host (
                        'The location could not be used: ' +
                        $_.Exception.Message
                    ) -ForegroundColor Yellow
                }
            }

            3 {
                return $null
            }
        }
    }
}

function Get-InvisiblePath {
    param([Parameter(Mandatory = $true)][string]$Parent)
    return Join-Path $Parent $BlankName
}

function Get-SupportPaths {
    param([Parameter(Mandatory = $true)][string]$Folder)

    return [pscustomobject]@{
        Icon = Join-Path $Folder $IconFileName
        DesktopIni = Join-Path $Folder $DesktopIniName
        Marker = Join-Path $Folder $MarkerFileName
    }
}

function Write-BytesWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    $lastError = $null

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            [IO.File]::WriteAllBytes($Path, $Bytes)
            return
        }
        catch {
            $lastError = $_
            if ($attempt -lt 4) {
                Start-Sleep -Milliseconds (200 * $attempt)
            }
        }
    }

    throw $lastError
}

function Write-LinesWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][Text.Encoding]$Encoding
    )

    $lastError = $null

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            [IO.File]::WriteAllLines($Path, $Lines, $Encoding)
            return
        }
        catch {
            $lastError = $_
            if ($attempt -lt 4) {
                Start-Sleep -Milliseconds (200 * $attempt)
            }
        }
    }

    throw $lastError
}

function Write-TextWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][Text.Encoding]$Encoding
    )

    $lastError = $null

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            [IO.File]::WriteAllText($Path, $Text, $Encoding)
            return
        }
        catch {
            $lastError = $_
            if ($attempt -lt 4) {
                Start-Sleep -Milliseconds (200 * $attempt)
            }
        }
    }

    throw $lastError
}

function Remove-FileWithRetry {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "A folder exists where a support file is expected: $Path"
    }

    $supportItem = Get-Item -LiteralPath $Path -Force
    if ($supportItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "A support file is a reparse point and was rejected: $Path"
    }

    $lastError = $null

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            Clear-PathAttributes -Path $Path
            Remove-Item -LiteralPath $Path -Force
            return
        }
        catch {
            $lastError = $_
            if ($attempt -lt 4) {
                Start-Sleep -Milliseconds (200 * $attempt)
            }
        }
    }

    throw $lastError
}

function Initialize-ShellNotifier {
    if ('IFT.NativeShell' -as [type]) {
        return
    }

    $memberDefinition = @'
[System.Runtime.InteropServices.DllImport(
    "shell32.dll",
    CharSet = System.Runtime.InteropServices.CharSet.Unicode
)]
public static extern void SHChangeNotify(
    int wEventId,
    uint uFlags,
    string dwItem1,
    string dwItem2
);
'@

    Add-Type `
        -Namespace IFT `
        -Name NativeShell `
        -MemberDefinition $memberDefinition `
        -ErrorAction Stop
}

function Refresh-Explorer {
    param([string[]]$Paths = @())

    $nativeWorked = $false

    try {
        Initialize-ShellNotifier

        foreach ($path in $Paths) {
            if ([string]::IsNullOrWhiteSpace($path)) {
                continue
            }

            # SHCNE_ATTRIBUTES = 0x00000800
            # SHCNE_UPDATEDIR = 0x00001000
            # SHCNF_PATHW = 0x0005
            [IFT.NativeShell]::SHChangeNotify(
                0x00000800,
                0x0005,
                $path,
                $null
            )
            [IFT.NativeShell]::SHChangeNotify(
                0x00001000,
                0x0005,
                $path,
                $null
            )
        }

        # SHCNE_ASSOCCHANGED with SHCNF_IDLIST prompts an icon-cache refresh.
        [IFT.NativeShell]::SHChangeNotify(
            0x08000000,
            0x0000,
            $null,
            $null
        )

        $nativeWorked = $true
    }
    catch {
        $nativeWorked = $false
    }

    if (-not $nativeWorked) {
        try {
            $refreshExe = Join-Path $env:SystemRoot 'System32\ie4uinit.exe'
            if (Test-Path -LiteralPath $refreshExe -PathType Leaf) {
                Start-Process `
                    -FilePath $refreshExe `
                    -ArgumentList '-show' `
                    -WindowStyle Hidden `
                    -ErrorAction SilentlyContinue |
                    Out-Null
            }
        }
        catch {
            # File Explorer can always be refreshed manually with F5.
        }
    }
}

function Test-ManagementMarker {
    param([Parameter(Mandatory = $true)][string]$Folder)

    $markerPath = Join-Path $Folder $MarkerFileName
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
        return $false
    }

    try {
        $markerItem = Get-Item -LiteralPath $markerPath -Force
        if ($markerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            return $false
        }

        return ([IO.File]::ReadAllText($markerPath).Trim() -eq $MarkerText)
    }
    catch {
        return $false
    }
}

function Write-ManagementMarker {
    param([Parameter(Mandatory = $true)][string]$Folder)

    $markerPath = Join-Path $Folder $MarkerFileName

    if (Test-Path -LiteralPath $markerPath) {
        if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
            throw "A folder exists where the management marker is expected: $markerPath"
        }

        $markerItem = Get-Item -LiteralPath $markerPath -Force
        if ($markerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "The management marker is a reparse point and was rejected: $markerPath"
        }

        Clear-PathAttributes -Path $markerPath
    }

    Write-TextWithRetry `
        -Path $markerPath `
        -Text $MarkerText `
        -Encoding ([Text.Encoding]::ASCII)

    Protect-PrivatePath -Path $markerPath
}

function Set-InvisibleAppearance {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [bool]$FinalHidden = $false,
        [bool]$FinalSystem = $false
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        throw "The target folder does not exist: $Target"
    }

    if (Test-ConversionSupportConflict -Folder $Target) {
        throw (
            'The folder contains a conflicting blank.ico, desktop.ini, or ' +
            '.ift-managed item. Nothing was overwritten.'
        )
    }

    $support = Get-SupportPaths -Folder $Target

    foreach ($supportPath in @(
        $support.Icon,
        $support.DesktopIni,
        $support.Marker
    )) {
        if (Test-Path -LiteralPath $supportPath) {
            if (-not (Test-Path -LiteralPath $supportPath -PathType Leaf)) {
                throw "A folder conflicts with a required support file: $supportPath"
            }

            $supportItem = Get-Item -LiteralPath $supportPath -Force
            if ($supportItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "A required support file is a reparse point: $supportPath"
            }
        }
    }

    $failure = $null

    try {
        Clear-PathAttributes -Path $Target

        foreach ($supportPath in @(
            $support.Icon,
            $support.DesktopIni,
            $support.Marker
        )) {
            if (Test-Path -LiteralPath $supportPath -PathType Leaf) {
                Clear-PathAttributes -Path $supportPath
            }
        }

        # Write the ownership marker first. If icon or desktop.ini creation is
        # interrupted, a later Reveal / Repair operation can safely replace the
        # partial support file instead of treating it as unrelated user content.
        Write-TextWithRetry `
            -Path $support.Marker `
            -Text $MarkerText `
            -Encoding ([Text.Encoding]::ASCII)
        Protect-PrivatePath -Path $support.Marker

        Write-BytesWithRetry -Path $support.Icon -Bytes $IconBytes

        $desktopIniLines = @(
            '[.ShellClassInfo]',
            'ConfirmFileOp=0',
            "IconResource=$IconFileName,0",
            "IconFile=$IconFileName",
            'IconIndex=0'
        )

        Write-LinesWithRetry `
            -Path $support.DesktopIni `
            -Lines $desktopIniLines `
            -Encoding ([Text.Encoding]::Unicode)

        Protect-PrivatePath -Path $support.Icon
        Protect-PrivatePath -Path $support.DesktopIni
        Protect-PrivatePath -Path $support.Marker

        Set-FolderAppearanceAttributes `
            -Path $Target `
            -Hidden $FinalHidden `
            -System $FinalSystem

        Grant-OriginalUserModify -Path $Target
        (Get-Item -LiteralPath $Target -Force).LastWriteTime = Get-Date

        Refresh-Explorer -Paths @($Target, (Split-Path -Parent $Target))
    }
    catch {
        $failure = $_
    }

    if ($null -ne $failure) {
        # Restore the intended final visibility as far as possible before
        # reporting the original failure.
        try {
            foreach ($supportPath in @(
                $support.Icon,
                $support.DesktopIni,
                $support.Marker
            )) {
                if (Test-Path -LiteralPath $supportPath -PathType Leaf) {
                    Protect-PrivatePath -Path $supportPath
                }
            }

            Set-FolderAppearanceAttributes `
                -Path $Target `
                -Hidden $FinalHidden `
                -System $FinalSystem
        }
        catch {
            # Preserve the original error.
        }

        throw $failure
    }
}

function Remove-InvisibleSupportFiles {
    param([Parameter(Mandatory = $true)][string]$Target)

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        throw "The target folder does not exist: $Target"
    }

    $support = Get-SupportPaths -Folder $Target
    Clear-PathAttributes -Path $Target

    Remove-FileWithRetry -Path $support.DesktopIni
    Remove-FileWithRetry -Path $support.Icon

    # Keep the hidden marker so the restored folder can be identified safely.
    if (Test-Path -LiteralPath $support.Marker -PathType Leaf) {
        Protect-PrivatePath -Path $support.Marker
    }
    else {
        Write-ManagementMarker -Folder $Target
    }

    Clear-PathAttributes -Path $Target
    Grant-OriginalUserModify -Path $Target
}

function Assert-InvisibleFolderExists {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $target = Get-InvisiblePath -Parent $Parent

    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw (
            "No blank-name folder was found in: $Parent`n" +
            'Choose option 1 to create it or option 7 to change location.'
        )
    }

    $targetItem = Get-Item -LiteralPath $target -Force
    if ($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw (
            'The blank-name item is a symbolic link, junction, or another ' +
            'reparse point. It was not modified for safety.'
        )
    }

    return $targetItem.FullName
}

function Get-MarkerFolders {
    param([Parameter(Mandatory = $true)][string]$Parent)

    if (-not (Test-Path -LiteralPath $Parent -PathType Container)) {
        return @()
    }

    $matches = @()

    foreach ($directory in @(
        Get-ChildItem `
            -LiteralPath $Parent `
            -Directory `
            -Force `
            -ErrorAction SilentlyContinue
    )) {
        if ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            continue
        }

        if (Test-ManagementMarker -Folder $directory.FullName) {
            $matches += $directory
        }
    }

    return $matches
}

function Get-RecordedRestoredPath {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $recorded = Read-StateText -Path $RestoredFile
    if ([string]::IsNullOrWhiteSpace($recorded)) {
        return $null
    }

    if (-not (Test-Path -LiteralPath $recorded -PathType Container)) {
        return $null
    }

    $item = Get-Item -LiteralPath $recorded -Force

    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        return $null
    }

    if (Test-SamePath -First $item.Parent.FullName -Second $Parent) {
        return $item.FullName
    }

    return $null
}

function Get-VisibleManagedPaths {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $paths = @()
    $recorded = Get-RecordedRestoredPath -Parent $Parent

    if ($null -ne $recorded) {
        $paths += $recorded
    }

    foreach ($folder in @(
        Get-MarkerFolders -Parent $Parent |
            Where-Object { $_.Name -ne $BlankName }
    )) {
        if ($paths -notcontains $folder.FullName) {
            $paths += $folder.FullName
        }
    }

    return $paths
}


function Get-ManagedFolderPath {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $invisible = Get-InvisiblePath -Parent $Parent
    $visiblePaths = @(Get-VisibleManagedPaths -Parent $Parent)

    if (Test-Path -LiteralPath $invisible -PathType Container) {
        $invisibleItem = Get-Item -LiteralPath $invisible -Force

        if ($invisibleItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw (
                'The blank-name item is a symbolic link, junction, or another ' +
                'reparse point. It was not opened or moved for safety.'
            )
        }

        if ($visiblePaths.Count -gt 0) {
            throw (
                "More than one managed folder was found in: $Parent`n" +
                'An invisible folder and at least one restored folder both exist. ' +
                'Resolve the duplicate before continuing.'
            )
        }

        return $invisibleItem.FullName
    }

    if ($visiblePaths.Count -eq 1) {
        return $visiblePaths[0]
    }

    if ($visiblePaths.Count -gt 1) {
        throw (
            "More than one managed visible folder was found in: $Parent`n" +
            'Use option 6 to select the intended folder.'
        )
    }

    throw (
        "No managed folder was found in: $Parent`n" +
        'Choose option 1 to create one, option 6 to convert a visible folder, ' +
        'or option 7 to change location.'
    )
}

function Get-DefaultVisibleFolder {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $recorded = Get-RecordedRestoredPath -Parent $Parent
    if ($null -ne $recorded) {
        return $recorded
    }

    $markerFolders = @(
        Get-MarkerFolders -Parent $Parent |
            Where-Object { $_.Name -ne $BlankName } |
            Sort-Object Name
    )

    if ($markerFolders.Count -eq 1) {
        return $markerFolders[0].FullName
    }

    $exact = Join-Path $Parent 'Visible Folder'
    if (Test-Path -LiteralPath $exact -PathType Container) {
        return (Get-Item -LiteralPath $exact -Force).FullName
    }

    $nameMatches = @(
        Get-ChildItem `
            -LiteralPath $Parent `
            -Directory `
            -Force `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^Visible Folder(?: [0-9]+)?$' } |
            Sort-Object Name
    )

    if ($nameMatches.Count -eq 1) {
        return $nameMatches[0].FullName
    }

    return $exact
}

function Copy-TextToClipboard {
    param([Parameter(Mandatory = $true)][string]$Text)

    try {
        Set-Clipboard -Value $Text -ErrorAction Stop
        return $true
    }
    catch {
        try {
            $clipExe = Join-Path $env:SystemRoot 'System32\clip.exe'

            if (Test-Path -LiteralPath $clipExe -PathType Leaf) {
                $Text | & $clipExe

                if ($LASTEXITCODE -eq 0) {
                    return $true
                }
            }
        }
        catch {
            # The address is still displayed if clipboard access fails.
        }
    }

    return $false
}

function Get-OriginalVisibility {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force

    return [pscustomobject]@{
        Attributes = $item.Attributes
        Hidden = [bool](
            $item.Attributes -band [IO.FileAttributes]::Hidden
        )
        System = [bool](
            $item.Attributes -band [IO.FileAttributes]::System
        )
    }
}

function Restore-ExactAttributes {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][IO.FileAttributes]$Attributes
    )

    if (Test-Path -LiteralPath $Path) {
        [IO.File]::SetAttributes($Path, $Attributes)
    }
}

function Test-SameVolumeRoot {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    $firstRoot = [IO.Path]::GetPathRoot(
        [IO.Path]::GetFullPath($First)
    )
    $secondRoot = [IO.Path]::GetPathRoot(
        [IO.Path]::GetFullPath($Second)
    )

    return [string]::Equals(
        $firstRoot,
        $secondRoot,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Test-FolderContainsReparsePoint {
    param([Parameter(Mandatory = $true)][string]$Folder)

    $rootAttributes = [IO.File]::GetAttributes($Folder)
    if ($rootAttributes -band [IO.FileAttributes]::ReparsePoint) {
        return $true
    }

    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($Folder)

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()

        foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($current)) {
            $attributes = [IO.File]::GetAttributes($entry)

            if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
                return $true
            }

            if ($attributes -band [IO.FileAttributes]::Directory) {
                $pending.Push($entry)
            }
        }
    }

    return $false
}

function Test-FolderContainsEncryptedItem {
    param([Parameter(Mandatory = $true)][string]$Folder)

    $rootAttributes = [IO.File]::GetAttributes($Folder)
    if ($rootAttributes -band [IO.FileAttributes]::Encrypted) {
        return $true
    }

    foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries(
        $Folder,
        '*',
        [IO.SearchOption]::AllDirectories
    )) {
        $attributes = [IO.File]::GetAttributes($entry)

        if ($attributes -band [IO.FileAttributes]::Encrypted) {
            return $true
        }
    }

    return $false
}


function Invoke-RobocopyQuiet {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $arguments = @(
        $Source,
        $Destination,
        '/E',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/FFT',
        '/R:2',
        '/W:1',
        '/XJ',
        '/NFL',
        '/NDL',
        '/NJH',
        '/NJS',
        '/NP'
    )

    & $RobocopyExe @arguments | Out-Null
    return $LASTEXITCODE
}

function Confirm-DirectoryCopy {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Write-Host ''
    Write-Host (
        'Verifying every copied file before removing the source...'
    ) -ForegroundColor Cyan

    $sourceRoot = Get-ComparablePath -Path $Source
    $destinationRoot = Get-ComparablePath -Path $Destination
    $sourcePrefix = $sourceRoot + [IO.Path]::DirectorySeparatorChar
    $destinationPrefix = (
        $destinationRoot + [IO.Path]::DirectorySeparatorChar
    )

    $sourceDirectories = @(
        Get-ChildItem `
            -LiteralPath $Source `
            -Directory `
            -Recurse `
            -Force `
            -ErrorAction Stop
    )
    $destinationDirectories = @(
        Get-ChildItem `
            -LiteralPath $Destination `
            -Directory `
            -Recurse `
            -Force `
            -ErrorAction Stop
    )

    if ($sourceDirectories.Count -ne $destinationDirectories.Count) {
        throw (
            'Directory verification failed: source and destination ' +
            'directory counts are different.'
        )
    }

    foreach ($sourceDirectory in $sourceDirectories) {
        $relative = $sourceDirectory.FullName.Substring($sourcePrefix.Length)
        $destinationDirectory = Join-Path $Destination $relative

        if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
            throw "A copied directory is missing: $relative"
        }
    }

    $sourceFiles = @(
        Get-ChildItem `
            -LiteralPath $Source `
            -File `
            -Recurse `
            -Force `
            -ErrorAction Stop
    )
    $destinationFiles = @(
        Get-ChildItem `
            -LiteralPath $Destination `
            -File `
            -Recurse `
            -Force `
            -ErrorAction Stop
    )

    if ($sourceFiles.Count -ne $destinationFiles.Count) {
        throw (
            'File verification failed: source and destination ' +
            'file counts are different.'
        )
    }

    $fileNumber = 0

    try {
        foreach ($sourceFile in $sourceFiles) {
            $fileNumber++
            $relative = $sourceFile.FullName.Substring($sourcePrefix.Length)
            $destinationFile = Join-Path $Destination $relative

            if (-not (Test-Path -LiteralPath $destinationFile -PathType Leaf)) {
                throw "A copied file is missing: $relative"
            }

            $destinationItem = Get-Item -LiteralPath $destinationFile -Force

            if ($sourceFile.Length -ne $destinationItem.Length) {
                throw "A copied file has a different size: $relative"
            }

            if ($sourceFiles.Count -gt 0) {
                $percent = [int](($fileNumber * 100) / $sourceFiles.Count)
                Write-Progress `
                    -Activity 'Verifying copied folder' `
                    -Status "$fileNumber of $($sourceFiles.Count) files" `
                    -PercentComplete $percent
            }

            $sourceHash = (
                Get-FileHash `
                    -LiteralPath $sourceFile.FullName `
                    -Algorithm SHA256 `
                    -ErrorAction Stop
            ).Hash
            $destinationHash = (
                Get-FileHash `
                    -LiteralPath $destinationFile `
                    -Algorithm SHA256 `
                    -ErrorAction Stop
            ).Hash

            if ($sourceHash -ne $destinationHash) {
                throw "A copied file failed SHA-256 verification: $relative"
            }
        }
    }
    finally {
        Write-Progress `
            -Activity 'Verifying copied folder' `
            -Completed
    }

    # Reject any destination object that was not represented above.
    foreach ($destinationDirectory in $destinationDirectories) {
        $relative = $destinationDirectory.FullName.Substring(
            $destinationPrefix.Length
        )
        $sourceDirectory = Join-Path $Source $relative

        if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
            throw "An unexpected destination directory was found: $relative"
        }
    }

    foreach ($destinationFile in $destinationFiles) {
        $relative = $destinationFile.FullName.Substring(
            $destinationPrefix.Length
        )
        $sourceFile = Join-Path $Source $relative

        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            throw "An unexpected destination file was found: $relative"
        }
    }
}

function Remove-DirectoryWithRetry {
    param([Parameter(Mandatory = $true)][string]$Path)

    $lastError = $null

    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            if (-not (Test-Path -LiteralPath $Path)) {
                return
            }

            Clear-PathAttributes -Path $Path
            Remove-Item `
                -LiteralPath $Path `
                -Recurse `
                -Force `
                -ErrorAction Stop

            if (-not (Test-Path -LiteralPath $Path)) {
                return
            }

            throw "Windows still reports that the source folder exists: $Path"
        }
        catch {
            $lastError = $_

            if ($attempt -lt 4) {
                Start-Sleep -Milliseconds (300 * $attempt)
            }
        }
    }

    throw $lastError
}

function Move-DirectoryPhysical {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationParent,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $nativeMoveError = $null

    if (Test-SameVolumeRoot -First $Source -Second $DestinationParent) {
        try {
            Move-Item `
                -LiteralPath $Source `
                -Destination $DestinationParent `
                -ErrorAction Stop

            return [pscustomobject]@{
                SourceRemoved = $true
                CleanupWarning = $null
                OperationWarning = $null
                UsedVerifiedCopy = $false
            }
        }
        catch {
            $nativeMoveError = $_
            $sourceStillExists = Test-Path `
                -LiteralPath $Source `
                -PathType Container
            $destinationNowExists = Test-Path `
                -LiteralPath $DestinationPath `
                -PathType Container

            # A provider can occasionally report a late error after the rename
            # has completed. Do not leave the saved location pointing at a path
            # that no longer exists in that situation.
            if ((-not $sourceStillExists) -and $destinationNowExists) {
                return [pscustomobject]@{
                    SourceRemoved = $true
                    CleanupWarning = $null
                    OperationWarning = $nativeMoveError.Exception.Message
                    UsedVerifiedCopy = $false
                }
            }

            # Fall back only when the source is intact and no destination item
            # exists. This also handles drive-letter mount-point boundaries.
            if ((-not $sourceStillExists) -or $destinationNowExists) {
                throw $nativeMoveError
            }
        }
    }

    if (-not (Test-Path -LiteralPath $RobocopyExe -PathType Leaf)) {
        throw (
            'Robocopy is required for this move, but robocopy.exe was not found.'
        )
    }

    if (Test-FolderContainsReparsePoint -Folder $Source) {
        throw (
            'The copy-based move was stopped because the managed folder ' +
            'contains a symbolic link, junction, or another reparse point. ' +
            'Review and move those links manually.'
        )
    }

    if (Test-FolderContainsEncryptedItem -Folder $Source) {
        throw (
            'The copy-based move was stopped because the managed folder ' +
            'contains an Encrypting File System (EFS) encrypted item. ' +
            'Use a destination on the same volume or move it with an ' +
            'encryption-aware process.'
        )
    }

    Write-Host ''
    Write-Host 'Copying the folder safely to the selected location...' `
        -ForegroundColor Cyan

    $copyCode = Invoke-RobocopyQuiet `
        -Source $Source `
        -Destination $DestinationPath

    # Microsoft defines Robocopy codes 0-7 as non-failure outcomes.
    if ($copyCode -ge 8) {
        throw "Robocopy failed with exit code $copyCode."
    }

    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Container)) {
        throw 'The copied destination folder was not created.'
    }

    Confirm-DirectoryCopy `
        -Source $Source `
        -Destination $DestinationPath

    $cleanupWarning = $null

    try {
        Remove-DirectoryWithRetry -Path $Source
    }
    catch {
        # The destination has already passed SHA-256 verification. Keep it as
        # the managed copy and report any source remnants for manual cleanup.
        $cleanupWarning = $_.Exception.Message
    }

    return [pscustomobject]@{
        SourceRemoved = (-not (Test-Path -LiteralPath $Source))
        CleanupWarning = $cleanupWarning
        OperationWarning = $null
        UsedVerifiedCopy = $true
    }
}

function Move-ManagedFolderCore {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationParent
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        Write-Host 'The source folder was not found.' -ForegroundColor Yellow
        Write-Host "Source: $Source"
        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $sourceItem = Get-Item -LiteralPath $Source -Force

    if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host ''
        Write-Host (
            'The managed item is a symbolic link, junction, or another ' +
            'reparse point. It was not moved for safety.'
        ) -ForegroundColor Yellow

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $sourceParent = $sourceItem.Parent.FullName
    $destinationParentPath = Normalize-ParentPath `
        -Path $DestinationParent `
        -CreateIfMissing

    if (Test-SamePath -First $sourceParent -Second $destinationParentPath) {
        Write-Host ''
        Write-Host 'The folder is already in the selected location.' `
            -ForegroundColor Yellow
        Write-Host "Current location: $sourceParent"

        return [pscustomobject]@{
            Success = $true
            Destination = $sourceItem.FullName
        }
    }

    if ((Test-SamePath -First $sourceItem.FullName -Second $destinationParentPath) -or
        (Test-PathInsideFolder `
            -Candidate $destinationParentPath `
            -Folder $sourceItem.FullName)) {
        Write-Host ''
        Write-Host (
            'The destination cannot be the managed folder itself ' +
            'or a folder inside it.'
        ) -ForegroundColor Yellow
        Write-Host 'No files were moved.'

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $destinationInvisible = Get-InvisiblePath -Parent $destinationParentPath
    $destinationVisible = @(
        Get-VisibleManagedPaths -Parent $destinationParentPath
    )

    if ((Test-Path -LiteralPath $destinationInvisible) -or
        ($destinationVisible.Count -gt 0)) {
        Write-Host ''
        Write-Host 'Folder already exists in the selected location.' `
            -ForegroundColor Yellow
        Write-Host (
            'That location already contains a managed invisible or restored folder.'
        )
        Write-Host 'No files were moved or overwritten.'

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $destinationPath = Join-Path $destinationParentPath $sourceItem.Name

    if (Test-Path -LiteralPath $destinationPath) {
        Write-Host ''
        Write-Host 'Folder already exists in the selected location.' `
            -ForegroundColor Yellow
        Write-Host 'No files were moved or overwritten.'

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $isInvisible = ($sourceItem.Name -eq $BlankName)

    if ($isInvisible -and
        (Test-ConversionSupportConflict -Folder $sourceItem.FullName)) {
        Write-Host ''
        Write-Host (
            'The invisible folder contains conflicting support-file content.'
        ) -ForegroundColor Yellow
        Write-Host 'Nothing was moved or overwritten.'

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $original = Get-OriginalVisibility -Path $sourceItem.FullName
    $moveSucceeded = $false
    $physicalResult = $null

    try {
        if ($isInvisible) {
            Clear-PathAttributes -Path $sourceItem.FullName
        }

        $physicalResult = Move-DirectoryPhysical `
            -Source $sourceItem.FullName `
            -DestinationParent $destinationParentPath `
            -DestinationPath $destinationPath

        if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
            throw 'Windows did not create the expected destination folder.'
        }

        $moveSucceeded = $true
    }
    catch {
        if (Test-Path -LiteralPath $sourceItem.FullName -PathType Container) {
            try {
                if ($isInvisible) {
                    Set-InvisibleAppearance `
                        -Target $sourceItem.FullName `
                        -FinalHidden $original.Hidden `
                        -FinalSystem $original.System
                }
                else {
                    Restore-ExactAttributes `
                        -Path $sourceItem.FullName `
                        -Attributes $original.Attributes
                }
            }
            catch {
                # Preserve the move error.
            }
        }

        Write-Host ''
        Write-Host 'The folder could not be moved.' -ForegroundColor Yellow
        Write-Host ('Reason: ' + $_.Exception.Message)
        Write-Host 'The saved current location was not changed.'

        if (Test-Path -LiteralPath $destinationPath) {
            Write-Host ''
            Write-Host (
                'Windows left an item at the destination after the failed move.'
            ) -ForegroundColor Yellow
            Write-Host "Review this path before retrying: $destinationPath"
            Write-Host 'The tool did not delete it automatically.'
        }

        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    if (-not $moveSucceeded) {
        return [pscustomobject]@{
            Success = $false
            Destination = $null
        }
    }

    $sourceCleanupWarning = $null
    $moveOperationWarning = $null

    if (($null -ne $physicalResult) -and
        (-not [string]::IsNullOrWhiteSpace($physicalResult.OperationWarning))) {
        $moveOperationWarning = $physicalResult.OperationWarning
    }

    if (($null -ne $physicalResult) -and
        (-not [string]::IsNullOrWhiteSpace($physicalResult.CleanupWarning))) {
        $sourceCleanupWarning = $physicalResult.CleanupWarning

        if (Test-Path -LiteralPath $sourceItem.FullName -PathType Container) {
            try {
                Clear-PathAttributes -Path $sourceItem.FullName
            }
            catch {
                # The warning below still identifies the source-remnant path.
            }
        }
    }

    Grant-OriginalUserModify -Path $destinationPath

    $appearanceWarning = $null
    if ($isInvisible) {
        try {
            Set-InvisibleAppearance `
                -Target $destinationPath `
                -FinalHidden $original.Hidden `
                -FinalSystem $original.System
        }
        catch {
            $appearanceWarning = $_.Exception.Message
        }
    }
    else {
        try {
            Write-ManagementMarker -Folder $destinationPath
        }
        catch {
            # The recorded path still identifies the restored folder.
        }
    }

    $stateWarning = $null

    try {
        Save-Location -Path $destinationParentPath

        if ($isInvisible) {
            Remove-StateFile -Path $RestoredFile
        }
        else {
            Save-RestoredPath -Path $destinationPath
        }
    }
    catch {
        $stateWarning = $_.Exception.Message
    }

    Refresh-Explorer -Paths @(
        $sourceParent,
        $destinationParentPath,
        $destinationPath
    )

    Write-Host ''
    Write-Host 'The managed folder and all contents were moved successfully.' `
        -ForegroundColor Green
    Write-Host "Previous location: $sourceParent"
    Write-Host "Current location: $destinationParentPath"
    Write-Host "Folder address: $destinationPath"

    if ($null -ne $moveOperationWarning) {
        Write-Host ''
        Write-Host (
            'The move completed, but Windows also reported a provider warning.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $moveOperationWarning"
    }

    if ($null -ne $appearanceWarning) {
        Write-Host ''
        Write-Host (
            'The move succeeded, but the invisible appearance needs repair.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $appearanceWarning"
        Write-Host 'Use option 3 (Reveal / Repair), then press F5 in File Explorer.'
    }

    if ($null -ne $sourceCleanupWarning) {
        Write-Host ''
        Write-Host (
            'The destination was copied and SHA-256 verified, but Windows ' +
            'could not remove every source remnant.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $sourceCleanupWarning"
        Write-Host "Review and remove the old path manually: $($sourceItem.FullName)"
    }

    if ($null -ne $stateWarning) {
        Write-Host ''
        Write-Host (
            'The move succeeded, but the private location record could not be updated.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $stateWarning"
        Write-Host "New parent location: $destinationParentPath"
    }

    return [pscustomobject]@{
        Success = $true
        Destination = $destinationPath
    }
}

function Set-CurrentLocationWithAutoMove {
    param(
        [Parameter(Mandatory = $true)][string]$CurrentParent,
        [Parameter(Mandatory = $true)][string]$NewParent
    )

    $selected = Normalize-ParentPath -Path $NewParent -CreateIfMissing

    try {
        $current = Normalize-ParentPath -Path $CurrentParent
    }
    catch {
        Save-Location -Path $selected

        Write-Host ''
        Write-Host 'The current location was changed successfully.' `
            -ForegroundColor Green
        Write-Host "Previous saved location: $CurrentParent"
        Write-Host "Current location: $selected"
        Write-Host (
            'The previous location was unavailable, so no folder was moved.'
        )

        return $selected
    }

    if (Test-SamePath -First $current -Second $selected) {
        Save-Location -Path $selected

        Write-Host ''
        Write-Host 'The selected location is already current.' `
            -ForegroundColor Yellow
        Write-Host "Current location: $selected"

        return $selected
    }

    $source = Get-InvisiblePath -Parent $current

    if (Test-Path -LiteralPath $source) {
        if (-not (Test-Path -LiteralPath $source -PathType Container)) {
            Write-Host ''
            Write-Host (
                'An item with the blank managed-folder name exists, ' +
                'but it is not a folder.'
            ) -ForegroundColor Yellow
            Write-Host 'The location was not changed and nothing was moved.'
            Write-Host "Current location: $current"
            return $null
        }

        $visibleConflicts = @(Get-VisibleManagedPaths -Parent $current)
        if ($visibleConflicts.Count -gt 0) {
            Write-Host ''
            Write-Host (
                'Both an invisible folder and a restored managed folder ' +
                'exist in the current location.'
            ) -ForegroundColor Yellow
            Write-Host (
                'The location was not changed. Resolve the duplicate before moving.'
            )
            foreach ($conflict in $visibleConflicts) {
                Write-Host "Restored managed folder: $conflict"
            }
            return $null
        }

        $moveResult = Move-ManagedFolderCore `
            -Source $source `
            -DestinationParent $selected

        if ($moveResult.Success) {
            return $selected
        }

        return $null
    }

    $visibleManaged = $null
    $managedLookupWarning = $null

    try {
        $visibleManaged = Get-ManagedFolderPath -Parent $current
    }
    catch {
        if ($_.Exception.Message -notlike 'No managed folder was found*') {
            $managedLookupWarning = $_.Exception.Message
        }
    }

    if ($null -ne $visibleManaged) {
        Write-Host ''
        Write-Host (
            'A restored managed folder exists in the current location.'
        ) -ForegroundColor Yellow
        Write-Host "Managed folder: $visibleManaged"
        Write-Host (
            'The location was not changed so the tool does not lose track of it.'
        )
        Write-Host (
            'Use Location Manager option 3 to move it, or option 6 to ' +
            'convert it back first.'
        )
        return $null
    }

    if ($null -ne $managedLookupWarning) {
        Write-Host ''
        Write-Host 'The current location could not be inspected safely.' `
            -ForegroundColor Yellow
        Write-Host "Details: $managedLookupWarning"
        Write-Host 'The location was not changed.'
        return $null
    }

    Save-Location -Path $selected

    Write-Host ''
    Write-Host 'The current location was changed successfully.' `
        -ForegroundColor Green
    Write-Host "Previous location: $current"
    Write-Host "Current location: $selected"
    Write-Host (
        'No managed folder existed in the previous location, ' +
        'so only the saved location changed.'
    )

    return $selected
}

function Test-AvailableDirectory {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    try {
        return (Test-Path -LiteralPath $Path -PathType Container)
    }
    catch {
        return $false
    }
}

function Get-InitialBrowseLocation {
    param([AllowEmptyString()][string]$SavedLocation)

    if (-not [string]::IsNullOrWhiteSpace($SavedLocation)) {
        try {
            if (Test-Path -LiteralPath $SavedLocation -PathType Container) {
                return Normalize-ParentPath -Path $SavedLocation
            }
        }
        catch {
            # Fall back to the permanent default below.
        }
    }

    return Normalize-ParentPath `
        -Path $DefaultLocation `
        -CreateIfMissing
}

function Select-CreateLocation {
    $current = Get-SavedLocation
    $initial = Get-InitialBrowseLocation -SavedLocation $current

    Write-Host 'Choose where the folder will be created or kept'
    Write-Host '-----------------------------------------------'
    Write-Host "Default location: $DefaultLocationDisplay"
    Write-Host "Current location: $current"
    Write-Host ''
    Write-Host (
        'If an invisible folder exists in the current location, ' +
        'choosing 1 or 2 moves it automatically.'
    )
    Write-Host ''
    Write-Host "  [1] Keep default location ($DefaultLocationDisplay)"
    Write-Host '  [2] Change location'
    Write-Host '  [3] Keep current location'
    Write-Host ''

    $selection = Read-NumericChoice -Prompt 'Select [1-3]' -Allowed @(1, 2, 3)

    switch ($selection) {
        1 {
            $selected = Normalize-ParentPath `
                -Path $DefaultLocation `
                -CreateIfMissing

            return Set-CurrentLocationWithAutoMove `
                -CurrentParent $current `
                -NewParent $selected
        }

        2 {
            $selected = Choose-ParentLocation `
                -InitialPath $initial `
                -Purpose 'Choose a new folder location'

            if ($null -eq $selected) {
                Write-Host ''
                Write-Host 'No location change was made.' `
                    -ForegroundColor Yellow
                Write-Host "Current location: $current"
                return $null
            }

            return Set-CurrentLocationWithAutoMove `
                -CurrentParent $current `
                -NewParent $selected
        }

        3 {
            if (-not (Test-AvailableDirectory -Path $current)) {
                Write-Host ''
                Write-Host 'The saved current location is unavailable.' `
                    -ForegroundColor Yellow
                Write-Host 'Choose option 1 or 2 to select an available location.'
                return $null
            }

            Write-Host ''
            Write-Host 'The current location was kept.' -ForegroundColor Green
            Write-Host "Current location: $current"
            return (Normalize-ParentPath -Path $current)
        }
    }
}

function Create-ManagedFolder {
    $parent = Select-CreateLocation
    if ($null -eq $parent) {
        return
    }

    $target = Get-InvisiblePath -Parent $parent

    if (Test-Path -LiteralPath $target) {
        Write-Host ''

        if (Test-Path -LiteralPath $target -PathType Container) {
            Write-Host 'Folder already exists.' -ForegroundColor Yellow
        }
        else {
            Write-Host (
                'An item with the blank folder name already exists.'
            ) -ForegroundColor Yellow
            Write-Host 'No existing item was changed.'
        }

        Write-Host "Current location: $parent"
        return
    }

    $visibleManaged = @(Get-VisibleManagedPaths -Parent $parent)
    if ($visibleManaged.Count -gt 0) {
        Write-Host ''
        Write-Host 'Folder already exists in restored visible form.' `
            -ForegroundColor Yellow

        foreach ($managedPath in $visibleManaged) {
            Write-Host "Managed folder: $managedPath"
        }

        Write-Host (
            'Use option 6 to convert it back instead of creating a duplicate.'
        )
        Write-Host "Current location: $parent"
        return
    }

    [IO.Directory]::CreateDirectory($target) | Out-Null
    Grant-OriginalUserModify -Path $target

    try {
        Set-InvisibleAppearance `
            -Target $target `
            -FinalHidden $false `
            -FinalSystem $false
    }
    catch {
        throw (
            "The folder was created, but its invisible appearance could not be applied.`n" +
            $_.Exception.Message
        )
    }

    $stateWarning = $null

    try {
        Save-Location -Path $parent
        Remove-StateFile -Path $RestoredFile
    }
    catch {
        $stateWarning = $_.Exception.Message
    }

    Write-Host ''
    Write-Host 'The invisible-looking folder was created successfully.' `
        -ForegroundColor Green
    Write-Host "Current location: $parent"
    Write-Host 'It appears as a blank clickable area in File Explorer.'

    if ($null -ne $stateWarning) {
        Write-Host ''
        Write-Host (
            'The folder was created, but the private location record ' +
            'could not be updated.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $stateWarning"
        Write-Host "Folder parent: $parent"
    }
}

function Hide-InvisibleFolder {
    $parent = Resolve-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Set-InvisibleAppearance `
        -Target $target `
        -FinalHidden $true `
        -FinalSystem $true

    Write-Host 'The folder is now hidden with Hidden and System attributes.' `
        -ForegroundColor Green
    Write-Host "Current location: $parent"
}

function Reveal-InvisibleFolder {
    $parent = Resolve-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Set-InvisibleAppearance `
        -Target $target `
        -FinalHidden $false `
        -FinalSystem $false

    Write-Host 'The folder was revealed and its transparent appearance repaired.' `
        -ForegroundColor Green
    Write-Host "Current location: $parent"
    Write-Host 'Press F5 in File Explorer if the icon cache has not refreshed yet.'
}

function Open-ManagedFolder {
    $parent = Resolve-CurrentLocation
    $target = Get-ManagedFolderPath -Parent $parent

    Invoke-Item -LiteralPath $target

    Write-Host "Opened: $target" -ForegroundColor Green
}

function Get-UniqueVisibleName {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $baseName = 'Visible Folder'
    $name = $baseName
    $number = 2

    while (Test-Path -LiteralPath (Join-Path $Parent $name)) {
        $name = "$baseName $number"
        $number++
    }

    return $name
}

function Restore-VisibleFolder {
    $parent = Resolve-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent
    $existingVisibleManaged = @(Get-VisibleManagedPaths -Parent $parent)

    if ($existingVisibleManaged.Count -gt 0) {
        Write-Host 'A restored managed folder already exists in this location.' `
            -ForegroundColor Yellow
        foreach ($managedPath in $existingVisibleManaged) {
            Write-Host "Managed folder: $managedPath"
        }
        Write-Host 'No folder was renamed or modified.'
        return
    }

    if (Test-ConversionSupportConflict -Folder $target) {
        throw (
            'The blank-name folder contains conflicting support-file content. ' +
            'It was not renamed or modified.'
        )
    }

    $original = Get-OriginalVisibility -Path $target
    $newName = Get-UniqueVisibleName -Parent $parent
    $restoredPath = Join-Path $parent $newName

    $renameWarning = $null

    try {
        Clear-PathAttributes -Path $target
        Rename-Item -LiteralPath $target -NewName $newName -ErrorAction Stop
    }
    catch {
        $sourceStillExists = Test-Path `
            -LiteralPath $target `
            -PathType Container
        $destinationNowExists = Test-Path `
            -LiteralPath $restoredPath `
            -PathType Container

        if ((-not $sourceStillExists) -and $destinationNowExists) {
            $renameWarning = $_.Exception.Message
        }
        else {
            try {
                if ($sourceStillExists) {
                    Set-InvisibleAppearance `
                        -Target $target `
                        -FinalHidden $original.Hidden `
                        -FinalSystem $original.System
                }
            }
            catch {
                # Preserve the rename error.
            }

            throw
        }
    }

    $cleanupWarning = $null

    try {
        Remove-InvisibleSupportFiles -Target $restoredPath
    }
    catch {
        $cleanupWarning = $_.Exception.Message

        try {
            Clear-PathAttributes -Path $restoredPath
            Write-ManagementMarker -Folder $restoredPath
        }
        catch {
            # The folder itself has already been restored and renamed.
        }
    }

    Grant-OriginalUserModify -Path $restoredPath

    $stateWarning = $null
    try {
        Save-Location -Path $parent
        Save-RestoredPath -Path $restoredPath
    }
    catch {
        $stateWarning = $_.Exception.Message
    }

    Refresh-Explorer -Paths @($parent, $restoredPath)

    Write-Host 'The folder was restored to a normal visible folder.' `
        -ForegroundColor Green
    Write-Host "Restored as: $restoredPath"

    if ($newName -ne 'Visible Folder') {
        Write-Host (
            'A numbered name was used because "Visible Folder" already existed.'
        )
    }

    if ($null -ne $renameWarning) {
        Write-Host ''
        Write-Host (
            'The restore completed, but Windows also reported a provider warning.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $renameWarning"
    }

    if ($null -ne $cleanupWarning) {
        Write-Host ''
        Write-Host (
            'The folder was restored, but one appearance support file ' +
            'could not be removed.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $cleanupWarning"
    }

    if ($null -ne $stateWarning) {
        Write-Host ''
        Write-Host (
            'The folder was restored, but the private location record ' +
            'could not be updated.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $stateWarning"
        Write-Host "Restored folder: $restoredPath"
    }
}

function Get-ProtectedKnownFolderPaths {
    $paths = @(
        $OriginalUserProfile,
        (Join-Path $OriginalUserProfile 'Desktop'),
        (Join-Path $OriginalUserProfile 'Documents'),
        (Join-Path $OriginalUserProfile 'Downloads'),
        (Join-Path $OriginalUserProfile 'Pictures'),
        (Join-Path $OriginalUserProfile 'Music'),
        (Join-Path $OriginalUserProfile 'Videos'),
        (Join-Path $OriginalUserProfile 'Favorites'),
        (Join-Path $OriginalUserProfile 'AppData'),
        $BaseLocalAppData
    )

    # Read redirected known-folder paths from the launching user's loaded hive.
    try {
        $shellFolderKey = (
            'Registry::HKEY_USERS\' + $OriginalUserSid +
            '\Software\Microsoft\Windows\CurrentVersion\Explorer' +
            '\User Shell Folders'
        )

        if (Test-Path -LiteralPath $shellFolderKey) {
            $properties = Get-ItemProperty `
                -LiteralPath $shellFolderKey `
                -ErrorAction Stop

            foreach ($property in $properties.PSObject.Properties) {
                if ($property.Name -like 'PS*') {
                    continue
                }

                if ($property.Value -is [string] -and
                    (-not [string]::IsNullOrWhiteSpace($property.Value))) {
                    $expanded = [Environment]::ExpandEnvironmentVariables(
                        $property.Value
                    )

                    if ([IO.Path]::IsPathRooted($expanded)) {
                        $paths += $expanded
                    }
                }
            }
        }
    }
    catch {
        # The normal profile-based paths above remain protected.
    }

    $unique = @()
    foreach ($path in $paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        try {
            $normalized = Get-ComparablePath -Path $path
            if ($unique -notcontains $normalized) {
                $unique += $normalized
            }
        }
        catch {
            # Ignore malformed optional paths.
        }
    }

    return $unique
}

function Test-ProtectedConversionPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$CurrentParent
    )

    $candidate = Get-ComparablePath -Path $Path

    $criticalPaths = @(
        [IO.Path]::GetPathRoot($candidate),
        $env:SystemRoot,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $env:ProgramData,
        $ConfigRoot,
        $DefaultLocation,
        $CurrentParent
    ) + @(Get-ProtectedKnownFolderPaths)

    # Never rename a critical path itself or a parent that contains one.
    foreach ($criticalPath in $criticalPaths) {
        if ([string]::IsNullOrWhiteSpace($criticalPath)) {
            continue
        }

        try {
            if ((Test-SamePath -First $candidate -Second $criticalPath) -or
                (Test-PathInsideFolder `
                    -Candidate $criticalPath `
                    -Folder $candidate)) {
                return $true
            }
        }
        catch {
            # Ignore an invalid optional environment path.
        }
    }

    # Never rename anything inside Windows, Program Files, AppData, or private state.
    foreach ($blockedTree in @(
        $env:SystemRoot,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        (Join-Path $OriginalUserProfile 'AppData'),
        $BaseLocalAppData,
        $ConfigRoot
    )) {
        if ([string]::IsNullOrWhiteSpace($blockedTree)) {
            continue
        }

        try {
            if (Test-PathInsideFolder `
                    -Candidate $candidate `
                    -Folder $blockedTree) {
                return $true
            }
        }
        catch {
            # Ignore an invalid optional environment path.
        }
    }

    # ProgramData is restricted except for folders below this tool's default
    # ProductIFT parent. The ProductIFT parent itself is blocked above.
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramData)) {
        try {
            if ((Test-PathInsideFolder `
                    -Candidate $candidate `
                    -Folder $env:ProgramData) -and
                (-not (Test-PathInsideFolder `
                    -Candidate $candidate `
                    -Folder $DefaultLocation))) {
                return $true
            }
        }
        catch {
            # Treat an invalid ProgramData value as non-matching.
        }
    }

    return $false
}

function Test-SupportPathUnsafe {
    param([Parameter(Mandatory = $true)][string]$Folder)

    $support = Get-SupportPaths -Folder $Folder

    foreach ($supportPath in @(
        $support.Icon,
        $support.DesktopIni,
        $support.Marker
    )) {
        if (-not (Test-Path -LiteralPath $supportPath)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $supportPath -PathType Leaf)) {
            return $true
        }

        try {
            $item = Get-Item -LiteralPath $supportPath -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                return $true
            }
        }
        catch {
            return $true
        }
    }

    return $false
}

function Test-IconMatchesTool {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    try {
        $iconText = [Convert]::ToBase64String(
            [IO.File]::ReadAllBytes($Path)
        )
        return ($iconText -eq $IconBase64)
    }
    catch {
        return $false
    }
}

function Test-DesktopIniMatchesTool {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    try {
        $allowedLines = @(
            '[.shellclassinfo]',
            'confirmfileop=0',
            'iconresource=blank.ico,0',
            'iconfile=blank.ico',
            'iconindex=0'
        )

        $iniLines = @(
            [IO.File]::ReadAllLines($Path) |
                ForEach-Object { $_.Trim().ToLowerInvariant() } |
                Where-Object { $_.Length -gt 0 }
        )

        foreach ($line in $iniLines) {
            if ($allowedLines -notcontains $line) {
                return $false
            }
        }

        $hasSection = $iniLines -contains '[.shellclassinfo]'
        $hasIconResource = $iniLines -contains 'iconresource=blank.ico,0'
        $hasIconFilePair = (
            ($iniLines -contains 'iconfile=blank.ico') -and
            ($iniLines -contains 'iconindex=0')
        )

        return (
            $hasSection -and
            ($hasIconResource -or $hasIconFilePair)
        )
    }
    catch {
        return $false
    }
}

function Test-InvisibleAppearanceHealthy {
    param([Parameter(Mandatory = $true)][string]$Folder)

    if (Test-SupportPathUnsafe -Folder $Folder) {
        return $false
    }

    try {
        $folderItem = Get-Item -LiteralPath $Folder -Force
        if (-not ($folderItem.Attributes -band [IO.FileAttributes]::ReadOnly)) {
            return $false
        }
    }
    catch {
        return $false
    }

    $support = Get-SupportPaths -Folder $Folder

    foreach ($supportPath in @(
        $support.Icon,
        $support.DesktopIni,
        $support.Marker
    )) {
        if (-not (Test-Path -LiteralPath $supportPath -PathType Leaf)) {
            return $false
        }

        try {
            $supportItem = Get-Item -LiteralPath $supportPath -Force
            $isHidden = [bool](
                $supportItem.Attributes -band [IO.FileAttributes]::Hidden
            )
            $isSystem = [bool](
                $supportItem.Attributes -band [IO.FileAttributes]::System
            )

            if ((-not $isHidden) -or (-not $isSystem)) {
                return $false
            }
        }
        catch {
            return $false
        }
    }

    return (
        (Test-ManagementMarker -Folder $Folder) -and
        (Test-IconMatchesTool -Path $support.Icon) -and
        (Test-DesktopIniMatchesTool -Path $support.DesktopIni)
    )
}

function Test-ConversionSupportConflict {
    param([Parameter(Mandatory = $true)][string]$Folder)

    if (Test-SupportPathUnsafe -Folder $Folder) {
        return $true
    }

    $support = Get-SupportPaths -Folder $Folder

    # A valid management marker establishes ownership of the three support files.
    # This allows Reveal/Repair and post-move repair to replace corrupted tool files.
    if (Test-ManagementMarker -Folder $Folder) {
        return $false
    }

    # Without a valid marker, existing files are adopted only when they exactly
    # match this tool. This prevents overwriting unrelated user content.
    if ((Test-Path -LiteralPath $support.Icon) -and
        (-not (Test-IconMatchesTool -Path $support.Icon))) {
        return $true
    }

    if ((Test-Path -LiteralPath $support.DesktopIni) -and
        (-not (Test-DesktopIniMatchesTool -Path $support.DesktopIni))) {
        return $true
    }

    if (Test-Path -LiteralPath $support.Marker) {
        return $true
    }

    return $false
}

function Convert-VisibleFolder {
    $parent = Resolve-CurrentLocation
    $defaultSource = Get-DefaultVisibleFolder -Parent $parent

    Write-Host 'Convert a visible folder to the invisible-looking form'
    Write-Host '------------------------------------------------------'
    Write-Host "Current location: $parent"
    Write-Host "Default source: $defaultSource"
    Write-Host ''
    Write-Host '  [1] Use the default visible folder'
    Write-Host '  [2] Browse and choose a visible folder'
    Write-Host '  [3] Enter a visible folder path'
    Write-Host '  [4] Cancel'
    Write-Host ''

    $selection = Read-NumericChoice -Prompt 'Select [1-4]' -Allowed @(1, 2, 3, 4)

    switch ($selection) {
        1 {
            $source = $defaultSource
        }

        2 {
            $source = Browse-ForFolder `
                -InitialPath $parent `
                -Description 'Choose the visible folder to convert'

            if ($null -eq $source) {
                Write-Host ''
                Write-Host 'Conversion cancelled.' -ForegroundColor Yellow
                return
            }
        }

        3 {
            Write-Host ''
            $entered = Read-Host 'Enter the visible folder name or full path'

            if ([string]::IsNullOrWhiteSpace($entered)) {
                Write-Host 'No path was entered. No changes were made.' `
                    -ForegroundColor Yellow
                return
            }

            $clean = [Environment]::ExpandEnvironmentVariables(
                $entered.Trim().Trim('"')
            )

            $isDriveAbsolute = $clean -match '^[A-Za-z]:[\\/]'
            $isUncAbsolute = $clean -match '^\\\\[^\\/]+[\\/][^\\/]+'

            try {
                if ($isDriveAbsolute -or $isUncAbsolute) {
                    $source = Normalize-ParentPath -Path $clean
                }
                else {
                    if (($clean -match '^[A-Za-z]:') -or
                        ($clean.IndexOf('\') -ge 0) -or
                        ($clean.IndexOf('/') -ge 0) -or
                        ($clean -eq '.') -or
                        ($clean -eq '..')) {
                        throw (
                            'Enter one folder name, or enter a complete path ' +
                            'such as D:\Private\Visible Folder.'
                        )
                    }

                    $source = Normalize-ParentPath `
                        -Path (Join-Path $parent $clean)
                }
            }
            catch {
                Write-Host ''
                Write-Host ('The folder path could not be used: ' + $_.Exception.Message) `
                    -ForegroundColor Yellow
                Write-Host 'No files were changed.'
                return
            }
        }

        4 {
            Write-Host ''
            Write-Host 'Conversion cancelled.' -ForegroundColor Yellow
            return
        }
    }

    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        Write-Host ''
        Write-Host 'The selected visible folder was not found.' `
            -ForegroundColor Yellow
        Write-Host "Selected path: $source"
        Write-Host 'No files were changed.'
        return
    }

    $sourceItem = Get-Item -LiteralPath $source -Force

    if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host ''
        Write-Host (
            'A symbolic link, junction, or another reparse point cannot be converted.'
        ) -ForegroundColor Yellow
        Write-Host 'No files were changed.'
        return
    }

    if ($null -eq $sourceItem.Parent) {
        Write-Host ''
        Write-Host 'A drive root cannot be converted.' -ForegroundColor Yellow
        Write-Host 'No files were changed.'
        return
    }

    $sourceParent = $sourceItem.Parent.FullName
    $target = Get-InvisiblePath -Parent $sourceParent

    if ($sourceItem.Name -eq $BlankName) {
        try {
            Save-Location -Path $sourceParent
        }
        catch {
            # Existing-folder selection is intentionally a normal notice.
        }

        Write-Host ''
        Write-Host 'Folder already exists.' -ForegroundColor Yellow
        Write-Host "Current location: $sourceParent"
        return
    }

    $otherManagedFolders = @(
        Get-VisibleManagedPaths -Parent $sourceParent |
            Where-Object {
                -not (Test-SamePath `
                    -First $_ `
                    -Second $sourceItem.FullName)
            }
    )

    if ($otherManagedFolders.Count -gt 0) {
        Write-Host ''
        Write-Host (
            'Another restored managed folder already exists in this location.'
        ) -ForegroundColor Yellow
        foreach ($managedPath in $otherManagedFolders) {
            Write-Host "Managed folder: $managedPath"
        }
        Write-Host 'The selected folder was not converted.'
        return
    }

    if (Test-ProtectedConversionPath `
            -Path $sourceItem.FullName `
            -CurrentParent $parent) {
        Write-Host ''
        Write-Host 'That system or application location cannot be converted.' `
            -ForegroundColor Yellow
        Write-Host 'No files were changed.'
        return
    }

    if (Test-Path -LiteralPath $target) {
        Write-Host ''
        Write-Host 'Folder already exists in the selected location.' `
            -ForegroundColor Yellow
        Write-Host 'The visible folder was not converted.'
        Write-Host "Current location: $sourceParent"
        return
    }

    if (Test-ConversionSupportConflict -Folder $sourceItem.FullName) {
        Write-Host ''
        Write-Host (
            'The selected folder contains conflicting blank.ico, desktop.ini, ' +
            'or .ift-managed content.'
        ) -ForegroundColor Yellow
        Write-Host (
            'Conversion was cancelled to avoid overwriting existing content.'
        )
        return
    }

    Write-Host ''
    Write-Host "Source folder: $($sourceItem.FullName)"
    Write-Host "New parent location: $sourceParent"
    Write-Host ''
    Write-Host '  [1] Continue with conversion'
    Write-Host '  [2] Cancel'
    Write-Host ''

    $confirm = Read-NumericChoice -Prompt 'Select [1-2]' -Allowed @(1, 2)
    if ($confirm -ne 1) {
        Write-Host 'Conversion cancelled.' -ForegroundColor Yellow
        return
    }

    $original = Get-OriginalVisibility -Path $sourceItem.FullName
    $renameWarning = $null

    try {
        Clear-PathAttributes -Path $sourceItem.FullName
        Rename-Item `
            -LiteralPath $sourceItem.FullName `
            -NewName $BlankName `
            -ErrorAction Stop
    }
    catch {
        $sourceStillExists = Test-Path `
            -LiteralPath $sourceItem.FullName `
            -PathType Container
        $destinationNowExists = Test-Path `
            -LiteralPath $target `
            -PathType Container

        if ((-not $sourceStillExists) -and $destinationNowExists) {
            $renameWarning = $_.Exception.Message
        }
        else {
            try {
                if ($sourceStillExists) {
                    Restore-ExactAttributes `
                        -Path $sourceItem.FullName `
                        -Attributes $original.Attributes
                }
            }
            catch {
                # Preserve the rename error.
            }

            throw
        }
    }

    $stateWarning = $null
    try {
        Save-Location -Path $sourceParent
        Remove-StateFile -Path $RestoredFile
    }
    catch {
        $stateWarning = $_.Exception.Message
    }

    $appearanceWarning = $null

    try {
        Set-InvisibleAppearance `
            -Target $target `
            -FinalHidden $false `
            -FinalSystem $false
    }
    catch {
        $appearanceWarning = $_.Exception.Message
    }

    Grant-OriginalUserModify -Path $target
    Refresh-Explorer -Paths @($sourceParent, $target)

    Write-Host ''
    Write-Host 'The folder was converted successfully.' -ForegroundColor Green
    Write-Host "Current location: $sourceParent"
    Write-Host 'Its existing contents were preserved.'

    if ($null -ne $renameWarning) {
        Write-Host ''
        Write-Host (
            'The conversion completed, but Windows also reported a provider warning.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $renameWarning"
    }

    if ($null -ne $appearanceWarning) {
        Write-Host ''
        Write-Host (
            'The folder was renamed, but its invisible appearance needs repair.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $appearanceWarning"
        Write-Host 'Use option 3 (Reveal / Repair).'
    }

    if ($null -ne $stateWarning) {
        Write-Host ''
        Write-Host (
            'The folder was converted, but the private location record ' +
            'could not be updated.'
        ) -ForegroundColor Yellow
        Write-Host "Details: $stateWarning"
        Write-Host "New parent location: $sourceParent"
    }
}

function Move-ManagedFolderManually {
    $current = Resolve-CurrentLocation

    try {
        $source = Get-ManagedFolderPath -Parent $current
    }
    catch {
        Write-Host 'A single managed folder could not be selected.' `
            -ForegroundColor Yellow
        Write-Host "Details: $($_.Exception.Message)"
        Write-Host "Current location: $current"
        return
    }

    $sourceItem = Get-Item -LiteralPath $source -Force

    Write-Host ''
    Write-Host 'Move managed folder'
    Write-Host '-------------------'
    Write-Host "Current location: $current"
    Write-Host "Folder being moved: $($sourceItem.FullName)"
    Write-Host ''

    $destinationParent = Choose-ParentLocation `
        -InitialPath $current `
        -Purpose 'Choose the destination parent location'

    if ($null -eq $destinationParent) {
        Write-Host ''
        Write-Host 'Move cancelled.' -ForegroundColor Yellow
        return
    }

    $null = Move-ManagedFolderCore `
        -Source $sourceItem.FullName `
        -DestinationParent $destinationParent
}

function Change-Location {
    $current = Get-SavedLocation
    $initial = Get-InitialBrowseLocation -SavedLocation $current

    Write-Host 'Location manager'
    Write-Host '----------------'
    Write-Host "Default location: $DefaultLocationDisplay"
    Write-Host "Current location: $current"
    Write-Host ''
    Write-Host (
        'When an invisible folder exists in the current location, ' +
        'choosing 1 or 2 moves it and all contents automatically.'
    )
    Write-Host ''
    Write-Host "  [1] Keep default location ($DefaultLocationDisplay)"
    Write-Host '  [2] Change current location'
    Write-Host '  [3] Move a managed folder manually'
    Write-Host '  [4] Keep current location and return'
    Write-Host ''

    $selection = Read-NumericChoice -Prompt 'Select [1-4]' -Allowed @(1, 2, 3, 4)

    switch ($selection) {
        1 {
            $selected = Normalize-ParentPath `
                -Path $DefaultLocation `
                -CreateIfMissing

            $null = Set-CurrentLocationWithAutoMove `
                -CurrentParent $current `
                -NewParent $selected
        }

        2 {
            $selected = Choose-ParentLocation `
                -InitialPath $initial `
                -Purpose 'Choose a new current location'

            if ($null -eq $selected) {
                Write-Host ''
                Write-Host 'No location change was made.' `
                    -ForegroundColor Yellow
                Write-Host "Current location: $current"
                return
            }

            $null = Set-CurrentLocationWithAutoMove `
                -CurrentParent $current `
                -NewParent $selected
        }

        3 {
            if (-not (Test-AvailableDirectory -Path $current)) {
                Write-Host ''
                Write-Host 'The current location is unavailable.' `
                    -ForegroundColor Yellow
                Write-Host 'Choose option 1 or 2 first.'
                return
            }

            Move-ManagedFolderManually
        }

        4 {
            Write-Host ''
            Write-Host 'The current location was kept.' -ForegroundColor Green
            Write-Host "Current location: $current"
        }
    }
}

function Show-FolderAddress {
    $parent = Resolve-CurrentLocation
    $target = Get-ManagedFolderPath -Parent $parent
    $item = Get-Item -LiteralPath $target -Force
    $copied = Copy-TextToClipboard -Text $item.FullName

    Write-Host 'Managed folder address'
    Write-Host '----------------------'
    Write-Host 'The exact address is shown between square brackets:'
    Write-Host ('[' + $item.FullName + ']') -ForegroundColor Cyan
    Write-Host ''

    if ($item.Name -eq $BlankName) {
        Write-Host (
            'The final path segment is Unicode U+2800, ' +
            'so it appears blank on screen.'
        )
    }

    if ($copied) {
        Write-Host 'The exact address was copied to the clipboard.' `
            -ForegroundColor Green
        Write-Host (
            'Paste it into File Explorer''s address bar and press Enter.'
        )
    }
    else {
        Write-Host (
            'Clipboard access failed; copy the displayed address manually.'
        ) -ForegroundColor Yellow
    }
}

function Compress-MenuText {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][int]$Width
    )

    if ($null -eq $Text) {
        $Text = ''
    }

    if ($Width -le 0) {
        return ''
    }

    if ($Text.Length -le $Width) {
        return $Text
    }

    if ($Width -le 3) {
        return $Text.Substring(0, $Width)
    }

    $leftLength = [Math]::Floor(($Width - 3) / 2)
    $rightLength = $Width - 3 - $leftLength

    return (
        $Text.Substring(0, $leftLength) +
        '...' +
        $Text.Substring($Text.Length - $rightLength)
    )
}

function Write-MenuBorder {
    Write-Host ('+' + ('-' * 76) + '+') -ForegroundColor DarkCyan
}

function Write-MenuRow {
    param(
        [AllowEmptyString()][string]$Text = '',
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [ValidateSet('Left', 'Center')][string]$Align = 'Left'
    )

    $innerWidth = 74
    $display = Compress-MenuText -Text $Text -Width $innerWidth

    if ($Align -eq 'Center') {
        $leftPadding = [Math]::Floor(
            ($innerWidth - $display.Length) / 2
        )
        $display = (' ' * $leftPadding) + $display
    }

    $display = $display.PadRight($innerWidth)

    Write-Host '| ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $display -NoNewline -ForegroundColor $Color
    Write-Host ' |' -ForegroundColor DarkCyan
}

function Write-MenuField {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [AllowEmptyString()][string]$Value,
        [ConsoleColor]$ValueColor = [ConsoleColor]::White
    )

    $innerWidth = 74
    $prefix = ('  {0,-18}: ' -f $Label)
    $valueWidth = $innerWidth - $prefix.Length
    $displayValue = (
        Compress-MenuText -Text $Value -Width $valueWidth
    ).PadRight($valueWidth)

    Write-Host '| ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $prefix -NoNewline -ForegroundColor Gray
    Write-Host $displayValue -NoNewline -ForegroundColor $ValueColor
    Write-Host ' |' -ForegroundColor DarkCyan
}

function Write-MenuOption {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $display = (
        Compress-MenuText -Text $Description -Width 68
    ).PadRight(68)

    Write-Host '| ' -NoNewline -ForegroundColor DarkCyan
    Write-Host '  [' -NoNewline -ForegroundColor Gray
    Write-Host $Key -NoNewline -ForegroundColor Cyan
    Write-Host '] ' -NoNewline -ForegroundColor Gray
    Write-Host $display -NoNewline -ForegroundColor White
    Write-Host ' |' -ForegroundColor DarkCyan
}

function Get-MenuSnapshot {
    $saved = Get-SavedLocation

    $snapshot = [ordered]@{
        Location = $saved
        State = 'Not created in this location'
        StateColor = [ConsoleColor]::DarkYellow
    }

    try {
        if (-not (Test-Path -LiteralPath $saved -PathType Container)) {
            $snapshot.State = 'Current location is unavailable'
            $snapshot.StateColor = [ConsoleColor]::Red
            return [pscustomobject]$snapshot
        }
    }
    catch {
        $snapshot.State = 'Saved location is invalid'
        $snapshot.StateColor = [ConsoleColor]::Red
        return [pscustomobject]$snapshot
    }

    try {
        $parent = Normalize-ParentPath -Path $saved
        $snapshot.Location = $parent
        $invisible = Get-InvisiblePath -Parent $parent

        if (Test-Path -LiteralPath $invisible -PathType Container) {
            $item = Get-Item -LiteralPath $invisible -Force

            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $snapshot.State = 'Blank-name reparse point - not managed'
                $snapshot.StateColor = [ConsoleColor]::Red
                return [pscustomobject]$snapshot
            }

            $hidden = [bool](
                $item.Attributes -band [IO.FileAttributes]::Hidden
            )
            $system = [bool](
                $item.Attributes -band [IO.FileAttributes]::System
            )
            $appearanceHealthy = Test-InvisibleAppearanceHealthy `
                -Folder $invisible
            $visibleManaged = @(Get-VisibleManagedPaths -Parent $parent)

            if ($visibleManaged.Count -gt 0) {
                $snapshot.State = 'Duplicate invisible and restored managed folders found'
                $snapshot.StateColor = [ConsoleColor]::Yellow
            }
            elseif ($hidden -and $system -and $appearanceHealthy) {
                $snapshot.State = 'Hidden completely'
                $snapshot.StateColor = [ConsoleColor]::Yellow
            }
            elseif ($hidden -and $system) {
                $snapshot.State = 'Hidden, but appearance files need repair'
                $snapshot.StateColor = [ConsoleColor]::Yellow
            }
            elseif ($hidden -or $system) {
                $snapshot.State = 'Partially hidden - use option 2 or 3'
                $snapshot.StateColor = [ConsoleColor]::Yellow
            }
            elseif ($appearanceHealthy) {
                $snapshot.State = 'Ready - blank name and transparent icon'
                $snapshot.StateColor = [ConsoleColor]::Green
            }
            else {
                $snapshot.State = 'Blank folder found - use option 3 to repair'
                $snapshot.StateColor = [ConsoleColor]::Yellow
            }
        }
        else {
            try {
                $managed = Get-ManagedFolderPath -Parent $parent
                $managedItem = Get-Item -LiteralPath $managed -Force
                $snapshot.State = 'Restored as "' + $managedItem.Name + '"'
                $snapshot.StateColor = [ConsoleColor]::Cyan
            }
            catch {
                if ($_.Exception.Message -like 'More than one managed*') {
                    $snapshot.State = 'Multiple managed visible folders found'
                    $snapshot.StateColor = [ConsoleColor]::Yellow
                }
            }
        }
    }
    catch {
        $snapshot.State = 'Saved location needs attention'
        $snapshot.StateColor = [ConsoleColor]::Red
    }

    return [pscustomobject]$snapshot
}

function Show-ProfessionalMenu {
    $snapshot = Get-MenuSnapshot

    try {
        $Host.UI.RawUI.WindowTitle = (
            'Invisible Folder Manager - Administrator - Offline'
        )
    }
    catch {
        # Some terminal hosts do not expose a writable title.
    }

    Write-Host ''
    Write-MenuBorder
    Write-MenuRow `
        -Text 'INVISIBLE FOLDER MANAGER' `
        -Color Cyan `
        -Align Center
    Write-MenuRow `
        -Text "Administrator | Offline | Version $ScriptVersion | Windows 10/11" `
        -Color DarkGray `
        -Align Center
    Write-MenuBorder
    Write-MenuField `
        -Label 'Default location' `
        -Value $DefaultLocationDisplay `
        -ValueColor DarkGray
    Write-MenuField `
        -Label 'Current location' `
        -Value $snapshot.Location `
        -ValueColor White
    Write-MenuField `
        -Label 'Folder status' `
        -Value $snapshot.State `
        -ValueColor $snapshot.StateColor
    Write-MenuBorder
    Write-MenuRow -Text 'FOLDER OPERATIONS' -Color Cyan
    Write-MenuOption `
        -Key '1' `
        -Description 'Create folder or select location; existing folder moves automatically'
    Write-MenuOption `
        -Key '2' `
        -Description 'Hide the invisible folder completely'
    Write-MenuOption `
        -Key '3' `
        -Description 'Reveal and repair the transparent folder appearance'
    Write-MenuOption `
        -Key '4' `
        -Description 'Open the managed folder in File Explorer'
    Write-MenuOption `
        -Key '5' `
        -Description 'Restore it as a normal folder named "Visible Folder"'
    Write-MenuOption `
        -Key '6' `
        -Description 'Convert a visible folder back to the invisible form'
    Write-MenuBorder
    Write-MenuRow -Text 'LOCATION AND ACCESS' -Color Cyan
    Write-MenuOption `
        -Key '7' `
        -Description 'Change location, auto-move, or move a managed folder manually'
    Write-MenuOption `
        -Key '8' `
        -Description 'Show and copy the exact managed folder address'
    Write-MenuOption -Key '9' -Description 'Exit the application'
    Write-MenuBorder
    Write-MenuRow `
        -Text 'Appearance only - folder contents are not encrypted.' `
        -Color DarkYellow `
        -Align Center
    Write-MenuBorder
    Write-Host ''
}

function Show-ActionHeader {
    param([Parameter(Mandatory = $true)][string]$Title)

    $current = Get-SavedLocation

    Write-Host ''
    Write-MenuBorder
    Write-MenuRow `
        -Text 'INVISIBLE FOLDER MANAGER' `
        -Color Cyan `
        -Align Center
    Write-MenuRow -Text $Title -Color White -Align Center
    Write-MenuBorder
    Write-MenuField `
        -Label 'Default location' `
        -Value $DefaultLocationDisplay `
        -ValueColor DarkGray
    Write-MenuField `
        -Label 'Current location' `
        -Value $current `
        -ValueColor White
    Write-MenuBorder
    Write-Host ''
}

function Test-PlatformCompatibility {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This batch file can run only on Microsoft Windows.'
    }

    $windowsMajor = $null

    try {
        $windowsVersion = Get-ItemProperty `
            -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
            -ErrorAction Stop

        if ($null -ne $windowsVersion.CurrentMajorVersionNumber) {
            $windowsMajor = [int]$windowsVersion.CurrentMajorVersionNumber
        }
        elseif (-not [string]::IsNullOrWhiteSpace($windowsVersion.CurrentVersion)) {
            $windowsMajor = [int]([Version]$windowsVersion.CurrentVersion).Major
        }
    }
    catch {
        $windowsMajor = [Environment]::OSVersion.Version.Major
    }

    if ($null -eq $windowsMajor) {
        $windowsMajor = [Environment]::OSVersion.Version.Major
    }

    if (($null -eq $windowsMajor) -or ($windowsMajor -lt 10)) {
        throw 'Windows 10 or Windows 11 is required.'
    }

    if ($PSVersionTable.PSVersion -lt [Version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    foreach ($requiredFile in @(
        $AttribExe,
        $IcaclsExe,
        $RobocopyExe,
        $ExplorerExe
    )) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "A required Windows component is missing: $requiredFile"
        }
    }

    if ($null -eq (Get-Command Get-FileHash -ErrorAction SilentlyContinue)) {
        throw 'The built-in Get-FileHash command is unavailable.'
    }

    if (($IconBytes.Length -lt 4) -or
        ($IconBytes[0] -ne 0) -or
        ($IconBytes[1] -ne 0) -or
        ($IconBytes[2] -ne 1) -or
        ($IconBytes[3] -ne 0)) {
        throw 'The embedded transparent icon is invalid.'
    }
}

function Initialize-Application {
    Test-PlatformCompatibility
    Ensure-ConfigRoot

    $defaultParent = Normalize-ParentPath `
        -Path $DefaultLocation `
        -CreateIfMissing

    Grant-OriginalUserModify -Path $defaultParent

    if (-not (Test-Path -LiteralPath $LocationFile -PathType Leaf)) {
        Save-Location -Path $defaultParent
    }
    else {
        $saved = Get-SavedLocation
        $savedIsValid = $true

        try {
            $expandedSaved = [Environment]::ExpandEnvironmentVariables($saved)
            $savedDriveAbsolute = $expandedSaved -match '^[A-Za-z]:[\\/]'
            $savedUncAbsolute = $expandedSaved -match '^\\\\[^\\/]+[\\/][^\\/]+'

            if ((-not $savedDriveAbsolute) -and (-not $savedUncAbsolute)) {
                throw 'The saved location is not an absolute path.'
            }

            $null = [IO.Path]::GetFullPath($expandedSaved)
        }
        catch {
            $savedIsValid = $false
        }

        if (-not $savedIsValid) {
            Save-Location -Path $defaultParent
            Remove-StateFile -Path $RestoredFile
        }
        elseif (Test-SamePath -First $saved -Second $DefaultLocation) {
            # The default directory has already been created above.
            Save-Location -Path $defaultParent
        }
    }

    Protect-StateStore
}

try {
    switch ($Action) {
        'Initialize' {
            Initialize-Application
        }

        'Menu' {
            Show-ProfessionalMenu
        }

        'Create' {
            Show-ActionHeader -Title 'CREATE FOLDER / SELECT LOCATION'
            Create-ManagedFolder
        }

        'Hide' {
            Show-ActionHeader -Title 'HIDE FOLDER'
            Hide-InvisibleFolder
        }

        'Reveal' {
            Show-ActionHeader -Title 'REVEAL / REPAIR FOLDER'
            Reveal-InvisibleFolder
        }

        'Open' {
            Show-ActionHeader -Title 'OPEN FOLDER'
            Open-ManagedFolder
        }

        'Restore' {
            Show-ActionHeader -Title 'RESTORE VISIBLE FOLDER'
            Restore-VisibleFolder
        }

        'Convert' {
            Show-ActionHeader -Title 'CONVERT TO INVISIBLE'
            Convert-VisibleFolder
        }

        'Location' {
            Show-ActionHeader -Title 'LOCATION MANAGER'
            Change-Location
        }

        'Address' {
            Show-ActionHeader -Title 'SHOW AND COPY ADDRESS'
            Show-FolderAddress
        }
    }

    exit 0
}
catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
