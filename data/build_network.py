"""Build assets/data/network.json — the Namangan bus network used by the app,
the deck and the poster.

Source of truth for what is REAL vs DEMO:
  * Routes 1, 2, 3 and their end stops are confirmed by the Ministry of
    Transport / press (see docs/sources). Their intermediate stops are a
    plausible illustration until the field survey (project stage 1).
  * Routes 5, 7, 9 are demo routes (demo: true) to show a richer network.
  * Stop coordinates are real landmarks from OpenStreetMap (osm_poi_raw.json,
    Nominatim); the line shapes follow real roads (OSRM).

Run:  python3 data/build_network.py      (needs internet for OSRM)
"""
import json
import math
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data" / "network.json"
CACHE = ROOT / "data" / "osrm_cache.json"

# id: (uz, ru, en, lat, lon, kind)
STOPS = {
    "otchopar":   ("Otchopar bosh bekati", "Отчопар (конечная)", "Otchopar terminal", 41.0065, 71.5811, "terminal"),
    "taxtakoprik": ("Taxtako‘prik", "Тахтакуприк", "Takhtakuprik", 41.0115, 71.6939, "terminal"),
    "chorsu":     ("Chorsu", "Чорсу", "Chorsu", 41.0011, 71.6795, "bazaar"),
    "yuksalish":  ("Yuksalish", "Юксалиш", "Yuksalish", 41.0437, 71.5512, "terminal"),
    "namdtu_k":   ("NamDTU (Kosonsoy)", "НамГТУ (Касансай)", "NamSTU (Kosonsoy)", 41.0121, 71.5928, "university"),
    "afsonalar":  ("Afsonalar bog‘i", "Парк Афсоналар", "Afsonalar Park", 41.0031, 71.6178, "park"),
    "namdtu_r":   ("NamDTU rektorati", "НамГТУ ректорат", "NamSTU main", 41.0072, 71.6301, "university"),
    "yangibozor": ("Yangibozor", "Янгибазар", "Yangibozor", 41.0079, 71.6383, "bazaar"),
    "avtovokzal": ("Avtovokzal", "Автовокзал", "Bus station", 41.0039, 71.6467, "station"),
    "bolalar":    ("Bolalar shifoxonasi", "Детская больница", "Children's hospital", 41.0180, 71.6614, "hospital"),
    "nanay":      ("Nanay bekati", "Нанай", "Nanay stop", 41.0086, 71.6784, "stop"),
    "yashil":     ("Yashil bozor", "Зелёный базар", "Green bazaar", 40.9980, 71.5988, "bazaar"),
    "diyor":      ("Diyor savdo markazi", "ТЦ Диёр", "Diyor mall", 40.9993, 71.6127, "mall"),
    "vokzal":     ("Temir yo‘l vokzali", "Ж/д вокзал", "Railway station", 40.9996, 71.6440, "rail"),
    "kichkintoy": ("Kichkintoylar bog‘i", "Детский парк", "Kids' park", 41.0008, 71.6573, "park"),
    "hokimlik":   ("Shahar hokimligi", "Хокимият города", "City hall", 41.0002, 71.6719, "gov"),
    "ulfatlar":   ("Ulfatlar", "Улфатлар", "Ulfatlar", 41.0214, 71.5648, "stop"),
    "chet_till":  ("Chet tillari instituti", "Институт иностр. языков", "Foreign Languages Inst.", 41.0203, 71.5482, "university"),
    "hidoyat":    ("Hidoyat", "Хидоят", "Hidoyat", 41.0204, 71.6220, "stop"),
    "oromgoh":    ("Oromgoh", "Оромгох", "Oromgoh", 41.0279, 71.6355, "stop"),
    "xorazm":     ("Xorazm bekati", "Хорезм", "Khorezm stop", 41.0203, 71.6420, "stop"),
    "aeroport":   ("Aeroport", "Аэропорт", "Airport", 40.9841, 71.5627, "airport"),
    "rovuston":   ("Rovuston", "Равустон", "Rovuston", 40.9805, 71.5884, "rail"),
    "toqimachi":  ("To‘qimachilik instituti", "Текстильный институт", "Textile Institute", 40.9836, 71.6103, "university"),
    "kardio":     ("Kardiologiya markazi", "Кардиоцентр", "Cardiology centre", 40.9888, 71.6390, "hospital"),
    "sardoba":    ("Sardoba bozori", "Рынок Сардоба", "Sardoba market", 40.9918, 71.6665, "bazaar"),
    "namdu":      ("NamDU", "НамГУ", "NamSU", 40.9815, 71.7011, "university"),
    "lola":       ("Lola bozori", "Рынок Лола", "Lola market", 40.9749, 71.7143, "bazaar"),
    "gulbog":     ("Gulbog‘", "Гульбог", "Gulbog", 41.0218, 71.7166, "terminal"),
    "texnikum4":  ("4-son texnikum", "Техникум №4", "College No. 4", 41.0191, 71.7150, "university"),
    "saxir":      ("Saxir", "Сахир", "Sakhir", 41.0077, 71.7113, "hospital"),
    "uychi":      ("Uychi ko‘chasi", "Улица Уйчи", "Uychi street", 41.0077, 71.7050, "stop"),
    "teatr":      ("Navoiy teatri", "Театр им. Навои", "Navoi Theatre", 41.0008, 71.6764, "theatre"),
    "bobur":      ("Bobur bog‘i", "Парк Бобура", "Babur Park", 40.9968, 71.6720, "park"),
    "muzey":      ("Viloyat muzeyi", "Областной музей", "Regional museum", 40.9987, 71.6688, "museum"),
    "yangi_nam":  ("Yangi Namangan", "Янги Наманган", "Yangi Namangan", 41.0482, 71.6269, "terminal"),
    "onko":       ("Onkologiya markazi", "Онкоцентр", "Oncology centre", 41.0244, 71.6420, "hospital"),
    "vil_bolalar": ("Viloyat bolalar kasalxonasi", "Обл. детская больница", "Regional children's hospital", 40.9802, 71.6226, "hospital"),
}

