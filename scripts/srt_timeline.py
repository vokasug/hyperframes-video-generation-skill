#!/usr/bin/env python3
"""srt_timeline.py — SRT + mp3 длительности -> JSON таймлайна видео.
Использование: srt_timeline.py <dir_vo> [lead_in] [tail]
Выход: JSON в stdout. Сцены идут по алфавиту имён файлов (01-..., 02-...)."""
import json, re, subprocess, sys
from pathlib import Path

LEAD = float(sys.argv[2]) if len(sys.argv) > 2 else 0.25
TAIL = float(sys.argv[3]) if len(sys.argv) > 3 else 0.30

def dur(p: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(p)], capture_output=True, text=True)
    return float(out.stdout.strip())

def parse_srt(p: Path):
    blocks = re.split(r"\n\s*\n", p.read_text(encoding="utf-8").strip())
    items = []
    for b in blocks:
        m = re.search(r"(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*\n(.+)",
                      b, re.S)
        if not m:
            continue
        h1, m1, s1, ms1, h2, m2, s2, ms2, text = m.groups()
        t1 = int(h1) * 3600 + int(m1) * 60 + int(s1) + int(ms1) / 1000
        t2 = int(h2) * 3600 + int(m2) * 60 + int(s2) + int(ms2) / 1000
        items.append({"text": " ".join(text.split()), "start": round(t1, 3), "end": round(t2, 3)})
    return items

vo_dir = Path(sys.argv[1])
scenes, cursor = [], 0.0
for mp3 in sorted(vo_dir.glob("*.mp3")):
    srt = mp3.with_suffix(".srt")
    vd = dur(mp3)
    scene_dur = round(vd + LEAD + TAIL, 3)
    sentences = []
    if srt.exists():
        for it in parse_srt(srt):
            sentences.append({"text": it["text"],
                              "start": round(cursor + LEAD + it["start"], 3),
                              "end": round(cursor + LEAD + it["end"], 3)})
    scenes.append({"id": mp3.stem, "start": round(cursor, 3), "vo_start": round(cursor + LEAD, 3),
                   "duration": scene_dur, "vo_duration": round(vd, 3), "sentences": sentences})
    cursor += scene_dur
print(json.dumps({"scenes": scenes, "total": round(cursor, 3)}, ensure_ascii=False, indent=2))
