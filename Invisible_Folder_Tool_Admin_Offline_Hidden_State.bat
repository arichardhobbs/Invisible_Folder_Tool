@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Invisible Folder Tool

rem Invisible Folder Tool
rem - Initial/default parent location: the launching user's Desktop.
rem - A custom parent location can be selected and is remembered.
rem - The invisible-looking folder name is Unicode U+2800 (Braille Pattern Blank).
rem - The folder icon is a fully transparent ICO file embedded in this script.
rem - The script self-elevates through Windows UAC and then runs as administrator.
rem - It uses only local Windows components and performs no downloads/network calls.
rem - Its small state store uses an opaque per-user name plus Hidden/System/No-Index attributes.
rem - This is cosmetic concealment only; it is not encryption or access control.

set "IFT_SELF=%~f0"

rem When elevation uses another administrator account, preserve the launching user's
rem Desktop, LocalAppData, and UserProfile so the tool still manages the intended files.
if /i "%~1"=="--elevated" (
    set "IFT_ORIGINAL_DESKTOP_B64=%~2"
    set "IFT_ORIGINAL_LOCALAPPDATA_B64=%~3"
    set "IFT_ORIGINAL_USERPROFILE_B64=%~4"
)

rem Force administrator rights. The elevated copy starts this file again after UAC consent.
"%SystemRoot%\System32\fltmc.exe" >nul 2>&1
if errorlevel 1 (
    echo Administrator permission is required.
    echo Windows will now display a User Account Control prompt.
    echo.
    powershell.exe -NoLogo -NoProfile -Command ^
      "$ErrorActionPreference='Stop';" ^
      "try {" ^
      "  $enc=[Text.Encoding]::Unicode;" ^
      "  $desktop64=[Convert]::ToBase64String($enc.GetBytes([Environment]::GetFolderPath('Desktop')));" ^
      "  $local64=[Convert]::ToBase64String($enc.GetBytes($env:LOCALAPPDATA));" ^
      "  $profile64=[Convert]::ToBase64String($enc.GetBytes($env:USERPROFILE));" ^
      "  Start-Process -FilePath $env:IFT_SELF -ArgumentList @('--elevated',$desktop64,$local64,$profile64) -Verb RunAs;" ^
      "} catch { Write-Host ('Elevation failed: ' + $_.Exception.Message); exit 1 }"
    if errorlevel 1 (
        echo.
        echo Administrator elevation was cancelled or failed.
        pause
    )
    endlocal
    exit /b
)

title Invisible Folder Tool - Administrator

rem Initialize and migrate the private state store immediately after elevation.
set "IFT_ACTION=Initialize"
call :RUN_EMBEDDED
if errorlevel 1 (
    echo.
    echo WARNING: The private state store could not be initialized.
    echo Other menu actions may fail until the problem is corrected.
    pause
)
goto MENU

:RUN_EMBEDDED
powershell.exe -NoLogo -NoProfile -Command ^
  "$raw=[IO.File]::ReadAllText($env:IFT_SELF);" ^
  "$marker='# POWERSHELL_SECTION_START';" ^
  "$index=$raw.LastIndexOf($marker);" ^
  "if($index -lt 0){Write-Error 'The embedded PowerShell section is missing.'; exit 1};" ^
  "$script=$raw.Substring($index+$marker.Length);" ^
  "& ([ScriptBlock]::Create($script)) -Action $env:IFT_ACTION"
exit /b %errorlevel%

:MENU
cls
echo ================================================================
echo                    Invisible Folder Tool
echo ================================================================
echo.
echo  1. Create or repair an invisible-looking folder
echo     ^(Desktop initially; enter another parent path if desired^)
echo  2. Hide the current invisible folder completely
echo  3. Reveal the current folder with blank name and transparent icon
echo  4. Open the current invisible folder
echo  5. Restore it as a normal visible folder named "Visible Folder"
echo  6. Convert "Visible Folder" back to blank name and transparent icon
echo  7. Choose or change the working parent location
echo  8. Show and copy the current managed folder address
echo  9. Exit
echo.
echo  Options 2-6 and 8 use the saved location selected by option 1 or 7.
echo.
choice /c 123456789 /n /m "Choose an option [1-9]: "

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
goto RUN_ACTION

:ACTION_HIDE
set "IFT_ACTION=Hide"
goto RUN_ACTION

