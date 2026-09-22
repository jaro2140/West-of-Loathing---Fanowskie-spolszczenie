# West of Loathing - Fanowskie spolszczenie
Nieoficjalne spolszczenie gry [**West of Loathing**](https://store.steampowered.com/app/597660/West_of_Loathing/) (Asymmetric Publications).
Potrzebujesz **legalnie posiadanej kopii** gry (Steam lub GOG).

> [!CAUTION]
> **Spolszczenie stworzone we współpracy z AI**

## Po co to jest?
West of Loathing to absurdalny western-RPG z suchym humorem, ale oficjalnie dostępny jest tylko po angielsku. Ten projekt to:
- **Fanowski patch językowy** — polskie dialogi, przedmioty, umiejętności i opisy
- **Otwarte źródła tłumaczeń** — paczki JSON w [`translations/`](translations/)
- **Instalatory** — Linux / SteamOS, macOS, Windows
- **Docelowo przełącznik EN/PL** — na razie patch podmienia pliki


# Status:
- **Pre-release BETA v0.9.1** — osobne patche Linux/Windows, teksty gotowe i wielokrotnie zweryfikowane; od tej wersji gra odmienia zwroty do gracza według płci wybranej postaci; trwają testy w grze


## Skala
- **37 307** unikalnych stringów tekstu — **100% przetłumaczone** (dialogi, przedmioty, umiejętności, opisy, gra główna + DLC *The Reckonin' at Gun Manor*), przejrzane ręcznie w kilku niezależnych rundach jakości.
- **125** grafik menu/UI — **122 przetłumaczone**, 3 wciąż oczekują (lista w release notes).
- **[Eksperymentalnie, Linux/macOS/Windows]** ~65 dodatkowych fraz UI zaszytych w kodzie gry (pasek walki, sklep, karta postaci itd.) tłumaczonych przez opcjonalny plugin BepInEx — patrz opis release'u.


## Roadmap
| Etap | Status |
|------|--------|
| Teksty | ✅ 100% (3. niezależna runda jakości zakończona) |
| Grafiki | ✅ ~98% (3 pozycje w toku) |
| Tekst zaszyty w kodzie gry (UI) | 🔄 przetłumaczony, plugin eksperymentalny (Linux/macOS/Windows) |
| Testy w grze | 🔄 w trakcie |
| Przełącznik EN/PL w grze | ⏳ planowane |
| Pierwszy oficjalny release | ⏳ po testach |


## Instalacja patcha
### Wymagania
1. West of Loathing ze Steam (lub GOG)
2. Najnowsza paczka z zakładki **[Releases](../../releases)** (plik ZIP zawiera już `patches/` + `installers/` + skrypty)

### Szybki start
1. Pobierz najnowsze archiwum ZIP zawierające warianty systemowe i rozpakuj je w całości.
2. Na Linux/SteamOS uruchom terminal w rozpakowanym folderze i wykonaj:

```bash
chmod +x installers/linux/*.sh
./installers/linux/install-pl.sh
```

Na Windows uruchom `installers\windows\install-pl.bat`. Instalator jest napisany
w czystym BAT, nie wymaga PowerShella i instaluje również opcjonalny BepInEx
dla Windows, jeśli paczka zawiera `bepinex/windows/`. Katalog Windows zawiera
dokładnie trzy samodzielne skrypty: instalację, weryfikację i przywracanie; nie
ma dodatkowego `installer.bat`. Po instalacji skrypt wypisuje wykryty plik `.exe`.
Na natywnym Windows opcje uruchamiania Steam powinny pozostać puste; dla wersji
Windows uruchamianej przez Proton skrypt pokaże właściwe `WINEDLLOVERRIDES`.

Paczki dla Linux i Windows nie są zamienne. Instalator sprawdza znacznik platformy
i przerwie działanie, jeśli otrzyma bundle zbudowany dla innego systemu. BETA v0.9.1
zawiera osobne, zweryfikowane statycznie pliki dla obu systemów.
Katalog instalatora macOS jest przygotowany, ale wymaga odrębnych bundli macOS i
nie użyje zastępczo paczki linuksowej.

Jeśli gra nie zostanie znaleziona automatycznie (np. Steam na karcie SD/innej ścieżce), skopiuj `game-path.env.example` jako `game-path.env` i ustaw w nim ścieżkę do `West of Loathing_Data/StreamingAssets`.

Po aktualizacji gry ze Steama uruchom instalator ponownie (Steam nadpisuje
spatchowane pliki). Na Linux weryfikację wykonuje
`./installers/linux/verify-install.sh`, a powrót do angielskiego
`./installers/linux/restore-en.sh`. Na Windows użyj odpowiednich plików `.bat` w
`installers\windows\`.

**Uwaga:** nie kopiuj samego folderu instalatorów bez `patches/` obok — instalator wymaga obu razem w jednym folderze, dokładnie tak jak są spakowane w Releases.

Układ zawartości ZIP-a po rozpakowaniu:

```text
installers/
  common/
  linux/
  macos/
  windows/
patches/
  linux/
  windows/
```


## Tłumaczenia

Źródło prawdy to paczki JSON w [`translations/batches/`](translations/batches/) (scalone w `translations/pl.json`). Uwagi/błędy w tłumaczeniu najlepiej zgłaszać przez Issues — każde zgłoszenie z kontekstem (nazwa questa/postaci, zrzut ekranu) przyspiesza poprawkę.


## Disclaimer
Fanowski projekt **niezwiązany z Asymmetric Publications**.  
West of Loathing jest znakiem towarowym jego właścicieli.  
Gra musi być legalnie zakupiona. Patch nie zawiera plików gry.
