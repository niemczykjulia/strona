# Julia Niemczyk — portfolio

Prywatne repozytorium strony portfolio Julii Niemczyk. Autorski one-pager w HTML, CSS i JavaScript, bez bibliotek komponentowych.

## Podgląd lokalny

W katalogu projektu uruchom:

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory dist
```

Otwórz http://localhost:8765.

## Pliki

- `dist/index.html` — treść i układ strony.
- `dist/style.css` — wygląd, responsywność i animacje.
- `dist/script.js` — interakcje i wczytywanie materiałów.
- `dist/assets/media.json` — konfiguracja 18 miejsc na zdjęcia i wideo.
- `dist/assets/content/` — katalog na właściwe materiały.
- `MEDIA.md` — instrukcja podmiany placeholderów.
- `RESEARCH.md` — research, źródła i założenia treści.
- `.openai/hosting.json` — konfiguracja istniejącej publikacji w Sites.

Strona nie wymaga instalacji zależności ani kompilacji. Fonty są pobierane z Google Fonts. Publikacja w Sites jest oddzielnym krokiem — sam push do tego repozytorium nie aktualizuje hostowanej strony.

## Aktualizacja portfolio — październik 2026

Strona zawiera aktualne doświadczenie (Allintraders, Estate Street i ING), sekcję prywatną oraz galerię 27 realizacji z filtrami tematycznymi. Wszystkie realizacje są widoczne domyślnie. Zdjęcia, grafiki i miniatury wideo są przygotowane w katalogu projektu.

### Pliki wideo pozostają lokalne

21 filmów zajmuje około 2,6 GB. Nie są częścią tego repozytorium: część przekracza limit 100 MiB pojedynczego pliku GitHuba. Zwykłe pobranie repozytorium nie przywróci odtwarzania filmów. Galeria zachowuje ich opisy i ścieżki; podgląd na komputerze właścicielki korzysta z lokalnych plików.

Przed publikacją kompletnej galerii należy zmniejszyć rozmiar filmów i zapewnić ich przechowywanie. Lista realizacji znajduje się w `dist/assets/portfolio.json`, a przyporządkowanie do plików źródłowych w `PORTFOLIO-MEDIA.md`.

Aby odtworzyć materiały na tym Macu, zachowując folder `Desktop/do portfolio JN` oraz wskazany film z folderu `Desktop/rolki`, uruchom w katalogu projektu:

```sh
ruby scripts/prepare-portfolio.rb
osascript -l JavaScript scripts/import-videos.js
ruby scripts/build-portfolio.rb
```

Skrypty zachowują oryginały. Import wideo przepisuje pliki do MP4 bez kompresji, dlatego nie zastępuje przygotowania mniejszych plików do publikacji.

## Miniatury rolek

21 miniatur w `dist/assets/content/posters/` pochodzi z rzeczywistych kadrów filmów. Kadry wybrano po przeglądzie sześciu próbek z każdej rolki. Zdjęcia mają szerokość do 1080 pikseli, z zachowaniem ograniczeń jakości źródła; nie są generowane przez AI.

Kolejność, podpisy i wybór kadrów zapisuje `scripts/portfolio-presentation.json`. `ruby scripts/generate-posters.rb` odtwarza miniatury na tym Macu z lokalnych filmów, używając zainstalowanych bibliotek CapCut (FFmpeg 61). `ruby scripts/build-portfolio.rb` aktualizuje galerię.
