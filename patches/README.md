## Paczki release

Ten katalog repozytorium zawiera wyłącznie gotowe archiwa ZIP przeznaczone do
publikacji w GitHub Releases. Nie dzielimy go na podkatalogi systemowe.

Po rozpakowaniu archiwum bundle Unity muszą znajdować się w osobnych katalogach:

```text
patches/
  linux/
    core
    house
    main_scene
    platform.txt
    source-sha256.txt
  windows/
    core
    house
    main_scene
    platform.txt
    source-sha256.txt
```

Binaria znajdują się wewnątrz ZIP-a i nie są commitowane jako osobne pliki.
Archiwum v0.9.1 zawiera również `bepinex/linux/`, `bepinex/macos/` i
`bepinex/windows/`; instalator Windows korzysta z oficjalnego runtime
BepInEx `win_x64` i nie wymaga PowerShella.
Gotową paczkę należy pobrać z zakładki [**Releases**](../../../releases).

Nie wolno używać plików z rozpakowanego `patches/linux/` na Windows — powoduje
to uszkodzone, różowe grafiki. Instalatory sprawdzają `platform.txt` przed
podmianą plików gry.