:ACTION_REVEAL
set "IFT_ACTION=Reveal"
goto RUN_ACTION

:ACTION_OPEN
set "IFT_ACTION=Open"
goto RUN_ACTION

:ACTION_RESTORE
set "IFT_ACTION=Restore"
goto RUN_ACTION

:ACTION_CONVERT
set "IFT_ACTION=Convert"
goto RUN_ACTION

:ACTION_LOCATION
set "IFT_ACTION=Location"
goto RUN_ACTION

:ACTION_ADDRESS
set "IFT_ACTION=Address"
goto RUN_ACTION

:RUN_ACTION
cls
call :RUN_EMBEDDED
echo.
pause
goto MENU

:END
endlocal
exit /b 0

# POWERSHELL_SECTION_START
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Initialize', 'Create', 'Hide', 'Reveal', 'Open', 'Restore', 'Convert', 'Location', 'Address')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

function Get-PreservedPath {
    param(
        [AllowEmptyString()][string]$Encoded,
        [Parameter(Mandatory = $true)][string]$Fallback
    )

    if ([string]::IsNullOrWhiteSpace($Encoded)) {
        return $Fallback
    }

    try {
        $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Encoded))
        if ([string]::IsNullOrWhiteSpace($decoded)) {
            return $Fallback
        }
        return $decoded
    }
    catch {
        return $Fallback
    }
}

$Desktop = Get-PreservedPath -Encoded $env:IFT_ORIGINAL_DESKTOP_B64 -Fallback ([Environment]::GetFolderPath('Desktop'))
$BaseLocalAppData = Get-PreservedPath -Encoded $env:IFT_ORIGINAL_LOCALAPPDATA_B64 -Fallback $env:LOCALAPPDATA
$OriginalUserProfile = Get-PreservedPath -Encoded $env:IFT_ORIGINAL_USERPROFILE_B64 -Fallback $env:USERPROFILE

# Keep path expansion and configuration tied to the user who launched the batch file.
$env:USERPROFILE = $OriginalUserProfile
$env:LOCALAPPDATA = $BaseLocalAppData

$BlankName = [string][char]0x2800
$IconFileName = 'blank.ico'
$DesktopIniName = 'desktop.ini'
$IconBase64 = 'AAABAAIAEBAAAAAAIABLAAAAJgAAACAgAAAAACAAUwAAAHEAAACJUE5HDQoaCgAAAA1JSERSAAAAEAAAABAIBgAAAB/z/2EAAAASSURBVHicY2AYBaNgFIwCCAAABBAAAVU3WtAAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAAaSURBVHic7cEBAQAAAIIg/69uSEABAAAA7wYQIAABGUM07gAAAABJRU5ErkJggg=='
$AttribExe = Join-Path $env:SystemRoot 'System32\attrib.exe'

# The current state directory name is calculated per user. It contains neither the
# tool name nor a descriptive file name, so ordinary searches for those old names
# will not locate the new state store. This remains concealment, not encryption.
function Get-OpaqueStateDirectoryName {
    $seedText = $OriginalUserProfile.ToLowerInvariant() + '|ift-state-v4|local-only'
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $seedBytes = [Text.Encoding]::UTF8.GetBytes($seedText)
        $hashBytes = $sha256.ComputeHash($seedBytes)
        $hashText = -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
        return '.' + $hashText.Substring(0, 32)
    }
    finally {
        $sha256.Dispose()
    }
}

$ConfigRoot = Join-Path $BaseLocalAppData (Get-OpaqueStateDirectoryName)
$LocationFile = Join-Path $ConfigRoot '.s1.dat'
$RestoredFile = Join-Path $ConfigRoot '.s2.dat'

# Previous versions used visible, descriptive names. Decode them only for a
# one-time migration, then remove the old state files and directory when safe.
$LegacyConfigRoot = Join-Path $BaseLocalAppData (
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('SW52aXNpYmxlRm9sZGVyVG9vbA=='))
)
$LegacyLocationFile = Join-Path $LegacyConfigRoot (
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('bG9jYXRpb24udHh0'))
)
$LegacyRestoredFile = Join-Path $LegacyConfigRoot (
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('bGFzdC1yZXN0b3JlZC50eHQ='))
)

