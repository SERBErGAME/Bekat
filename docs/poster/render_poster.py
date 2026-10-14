"""Render bekat_poster.html to A3 landscape PDF (vector) + 300 dpi PNG, uz and ru.

Usage: python3 docs/poster/render_poster.py
Needs Playwright with Chromium. Images come from docs/assets (run docs/make_assets.py first).
"""
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
SRC = HERE / "bekat_poster.html"
W, H = 1782, 1260  # .board size

with sync_playwright() as p:
    browser = p.chromium.launch()
    for lang in ("uz", "ru"):
        page = browser.new_page(viewport={"width": W, "height": H}, device_scale_factor=4961 / W)
        page.goto(SRC.as_uri() + f"?lang={lang}", wait_until="networkidle")
        page.evaluate("document.fonts.ready")
        page.wait_for_timeout(600)
        overflow = page.evaluate("""() => [...document.querySelectorAll('.card, .board')]
            .filter(e => e.scrollHeight > e.clientHeight + 1 || e.scrollWidth > e.clientWidth + 1)
            .map(e => (e.querySelector('.label')?.textContent || e.className) + ` ${e.scrollHeight}>${e.clientHeight}`)""")
        print(lang, "overflow:", overflow or "none")
        page.screenshot(path=str(HERE / f"Bekat_poster_A3_{lang.upper()}.png"))
        page.pdf(path=str(HERE / f"Bekat_poster_A3_{lang.upper()}.pdf"), width="420mm", height="297mm",
                 print_background=True, margin={"top": "0", "right": "0", "bottom": "0", "left": "0"},
                 scale=1587.4 / W)
        page.close()
    browser.close()
print("done")
