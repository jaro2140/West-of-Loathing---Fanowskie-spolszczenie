@echo off
setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0..\.." >nul 2>&1
if errorlevel 1 (
  echo BLAD: nie mozna ustalic katalogu paczki instalacyjnej.
  exit /b 1
)
set "ROOT=!CD!"
popd
set "BUNDLES=core house main_scene"
set "BEPINEX_REQUIRED_FILES=doorstop_config.ini winhttp.dll BepInEx\core\0Harmony.dll BepInEx\core\0Harmony20.dll BepInEx\core\BepInEx.Harmony.dll BepInEx\core\BepInEx.Preloader.dll BepInEx\core\BepInEx.dll BepInEx\core\HarmonyXInterop.dll BepInEx\core\Mono.Cecil.Mdb.dll BepInEx\core\Mono.Cecil.Pdb.dll BepInEx\core\Mono.Cecil.Rocks.dll BepInEx\core\Mono.Cecil.dll BepInEx\core\MonoMod.RuntimeDetour.dll BepInEx\core\MonoMod.Utils.dll BepInEx\plugins\WestOfLoathingPL.dll"
set "BEPINEX_OPTIONAL_FILES=.doorstop_version changelog.txt"
set "BEPINEX_FILES=!BEPINEX_REQUIRED_FILES! !BEPINEX_OPTIONAL_FILES!"
goto :Install

:Install
call :FindPatches || exit /b 1
call :ValidatePatch || exit /b 1
set "MANIFEST_FILE=!PATCHES!\source-sha256.txt"
call :LoadManifest || exit /b 1
call :FindGame || exit /b 1
call :SetGamePaths

if not exist "!BACKUP!" mkdir "!BACKUP!" || (
  echo BLAD: nie mozna utworzyc backupu: !BACKUP!
  exit /b 1
)

set "LEGACY=!ROOT!\Game_Translate\build\backup\windows"
call :MigrateBackup
set "LEGACY=!ROOT!\Installers\backup\windows"
call :MigrateBackup
set "LEGACY=!ROOT!\backup\windows"
call :MigrateBackup

echo === West of Loathing PL - instalacja Windows ===
echo Gra:    !GAME_STREAMING!
echo Patch:  !PATCHES!
echo Backup: !BACKUP!
echo.

for %%B in (%BUNDLES%) do call :PreflightBundle %%B || exit /b 1

set "COPIED_core="
set "COPIED_house="
set "COPIED_main_scene="
for %%B in (%BUNDLES%) do call :InstallBundle %%B || goto :InstallRollback

copy /y "!PATCHES!\platform.txt" "!BACKUP!\platform.txt" >nul || goto :InstallRollback
copy /y "!PATCHES!\source-sha256.txt" "!BACKUP!\source-sha256.txt" >nul || goto :InstallRollback

echo.
echo --- Plugin BepInEx dla Windows ---
call :InstallBepInEx
if errorlevel 1 (
  echo UWAGA: BepInEx nie zostal zainstalowany. Patch tekstowy jest juz gotowy.
)

echo.
echo Gotowe.
echo Weryfikacja: %~dp0verify-install.bat
echo Przywrocenie EN: %~dp0restore-en.bat
exit /b 0

:InstallRollback
echo BLAD: instalacja nie powiodla sie. Przywracam pliki z backupu...
for %%B in (%BUNDLES%) do call :RollbackBundle %%B
exit /b 1

:Verify
call :FindPatches || exit /b 1
call :ValidatePatch || exit /b 1
call :FindGame || exit /b 1
call :SetGamePaths

echo === Weryfikacja patcha Windows ===
echo Gra: !GAME_STREAMING!
echo.
for %%B in (%BUNDLES%) do call :VerifyBundle %%B
echo.
call :BepInExStatus
exit /b 0

:Restore
call :FindGame || exit /b 1
call :SetGamePaths
call :FindVerifiedBackup || exit /b 1
set "MANIFEST_FILE=!BACKUP!\source-sha256.txt"
call :LoadManifest || exit /b 1

for %%B in (%BUNDLES%) do call :PreflightRestore %%B || exit /b 1

echo === Przywracanie angielskich plikow ===
echo Gra:    !GAME_STREAMING!
echo Backup: !BACKUP!
for %%B in (%BUNDLES%) do call :RestoreBundle %%B || exit /b 1

