@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0..\..\"
set "PATCHES=%ROOT%patches"
if exist "%ROOT%Game_Translate\build\patches\core" set "PATCHES=%ROOT%Game_Translate\build\patches"

echo === Weryfikacja patcha (Windows) ===

if not exist "%PATCHES%\core" (
  echo Brak patches\core
  exit /b 1
)

set "GAME_STREAMING="
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
  echo Nie znaleziono gry. Ustaw WOL_STREAMING w game-path.env
  exit /b 1
)

echo Gra: %GAME_STREAMING%
echo.

for %%B in (core house main_scene) do (
  if exist "%PATCHES%\%%B" (
    if exist "!GAME_STREAMING!\%%B" (
      fc /b "%PATCHES%\%%B" "!GAME_STREAMING!\%%B" >nul 2>&1
      if errorlevel 1 (
        echo   %%B: NIE zainstalowany
      ) else (
        echo   %%B: ZAINSTALOWANY
      )
    ) else (
      echo   %%B: brak pliku w grze
    )
  ) else (
    echo   %%B: brak w patches/
  )
)
