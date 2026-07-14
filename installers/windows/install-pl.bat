@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0..\..\"
set "PATCHES=%ROOT%patches"
set "BACKUP=%ROOT%backup"
if exist "%ROOT%Game_Translate\build\patches\core" (
  set "PATCHES=%ROOT%Game_Translate\build\patches"
  set "BACKUP=%ROOT%Game_Translate\build\backup"
)

if not exist "%PATCHES%\core" (
  echo Blad: brak patches\core — pobierz najnowszy release i wypakuj obok tego pliku
  exit /b 1
)

set "GAME_STREAMING="

if exist "%ROOT%game-path.env" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%ROOT%game-path.env") do (
    if /i "%%A"=="WOL_STREAMING" set "GAME_STREAMING=%%B"
  )
)

if defined WOL_STREAMING set "GAME_STREAMING=%WOL_STREAMING%"

if not defined GAME_STREAMING (
  if exist "%ProgramFiles(x86)%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets" (
    set "GAME_STREAMING=%ProgramFiles(x86)%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets"
  )
)
if not defined GAME_STREAMING (
  if exist "%ProgramFiles%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets" (
    set "GAME_STREAMING=%ProgramFiles%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets"
  )
)

if not defined GAME_STREAMING (
  echo Nie znaleziono gry. Utworz game-path.env w katalogu projektu.
  exit /b 1
)

echo Gra:   !GAME_STREAMING!
echo Patch: %PATCHES%
if not exist "%BACKUP%" mkdir "%BACKUP%"

echo Bundle do instalacji:
for %%B in (core house main_scene) do (
  if exist "%PATCHES%\%%B" (
    echo   + %%B
  ) else (
    echo   - %%B ^(brak w patches/^)
  )
)
echo.

call :install core
call :install house
call :install main_scene
echo Gotowe.
exit /b 0

:install
set "NAME=%~1"
if not exist "%PATCHES%\%NAME%" (
  echo   pomijam %NAME%
  goto :eof
)
if not exist "!GAME_STREAMING!\%NAME%" (
  echo   blad: brak oryginalu !GAME_STREAMING!\%NAME%
  exit /b 1
)
if not exist "%BACKUP%\%NAME%" (
  copy /y "!GAME_STREAMING!\%NAME%" "%BACKUP%\%NAME%" >nul
  echo   backup: %NAME%
)
copy /y "%PATCHES%\%NAME%" "!GAME_STREAMING!\%NAME%" >nul
echo   zainstalowano: %NAME%
goto :eof
