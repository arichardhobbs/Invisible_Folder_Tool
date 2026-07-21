@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Invisible Folder Tool

rem Creates one invisible-looking folder on the current user's Desktop.
rem The folder name is Unicode U+2800 (Braille Pattern Blank).
rem Its icon is a fully transparent ICO file.
rem No user files are deleted by this tool.

set "ICON_B64=AAABAAIAEBAAAAAAIABLAAAAJgAAACAgAAAAACAAUwAAAHEAAACJUE5HDQoaCgAAAA1JSERSAAAAEAAAABAIBgAAAB/z/2EAAAASSURBVHicY2AYBaNgFIwCCAAABBAAAVU3WtAAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAAaSURBVHic7cEBAQAAAIIg/69uSEABAAAA7wYQIAABGUM07gAAAABJRU5ErkJggg=="

:MENU
cls
echo ==================================================
echo              Invisible Folder Tool
echo ==================================================
echo.
echo  1. Create or repair the invisible-looking folder
echo  2. Hide the folder completely
echo  3. Reveal it as an invisible-looking desktop folder
echo  4. Open the folder
echo  5. Restore it to a normal visible folder
echo  6. Exit
echo.
choice /c 123456 /n /m "Choose an option [1-6]: "

if errorlevel 6 goto :EOF
if errorlevel 5 goto RESTORE
if errorlevel 4 goto OPENFOLDER
if errorlevel 3 goto REVEAL
if errorlevel 2 goto HIDE
if errorlevel 1 goto CREATE
goto MENU

:CREATE
cls
echo Creating the invisible-looking folder...
powershell.exe -NoLogo -NoProfile -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$desktop=[Environment]::GetFolderPath('Desktop');" ^
  "$target=Join-Path $desktop ([string][char]0x2800);" ^
  "if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target | Out-Null };" ^
  "$icon=Join-Path $target 'blank.ico';" ^
  "[IO.File]::WriteAllBytes($icon,[Convert]::FromBase64String('%ICON_B64%'));" ^
  "$ini=Join-Path $target 'desktop.ini';" ^
  "[IO.File]::WriteAllLines($ini,@('[.ShellClassInfo]','IconResource=blank.ico,0','ConfirmFileOp=0'),[Text.Encoding]::Unicode);" ^
  "attrib.exe +h +s $icon | Out-Null;" ^
  "attrib.exe +h +s $ini | Out-Null;" ^
  "attrib.exe -h -s +r $target | Out-Null;" ^
  "(Get-Item -LiteralPath $target).LastWriteTime=Get-Date;" ^
  "$refresh=Join-Path $env:SystemRoot 'System32\ie4uinit.exe';" ^
  "if (Test-Path -LiteralPath $refresh) { Start-Process -FilePath $refresh -ArgumentList '-show' -WindowStyle Hidden -ErrorAction SilentlyContinue };" ^
  "Write-Host 'Done. A blank clickable area now represents the folder on your Desktop.'"
if errorlevel 1 echo ERROR: The folder could not be created or customized.
echo.
pause
goto MENU

:HIDE
cls
powershell.exe -NoLogo -NoProfile -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$target=Join-Path ([Environment]::GetFolderPath('Desktop')) ([string][char]0x2800);" ^
  "if (-not (Test-Path -LiteralPath $target)) { throw 'The invisible folder does not exist yet.' };" ^
  "attrib.exe +h +s $target | Out-Null;" ^
  "Write-Host 'The folder is now completely hidden.'"
if errorlevel 1 echo ERROR: Create the folder first by choosing option 1.
echo.
pause
goto MENU

:REVEAL
cls
powershell.exe -NoLogo -NoProfile -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$target=Join-Path ([Environment]::GetFolderPath('Desktop')) ([string][char]0x2800);" ^
  "if (-not (Test-Path -LiteralPath $target)) { throw 'The invisible folder does not exist yet.' };" ^
  "attrib.exe -h -s +r $target | Out-Null;" ^
  "(Get-Item -LiteralPath $target).LastWriteTime=Get-Date;" ^
  "$refresh=Join-Path $env:SystemRoot 'System32\ie4uinit.exe';" ^
  "if (Test-Path -LiteralPath $refresh) { Start-Process -FilePath $refresh -ArgumentList '-show' -WindowStyle Hidden -ErrorAction SilentlyContinue };" ^
  "Write-Host 'The invisible-looking folder is visible again as a blank desktop area.'"
if errorlevel 1 echo ERROR: Create the folder first by choosing option 1.
echo.
pause
goto MENU

:OPENFOLDER
cls
powershell.exe -NoLogo -NoProfile -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$target=Join-Path ([Environment]::GetFolderPath('Desktop')) ([string][char]0x2800);" ^
  "if (-not (Test-Path -LiteralPath $target)) { throw 'The invisible folder does not exist yet.' };" ^
  "Invoke-Item -LiteralPath $target"
if errorlevel 1 echo ERROR: Create the folder first by choosing option 1.
goto MENU

:RESTORE
cls
echo Restoring the folder to a normal visible folder...
powershell.exe -NoLogo -NoProfile -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$desktop=[Environment]::GetFolderPath('Desktop');" ^
  "$target=Join-Path $desktop ([string][char]0x2800);" ^
  "if (-not (Test-Path -LiteralPath $target)) { throw 'The invisible folder does not exist yet.' };" ^
  "attrib.exe -h -s -r $target | Out-Null;" ^
  "$ini=Join-Path $target 'desktop.ini';" ^
  "$icon=Join-Path $target 'blank.ico';" ^
  "if (Test-Path -LiteralPath $ini) { attrib.exe -h -s $ini | Out-Null; Remove-Item -LiteralPath $ini -Force };" ^
  "if (Test-Path -LiteralPath $icon) { attrib.exe -h -s $icon | Out-Null; Remove-Item -LiteralPath $icon -Force };" ^
  "$base='Visible Folder'; $newName=$base; $number=2;" ^
  "while (Test-Path -LiteralPath (Join-Path $desktop $newName)) { $newName=$base+' '+$number; $number++ };" ^
  "Rename-Item -LiteralPath $target -NewName $newName;" ^
  "$refresh=Join-Path $env:SystemRoot 'System32\ie4uinit.exe';" ^
  "if (Test-Path -LiteralPath $refresh) { Start-Process -FilePath $refresh -ArgumentList '-show' -WindowStyle Hidden -ErrorAction SilentlyContinue };" ^
  "Write-Host ('Restored as: '+(Join-Path $desktop $newName))"
if errorlevel 1 echo ERROR: The invisible folder could not be restored.
echo.
pause
goto MENU
