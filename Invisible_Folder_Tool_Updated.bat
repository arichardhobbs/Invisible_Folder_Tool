@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Richard's Invisible Folder Tool

rem Invisible Folder Tool
rem - Initial/default parent location: the current user's Desktop.
rem - A custom parent location can be selected and is remembered.
rem - The invisible-looking folder name is Unicode U+2800 (Braille Pattern Blank).
rem - The folder icon is a fully transparent ICO file.
rem - This is cosmetic concealment only; it is not encryption or access control.

set "IFT_SELF=%~f0"

:MENU
cls
echo ================================================================
echo                   Richard's Invisible Folder Tool
echo ================================================================
echo.
echo  1. Create an invisible-looking folder
echo     ^(Default location - Desktop; enter another parent path if desired^)
echo  2. Hide the current invisible folder completely
echo  3. Reveal the Invisible folder with blank name and transparent icon
echo  4. Open the current invisible folder
echo  5. Restore it as a normal visible folder named "Visible Folder"
echo  6. Convert "Visible Folder" back to blank name and transparent icon
echo  7. Choose or change the working parent location
echo  8. Exit
echo.
echo  Options 2-6 use the saved working location selected by option 1 or 7.
echo.
choice /c 12345678 /n /m "Choose an option [1-8]: "

if errorlevel 8 goto END
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

:RUN_ACTION
cls
powershell.exe -NoLogo -NoProfile -Command ^
  "$raw=[IO.File]::ReadAllText($env:IFT_SELF);" ^
  "$marker='# POWERSHELL_SECTION_START';" ^
  "$index=$raw.LastIndexOf($marker);" ^
  "if($index -lt 0){Write-Error 'The embedded PowerShell section is missing.'; exit 1};" ^
  "$script=$raw.Substring($index+$marker.Length);" ^
  "& ([ScriptBlock]::Create($script)) -Action $env:IFT_ACTION"
echo.
pause
goto MENU

:END
endlocal
exit /b 0

# POWERSHELL_SECTION_START
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Create', 'Hide', 'Reveal', 'Open', 'Restore', 'Convert', 'Location')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

$BlankName = [string][char]0x2800
$IconFileName = 'blank.ico'
$DesktopIniName = 'desktop.ini'
$IconBase64 = 'AAABAAIAEBAAAAAAIABLAAAAJgAAACAgAAAAACAAUwAAAHEAAACJUE5HDQoaCgAAAA1JSERSAAAAEAAAABAIBgAAAB/z/2EAAAASSURBVHicY2AYBaNgFIwCCAAABBAAAVU3WtAAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAAaSURBVHic7cEBAQAAAIIg/69uSEABAAAA7wYQIAABGUM07gAAAABJRU5ErkJggg=='
$ConfigRoot = Join-Path $env:LOCALAPPDATA 'InvisibleFolderTool'
$LocationFile = Join-Path $ConfigRoot 'location.txt'
$RestoredFile = Join-Path $ConfigRoot 'last-restored.txt'
$Desktop = [Environment]::GetFolderPath('Desktop')
$AttribExe = Join-Path $env:SystemRoot 'System32\attrib.exe'

function Ensure-ConfigRoot {
    if (-not (Test-Path -LiteralPath $ConfigRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $ConfigRoot -Force | Out-Null
    }
}

function Save-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )

    Ensure-ConfigRoot
    [IO.File]::WriteAllText($Path, $Value)
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

    if (Test-Path -LiteralPath $RestoredFile -PathType Leaf) {
        Remove-Item -LiteralPath $RestoredFile -Force -ErrorAction SilentlyContinue
    }

    Write-Host 'The visible folder was converted back successfully.'
    Write-Host "Parent location: $sourceParent"
    Write-Host 'Its contents were not deleted or moved.'
}

function Change-Location {
    $selected = Select-Location
    Write-Host ''
    Write-Host "Saved working location: $selected"
    Write-Host 'Options 2-6 will now use this parent location.'
    Write-Host 'Changing this setting does not move any existing folder.'
}

try {
    switch ($Action) {
        'Create'  { Create-OrRepair }
        'Hide'    { Hide-InvisibleFolder }
        'Reveal'  { Reveal-InvisibleFolder }
        'Open'    { Open-InvisibleFolder }
        'Restore' { Restore-VisibleFolder }
        'Convert' { Convert-VisibleFolder }
        'Location' { Change-Location }
    }
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
