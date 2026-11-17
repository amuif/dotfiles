pragma Singleton

// World clock: one extra city shown next to the bar clock.
// The chosen zone is saved in ~/.local/state/caelestia/worldclock.txt
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    property string zone: ""
    // [{ zone, city, region, offset (minutes from UTC) }]
    property var zones: []
    readonly property bool loaded: zones.length > 0

    readonly property var current: zones.find(z => z.zone === zone) ?? null
    readonly property string city: cityOf(zone)

    readonly property string timeStr: {
        Time.minutes; // re-evaluate every minute
        return current ? formatFor(current.offset) : "";
    }

    // "+1" / "-1" when the city is on a different calendar day than here
    readonly property string dayDiff: {
        Time.hours;
        if (!current)
            return "";
        const now = new Date();
        const there = new Date(now.getTime() + current.offset * 60000);
        const hereDay = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
        const thereDay = Date.UTC(there.getUTCFullYear(), there.getUTCMonth(), there.getUTCDate());
        const diff = Math.round((thereDay - hereDay) / 86400000);
        return diff === 0 ? "" : (diff > 0 ? `+${diff}` : `${diff}`);
    }

    function cityOf(z: string): string {
        return z ? z.split("/").pop().replace(/_/g, " ") : "";
    }

    function pad(n: int): string {
        return n < 10 ? `0${n}` : `${n}`;
    }

    function formatFor(offset: int): string {
        const d = new Date(Date.now() + offset * 60000);
        let h = d.getUTCHours();
        const m = pad(d.getUTCMinutes());
        if (Units.twelveHourClock) {
            const ap = h >= 12 ? "pm" : "am";
            h = h % 12 || 12;
            return `${pad(h)}:${m} ${ap}`;
        }
        return `${pad(h)}:${m}`;
    }

    function formatOffset(offset: int): string {
        const sign = offset >= 0 ? "+" : "-";
        const a = Math.abs(offset);
        const h = Math.floor(a / 60);
        const m = a % 60;
        return `UTC${sign}${h}${m ? ":" + pad(m) : ""}`;
    }

    function setZone(z: string): void {
        zone = z;
        store.setText(z);
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase().replace(/ /g, "_");
        if (!q)
            return zones;
        const starts = [];
        const contains = [];
        for (const z of zones) {
            const c = z.city.toLowerCase().replace(/ /g, "_");
            const full = z.zone.toLowerCase();
            if (c.startsWith(q))
                starts.push(z);
            else if (full.includes(q))
                contains.push(z);
        }
        return starts.concat(contains);
    }

    FileView {
        id: store

        path: `${Paths.state}/worldclock.txt`
        printErrors: false
        onLoaded: root.zone = text().trim()
    }

    Process {
        id: listProc

        running: true
        command: ["python3", "-I", "-c", `
import zoneinfo, datetime
now = datetime.datetime.now(datetime.timezone.utc)
out = []
for z in sorted(zoneinfo.available_timezones()):
    if "/" not in z or z.startswith(("Etc/", "SystemV/", "US/", "posix", "right")):
        continue
    try:
        off = now.astimezone(zoneinfo.ZoneInfo(z)).utcoffset()
    except Exception:
        continue
    out.append(f"{z}\\t{int(off.total_seconds() // 60)}")
print("\\n".join(out))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const [z, off] = line.split("\t");
                    if (!z)
                        continue;
                    const parts = z.split("/");
                    list.push({
                        zone: z,
                        city: root.cityOf(z),
                        region: parts.slice(0, -1).join(" / ").replace(/_/g, " "),
                        offset: parseInt(off)
                    });
                }
                root.zones = list;
            }
        }
    }

    // Refresh offsets hourly so daylight-saving changes are picked up
    Timer {
        interval: 3600000
        repeat: true
        running: true
        onTriggered: listProc.running = true
    }
}