call :RestoreBepInEx
echo Przywrocono wersje angielska.
exit /b 0

:FindPatches
set "PATCHES="
for %%P in (
  "!ROOT!\Game_Translate\build\patches\windows"
  "!ROOT!\Installers\patches\windows"
  "!ROOT!\patches\windows"
) do if not defined PATCHES if exist "%%~fP\core" set "PATCHES=%%~fP"

if not defined PATCHES (
  echo BLAD: brak patcha Windows. Oczekiwano patches\windows\core.
  exit /b 1
)
exit /b 0

:ValidatePatch
if not exist "!PATCHES!\platform.txt" (
  echo BLAD: brak !PATCHES!\platform.txt.
  echo Instalacja zatrzymana: bundle Linux moze powodowac rozowe grafiki na Windows.
  exit /b 1
)
set "PATCH_PLATFORM="
set /p "PATCH_PLATFORM="<"!PATCHES!\platform.txt"
if /i not "%PATCH_PLATFORM%"=="windows" (
  echo BLAD: patch jest przeznaczony dla platformy "%PATCH_PLATFORM%", nie Windows.
  exit /b 1
)
if not exist "!PATCHES!\source-sha256.txt" (
  echo BLAD: brak manifestu !PATCHES!\source-sha256.txt.
  exit /b 1
)
where certutil.exe >nul 2>&1 || (
  echo BLAD: system nie zawiera certutil.exe potrzebnego do kontroli SHA-256.
  exit /b 1
)
exit /b 0

:LoadManifest
for %%B in (%BUNDLES%) do set "SOURCE_HASH_%%B="
for /f "usebackq tokens=1,2" %%H in ("!MANIFEST_FILE!") do (
  if /i "%%I"=="core" set "SOURCE_HASH_core=%%H"
  if /i "%%I"=="house" set "SOURCE_HASH_house=%%H"
  if /i "%%I"=="main_scene" set "SOURCE_HASH_main_scene=%%H"
)
if not defined SOURCE_HASH_core (
  echo BLAD: manifest !MANIFEST_FILE! nie zawiera sumy pliku core.
  exit /b 1
)
exit /b 0

:FindGame
set "GAME_STREAMING="

if defined WOL_STREAMING (
  set "CONFIGURED=!WOL_STREAMING:"=!"
  set "CANDIDATE=!CONFIGURED!"
  call :ResolveStreaming
)
if defined GAME_STREAMING exit /b 0

if exist "!ROOT!\game-path.env" (
  for /f "usebackq tokens=1,* delims==" %%A in ("!ROOT!\game-path.env") do (
    if /i "%%A"=="WOL_STREAMING" set "CONFIGURED=%%B"
  )
  if defined CONFIGURED (
    set "CONFIGURED=!CONFIGURED:"=!"
    set "CANDIDATE=!CONFIGURED!"
    call :ResolveStreaming
  )
)
if defined GAME_STREAMING exit /b 0

for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul') do (
  set "STEAM_ROOT=%%B"
  call :TrySteamRoot
)
if defined GAME_STREAMING exit /b 0
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Valve\Steam" /v InstallPath 2^>nul') do (
  set "STEAM_ROOT=%%B"
  call :TrySteamRoot
)
if defined GAME_STREAMING exit /b 0
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul') do (
  set "STEAM_ROOT=%%B"
  call :TrySteamRoot
)
if defined GAME_STREAMING exit /b 0

if defined ProgramFiles (
  set "STEAM_ROOT=!ProgramFiles!\Steam"
  call :TrySteamRoot
)
if defined GAME_STREAMING exit /b 0

for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%D:\" (
  set "CANDIDATE=%%D:\SteamLibrary\steamapps\common\West of Loathing"
  call :ResolveStreaming
  if not defined GAME_STREAMING set "CANDIDATE=%%D:\Steam\steamapps\common\West of Loathing"
  if not defined GAME_STREAMING call :ResolveStreaming
  if not defined GAME_STREAMING set "CANDIDATE=%%D:\GOG Games\West of Loathing"
  if not defined GAME_STREAMING call :ResolveStreaming
)
if defined GAME_STREAMING exit /b 0