function Set-StateAttributes {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Protect', 'Clear')]
        [string]$Mode
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if ($Mode -eq 'Protect') {
        $arguments = @('+h', '+s', '+i', $Path)
        $fallbackArguments = @('+h', '+s', $Path)
    }
    else {
        $arguments = @('-h', '-s', '-r', '-i', $Path)
        $fallbackArguments = @('-h', '-s', '-r', $Path)
    }

    & $AttribExe @arguments | Out-Null
    if ($LASTEXITCODE -ne 0) {
        # Older attrib.exe builds may not recognize the no-index flag.
        & $AttribExe @fallbackArguments | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Windows could not update the private state-store attributes: $Path"
    }
}

function Protect-StateStore {
    if (Test-Path -LiteralPath $LocationFile -PathType Leaf) {
        Set-StateAttributes -Path $LocationFile -Mode Protect
    }

    if (Test-Path -LiteralPath $RestoredFile -PathType Leaf) {
        Set-StateAttributes -Path $RestoredFile -Mode Protect
    }

    if (Test-Path -LiteralPath $ConfigRoot -PathType Container) {
        Set-StateAttributes -Path $ConfigRoot -Mode Protect
    }
}

function Migrate-LegacyStateStore {
    if (($LegacyConfigRoot -eq $ConfigRoot) -or (-not (Test-Path -LiteralPath $LegacyConfigRoot -PathType Container))) {
        return
    }

    $migrationPairs = @(
        @{ Old = $LegacyLocationFile; New = $LocationFile },
        @{ Old = $LegacyRestoredFile; New = $RestoredFile }
    )

    foreach ($pair in $migrationPairs) {
        if (Test-Path -LiteralPath $pair.Old -PathType Leaf) {
            if (-not (Test-Path -LiteralPath $pair.New -PathType Leaf)) {
                $legacyValue = [IO.File]::ReadAllText($pair.Old)
                [IO.File]::WriteAllText($pair.New, $legacyValue)
            }

            if (Test-Path -LiteralPath $pair.New -PathType Leaf) {
                Set-StateAttributes -Path $pair.Old -Mode Clear
                Remove-Item -LiteralPath $pair.Old -Force
            }
        }
    }

    $remaining = @(Get-ChildItem -LiteralPath $LegacyConfigRoot -Force -ErrorAction SilentlyContinue)
    if ($remaining.Count -eq 0) {
        Set-StateAttributes -Path $LegacyConfigRoot -Mode Clear
        Remove-Item -LiteralPath $LegacyConfigRoot -Force
    }
    else {
        # Do not delete files that were not created by this tool.
        Set-StateAttributes -Path $LegacyConfigRoot -Mode Protect
    }
}

function Ensure-ConfigRoot {
    if (-not (Test-Path -LiteralPath $ConfigRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $ConfigRoot -Force | Out-Null
    }

    Migrate-LegacyStateStore
    Protect-StateStore
}

function Save-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )

    Ensure-ConfigRoot

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Set-StateAttributes -Path $Path -Mode Clear
    }

    [IO.File]::WriteAllText($Path, $Value)
    Set-StateAttributes -Path $Path -Mode Protect
    Set-StateAttributes -Path $ConfigRoot -Mode Protect
}

function Remove-StateFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Set-StateAttributes -Path $Path -Mode Clear
        Remove-Item -LiteralPath $Path -Force
    }

    Protect-StateStore
}

function Normalize-ParentPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$CreateIfMissing
    )

    $value = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw 'No parent location was supplied.'
    }

    if ($value -eq '~') {
        $value = $env:USERPROFILE
    }
    elseif ($value.StartsWith('~\') -or $value.StartsWith('~/')) {
        $value = Join-Path $env:USERPROFILE $value.Substring(2)
    }

    $fullPath = [IO.Path]::GetFullPath($value)

    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        throw "The selected path is a file, not a folder: $fullPath"
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
        if (-not $CreateIfMissing) {
            throw "The selected parent location does not exist: $fullPath"
        }

        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created parent location: $fullPath"
    }

    return (Get-Item -LiteralPath $fullPath -Force).FullName
}

function Save-Location {
    param([Parameter(Mandatory = $true)][string]$Path)
    Save-TextFile -Path $LocationFile -Value $Path
}

