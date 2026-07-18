#!/usr/bin/env python3
"""podcast_tts.py — мультиголосая озвучка сцен (подкаст-формат, диалоги).
Вход: <project>/script/*.txt, строки вида 'S: текст' / 'D: текст' (префикс = голос из VOICES).
Действия: per-line edge-tts -> склейка сцены с паузами GAP -> vo/<scene>.mp3 + vo/<scene>.srt
(со сдвигами) -> lines.json (локальные метки реплик со спикером для аватаров/субтитров).
Далее: srt_timeline.py vo -> timeline.json; глобальное время реплики = scene.start + LEAD + local.
Использование: podcast_tts.py [project_dir] [gap_sec] [rate]
Пример: podcast_tts.py . 0.15 +5%"""
import json, re, subprocess, sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
GAP = float(sys.argv[2]) if len(sys.argv) > 2 else 0.15
RATE = sys.argv[3] if len(sys.argv) > 3 else "+5%"
# Префиксы реплик -> голоса edge-tts. Меняй под свой подкаст.
VOICES = {"S": "ru-RU-SvetlanaNeural", "D": "ru-RU-DmitryNeural"}

def run(cmd):
    subprocess.run(cmd, check=True, capture_output=True)

def dur(p: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(p)], capture_output=True, text=True)
    return float(out.stdout.strip())

def parse_srt(p: Path):
    blocks = re.split(r"\n\s*\n", p.read_text(encoding="utf-8").strip())
    items = []
    for b in blocks:
        m = re.search(r"(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*\n(.+)", b, re.S)
        if not m:
            continue
        h1, m1, s1, ms1, h2, m2, s2, ms2, text = m.groups()
        t1 = int(h1)*3600 + int(m1)*60 + int(s1) + int(ms1)/1000
        t2 = int(h2)*3600 + int(m2)*60 + int(s2) + int(ms2)/1000
        items.append({"text": " ".join(text.split()), "start": t1, "end": t2})
    return items

def fmt_ts(t: float) -> str:
    ms = round(t * 1000)
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

(ROOT / "vo").mkdir(exist_ok=True)
(ROOT / "vo_lines").mkdir(exist_ok=True)
all_lines = {}
total_speech = 0.0

for txt in sorted((ROOT / "script").glob("*.txt")):
    scene = txt.stem
    entries = []
    for raw in txt.read_text(encoding="utf-8").splitlines():
        raw = raw.strip()
        if not raw:
            continue
        sp, _, text = raw.partition(":")
        sp = sp.strip()
        if sp not in VOICES:
            sys.exit(f"{txt.name}: неизвестный префикс голоса '{sp}' (есть: {', '.join(VOICES)})")
        entries.append((sp, text.strip()))

    line_files = []
    for i, (sp, text) in enumerate(entries, 1):
        base = f"{scene}-{i:02d}-{sp.lower()}"
        mp3 = ROOT / "vo_lines" / f"{base}.mp3"
        srt = ROOT / "vo_lines" / f"{base}.srt"
        tmp = ROOT / "vo_lines" / f"{base}.txt"
        tmp.write_text(text, encoding="utf-8")
        run(["edge-tts", "--voice", VOICES[sp], f"--rate={RATE}", "--file", str(tmp),
             "--write-media", str(mp3), "--write-subtitles", str(srt)])
        line_files.append((sp, text, mp3, srt))
        tmp.unlink()
        print(f"  {base}.mp3")

    # склейка сцены с паузами GAP между репликами
    lst = ROOT / "vo_lines" / f"{scene}.concat.txt"
    parts = []
    for i, (_, _, mp3, _) in enumerate(line_files):
        parts.append(str(mp3))
        if i < len(line_files) - 1:
            sil = ROOT / "vo_lines" / f"{scene}-sil{i}.mp3"
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=24000:cl=mono",
                 "-t", str(GAP), str(sil)])
            parts.append(str(sil))
    lst.write_text("\n".join(f"file '{p}'" for p in parts), encoding="utf-8")
    out_mp3 = ROOT / "vo" / f"{scene}.mp3"
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(lst),
         "-c:a", "libmp3lame", "-q:a", "4", str(out_mp3)])

    # сцена SRT + lines.json (локальное время)
    cursor, srt_blocks, lines, idx = 0.0, [], [], 1
    for sp, text, mp3, srt in line_files:
        for it in parse_srt(srt):
            srt_blocks.append((idx, cursor + it["start"], cursor + it["end"], it["text"]))
            idx += 1
        d = dur(mp3)
        lines.append({"speaker": sp, "text": text,
                      "start": round(cursor, 3), "end": round(cursor + d, 3)})
        cursor += d + GAP
    scene_srt = "\n\n".join(f"{i}\n{fmt_ts(a)} --> {fmt_ts(b)}\n{t}" for i, a, b, t in srt_blocks)
    (ROOT / "vo" / f"{scene}.srt").write_text(scene_srt + "\n", encoding="utf-8")
    all_lines[scene] = lines
    d_scene = dur(out_mp3)
    total_speech += d_scene
    print(f"== {scene}: {d_scene:.2f} c, реплик: {len(lines)}")

for f in (ROOT / "vo_lines").glob("*-sil*.mp3"):
    f.unlink()
(ROOT / "lines.json").write_text(json.dumps(all_lines, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Речь суммарно: {total_speech:.2f} c")
print("Далее: srt_timeline.py vo [lead] [tail] > timeline.json; глоб. метка реплики = scene.start + lead + lines.json.local")
