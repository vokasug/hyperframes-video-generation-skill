#!/usr/bin/env python3
"""fetch_fonts.py — fallback: скачать woff2 с кириллицей с Google Fonts.
Использование: fetch_fonts.py <assets_dir>  (по умолчанию ./assets)"""
import re, sys, urllib.request
from pathlib import Path

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "assets") / "fonts"
OUT.mkdir(parents=True, exist_ok=True)
UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0 Safari/537.36"}
FAMILIES = [("Unbounded", "Unbounded:wght@500;700;900"),
            ("Manrope", "Manrope:wght@400;600;800"),
            ("JetBrains Mono", "JetBrains+Mono:wght@500;700")]

css_out = []
for fam, q in FAMILIES:
    css = urllib.request.urlopen(urllib.request.Request(
        f"https://fonts.googleapis.com/css2?family={q}&display=swap", headers=UA)).read().decode()
    for subset, block in re.findall(r"/\*\s*([a-z-]+)\s*\*/\s*(@font-face\s*\{[^}]+\})", css):
        if subset not in ("cyrillic", "cyrillic-ext", "latin"):
            continue
        mu = re.search(r"url\((https://[^)]+\.woff2)\)", block)
        mw = re.search(r"font-weight:\s*(\d+)", block)
        if not mu or not mw:
            continue
        fname = f"{fam.replace(' ', '')}-{mw.group(1)}-{subset}.woff2"
        fpath = OUT / fname
        if not fpath.exists():
            urllib.request.urlretrieve(mu.group(1), fpath)
        css_out.append(block.replace(mu.group(1), f"fonts/{fname}"))
    print(fam, "ok")

(OUT.parent / "fonts.css").write_text("\n".join(css_out), encoding="utf-8")
print(f"fonts.css: {len(css_out)} faces -> {OUT.parent / 'fonts.css'}")