function Get-CurrentLocation {
    Ensure-ConfigRoot

    if (-not (Test-Path -LiteralPath $LocationFile -PathType Leaf)) {
        $initial = Normalize-ParentPath -Path $Desktop
        Save-Location -Path $initial
        return $initial
    }

    $saved = [IO.File]::ReadAllText($LocationFile).Trim()
    if ([string]::IsNullOrWhiteSpace($saved)) {
        $initial = Normalize-ParentPath -Path $Desktop
        Save-Location -Path $initial
        return $initial
    }

    try {
        return Normalize-ParentPath -Path $saved
    }
    catch {
        throw "The saved working location is unavailable. Choose option 7 to select a valid location. Saved value: $saved"
    }
}

function Select-Location {
    try {
        $current = Get-CurrentLocation
    }
    catch {
        $current = Normalize-ParentPath -Path $Desktop
        Write-Host ('NOTICE: ' + $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "Falling back to Desktop for this selection: $current"
        Write-Host ''
    }

    Write-Host 'Working parent location'
    Write-Host '-----------------------'
    Write-Host "Current: $current"
    Write-Host 'Press Enter to keep it, or type another parent folder path.'
    Write-Host 'Environment variables such as %USERPROFILE% are supported.'
    Write-Host ''

    $entered = Read-Host 'Parent location'
    if ([string]::IsNullOrWhiteSpace($entered)) {
        $selected = $current
    }
    else {
        $selected = Normalize-ParentPath -Path $entered -CreateIfMissing
    }

    Save-Location -Path $selected
    return $selected
}

function Get-InvisiblePath {
    param([Parameter(Mandatory = $true)][string]$Parent)
    return Join-Path $Parent $BlankName
}

function Invoke-Attrib {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    & $AttribExe @Arguments | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Windows could not update file attributes. attrib.exe exit code: $LASTEXITCODE"
    }
}

function Refresh-Explorer {
    try {
        $refresh = Join-Path $env:SystemRoot 'System32\ie4uinit.exe'
        if (Test-Path -LiteralPath $refresh -PathType Leaf) {
            Start-Process -FilePath $refresh -ArgumentList '-show' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
        }
    }
    catch {
        # Explorer can also be refreshed manually with F5; refresh failure is non-fatal.
    }
}

function Set-InvisibleAppearance {
    param([Parameter(Mandatory = $true)][string]$Target)

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        throw "The target folder does not exist: $Target"
    }

    $iconPath = Join-Path $Target $IconFileName
    $desktopIniPath = Join-Path $Target $DesktopIniName

    [IO.File]::WriteAllBytes($iconPath, [Convert]::FromBase64String($IconBase64))
    [IO.File]::WriteAllLines(
        $desktopIniPath,
        @(
            '[.ShellClassInfo]',
            "IconResource=$IconFileName,0",
            'ConfirmFileOp=0'
        ),
        [Text.Encoding]::Unicode
    )

    Invoke-Attrib -Arguments @('+h', '+s', $iconPath)
    Invoke-Attrib -Arguments @('+h', '+s', $desktopIniPath)
    Invoke-Attrib -Arguments @('-h', '-s', '+r', $Target)

    (Get-Item -LiteralPath $Target -Force).LastWriteTime = Get-Date
    Refresh-Explorer
}

function Remove-InvisibleAppearance {
    param([Parameter(Mandatory = $true)][string]$Target)

    Invoke-Attrib -Arguments @('-h', '-s', '-r', $Target)

    $desktopIniPath = Join-Path $Target $DesktopIniName
    $iconPath = Join-Path $Target $IconFileName

    if (Test-Path -LiteralPath $desktopIniPath -PathType Leaf) {
        Invoke-Attrib -Arguments @('-h', '-s', $desktopIniPath)
        Remove-Item -LiteralPath $desktopIniPath -Force
    }

    if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
        Invoke-Attrib -Arguments @('-h', '-s', $iconPath)
        Remove-Item -LiteralPath $iconPath -Force
    }

    Refresh-Explorer
}

function Assert-InvisibleFolderExists {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $target = Get-InvisiblePath -Parent $Parent
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "No blank-name folder was found in: $Parent`nChoose option 1 to create it, or option 7 to change the working location."
    }

    return $target
}

