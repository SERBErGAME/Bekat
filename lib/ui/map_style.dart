import 'dart:convert';

import '../data/network.dart';

/// Line offsets (px at z15) so routes sharing a street sit side by side,
/// like lines on a metro map.
const routeOffset = {
  '1': -3.0,
  '2': -3.0,
  '3': 3.0,
  '5': -3.0,
  '7': 3.0,
  '9': 0.0,
};

String hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Map<String, dynamic> routesGeoJson(Network net, String lang) => {
  'type': 'FeatureCollection',
  'features': [
    for (final r in net.routes)
      {
        'type': 'Feature',
        'properties': {
          'id': r.id,
          'color': hex(r.color.toARGB32()),
          'offset': routeOffset[r.id] ?? 0,
          'demo': r.demo,
        },
        'geometry': {
          'type': 'LineString',
          'coordinates': [for (final p in r.shape) p.lonLat],
        },
      },
  ],
};

Map<String, dynamic> stopsGeoJson(Network net, String lang) => {
  'type': 'FeatureCollection',
  'features': [
    for (final s in net.stops.values)
      {
        'type': 'Feature',
        'id': s.id,
        'properties': {
          'id': s.id,
          'name': s.name.of(lang),
          'hub': s.routeIds.length > 1,
          'color': hex(net.route(s.routeIds.first).color.toARGB32()),
        },
        'geometry': {'type': 'Point', 'coordinates': s.pos.lonLat},
      },
  ],
};

