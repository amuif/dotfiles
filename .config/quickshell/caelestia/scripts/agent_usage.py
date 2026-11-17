#!/usr/bin/env python3
"""Local AI-agent usage for the Caelestia bar (agents ring + popout).

Reads only what each agent writes on this machine, so nothing here calls any
API or depends on undocumented endpoints. Prints one JSON object to stdout.

Detected agents
  claude       Claude Code   ~/.claude/projects/**/*.jsonl  exact token counts per reply
  antigravity  Antigravity   ~/.gemini/antigravity-cli/history.jsonl  prompt timestamps

No agent stores the plan quota locally, so "window" is the current 5-hour
block (same rule Claude uses: starts at the first message, rounded down to the
hour, lasts 5h) and "ratio" compares it with your busiest past 5-hour block
(or a floor: 2M fresh tokens / 50 prompts, whichever is larger).
"""

import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

HOME = Path.home()
BLOCK_MS = 5 * 3600 * 1000
HOUR_MS = 3600 * 1000
LOOKBACK_DAYS = 30


def now_ms() -> int:
    return int(time.time() * 1000)


def start_of_today_ms() -> int:
    d = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    return int(d.timestamp() * 1000)


def running(name: str) -> bool:
    try:
        return subprocess.run(["pgrep", "-x", name], capture_output=True).returncode == 0
    except OSError:
        return False


def blocks(events):
    """events: sorted list of (ts_ms, weight). Returns list of blocks."""
    out = []
    cur = None
    for ts, w in events:
        if cur is None or ts >= cur["end"] or ts - cur["last"] >= BLOCK_MS:
            start = ts - ts % HOUR_MS
            cur = {"start": start, "end": start + BLOCK_MS, "last": ts, "total": 0, "count": 0}
            out.append(cur)
        cur["total"] += w
        cur["count"] += 1
        cur["last"] = ts
    return out


def summarize(events, unit, floor):
    events.sort()
    t = now_ms()
    bl = blocks(events)
    active = bl[-1] if bl and t < bl[-1]["end"] else None
    past = [b for b in bl if b is not active]
    peak = max((b["total"] for b in past), default=0)
    today0 = start_of_today_ms()
    week0 = t - 7 * 24 * HOUR_MS
    today = [w for ts, w in events if ts >= today0]
    week = [w for ts, w in events if ts >= week0]
    window = None
    if active:
        window = {
            "total": active["total"],
            "count": active["count"],
            "start": active["start"],
            "end": active["end"],
        }
    # Reference = busiest past 5h block, but never below a sensible floor so a
    # fresh machine doesn't show a full ring after the first few messages
    ref = max(peak, floor)
    ratio = min(1.0, window["total"] / ref) if window and ref else 0.0
    return {
        "unit": unit,
        "window": window,
        "peak": peak,
        "reference": ref,
        "ratio": ratio,
        "today": {"total": sum(today), "count": len(today)},
        "week": {"total": sum(week), "count": len(week)},
        "lastActivity": events[-1][0] if events else None,
    }


def parse_ts(s: str):
    try:
        return int(datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp() * 1000)
    except (ValueError, AttributeError):
        return None


def claude():
    root = HOME / ".claude" / "projects"
    if not root.is_dir():
        return None
    cutoff = time.time() - LOOKBACK_DAYS * 86400
    seen = set()
    events = []
    model = None
    model_ts = 0
    for f in root.rglob("*.jsonl"):
        try:
            if f.stat().st_mtime < cutoff:
                continue
            fh = f.open(encoding="utf-8", errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                if '"assistant"' not in line or '"usage"' not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if d.get("type") != "assistant":
                    continue
                msg = d.get("message") or {}
                usage = msg.get("usage") or {}
                key = (msg.get("id"), d.get("requestId"))
                if key[0] and key in seen:
                    continue
                seen.add(key)
                ts = parse_ts(d.get("timestamp"))
                if ts is None:
                    continue
                # Fresh tokens only: cache reads are cheap re-reads of earlier context
                tokens = (usage.get("input_tokens") or 0) + (usage.get("output_tokens") or 0) + (usage.get("cache_creation_input_tokens") or 0)
                if tokens <= 0:
                    continue
                events.append((ts, tokens))
                m = msg.get("model")
                if m and not m.startswith("<") and ts > model_ts:
                    model, model_ts = m, ts
    s = summarize(events, "tokens", 2_000_000)
    s.update({"id": "claude", "name": "Claude Code", "icon": "smart_toy", "running": running("claude"), "model": model})
    return s


def antigravity():
    base = HOME / ".gemini" / "antigravity-cli"
    hist = base / "history.jsonl"
    if not base.is_dir():
        return None
    events = []
    cutoff = now_ms() - LOOKBACK_DAYS * 86400 * 1000
    try:
        with hist.open(encoding="utf-8", errors="replace") as fh:
            for line in fh:
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if d.get("type") == "slash_command":
                    continue
                ts = d.get("timestamp")
                if isinstance(ts, (int, float)) and ts >= cutoff:
                    events.append((int(ts), 1))
    except OSError:
        pass
    s = summarize(events, "prompts", 50)
    s.update({"id": "antigravity", "name": "Antigravity", "icon": "auto_awesome", "running": running("agy"), "model": None})
    return s


def main():
    agents = []
    for fn in (claude, antigravity):
        try:
            a = fn()
        except Exception as e:  # never break the bar over one agent
            print(f"agent_usage: {fn.__name__}: {e}", file=sys.stderr)
            a = None
        if a:
            agents.append(a)
    print(json.dumps({"updated": now_ms(), "agents": agents}))


if __name__ == "__main__":
    main()