echo Nie znaleziono gry automatycznie.
set "MANUAL_PATH="
set /p "MANUAL_PATH=Wklej sciezke do gry lub StreamingAssets (Enter = anuluj): "
if defined MANUAL_PATH (
  set "CANDIDATE=!MANUAL_PATH!"
  call :ResolveStreaming
)
if not defined GAME_STREAMING (
  echo BLAD: nie znaleziono West of Loathing_Data\StreamingAssets\core.
  echo Ustaw WOL_STREAMING w game-path.env obok katalogow installers i patches.
  exit /b 1
)
exit /b 0

:TrySteamRoot
if not defined STEAM_ROOT exit /b 0
set "STEAM_ROOT=!STEAM_ROOT:/=\!"
set "CANDIDATE=!STEAM_ROOT!\steamapps\common\West of Loathing"
call :ResolveStreaming
if defined GAME_STREAMING exit /b 0

set "VDF=!STEAM_ROOT!\steamapps\libraryfolders.vdf"
if not exist "!VDF!" exit /b 0
for /f "usebackq tokens=*" %%L in ("!VDF!") do (
  set "VDF_LINE=%%L"
  for /f tokens^=2^,4^ delims^=^" %%A in ("!VDF_LINE!") do if not "%%B"=="" (
    set "LIBRARY=%%B"
    set "LIBRARY=!LIBRARY:\\=\!"
    set "CANDIDATE=!LIBRARY!\steamapps\common\West of Loathing"
    call :ResolveStreaming
  )
)
exit /b 0

:ResolveStreaming
if defined GAME_STREAMING exit /b 0
set "CANDIDATE=!CANDIDATE:"=!"
if not defined CANDIDATE exit /b 0

if exist "!CANDIDATE!" for %%I in ("!CANDIDATE!") do if /i "%%~xI"==".exe" set "CANDIDATE=%%~dpI"
for %%I in ("!CANDIDATE!") do set "CANDIDATE=%%~fI"

for %%P in (
  "!CANDIDATE!"
  "!CANDIDATE!\StreamingAssets"
  "!CANDIDATE!\West of Loathing_Data\StreamingAssets"
) do if not defined GAME_STREAMING if exist "%%~fP\core" set "GAME_STREAMING=%%~fP"
exit /b 0

:SetGamePaths
for %%I in ("!GAME_STREAMING!\..\..") do set "GAME_ROOT=%%~fI"
set "BACKUP=!GAME_ROOT!\.wol_pl_backup"
exit /b 0

:GetHash
set "FILE_HASH="
for /f "skip=1 delims=" %%H in ('certutil.exe -hashfile "!HASH_FILE!" SHA256 2^>nul') do if not defined FILE_HASH set "FILE_HASH=%%H"
set "FILE_HASH=!FILE_HASH: =!"
if not defined FILE_HASH (
  echo BLAD: nie mozna obliczyc SHA-256 pliku !HASH_FILE!.
  exit /b 1
)
exit /b 0

:MigrateBackup
if not exist "!LEGACY!" exit /b 0
for %%I in ("!LEGACY!") do set "LEGACY=%%~fI"
if /i "!LEGACY!"=="!BACKUP!" exit /b 0
for %%B in (%BUNDLES%) do call :MigrateBackupFile %%B
exit /b 0

:MigrateBackupFile
set "NAME=%~1"
if not exist "!LEGACY!\%NAME%" exit /b 0
if exist "!BACKUP!\%NAME%" exit /b 0
call set "EXPECTED=%%SOURCE_HASH_%NAME%%%"
if not defined EXPECTED exit /b 0
set "HASH_FILE=!LEGACY!\%NAME%"
call :GetHash || exit /b 0
if /i not "!FILE_HASH!"=="!EXPECTED!" exit /b 0
copy /y "!LEGACY!\%NAME%" "!BACKUP!\%NAME%" >nul
echo   migracja starego backupu: %NAME%
exit /b 0

:PreflightBundle
set "NAME=%~1"
if not exist "!PATCHES!\%NAME%" (
  echo   pomijam %NAME% ^(brak w patchu^)
  exit /b 0
)
call set "EXPECTED=%%SOURCE_HASH_%NAME%%%"
if not defined EXPECTED (
  echo BLAD: manifest nie zawiera sumy oryginalnego pliku %NAME%.
  exit /b 1
)
if not exist "!GAME_STREAMING!\%NAME%" (
  echo BLAD: brak pliku gry !GAME_STREAMING!\%NAME%.
  exit /b 1
)

