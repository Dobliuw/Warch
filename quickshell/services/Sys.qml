pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Métricas del sistema: CPU, RAM, GPU, red, VPN y actualizaciones.
Singleton {
    id: root

    property int cpu: 0
    property real ramUsedG: 0
    property real ramTotalG: 0
    property int gpuTemp: 0
    property int gpuUtil: 0
    property int cpuTemp: 0
    property real diskUsedG: 0
    property real diskTotalG: 0
    property int uptimeS: 0
    property string kernel: ""
    property real rxMBs: 0
    property real txMBs: 0
    // VPN: tun* es la de laboratorio (openvpn: HTB, THM…) y su IP es el LHOST; nordlynx es NordVPN
    property string tun0: ""        // IP de la primera interfaz tun* (LHOST)
    property string tunName: ""     // nombre de esa interfaz (tun0, tun1…)
    property string nordIp: ""
    readonly property bool nordUp: nordIp !== ""
    readonly property string vpnName: tun0 ? tunName : nordIp ? "nordlynx" : ""
    readonly property string vpnIp: tun0 || nordIp
    property int updates: -1        // -1 = desconocido

    property var _cpuPrev: null
    property var _netPrev: null
    property string iface: ""      // interfaz de la ruta por defecto (cable o Wi-Fi)

    // CPU, RAM y red desde /proc, cada 2s
    FileView { id: statFile; path: "/proc/stat"; onLoaded: root.parseCpu(text()) }
    FileView { id: memFile; path: "/proc/meminfo"; onLoaded: root.parseMem(text()) }
    FileView { id: netFile; path: "/proc/net/dev"; onLoaded: root.parseNet(text()) }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: { statFile.reload(); memFile.reload(); netFile.reload(); }
    }

    function parseCpu(t) {
        const f = t.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (f.length < 5) return;
        const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
        if (_cpuPrev) {
            const dt = total - _cpuPrev.total, di = idle - _cpuPrev.idle;
            if (dt > 0) cpu = Math.round(100 * (1 - di / dt));
        }
        _cpuPrev = { idle, total };
    }

    function parseMem(t) {
        const get = k => { const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")); return m ? Number(m[1]) : 0; };
        ramTotalG = get("MemTotal") / 1048576;
        ramUsedG = (get("MemTotal") - get("MemAvailable")) / 1048576;
    }

    function parseNet(t) {
        const line = t.split("\n").find(l => l.trim().startsWith(iface + ":"));
        if (!line) return;
        const f = line.split(":")[1].trim().split(/\s+/).map(Number);
        const now = Date.now();
        if (_netPrev) {
            const s = (now - _netPrev.t) / 1000;
            rxMBs = (f[0] - _netPrev.rx) / s / 1048576;
            txMBs = (f[8] - _netPrev.tx) / s / 1048576;
        }
        _netPrev = { rx: f[0], tx: f[8], t: now };
    }

    // GPU NVIDIA cada 3s
    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",").map(s => parseInt(s));
                if (p.length >= 2) { root.gpuTemp = p[0]; root.gpuUtil = p[1]; }
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: gpuProc.running = true }

    // Interfaces VPN cada 5s
    Process {
        id: addrProc
        command: ["ip", "-4", "-j", "addr"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ifs = JSON.parse(text);
                    const ip = name => { const i = ifs.find(x => x.ifname === name); return i && i.addr_info.length ? i.addr_info[0].local : ""; };
                    const tun = ifs.find(x => /^tun\d+$/.test(x.ifname) && x.addr_info.length);
                    root.tunName = tun ? tun.ifname : "";
                    root.tun0 = tun ? tun.addr_info[0].local : "";
                    root.nordIp = ip("nordlynx");
                } catch (e) {}
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: addrProc.running = true }

    // Actualizaciones cada 30 min (checkupdates viene de pacman-contrib)
    Process {
        id: updProc
        command: ["sh", "-c", "{ command -v checkupdates >/dev/null && checkupdates; command -v yay >/dev/null && yay -Qua; } 2>/dev/null | wc -l"]
        stdout: StdioCollector { onStreamFinished: root.updates = parseInt(text.trim()) }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: updProc.running = true }

    // Temperatura de CPU (coretemp) cada 3s
    Process {
        id: cpuTempProc
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = coretemp ] && cat $h/temp1_input && break; done"]
        stdout: StdioCollector { onStreamFinished: root.cpuTemp = Math.round(parseInt(text.trim()) / 1000) || 0 }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuTempProc.running = true }

    // Disco (/) cada minuto
    Process {
        id: diskProc
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                if (f.length === 2) { root.diskUsedG = f[0] / 1073741824; root.diskTotalG = f[1] / 1073741824; }
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: diskProc.running = true }

    // Tiempo encendido
    FileView { id: upFile; path: "/proc/uptime"; onLoaded: root.uptimeS = Math.floor(parseFloat(text())) }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: upFile.reload() }

    Process {
        running: true
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: root.kernel = text.trim() }
    }

    function fmtUptime() {
        const h = Math.floor(uptimeS / 3600), m = Math.floor(uptimeS / 60) % 60;
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }

    // Interfaz de salida a internet (cambia si pasás de cable a Wi-Fi)
    Process {
        id: routeProc
        command: ["ip", "-j", "route", "get", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const r = JSON.parse(text)[0]; if (r && r.dev !== root.iface) { root.iface = r.dev; root._netPrev = null; } } catch (e) {}
            }
        }
    }
    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true; onTriggered: routeProc.running = true }
}
