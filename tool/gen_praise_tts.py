"""Generate neural TTS praise clips for fast matches (ru + en)."""

from __future__ import annotations

import asyncio
from pathlib import Path

import edge_tts

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sfx" / "praise"

PHRASES: dict[str, list[str]] = {
    "ru": [
        "Здорово!",
        "Отлично!",
        "Супер!",
        "Есть!",
        "Красиво!",
        "Молодец!",
        "Класс!",
        "Так держать!",
    ],
    "en": [
        "Great!",
        "Nice!",
        "Super!",
        "Yes!",
        "Beautiful!",
        "Well done!",
        "Awesome!",
        "Keep it up!",
    ],
}

VOICES = {
    "ru": "ru-RU-SvetlanaNeural",
    "en": "en-US-JennyNeural",
}

RATE = "-10%"


async def _save(lang: str, index: int, text: str) -> Path:
    out = OUT_DIR / f"{lang}_{index}.mp3"
    communicate = edge_tts.Communicate(text, VOICES[lang], rate=RATE)
    await communicate.save(str(out))
    print(f"wrote {out.relative_to(ROOT)} ({out.stat().st_size} bytes)")
    return out


async def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    jobs = []
    for lang, lines in PHRASES.items():
        for i, text in enumerate(lines, start=1):
            jobs.append(_save(lang, i, text))
    await asyncio.gather(*jobs)


if __name__ == "__main__":
    asyncio.run(main())