# number, colour, headway (min), demo?, [uz/ru/en name], stop ids
ROUTES = [
    ("1", "#E53935", 8, False, ("Otchopar – Taxtako‘prik", "Отчопар – Тахтакуприк", "Otchopar – Takhtakuprik"),
     ["otchopar", "namdtu_k", "afsonalar", "namdtu_r", "yangibozor", "xorazm", "bolalar", "nanay", "taxtakoprik"]),
    ("2", "#1E6FE8", 10, False, ("Otchopar – Chorsu", "Отчопар – Чорсу", "Otchopar – Chorsu"),
     ["otchopar", "yashil", "diyor", "vokzal", "kichkintoy", "hokimlik", "chorsu"]),
    ("3", "#22A55B", 10, False, ("Yuksalish – Chorsu", "Юксалиш – Чорсу", "Yuksalish – Chorsu"),
     ["yuksalish", "chet_till", "ulfatlar", "hidoyat", "xorazm", "bolalar", "nanay", "chorsu"]),
    ("5", "#F59E0B", 15, True, ("Aeroport – Lola bozori", "Аэропорт – рынок Лола", "Airport – Lola market"),
     ["aeroport", "toqimachi", "kardio", "sardoba", "namdu", "lola"]),
    ("7", "#8B5CF6", 12, True, ("Gulbog‘ – Temir yo‘l vokzali", "Гульбог – Ж/д вокзал", "Gulbog – Railway station"),
     ["gulbog", "texnikum4", "saxir", "uychi", "taxtakoprik", "chorsu", "teatr", "bobur", "muzey", "kichkintoy", "vokzal"]),
    ("9", "#06B6D4", 12, True, ("Yangi Namangan – Viloyat bolalar kasalxonasi", "Янги Наманган – Обл. детская больница", "Yangi Namangan – Regional children's hospital"),
     ["yangi_nam", "oromgoh", "xorazm", "yangibozor", "avtovokzal", "vokzal", "kardio", "vil_bolalar"]),
]

