"""Drive the Bekat web build headlessly and take screenshots.

Usage: python3 tool/shoot.py OUTDIR "action;action;..."
Actions: wait:ms | shot:name | click:x,y | type:text | key:Enter
Serve build/web first (python3 -m http.server 8766 -d build/web).
"""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
actions = sys.argv[2].split(";")
lang = sys.argv[3] if len(sys.argv) > 3 else "uz"
import os
W, H = int(os.environ.get("W", 412)), int(os.environ.get("H", 880))
with sync_playwright() as p:
    b = p.chromium.launch(args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
    ctx = b.new_context(viewport={"width": W, "height": H}, device_scale_factor=float(os.environ.get("DPR", 2)), locale="uz-UZ",
                        timezone_id="Asia/Tashkent")
    page = ctx.new_page()
    page.on("console", lambda m: print("console:", m.text) if m.type in ("error",) else None)
    page.add_init_script(f"localStorage.setItem('flutter.lang', JSON.stringify('{lang}'))")
    page.goto("http://localhost:8766/" + os.environ.get("Q", ""), wait_until="networkidle")
    for a in actions:
        k, _, v = a.partition(":")
        if k == "wait": page.wait_for_timeout(int(v))
        elif k == "shot": page.screenshot(path=str(out / f"{v}.png")); print("shot", v)
        elif k == "click":
            x, y = map(float, v.split(",")); page.mouse.click(x, y)
        elif k == "type": page.keyboard.type(v, delay=60)
        elif k == "key": page.keyboard.press(v)
    b.close()
