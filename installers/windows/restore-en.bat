@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0..\..\"
set "BACKUP=%ROOT%backup"
set "ORIGINAL_STREAMING=%ROOT%original\StreamingAssets"
if exist "%ROOT%Game_Translate\build\patches\core" (
  set "BACKUP=%ROOT%Game_Translate\build\backup"
  set "ORIGINAL_STREAMING=%ROOT%Game\original\StreamingAssets"
)

set "GAME_STREAMING="
if defined WOL_STREAMING set "GAME_STREAMING=%WOL_STREAMING%"
if not defined GAME_STREAMING (
  if exist "%ProgramFiles(x86)%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets" (
    set "GAME_STREAMING=%ProgramFiles(x86)%\Steam\steamapps\common\West of Loathing\West of Loathing_Data\StreamingAssets"
  )
)

if not exist "%BACKUP%\core" (
  if exist "%ORIGINAL_STREAMING%\core" set "BACKUP=%ORIGINAL_STREAMING%"
)

if not exist "%BACKUP%\core" (
  echo Brak backup. Steam: Zweryfikuj pliki gry.
  exit /b 1
)

call :restore core
call :restore house
call :restore main_scene
echo Przywrocono angielski.
exit /b 0

:restore
set "NAME=%~1"
if exist "%BACKUP%\%NAME%" (
  copy /y "%BACKUP%\%NAME%" "!GAME_STREAMING!\%NAME%" >nul
  echo   przywrocono: %NAME%
)
goto :eof