# Places people search for that are not stops (from OSM).
POI_KINDS = {"marketplace": "bazaar", "university": "university", "college": "university",
             "park": "park", "mall": "mall", "museum": "museum", "theatre": "theatre",
             "station": "rail", "attraction": "landmark", "hospital": "hospital",
             "place_of_worship": "landmark"}


class RoadGraph:
    """Undirected graph of Namangan's main roads (OSM trunk..tertiary).

    Lines are drawn along the shortest main-road path between stops. This
    ignores one-way rules on purpose: the shapes are an illustration until
    the field survey records the real bus paths.
    """

    def __init__(self):
        raw = json.loads((ROOT / "data" / "osm_main_roads.json").read_text())
        self.adj = {}
        self.segs = []
        for e in raw["elements"]:
            cost = 2.0 if e["tags"]["highway"] == "tertiary" else 1.0
            g = [(round(p["lat"], 6), round(p["lon"], 6)) for p in e["geometry"]]
            for a, b in zip(g, g[1:]):
                self._link(a, b, cost)
                self.segs.append((a, b, cost))

    def _link(self, a, b, cost):
        w = dist(a, b) * cost
        self.adj.setdefault(a, {})[b] = w
        self.adj.setdefault(b, {})[a] = w

    def snap(self, lat, lon):
        """Insert the nearest point on any main road as a graph node."""
        kx, ky = math.cos(math.radians(lat)) * 111320, 110540
        best = None
        for a, b, cost in self.segs:
            ax, ay = (a[1] - lon) * kx, (a[0] - lat) * ky
            bx, by = (b[1] - lon) * kx, (b[0] - lat) * ky
            dx, dy = bx - ax, by - ay
            t = max(0.0, min(1.0, -(ax * dx + ay * dy) / ((dx * dx + dy * dy) or 1e-9)))
            px, py = ax + t * dx, ay + t * dy
            d = math.hypot(px, py) * (1.6 if cost > 1 else 1.0)  # prefer major roads
            if best is None or d < best[0]:
                best = (d, (round(lat + py / ky, 6), round(lon + px / kx, 6)), a, b, cost)
        d, p, a, b, cost = best
        if p not in self.adj:
            self._link(p, a, cost)
            self._link(p, b, cost)
        return p, d

    def path(self, src, dst):
        import heapq
        dist_to, prev, pq = {src: 0.0}, {}, [(0.0, src)]
        while pq:
            d, u = heapq.heappop(pq)
            if u == dst:
                break
            if d > dist_to[u]:
                continue
            for v, w in self.adj[u].items():
                nd = d + w
                if nd < dist_to.get(v, 1e18):
                    dist_to[v], prev[v] = nd, u
                    heapq.heappush(pq, (nd, v))
        if dst not in prev and src != dst:
            return None
        out, u = [dst], dst
        while u != src:
            u = prev[u]
            out.append(u)
        return out[::-1]


