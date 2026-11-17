pragma Singleton

// Local AI-agent usage (Claude Code, Antigravity, ...) for the bar ring + popout.
// Data comes from scripts/agent_usage.py, which only reads the agents' own local
// logs — no API calls, no undocumented endpoints.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var agents: []
    property real updated: 0

    // Claude is the primary agent (bar ring); the rest show under "Other agents"
    readonly property var claude: agents.find(a => a.id === "claude") ?? null
    readonly property var others: agents.filter(a => a.id !== "claude")
    readonly property real maxRatio: agents.reduce((m, a) => Math.max(m, a.ratio ?? 0), 0)

    function logo(agent: var): string {
        return agent?.logo ? `file://${Quickshell.shellPath(`assets/agents/${agent.logo}`)}` : "";
    }
    readonly property bool anyRunning: agents.some(a => a.running)

    function refresh(): void {
        if (!proc.running)
            proc.running = true;
    }

    function formatCount(n: real): string {
        if (n >= 1e6)
            return `${(n / 1e6).toFixed(n >= 1e7 ? 0 : 1)}M`;
        if (n >= 1e3)
            return `${(n / 1e3).toFixed(n >= 1e4 ? 0 : 1)}k`;
        return `${Math.round(n)}`;
    }

    function formatDuration(ms: real): string {
        const m = Math.max(0, Math.round(ms / 60000));
        const h = Math.floor(m / 60);
        return h > 0 ? `${h}h ${m % 60}m` : `${m}m`;
    }

    function formatAgo(ts: real): string {
        if (!ts)
            return "never";
        const m = Math.round((Date.now() - ts) / 60000);
        if (m < 1)
            return "just now";
        if (m < 60)
            return `${m}m ago`;
        const h = Math.floor(m / 60);
        if (h < 24)
            return `${h}h ago`;
        return `${Math.floor(h / 24)}d ago`;
    }

    Process {
        id: proc

        command: ["python3", "-I", `${Quickshell.shellDir}/scripts/agent_usage.py`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.agents = data.agents ?? [];
                    root.updated = data.updated ?? Date.now();
                } catch (e) {
                    console.warn("AgentUsage: bad output from agent_usage.py");
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 60000
        onTriggered: root.refresh()
    }
}
