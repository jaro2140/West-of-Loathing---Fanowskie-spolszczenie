# West of Loathing - Fanowskie spolszczenie
Nieoficjalne spolszczenie gry [**West of Loathing**](https://store.steampowered.com/app/597660/West_of_Loathing/) (Asymmetric Publications).
Potrzebujesz **legalnie posiadanej kopii** gry (Steam lub GOG).


## Po co to jest?
West of Loathing to absurdalny western-RPG z suchym humorem, ale oficjalnie dostępny jest tylko po angielsku. Ten projekt to:
- **Fanowski patch językowy** — polskie dialogi, przedmioty, umiejętności i opisy
- **Otwarte źródła tłumaczeń** — paczki JSON w [`translations/`](translations/)
- **Instalatory** — Linux / SteamOS, macOS, Windows
- **Docelowo przełącznik EN/PL** — na razie patch podmienia pliki


# Status:
- **Pre-release BETA** — teksty gotowe, patch w fazie testów w grze przed pierwszym oficjalnym wydaniem


## Skala
- **36 692** unikalnych stringów tekstu — **100% przetłumaczone** (dialogi, przedmioty, umiejętności, opisy, gra główna + DLC *The Reckonin' at Gun Manor*).
- **125** grafik menu/UI — **122 przetłumaczone**, 3 wciąż oczekują (lista w release notes).


## Roadmap
| Etap | Status |
|------|--------|
| Teksty | ✅ 100% |
| Grafiki | ✅ ~98% (3 pozycje w toku) |
| Testy w grze | 🔄 w trakcie |
| Przełącznik EN/PL w grze | ⏳ planowane |
| Pierwszy oficjalny release | ⏳ po testach |


## Instalacja patcha
### Wymagania
1. West of Loathing ze Steam (lub GOG)
2. Najnowsza paczka z zakładki **[Releases](../../releases)** (plik ZIP zawiera już `patches/` + `installers/` + skrypty)

### Szybki start
1. Pobierz i rozpakuj paczkę z *Releases* — całość (patches, installers, install-pl.sh...) jest już w jednym folderze.
2. Uruchom terminal w tym folderze i wykonaj:

```bash
chmod +x install-pl.sh restore-en.sh verify-install.sh
./install-pl.sh
```

Na Windows uruchom `installers\windows\install-pl.bat`.

Jeśli gra nie zostanie znaleziona automatycznie (np. Steam na karcie SD/innej ścieżce), skopiuj `game-path.env.example` jako `game-path.env` i ustaw w nim ścieżkę do `West of Loathing_Data/StreamingAssets`.

Po aktualizacji gry ze Steama uruchom instalator ponownie (Steam nadpisuje spatchowane pliki). Weryfikacja: `./verify-install.sh`. Powrót do angielskiego: `./restore-en.sh`.

**Uwaga:** nie kopiuj samego folderu instalatorów bez `patches/` obok — instalator wymaga obu razem w jednym folderze, dokładnie tak jak są spakowane w Releases.


## Tłumaczenia

Źródło prawdy to paczki JSON w [`translations/batches/`](translations/batches/) (scalone w `translations/pl.json`). Uwagi/błędy w tłumaczeniu najlepiej zgłaszać przez Issues — każde zgłoszenie z kontekstem (nazwa questa/postaci, zrzut ekranu) przyspiesza poprawkę.


## Disclaimer
Fanowski projekt **niezwiązany z Asymmetric Publications**.  
West of Loathing jest znakiem towarowym jego właścicieli.  
Gra musi być legalnie zakupiona. Patch nie zawiera plików gry.
