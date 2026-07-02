# West of Loathing - Fanowskie spolszczenie
Nieoficjalne spolszczenie gry [**West of Loathing**](https://store.steampowered.com/app/597660/West_of_Loathing/) (Asymmetric Publications).
Potrzebujesz **legalnie posiadanej kopii** gry (Steam lub GOG).


## Po co to jest?
West of Loathing to absurdalny western-RPG z suchym humorem, ale oficjalnie dostępny jest tylko po angielsku. Ten projekt to:
- **Fanowski patch językowy** — polskie dialogi, przedmioty, umiejętności i opisy
- **Otwarte źródła tłumaczeń** — paczki JSON w repozytorium
- **Instalatory** — Linux / SteamOS, macOS, Windows
- **Docelowo przełącznik EN/PL** — na razie patch podmienia pliki


**Status**:
Wczesna wersja BETA — **grywalna**


## Skala
~**25 000+** unikalnych stringów do przetłumaczenia.
~**100** grafik do przetłumaczenia


## Roadmap
| Etap | Status |
|------|--------|
| Teksty | ⏳ ~70% |
| Grafiki | ⏳ ~80% |
| Przełącznik EN/PL w grze | ⏳ planowane |


## Instalacja patcha
### Wymagania
1. West of Loathing ze Steam (lub GOG)
2. Paczka `patches/core` + `patches/house` + `patches/main_scene` - do pobrania z *releases*

### Szybki start
1. Skopiuj zawartość `patches` oraz `install.sh` do jednego folderu (pliki patches do znalezienia w release)
2. Uruchom terminal, przejdź do wcześniejszego folderu i uruchom:
```bash
chmod +x install-pl.sh restore-en.sh verify-install.sh
./install-pl.sh
```

Na SteamOS ustaw ścieżkę w `game-path.env` (wzór: `game-path.env.example`).
Po aktualizacji gry ze Steama uruchom instalator ponownie.


## Disclaimer
Fanowski projekt **niezwiązany z Asymmetric Publications**.  
West of Loathing jest znakiem towarowym jego właścicieli.  
Gra musi być legalnie zakupiona. Patch nie zawiera plików gry.