function Get-DefaultVisibleFolder {
    param([Parameter(Mandatory = $true)][string]$Parent)

    if (Test-Path -LiteralPath $RestoredFile -PathType Leaf) {
        $recorded = [IO.File]::ReadAllText($RestoredFile).Trim()
        if (-not [string]::IsNullOrWhiteSpace($recorded) -and
            (Test-Path -LiteralPath $recorded -PathType Container)) {
            $item = Get-Item -LiteralPath $recorded -Force
            if ($item.Parent.FullName -eq $Parent) {
                return $item.FullName
            }
        }
    }

    $exact = Join-Path $Parent 'Visible Folder'
    if (Test-Path -LiteralPath $exact -PathType Container) {
        return (Get-Item -LiteralPath $exact -Force).FullName
    }

    $matches = @(
        Get-ChildItem -LiteralPath $Parent -Directory -Force |
            Where-Object { $_.Name -match '^Visible Folder(?: [0-9]+)?$' } |
            Sort-Object Name
    )

    if ($matches.Count -eq 1) {
        return $matches[0].FullName
    }

    return $exact
}

function Get-ManagedFolderPath {
    param([Parameter(Mandatory = $true)][string]$Parent)

    $invisible = Get-InvisiblePath -Parent $Parent
    if (Test-Path -LiteralPath $invisible -PathType Container) {
        return (Get-Item -LiteralPath $invisible -Force).FullName
    }

    if (Test-Path -LiteralPath $RestoredFile -PathType Leaf) {
        $recorded = [IO.File]::ReadAllText($RestoredFile).Trim()
        if (-not [string]::IsNullOrWhiteSpace($recorded) -and
            (Test-Path -LiteralPath $recorded -PathType Container)) {
            $item = Get-Item -LiteralPath $recorded -Force
            if ($item.Parent.FullName -eq $Parent) {
                return $item.FullName
            }
        }
    }

    $visibleMatches = @(
        Get-ChildItem -LiteralPath $Parent -Directory -Force |
            Where-Object { $_.Name -match '^Visible Folder(?: [0-9]+)?$' } |
            Sort-Object Name
    )

    if ($visibleMatches.Count -eq 1) {
        return $visibleMatches[0].FullName
    }

    if ($visibleMatches.Count -gt 1) {
        throw "More than one restored folder was found in: $Parent`nUse option 6 to select one, or option 1 to create/repair the blank-name folder."
    }

    throw "No managed folder was found in: $Parent`nChoose option 1 to create it, option 6 to convert a visible folder, or option 7 to change location."
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
            # The address will still be displayed even if clipboard access fails.
        }
    }

    return $false
}

function Create-OrRepair {
    $parent = Select-Location
    $target = Get-InvisiblePath -Parent $parent
    $created = $false

    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        New-Item -ItemType Directory -Path $target | Out-Null
        $created = $true
    }

    Set-InvisibleAppearance -Target $target

    Write-Host ''
    if ($created) {
        Write-Host 'Created the invisible-looking folder.'
    }
    else {
        Write-Host 'Repaired the blank name, transparent icon, and required attributes.'
    }
    Write-Host "Parent location: $parent"
    Write-Host 'The folder appears as a blank clickable area in File Explorer.'
}

function Hide-InvisibleFolder {
    $parent = Get-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Invoke-Attrib -Arguments @('+h', '+s', $target)
    Refresh-Explorer

    Write-Host 'The folder is now completely hidden by Windows Hidden and System attributes.'
    Write-Host "Parent location: $parent"
}

function Reveal-InvisibleFolder {
    $parent = Get-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Invoke-Attrib -Arguments @('-h', '-s', '+r', $target)
    (Get-Item -LiteralPath $target -Force).LastWriteTime = Get-Date
    Refresh-Explorer

    Write-Host 'The folder is visible again as a blank-name, transparent-icon area.'
    Write-Host "Parent location: $parent"
}

function Open-InvisibleFolder {
    $parent = Get-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Invoke-Item -LiteralPath $target
    Write-Host "Opened the folder in: $parent"
}