/// Full MapLibre style: OpenFreeMap vector tiles restyled light & quiet,
/// white extruded buildings, plus the bus network baked in.
String buildStyle(Network net, String lang) {
  const font = ['Noto Sans Regular'];
  const fontB = ['Noto Sans Bold'];
  final nameExpr = lang == 'ru'
      ? [
          'coalesce',
          ['get', 'name:ru'],
          ['get', 'name'],
        ]
      : [
          'coalesce',
          ['get', 'name:uz'],
          ['get', 'name:latin'],
          ['get', 'name'],
        ];
  final style = {
    'version': 8,
    'name': 'Bekat Light',
    'glyphs': 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
    // soft, almost shadowless light: buildings read as clean white blocks
    'light': {
      'anchor': 'viewport',
      'color': '#FFFFFF',
      'intensity': 0.18,
      'position': [1.2, 200, 35],
    },
    'sources': {
      'omt': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet'},
      'routes': {'type': 'geojson', 'data': routesGeoJson(net, lang)},
      'stops': {'type': 'geojson', 'data': stopsGeoJson(net, lang)},
    },
    'layers': [
      {
        'id': 'bg',
        'type': 'background',
        'paint': {'background-color': '#EDF0F5'},
      },
      {
        'id': 'residential',
        'type': 'fill',
        'source': 'omt',
        'source-layer': 'landuse',
        'filter': [
          '==',
          ['get', 'class'],
          'residential',
        ],
        'paint': {'fill-color': '#E8EBF1'},
      },
      {
        'id': 'park',
        'type': 'fill',
        'source': 'omt',
        'source-layer': 'park',
        'paint': {'fill-color': '#D9EBD6'},
      },
      {
        'id': 'green',
        'type': 'fill',
        'source': 'omt',
        'source-layer': 'landcover',
        'filter': [
          'match',
          ['get', 'class'],
          ['grass', 'wood', 'farmland'],
          true,
          false,
        ],
        'paint': {'fill-color': '#E1EEDD', 'fill-opacity': 0.7},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': 'omt',
        'source-layer': 'water',
        'paint': {'fill-color': '#CFE1F2'},
      },
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'waterway',
        'paint': {
          'line-color': '#CFE1F2',
          'line-width': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            1,
            16,
            4,
          ],
        },
      },
      {
        'id': 'road-minor',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'transportation',
        'filter': [
          'match',
          ['get', 'class'],
          ['minor', 'service', 'track'],
          true,
          false,
        ],
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#FFFFFF',
          'line-width': [
            'interpolate',
            ['exponential', 1.6],
            ['zoom'],
            13,
            0.8,
            17,
            9,
          ],
        },
      },
      {
        'id': 'road-major-case',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'transportation',
        'filter': [
          'match',
          ['get', 'class'],
          ['primary', 'secondary', 'tertiary', 'trunk', 'motorway'],
          true,
          false,
        ],
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#D8DEE8',
          'line-width': [
            'interpolate',
            ['exponential', 1.6],
            ['zoom'],
            10,
            1.5,
            17,
            22,
          ],
        },
      },
      {
        'id': 'road-major',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'transportation',
        'filter': [
          'match',
          ['get', 'class'],
          ['primary', 'secondary', 'tertiary', 'trunk', 'motorway'],
          true,
          false,
        ],
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#FFFFFF',
          'line-width': [
            'interpolate',
            ['exponential', 1.6],
            ['zoom'],
            10,
            0.8,
            17,
            18,
          ],
        },
      },
      {
        'id': 'rail',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'transportation',
        'filter': [
          '==',
          ['get', 'class'],
          'rail',
        ],
        'paint': {
          'line-color': '#C3CAD6',
          'line-width': 1.4,
          'line-dasharray': [3, 2],
        },
      },
      {
        'id': 'buildings',
        'type': 'fill-extrusion',
        'source': 'omt',
        'source-layer': 'building',
        'minzoom': 13.5,
        'paint': {
          'fill-extrusion-color': [
            'interpolate',
            ['linear'],
            [
              'coalesce',
              ['get', 'render_height'],
              6,
            ],
            0,
            '#F7F8FB',
            20,
            '#FFFFFF',
          ],
          'fill-extrusion-height': [
            'interpolate',
            ['linear'],
            ['zoom'],
            13.5,
            0,
            14.5,
            [
              '*',
              1.6,
              [
                'max',
                7,
                [
                  'coalesce',
                  ['get', 'render_height'],
                  7,
                ],
              ],
            ],
          ],
          'fill-extrusion-base': [
            'coalesce',
            ['get', 'render_min_height'],
            0,
          ],
          'fill-extrusion-opacity': 0.88,
          'fill-extrusion-vertical-gradient': true,
        },
      },
      {
        'id': 'road-label',
        'type': 'symbol',
        'source': 'omt',
        'source-layer': 'transportation_name',
        'minzoom': 14.5,
        'filter': [
          'match',
          ['get', 'class'],
          ['primary', 'secondary', 'tertiary', 'trunk'],
          true,
          false,
        ],
        'layout': {
          'text-field': nameExpr,
          'text-font': font,
          'text-size': 11,
          'symbol-placement': 'line',
          'text-max-angle': 30,
        },
        'paint': {
          'text-color': '#A3AAB7',
          'text-halo-color': '#FFFFFF',
          'text-halo-width': 1.4,
        },
      },
      {
        'id': 'place-label',
        'type': 'symbol',
        'source': 'omt',
        'source-layer': 'place',
        'filter': [
          'match',
          ['get', 'class'],
          ['suburb', 'neighbourhood', 'quarter'],
          true,
          false,
        ],
        'minzoom': 12,
        'layout': {
          'text-field': nameExpr,
          'text-font': font,
          'text-size': 11.5,
          'text-transform': 'none',
        },
        'paint': {
          'text-color': '#B3B9C4',
          'text-halo-color': '#EDF0F5',
          'text-halo-width': 1.5,
        },
      },
      // ---- bus network ----
      {
        'id': 'route-case',
        'type': 'line',
        'source': 'routes',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#FFFFFF',
          'line-width': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            4,
            16,
            11,
          ],
          'line-offset': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            [
              '*',
              0.4,
              ['get', 'offset'],
            ],
            16,
            [
              '*',
              1.4,
              ['get', 'offset'],
            ],
          ],
        },
      },
      {
        'id': 'route-line',
        'type': 'line',
        'source': 'routes',
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': ['get', 'color'],
          'line-width': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            2.2,
            16,
            6.5,
          ],
          'line-offset': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            [
              '*',
              0.4,
              ['get', 'offset'],
            ],
            16,
            [
              '*',
              1.4,
              ['get', 'offset'],
            ],
          ],
        },
      },
      {
        'id': 'stop-dot',
        'type': 'circle',
        'source': 'stops',
        'paint': {
          'circle-radius': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            [
              'case',
              ['get', 'hub'],
              4,
              2.5,
            ],
            16,
            [
              'case',
              ['get', 'hub'],
              9,
              6.5,
            ],
          ],
          'circle-color': '#FFFFFF',
          'circle-stroke-color': [
            'case',
            ['get', 'hub'],
            '#15171C',
            ['get', 'color'],
          ],
          'circle-stroke-width': [
            'interpolate',
            ['linear'],
            ['zoom'],
            11,
            1.5,
            16,
            3,
          ],
          'circle-pitch-alignment': 'map',
        },
      },
      {
        'id': 'stop-label',
        'type': 'symbol',
        'source': 'stops',
        'minzoom': 12.6,
        'layout': {
          'text-field': ['get', 'name'],
          'text-font': fontB,
          'text-size': [
            'interpolate',
            ['linear'],
            ['zoom'],
            12.6,
            10.5,
            16,
            13.5,
          ],
          'text-anchor': 'top',
          'text-offset': [0, 0.9],
          'text-max-width': 8,
        },
        'paint': {
          'text-color': '#2A2E36',
          'text-halo-color': '#FFFFFF',
          'text-halo-width': 1.8,
        },
      },
    ],
  };
  return jsonEncode(style);
}