set "HASH_FILE=!PATCHES!\%NAME%"
call :GetHash || exit /b 1
set "PATCH_HASH=!FILE_HASH!"
set "HASH_FILE=!GAME_STREAMING!\%NAME%"
call :GetHash || exit /b 1
set "TARGET_HASH=!FILE_HASH!"

if /i "!TARGET_HASH!"=="!PATCH_HASH!" (
  if not exist "!BACKUP!\%NAME%" (
    echo BLAD: %NAME% jest juz podmieniony, ale brakuje poprawnego backupu Windows.
    echo Przywroc pliki przez Steam przed ponowna instalacja.
    exit /b 1
  )
  set "HASH_FILE=!BACKUP!\%NAME%"
  call :GetHash || exit /b 1
  if /i not "!FILE_HASH!"=="!EXPECTED!" (
    echo BLAD: backup %NAME% nie jest zgodny z oryginalem Windows.
    exit /b 1
  )
  exit /b 0
)

if /i not "!TARGET_HASH!"=="!EXPECTED!" (
  echo BLAD: plik gry %NAME% nie pasuje do wersji patcha Windows.
  echo W Steam wybierz Wlasciwosci - Zainstalowane pliki - Sprawdz spojnosc plikow.
  exit /b 1
)

if exist "!BACKUP!\%NAME%" (
  set "HASH_FILE=!BACKUP!\%NAME%"
  call :GetHash || exit /b 1
  if /i not "!FILE_HASH!"=="!EXPECTED!" (
    echo BLAD: istniejacy backup %NAME% nie jest poprawnym oryginalem Windows.
    exit /b 1
  )
)
exit /b 0

:InstallBundle
set "NAME=%~1"
if not exist "!PATCHES!\%NAME%" exit /b 0
set "HASH_FILE=!PATCHES!\%NAME%"
call :GetHash || exit /b 1
set "PATCH_HASH=!FILE_HASH!"
set "HASH_FILE=!GAME_STREAMING!\%NAME%"
call :GetHash || exit /b 1
if /i "!FILE_HASH!"=="!PATCH_HASH!" (
  echo   %NAME%: juz zainstalowany
  exit /b 0
)

if not exist "!BACKUP!\%NAME%" (
  copy /y "!GAME_STREAMING!\%NAME%" "!BACKUP!\%NAME%" >nul || exit /b 1
  echo   backup: %NAME%
)
set "COPIED_%NAME%=1"
copy /y "!PATCHES!\%NAME%" "!GAME_STREAMING!\%NAME%" >nul || exit /b 1
set "HASH_FILE=!GAME_STREAMING!\%NAME%"
call :GetHash || exit /b 1
if /i not "!FILE_HASH!"=="!PATCH_HASH!" (
  echo BLAD: weryfikacja po kopiowaniu nie powiodla sie: %NAME%.
  exit /b 1
)
echo   zainstalowano: %NAME%
exit /b 0

:RollbackBundle
set "NAME=%~1"
call set "WAS_COPIED=%%COPIED_%NAME%%%"
if defined WAS_COPIED if exist "!BACKUP!\%NAME%" copy /y "!BACKUP!\%NAME%" "!GAME_STREAMING!\%NAME%" >nul
exit /b 0

:VerifyBundle
set "NAME=%~1"
if not exist "!PATCHES!\%NAME%" (
  echo   %NAME%: brak w patchu
  exit /b 0
)
if not exist "!GAME_STREAMING!\%NAME%" (
  echo   %NAME%: brak pliku w grze
  exit /b 0
)
set "HASH_FILE=!PATCHES!\%NAME%"
call :GetHash || exit /b 0
set "PATCH_HASH=!FILE_HASH!"
set "HASH_FILE=!GAME_STREAMING!\%NAME%"
call :GetHash || exit /b 0
if /i "!FILE_HASH!"=="!PATCH_HASH!" (
  echo   %NAME%: ZAINSTALOWANY
) else (
  echo   %NAME%: NIE zainstalowany
)
exit /b 0