def dist(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 6371000 * 2 * math.asin(math.sqrt(h))


def road_route(graph, points):
    """Same result shape as osrm(): line [lon,lat], snapped [lon,lat], legs (m)."""
    nodes = [graph.snap(lat, lon)[0] for lat, lon in points]
    line, legs = [], []
    for a, b in zip(nodes, nodes[1:]):
        p = graph.path(a, b)
        if p is None:
            return None
        legs.append(sum(dist(x, y) for x, y in zip(p, p[1:])))
        line.extend(p if not line else p[1:])
    return {"line": [[lon, lat] for lat, lon in line],
            "snapped": [[lon, lat] for lat, lon in nodes], "legs": legs}


def osrm(points):
    key = ";".join(f"{lon:.5f},{lat:.5f}" for lat, lon in points)
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    if key not in cache:
        url = (f"https://router.project-osrm.org/route/v1/driving/{key}"
               "?overview=full&geometries=geojson")
        req = urllib.request.Request(url, headers={"User-Agent": "Bekat/0.1 (student project)"})
        with urllib.request.urlopen(req, timeout=60) as r:
            data = json.load(r)
        assert data["code"] == "Ok", data
        cache[key] = {
            "line": data["routes"][0]["geometry"]["coordinates"],
            "snapped": [w["location"] for w in data["waypoints"]],
            "legs": [leg["distance"] for leg in data["routes"][0]["legs"]],
        }
        CACHE.write_text(json.dumps(cache))
        time.sleep(1.0)
    return cache[key]


def simplify(coords, tol=0.00004):
    """Douglas–Peucker on lon/lat, keeps the file small."""
    if len(coords) < 3:
        return coords
    (x1, y1), (x2, y2) = coords[0], coords[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = math.hypot(dx, dy) or 1e-12
    best, idx = 0.0, 0
    for i in range(1, len(coords) - 1):
        x, y = coords[i]
        d = abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norm
        if d > best:
            best, idx = d, i
    if best <= tol:
        return [coords[0], coords[-1]]
    return simplify(coords[:idx + 1], tol)[:-1] + simplify(coords[idx:], tol)


def main():
    graph = RoadGraph()
    for sid, v in list(STOPS.items()):
        node, d = graph.snap(v[3], v[4])
        if d > 250:
            print(f"  note: {sid} is {d:.0f} m from a main road")
    snapped = {}
    routes = []
    for num, color, headway, demo, names, seq in ROUTES:
        pts = [(STOPS[s][3], STOPS[s][4]) for s in seq]
        res = road_route(graph, pts)
        if res is None:
            print(f"  route {num}: main roads not connected, using OSRM")
            res = osrm(pts)
        for s, (lon, lat) in zip(seq, res["snapped"]):
            snapped.setdefault(s, (lat, lon))
        line = [[round(lon, 5), round(lat, 5)] for lon, lat in simplify(res["line"])]
        routes.append({
            "id": num, "color": color, "headwayMin": headway, "demo": demo,
            "name": dict(zip(("uz", "ru", "en"), names)),
            "stops": seq, "legMeters": [round(m) for m in res["legs"]],
            "line": line,
        })
        print(f"route {num}: {len(seq)} stops, {sum(res['legs'])/1000:.1f} km, {len(line)} pts")

    stops = []
    for sid, (uz, ru, en, lat, lon, kind) in STOPS.items():
        if not any(sid in r["stops"] for r in routes):
            continue
        lat, lon = snapped.get(sid, (lat, lon))
        stops.append({"id": sid, "name": {"uz": uz, "ru": ru, "en": en},
                      "lat": round(lat, 5), "lon": round(lon, 5), "kind": kind,
                      "routes": [r["id"] for r in routes if sid in r["stops"]]})

    raw = json.loads((ROOT / "data" / "osm_poi_raw.json").read_text())
    pois, seen = [], set()
    for e in raw["elements"]:
        t = e["tags"]
        name = t.get("name:uz") or t.get("name")
        kind = next((POI_KINDS[t[k]] for k in ("amenity", "leisure", "shop", "railway", "tourism")
                     if t.get(k) in POI_KINDS), None)
        if not name or not kind or name.lower() in seen or "питак" in name.lower():
            continue
        seen.add(name.lower())
        c = e.get("center", e)
        pois.append({"name": name, "ru": t.get("name:ru"), "lat": round(c["lat"], 5),
                     "lon": round(c["lon"], 5), "kind": kind})

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "city": "Namangan",
        "generated": time.strftime("%Y-%m-%d"),
        "note": "Routes 1-3: confirmed numbers and end stops; intermediate stops illustrative. "
                "Routes 5, 7, 9: demo. Map data (c) OpenStreetMap contributors (ODbL).",
        "stops": stops, "routes": routes, "pois": pois,
    }, ensure_ascii=False, separators=(",", ":")))
    print("stops", len(stops), "pois", len(pois), "->", OUT, OUT.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
