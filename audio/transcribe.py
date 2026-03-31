"""
transcribe.py
-------------
Transcribe MP3 file(s) using local Whisper and output:
  - ./output/[filename].txt    raw timestamped transcription
  - ./output/[filename].srt    SRT subtitle file

Usage:
    python transcribe.py                        # process all .mp3 in ./input/
    python transcribe.py audio.mp3              # process a single file
    python transcribe.py audio.mp3 --words 8   # max 8 words per line
    python transcribe.py audio.mp3 --model medium

Requirements:
    pip install openai-whisper
    pip install setuptools   # if you get a 'pkg_resources' error

Models (downloaded automatically on first run):
    tiny   ~75 MB   fastest, less accurate
    base   ~150 MB  good balance  ← default
    small  ~460 MB  better
    medium ~1.5 GB  very good
    large  ~3 GB    best, slow without GPU
"""

import os
import sys
import glob
import argparse

try:
    import whisper
except ImportError:
    print("❌  openai-whisper is not installed. Run:  pip install openai-whisper")
    sys.exit(1)


OUTPUT_DIR = "./output"


def seconds_to_timestamp_simple(seconds: float) -> str:
    """Convert float seconds → [HH:MM:SS]  (raw output)"""
    total_s = int(seconds)
    h = total_s // 3600
    m = (total_s % 3600) // 60
    s = total_s % 60
    return f"[{h:02d}:{m:02d}:{s:02d}]"


def seconds_to_timestamp_srt(seconds: float) -> str:
    """Convert float seconds → HH:MM:SS,mmm  (SRT format with milliseconds)"""
    ms = int(round(seconds * 1000))
    h  = ms // 3_600_000; ms %= 3_600_000
    m  = ms //    60_000; ms %=    60_000
    s  = ms //     1_000; ms %=     1_000
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def split_segment_by_words(words: list, max_words: int) -> list[dict]:
    """Split a list of word-timestamp dicts into chunks of at most max_words."""
    chunks = []
    for i in range(0, len(words), max_words):
        group = words[i : i + max_words]
        chunks.append({
            "start": group[0]["start"],
            "end":   group[-1]["end"],
            "text":  " ".join(w["word"].strip() for w in group),
        })
    return chunks


def build_segments(result: dict, max_words: int) -> list[dict]:
    """
    Respect Whisper's natural segment boundaries first.
    If a segment has more than max_words words, split it further
    using word-level timestamps.
    """
    segments = []
    for seg in result["segments"]:
        words = seg.get("words", [])
        if not words:
            segments.append({
                "start": seg["start"],
                "end":   seg["end"],
                "text":  seg["text"].strip(),
            })
            continue

        if len(words) <= max_words:
            segments.append({
                "start": words[0]["start"],
                "end":   words[-1]["end"],
                "text":  " ".join(w["word"].strip() for w in words),
            })
        else:
            segments.extend(split_segment_by_words(words, max_words))

    return segments


def format_raw(segments: list[dict]) -> str:
    """[HH:MM:SS] --> [HH:MM:SS]  text"""
    lines = []
    for seg in segments:
        start = seconds_to_timestamp_simple(seg["start"])
        end   = seconds_to_timestamp_simple(seg["end"])
        lines.append(f"{start} --> {end}  {seg['text'].strip()}")
    return "\n".join(lines)


def format_srt(segments: list[dict]) -> str:
    """Numbered SRT blocks with millisecond precision."""
    blocks = []
    for idx, seg in enumerate(segments, start=1):
        start = seconds_to_timestamp_srt(seg["start"])
        end   = seconds_to_timestamp_srt(seg["end"])
        blocks.append(f"{idx}\n{start} --> {end}\n{seg['text'].strip()}")
    return "\n\n".join(blocks)


def process_file(audio_path: str, model, max_words: int) -> None:
    print(f"\n🎙  Transcribing {audio_path} …")

    result = model.transcribe(audio_path, verbose=False, word_timestamps=True)
    segments = build_segments(result, max_words)

    base = os.path.splitext(os.path.basename(audio_path))[0]
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    raw_path = os.path.join(OUTPUT_DIR, base + ".txt")
    with open(raw_path, "w", encoding="utf-8") as f:
        f.write(format_raw(segments))
    print(f"   ✅  Raw  → {raw_path}")

    srt_path = os.path.join(OUTPUT_DIR, base + ".srt")
    with open(srt_path, "w", encoding="utf-8") as f:
        f.write(format_srt(segments))
    print(f"   ✅  SRT  → {srt_path}")


def main():
    parser = argparse.ArgumentParser(description="Transcribe MP3(s) using local Whisper.")
    parser.add_argument("audio", nargs="?", default=None,
                        help="Path to an audio file. If omitted, processes all .mp3 in ./input/")
    parser.add_argument("--model", default="base",
                        choices=["tiny", "base", "small", "medium", "large"],
                        help="Whisper model to use (default: base)")
    parser.add_argument("--words", type=int, default=6, metavar="N",
                        help="Max words per subtitle line, respecting natural pauses (default: 6)")
    args = parser.parse_args()

    # Collect files to process
    if args.audio:
        if not os.path.isfile(args.audio):
            print(f"❌  File not found: {args.audio}")
            sys.exit(1)
        files = [args.audio]
    else:
        files = sorted(glob.glob("./input/*.mp3"))
        if not files:
            print("❌  No .mp3 files found in ./input/")
            sys.exit(1)
        print(f"📂  Found {len(files)} file(s) in ./input/")

    print(f"📦  Loading Whisper model '{args.model}' (downloaded once, then cached) …")
    model = whisper.load_model(args.model)

    for audio_path in files:
        process_file(audio_path, model, args.words)

    print(f"\n🎉  Done! Output saved to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()