:FindVerifiedBackup
set "BACKUP="
set "BACKUP_CANDIDATE=!GAME_ROOT!\.wol_pl_backup"
call :TryBackup
set "BACKUP_CANDIDATE=!ROOT!\Game_Translate\build\backup\windows"
call :TryBackup
set "BACKUP_CANDIDATE=!ROOT!\Installers\backup\windows"
call :TryBackup
set "BACKUP_CANDIDATE=!ROOT!\backup\windows"
call :TryBackup
if not defined BACKUP (
  echo BLAD: brak zweryfikowanego backupu Windows.
  echo Przywroc oryginaly przez Steam: Wlasciwosci - Zainstalowane pliki - Sprawdz spojnosc.
  exit /b 1
)
exit /b 0

:TryBackup
if defined BACKUP exit /b 0
if not exist "!BACKUP_CANDIDATE!\core" exit /b 0
if not exist "!BACKUP_CANDIDATE!\platform.txt" exit /b 0
if not exist "!BACKUP_CANDIDATE!\source-sha256.txt" exit /b 0
set "BACKUP_PLATFORM="
set /p "BACKUP_PLATFORM="<"!BACKUP_CANDIDATE!\platform.txt"
if /i "!BACKUP_PLATFORM!"=="windows" for %%I in ("!BACKUP_CANDIDATE!") do set "BACKUP=%%~fI"
exit /b 0

:PreflightRestore
set "NAME=%~1"
call set "EXPECTED=%%SOURCE_HASH_%NAME%%%"
if not defined EXPECTED exit /b 0
if not exist "!BACKUP!\%NAME%" (
  echo BLAD: brak pliku backupu !BACKUP!\%NAME%.
  exit /b 1
)
set "HASH_FILE=!BACKUP!\%NAME%"
call :GetHash || exit /b 1
if /i not "!FILE_HASH!"=="!EXPECTED!" (
  echo BLAD: backup %NAME% nie przeszedl kontroli SHA-256.
  exit /b 1
)
exit /b 0

:RestoreBundle
set "NAME=%~1"
call set "EXPECTED=%%SOURCE_HASH_%NAME%%%"
if not defined EXPECTED exit /b 0
copy /y "!BACKUP!\%NAME%" "!GAME_STREAMING!\%NAME%" >nul || exit /b 1
echo   przywrocono: %NAME%
exit /b 0

:FindBepInExBundle
set "BEPINEX_BUNDLE="
if exist "!ROOT!\Game_Translate\build\bepinex\windows\winhttp.dll" set "BEPINEX_BUNDLE=!ROOT!\Game_Translate\build\bepinex\windows"
if not defined BEPINEX_BUNDLE if exist "!ROOT!\bepinex\windows\winhttp.dll" set "BEPINEX_BUNDLE=!ROOT!\bepinex\windows"
exit /b 0

:InstallBepInEx
call :FindBepInExBundle
if not defined BEPINEX_BUNDLE (
  echo Pomijam - paczka nie zawiera BepInEx dla Windows.
  exit /b 0
)

set "BEPINEX_MANIFEST=!BACKUP!\bepinex_manifest.txt"
if exist "!GAME_ROOT!\BepInEx" if not exist "!BEPINEX_MANIFEST!" (
  if not exist "!GAME_ROOT!\BepInEx\plugins\WestOfLoathingPL.dll" (
    echo BLAD: wykryto obca instalacje BepInEx bez manifestu tego instalatora.
    echo Nie nadpisuje cudzych modow. Patch tekstowy pozostaje zainstalowany.
    exit /b 1
  )
  set "HASH_FILE=!BEPINEX_BUNDLE!\BepInEx\plugins\WestOfLoathingPL.dll"
  call :GetHash || exit /b 1
  set "EXPECTED_PLUGIN_HASH=!FILE_HASH!"
  set "HASH_FILE=!GAME_ROOT!\BepInEx\plugins\WestOfLoathingPL.dll"
  call :GetHash || exit /b 1
  if /i not "!FILE_HASH!"=="!EXPECTED_PLUGIN_HASH!" (
    echo BLAD: wykryto inny lub zmodyfikowany plugin WestOfLoathingPL.dll.
    echo Nie nadpisuje instalacji bez manifestu tego instalatora.
    exit /b 1
  )
  echo   wykryto nasz plugin bez manifestu - odtwarzam manifest.
)

