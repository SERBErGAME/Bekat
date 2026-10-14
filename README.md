# Bekat 🚌 — Namangan avtobuslari uchun aqlli marshrut xaritasi

**Bekat** ("bus stop" in Uzbek) shows how to get anywhere in Namangan by city bus:
pick a place on the 3D map or search for it, and the app shows which bus to take, where to
change, how long to walk and when the bus arrives. If no bus goes there, it shows the
closest you can get. Author: **Rasulov Farruh** (NamDTU), for the "Eng yaxshi kreativ g‘oya"
2026 contest.

## Features (working prototype)
- **3D live map**: MapLibre + OpenFreeMap/OpenStreetMap tiles, white extruded buildings,
  coloured route lines, animated buses with route badges.
- **Trip planner with transfers**: RAPTOR (Delling et al., 2012), runs on the phone, up to
  2 transfers, walking between nearby stops, plus a "closest reachable" mode.
- **Metro-style network diagram**: hand-laid octilinear map of all lines, with live buses
  and tap-a-stop arrivals.
- **Trip mode**: stop strip, stops left, time left, bus ETA, where to get off or change.
- **Search** in Latin and Cyrillic (`chorsu` = `Чорсу`), online Nominatim fallback.
- Uzbek / Russian / English, a large-text mode, and a ×10 demo clock for presentations.

## What is real and what is a sample
| Data | Status |
|---|---|
| Routes №1 Otchopar–Taxtako‘prik, №2 Otchopar–Chorsu, №3 Yuksalish–Chorsu | Numbers and end stops **confirmed** (Mintrans, press 2026) |
| Intermediate stops of №1–3 | Real landmarks, **illustrative order**, until the field survey |
| Routes №5, №7, №9 | **Demo** (`demo: true`), shown as "namuna" in the app |
| Stop/POI coordinates | Real (OpenStreetMap, Nominatim) |
| Line shapes | Shortest path on Namangan's main roads (OSM) |
| Bus positions / ETAs | Simulated from headway (18 km/h), not live GPS |

Project stage 1 replaces the samples with GPS-surveyed routes in GTFS format.

## Run
```bash
flutter pub get
flutter run                      # Android / iOS device
flutter run -d chrome            # web
flutter test                     # 7 planner/search/schedule tests
flutter build web --release      # build/web
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk (debug-signed)
```
Web-only URL switches for renders: `?clean` hides overlays; `?cam=lat,lon,zoom,tilt,bearing` fixes the camera.

## Structure
```
lib/
  main.dart                 app + animated splash
  core/  app_state.dart     state, clock (demo ×10), GPS (falls back to NamDTU outside Namangan)
         i18n.dart          uz/ru/en strings     theme.dart  design tokens
  data/  network.dart       stops, routes, polylines
         schedule.dart      headway timetable → bus positions & arrivals
         planner.dart       RAPTOR journeys      search.dart  Latin/Cyrillic search
  ui/    home_screen.dart   search pill, nearby card, options, trip mode
         map_view.dart      MapLibre map, buses, trip layer, camera tween
         map_style.dart     light 3D style      scheme_screen.dart  metro diagram
         search_screen.dart settings_sheet.dart  widgets.dart (badges, iso bus, sprites)
data/build_network.py       builds assets/data/network.json (OSM + road graph)
tool/shoot.py               headless screenshots of the web build
docs/                       contest documents (below)
```

## Contest documents (`docs/`)
| File | What |
|---|---|
| `Eng_yaxshi_kreativ_goya_Bekat_Rasulov_Farruh.docx` | Application form (template filled in), built by `build_ariza.py` |
| `Bekat_Taqdimot_UZ.pptx`, `Bekat_Prezentatsiya_RU.pptx` | 14-slide decks, built by `deck/build_deck.js` |
| `poster/Bekat_poster_A3_UZ.pdf/.png`, `…_RU…` | A3 posters, built by `poster/render_poster.py` |
| `shots/`, `assets/` | Real app screenshots and mockups (`make_assets.py`) |

Regenerate after app changes:
```bash
flutter build web --release && (python3 -m http.server 8766 -d build/web &)
python3 tool/shoot.py docs/shots/uz "wait:1300;shot:01_splash;wait:10500;shot:02_home;click:340,553;wait:2800;shot:03_scheme;click:36,32;wait:1500;click:170,40;wait:1200;type:chorsu;wait:1000;shot:04_search;click:200,118;wait:4200;shot:05_plan;click:310,680;wait:5000;shot:06_trip" uz
#   (same with docs/shots/ru, "type:чорсу" and last argument ru)
W=1500 H=1150 python3 tool/shoot.py docs/shots/uz "wait:11000;click:1428,823;wait:3200;shot:scheme_wide" uz
W=1600 H=1000 Q="?clean&cam=41.0045,71.6745,15.2,62,-28" python3 tool/shoot.py docs/shots/uz "wait:17000;shot:map_center" uz
python3 docs/make_assets.py
(cd docs/deck && npm install && node build_deck.js)
python3 docs/poster/render_poster.py
python3 docs/build_ariza.py
```

Map data © OpenStreetMap contributors (ODbL), tiles by OpenFreeMap. Font: Inter (OFL).