function Restore-VisibleFolder {
    $parent = Get-CurrentLocation
    $target = Assert-InvisibleFolderExists -Parent $parent

    Remove-InvisibleAppearance -Target $target

    $baseName = 'Visible Folder'
    $newName = $baseName
    $number = 2
    while (Test-Path -LiteralPath (Join-Path $parent $newName)) {
        $newName = "$baseName $number"
        $number++
    }

    Rename-Item -LiteralPath $target -NewName $newName
    $restoredPath = Join-Path $parent $newName
    Save-TextFile -Path $RestoredFile -Value $restoredPath
    Refresh-Explorer

    Write-Host 'The folder was restored to a normal visible folder.'
    Write-Host "Restored as: $restoredPath"
    if ($newName -ne $baseName) {
        Write-Host 'The numbered name was used because "Visible Folder" already existed.'
    }
}

function Convert-VisibleFolder {
    $parent = Get-CurrentLocation
    $defaultSource = Get-DefaultVisibleFolder -Parent $parent

    Write-Host 'Convert a visible folder back to the invisible-looking form'
    Write-Host '----------------------------------------------------------'
    Write-Host "Working parent location: $parent"
    Write-Host "Default source: $defaultSource"
    Write-Host 'Press Enter to use the default, or enter a folder name/full path.'
    Write-Host ''

    $entered = Read-Host 'Visible folder to convert'
    if ([string]::IsNullOrWhiteSpace($entered)) {
        $source = $defaultSource
    }
    else {
        $clean = [Environment]::ExpandEnvironmentVariables($entered.Trim().Trim('"'))
        if ([IO.Path]::IsPathRooted($clean)) {
            $source = [IO.Path]::GetFullPath($clean)
        }
        else {
            $source = Join-Path $parent $clean
        }
    }

    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "The visible folder was not found: $source"
    }

    $sourceItem = Get-Item -LiteralPath $source -Force
    $sourceParent = $sourceItem.Parent.FullName
    $target = Get-InvisiblePath -Parent $sourceParent

    if ($sourceItem.Name -eq $BlankName) {
        Set-InvisibleAppearance -Target $sourceItem.FullName
        Save-Location -Path $sourceParent
        Write-Host 'The folder already had the blank name; its transparent appearance was repaired.'
        Write-Host "Parent location: $sourceParent"
        return
    }

    if (Test-Path -LiteralPath $target) {
        throw "A blank-name folder already exists in: $sourceParent`nRestore or move that folder before converting another one."
    }

    Invoke-Attrib -Arguments @('-h', '-s', '-r', $sourceItem.FullName)
    Rename-Item -LiteralPath $sourceItem.FullName -NewName $BlankName
    Set-InvisibleAppearance -Target $target
    Save-Location -Path $sourceParent

    Remove-StateFile -Path $RestoredFile

    Write-Host 'The visible folder was converted back successfully.'
    Write-Host "Parent location: $sourceParent"
    Write-Host 'Its contents were not deleted or moved.'
}

function Change-Location {
    $selected = Select-Location
    Write-Host ''
    Write-Host "Saved working location: $selected"
    Write-Host 'Options 2-6 and 8 will now use this parent location.'
    Write-Host 'Changing this setting does not move any existing folder.'
}

function Show-FolderAddress {
    $parent = Get-CurrentLocation
    $target = Get-ManagedFolderPath -Parent $parent
    $item = Get-Item -LiteralPath $target -Force
    $copied = Copy-TextToClipboard -Text $item.FullName

    Write-Host 'Managed folder address'
    Write-Host '----------------------'
    Write-Host 'The exact address is shown between square brackets:'
    Write-Host ('[' + $item.FullName + ']') -ForegroundColor Cyan
    Write-Host ''

    if ($item.Name -eq $BlankName) {
        Write-Host 'The final path segment is Unicode U+2800, so it appears blank on screen.'
    }

    if ($copied) {
        Write-Host 'The exact address was also copied to the Windows clipboard.' -ForegroundColor Green
        Write-Host 'Paste it into File Explorer''s address bar and press Enter.'
    }
    else {
        Write-Host 'Clipboard access failed; select and copy the displayed address manually.' -ForegroundColor Yellow
    }
}

try {
    switch ($Action) {
        'Initialize' { Ensure-ConfigRoot }
        'Create'  { Create-OrRepair }
        'Hide'    { Hide-InvisibleFolder }
        'Reveal'  { Reveal-InvisibleFolder }
        'Open'    { Open-InvisibleFolder }
        'Restore' { Restore-VisibleFolder }
        'Convert' { Convert-VisibleFolder }
        'Location' { Change-Location }
        'Address'  { Show-FolderAddress }
    }
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