if not exist "!GAME_ROOT!\BepInEx" if not exist "!BEPINEX_MANIFEST!" (
  for %%R in (!BEPINEX_FILES!) do (
    if exist "!BEPINEX_BUNDLE!\%%R" if exist "!GAME_ROOT!\%%R" (
      echo BLAD: plik !GAME_ROOT!\%%R juz istnieje i nie nalezy do tego instalatora.
      exit /b 1
    )
  )
)

for %%R in (!BEPINEX_REQUIRED_FILES!) do if not exist "!BEPINEX_BUNDLE!\%%R" (
  echo BLAD: niekompletna paczka BepInEx - brak wymaganego pliku %%R.
  exit /b 1
)
where xcopy.exe >nul 2>&1 || (
  echo BLAD: system nie zawiera xcopy.exe potrzebnego do instalacji BepInEx.
  exit /b 1
)

if not exist "!BACKUP!" mkdir "!BACKUP!" || exit /b 1
if not exist "!BEPINEX_MANIFEST!" type nul >"!BEPINEX_MANIFEST!"
set /a BEPINEX_COUNT=0
for %%R in (!BEPINEX_FILES!) do (
  if exist "!BEPINEX_BUNDLE!\%%R" (
    findstr /x /l /c:"%%R" "!BEPINEX_MANIFEST!" >nul 2>&1 || echo %%R>>"!BEPINEX_MANIFEST!"
    set /a BEPINEX_COUNT+=1
  )
)

xcopy "!BEPINEX_BUNDLE!\*" "!GAME_ROOT!" /E /H /I /R /V /Y /Q >nul
set "XCOPY_EXIT=!ERRORLEVEL!"
if not "!XCOPY_EXIT!"=="0" (
  echo BLAD: xcopy nie skopiowal paczki BepInEx ^(kod !XCOPY_EXIT!^).
  echo Manifest pozostawiono, aby restore-en.bat mogl bezpiecznie usunac czesciowa instalacje.
  exit /b 1
)

for %%R in (!BEPINEX_REQUIRED_FILES!) do (
  if not exist "!GAME_ROOT!\%%R" (
    echo BLAD: po kopiowaniu nadal brakuje wymaganego pliku %%R.
    exit /b 1
  )
  set "HASH_FILE=!BEPINEX_BUNDLE!\%%R"
  call :GetHash || exit /b 1
  set "EXPECTED_BEPINEX_HASH=!FILE_HASH!"
  set "HASH_FILE=!GAME_ROOT!\%%R"
  call :GetHash || exit /b 1
  if /i not "!FILE_HASH!"=="!EXPECTED_BEPINEX_HASH!" (
    echo BLAD: plik %%R rozni sie po kopiowaniu.
    exit /b 1
  )
)

echo   BepInEx Windows: zainstalowano i sprawdzono !BEPINEX_COUNT! plikow.
echo   Plugin uruchomi sie automatycznie przez winhttp.dll przy starcie gry.
call :PrintBepInExLaunchInfo
exit /b 0

:DetectWindowsExecutable
set "GAME_EXECUTABLE="
set "CONFIGURED_EXE="

if defined WOL_WINDOWS_EXECUTABLE set "CONFIGURED_EXE=!WOL_WINDOWS_EXECUTABLE:"=!"
if not defined CONFIGURED_EXE if exist "!ROOT!\game-path.env" (
  for /f "usebackq tokens=1,* delims==" %%A in ("!ROOT!\game-path.env") do (
    if /i "%%A"=="WOL_WINDOWS_EXECUTABLE" set "CONFIGURED_EXE=%%B"
  )
  if defined CONFIGURED_EXE set "CONFIGURED_EXE=!CONFIGURED_EXE:"=!"
)

if defined CONFIGURED_EXE if exist "!CONFIGURED_EXE!" (
  for %%E in ("!CONFIGURED_EXE!") do (
    set "EXE_DIR=%%~dpE"
    if /i "%%~xE"==".exe" if /i "!EXE_DIR!"=="!GAME_ROOT!\" set "GAME_EXECUTABLE=%%~fE"
  )
)
if defined GAME_EXECUTABLE exit /b 0

if exist "!GAME_ROOT!\West of Loathing.exe" (
  set "GAME_EXECUTABLE=!GAME_ROOT!\West of Loathing.exe"
  exit /b 0
)

