# Spikedunk – Dommerapp

Web-appen dommeren bruker ved banen i Spikedunk, et hobbyprosjekt som digitaliserer norske sandvolleyballturneringer fra påmelding til resultat. Dommeren skanner en QR-kode fra admin og fører kampen direkte, uten innlogging.

Spikedunk består av tre Flutter-apper som deler én Firebase-database:

| App | Repo | Brukes av |
| --- | --- | --- |
| Admin | [norgestouradmin](https://github.com/RuudyBoy/norgestouradmin) | Arrangører |
| **Dommerapp** (dette repoet) | [norgestourlivescore](https://github.com/RuudyBoy/norgestourlivescore) | Dommere ved banen |
| Spillerapp | [norgestourapp](https://github.com/RuudyBoy/norgestourapp) | Spillere og publikum |

Case study: [cjrportfolio.netlify.app/spikedunk](https://cjrportfolio.netlify.app/spikedunk)

## Hva appen gjør

- Åpnes med `?matchId=…` i URL-en, som QR-koden fra admin peker til.
- Oppsett før kamp: lagfarger og serverekkefølge.
- Registrerer poeng med årsak, knyttet til spilleren: serveess, angrep, blokk, angrepsfeil, servefeil, teknisk feil/nettfeil og motstanderfeil.
- Ved ess velger dommeren hvem som bommet på mottaket. Ved angrep logges legget til partneren automatisk, og serven som var i spill logges for serveren.
- Følger reglene for sandvolleyball: sidebytte hvert 7. poeng (hvert 5. i tredje sett), teknisk timeout ved 21 poeng til sammen i sett 1 og 2, sett til 21 (15 i tredje sett) med to poengs margin.
- Timeouts, angreknapp og avslutning av sett og kamp.

## Hvordan det fungerer

Hver handling lagres som et eget dokument i `matches/{id}/events`, mens stillingen ligger på kampdokumentet `matches/{id}`. Hendelsene er grunnlaget for statistikk og fantasypoeng i spillerappen, og gjør det mulig å angre siste handling.

Når kampen settes til `finished`, trigges Cloud Function `matchRunner` i admin-repoet og flytter vinneren videre i sluttspillet. Spillerappen og admin lytter på det samme dokumentet og viser stillingen live.

## Struktur

```
norges_tour_scorekeeper/
  lib/
    main.dart        Landingsside (leser matchId), oppsett og poengtavle
    theme/           Farger, typografi og tema (designsystem)
  web/               Web-oppsett
  firebase.json      Firebase Hosting (spikedunk.web.app)
```

## Teknologi

Flutter Web og Dart · Cloud Firestore · Firebase Hosting

## Kjør lokalt

Krever Flutter (Dart SDK 3.9 eller nyere).

```bash
cd norges_tour_scorekeeper
flutter pub get
flutter run -d chrome
```

Åpne deretter appen med `?matchId=<id>` i adressen. Publisering:

```bash
flutter build web
firebase deploy --only hosting:score-app
```

## Status

Fungerende prototype, brukt i demoturneringer. Appen har ingen innlogging i dag. Neste steg er en kortlivet kamp-token i QR-koden og strammere Firestore-regler.

Laget av Christian Jørgensen Ruud.
