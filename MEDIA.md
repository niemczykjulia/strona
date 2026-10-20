# Jak dodać zdjęcia i wideo Julii

Strona ma 18 podpisanych miejsc na materiały. Główne zdjęcie Julii pozostaje bez zmian.

1. Wgraj zdjęcia lub filmy do `dist/assets/content/`.
2. W pliku `dist/assets/media.json` znajdź właściwy identyfikator.
3. Ustaw `src` na ścieżkę względem strony, np. `assets/content/julia-backstage.jpg`.
4. Uzupełnij `alt` opisem faktycznej zawartości zdjęcia. Dla wideo użyj `type: "video"`, dla zdjęcia `type: "image"`.
5. Odśwież stronę. Materiał zastąpi placeholder. Puste `src` pozostawia placeholder. Jeśli materiał się nie załaduje, placeholder pozostaje widoczny.

Przykład zdjęcia:

```json
"julia-backstage": {
  "src": "assets/content/julia-backstage.jpg",
  "alt": "Julia podczas nagrywania materiałów dla klienta",
  "type": "image",
  "position": "50% 50%"
}
```

Przykład wideo (wpis w obiekcie pliku JSON):

```json
"reel-montaz": {
  "src": "assets/content/rolka.mp4",
  "alt": "Wybrana rolka zmontowana przez Julię",
  "type": "video",
  "poster": "assets/content/rolka-okladka.jpg",
  "position": "50% 50%"
}
```

Wideo ma standardowe przyciski odtwarzania, bez autoplay. Gdy dostarczysz wideo z mową, dodaj napisy do materiału. W miejscach na wideo można także umieścić zdjęcie, zmieniając `type` na `image`.

`position` określa kadrowanie: np. `50% 20%` przesunie ważny fragment zdjęcia bliżej góry. Układ zachowuje proporcje placeholdera, więc najlepiej dostarczyć kadr w podanych proporcjach.

| Identyfikator | Materiał | Proporcje |
| --- | --- | --- |
| julia-portret | Dodatkowy portret Julii | 4:5 |
| julia-backstage | Julia przy pracy | 4:5 |
| polka-material | Otwarcie / content Polka Pilates | 16:10 |
| forme-material | ForMe Pilates | 16:10 |
| reforme-material | Reforme | 16:10 |
| pila-material | Pila Pila | 16:10 |
| camp-wydarzenie | Szeroki kadr ALLinCamp | 3:2 |
| camp-julia | Julia na campie | 4:5 |
| camp-wywiad | Wywiad / relacja z campa | 4:5 |
| allinconf | Konferencja | 4:3 |
| tenis-wyjazd | Wyjazd tenisowy / promocja | 4:3 |
| partnerstwa | Sponsoring i współprace | 4:3 |
| reel-backstage | Backstage nagrań | 9:16 |
| reel-montaz | Gotowa rolka / okładka | 9:16 |
| kreacja-optyk | Kreacja dla optyka | 1:1 |
| kreacja-ecommerce | Kreacja e-commerce | 1:1 |
| kreacja-taniec | Kreacja studia tańca | 1:1 |
| kreacja-beauty | Kreacja beauty | 1:1 |

Zmiana plików aktualizuje podgląd lokalny. Wersja online wymaga ponownego wdrożenia. Plik konfiguracyjny i treści są statyczne; strona nie przesyła plików ani nie zapisuje zmian przez przeglądarkę.