set "DATA_DIR_NAME="
for %%D in ("!GAME_STREAMING!\..") do set "DATA_DIR_NAME=%%~nxD"
if defined DATA_DIR_NAME (
  set "DERIVED_EXE_NAME=!DATA_DIR_NAME:_Data=.exe!"
  if exist "!GAME_ROOT!\!DERIVED_EXE_NAME!" (
    set "GAME_EXECUTABLE=!GAME_ROOT!\!DERIVED_EXE_NAME!"
    exit /b 0
  )
)

set /a EXE_CANDIDATE_COUNT=0
set "EXE_CANDIDATE="
for %%E in ("!GAME_ROOT!\*.exe") do if exist "%%~fE" if /i not "%%~nxE"=="UnityCrashHandler64.exe" (
  set /a EXE_CANDIDATE_COUNT+=1
  set "EXE_CANDIDATE=%%~fE"
)
if !EXE_CANDIDATE_COUNT! EQU 1 set "GAME_EXECUTABLE=!EXE_CANDIDATE!"
exit /b 0

:PrintBepInExLaunchInfo
call :DetectWindowsExecutable
if defined GAME_EXECUTABLE (
  echo   Wykryty plik wykonywalny: !GAME_EXECUTABLE!
  echo   Steam na Windows: uruchom gre normalnie. Opcje uruchamiania pozostaw puste.
  exit /b 0
)

echo.
echo UWAGA: BepInEx zostal skopiowany, ale nie wykryto pliku wykonywalnego gry.
echo Plik winhttp.dll musi znajdowac sie obok rzeczywistego pliku .exe gry.
echo W Steam wybierz: Wlasciwosci - Zainstalowane pliki - Przegladaj.
echo Na natywnym Windows pozostaw pole Opcje uruchamiania puste.
echo Jezeli uruchamiasz wersje Windows przez Proton/SteamOS, ustaw w Steam:
echo.
echo   WINEDLLOVERRIDES="winhttp.dll=n,b" %%command%%
echo.
echo Opcjonalnie ustaw WOL_WINDOWS_EXECUTABLE w game-path.env i uruchom instalator ponownie.
exit /b 0

:BepInExStatus
set "BEPINEX_MANIFEST=!BACKUP!\bepinex_manifest.txt"
if exist "!BEPINEX_MANIFEST!" (
  set /a BEPINEX_MISSING=0
  for /f "usebackq delims=" %%R in ("!BEPINEX_MANIFEST!") do if not exist "!GAME_ROOT!\%%R" set /a BEPINEX_MISSING+=1
  if !BEPINEX_MISSING! EQU 0 (
    echo BepInEx Windows: ZAINSTALOWANY
    call :DetectWindowsExecutable
    if defined GAME_EXECUTABLE (
      echo Plik wykonywalny: !GAME_EXECUTABLE!
    ) else (
      echo UWAGA: nie wykryto pliku wykonywalnego gry obok winhttp.dll.
    )
  ) else (
    echo BepInEx Windows: NIEKOMPLETNY - brak !BEPINEX_MISSING! plikow
  )
  exit /b 0
)
if exist "!GAME_ROOT!\BepInEx" (
  echo BepInEx Windows: wykryty, ale bez manifestu tego instalatora
) else (
  echo BepInEx Windows: NIE zainstalowany
)
exit /b 0

:RestoreBepInEx
set "BEPINEX_MANIFEST=!BACKUP!\bepinex_manifest.txt"
if not exist "!BEPINEX_MANIFEST!" (
  echo BepInEx: brak manifestu - nic do cofniecia.
  exit /b 0
)
for /f "usebackq delims=" %%R in ("!BEPINEX_MANIFEST!") do if exist "!GAME_ROOT!\%%R" del /f /q "!GAME_ROOT!\%%R" >nul 2>&1
for /f "delims=" %%D in ('dir /ad /b /s "!GAME_ROOT!\BepInEx" 2^>nul ^| sort /r') do rd "%%D" >nul 2>&1
rd "!GAME_ROOT!\BepInEx" >nul 2>&1
del /f /q "!BEPINEX_MANIFEST!" >nul 2>&1
echo BepInEx Windows: usunieto pliki nalezace do tego instalatora.
exit /b 0
