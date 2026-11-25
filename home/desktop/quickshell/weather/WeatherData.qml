pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string place: "Ankara"
    readonly property real latitude: 39.9334
    readonly property real longitude: 32.8597

    property bool ready: false
    property bool failed: false
    property var current: ({})
    property var days: []
    property string sunrise: ""
    property string sunset: ""
    property date updated
    property var request: null

    readonly property string glyph: ready ? glyphFor(current.code, current.night) : ""
    readonly property string condition: ready ? nameFor(current.code) : ""

    function glyphFor(code: int, night: bool): string {
        const g = c => String.fromCodePoint(c);
        if (code === 0)
            return night ? g(0xF0594) : g(0xF0599);
        if (code <= 2)
            return night ? g(0xF0F31) : g(0xF0595);
        if (code === 3)
            return g(0xF0590);
        if (code === 45 || code === 48)
            return g(0xF0591);
        if (code >= 51 && code <= 61)
            return g(0xF0597);
        if (code === 66 || code === 67)
            return g(0xF067F);
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return g(0xF0598);
        if (code === 63 || code === 65 || (code >= 80 && code <= 82))
            return g(0xF0596);
        if (code >= 95)
            return g(0xF067E);
        return g(0xF0590);
    }

    function nameFor(code: int): string {
        if (code === 0)
            return "Açık";
        if (code === 1)
            return "Az bulutlu";
        if (code === 2)
            return "Parçalı bulutlu";
        if (code === 3)
            return "Kapalı";
        if (code === 45 || code === 48)
            return "Sisli";
        if (code >= 51 && code <= 57)
            return "Çisenti";
        if (code === 61 || code === 80)
            return "Hafif yağmur";
        if (code === 63 || code === 81)
            return "Yağmurlu";
        if (code === 65 || code === 82)
            return "Sağanak";
        if (code === 66 || code === 67)
            return "Dondurucu yağmur";
        if (code >= 71 && code <= 77)
            return "Karlı";
        if (code === 85 || code === 86)
            return "Kar sağanağı";
        if (code >= 95)
            return "Gök gürültülü";
        return "Bulutlu";
    }

    function refresh(): void {
        const url = "https://api.open-meteo.com/v1/forecast" + `?latitude=${root.latitude}&longitude=${root.longitude}` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day,precipitation_probability" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset" + "&timezone=Europe%2FIstanbul&forecast_days=6";
        if (root.request)
            return;
        const xhr = new XMLHttpRequest();
        root.request = xhr;
        watchdog.restart();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.request !== xhr)
                return;
            root.request = null;
            watchdog.stop();
            try {
                if (xhr.status !== 200)
                    throw new Error(`HTTP ${xhr.status}`);
                root.apply(JSON.parse(xhr.responseText));
                root.failed = false;
                timer.interval = 15 * 60000;
            } catch (e) {
                console.warn(`weather: ${e}`);
                root.failed = true;
                timer.interval = 60000;
            }
            timer.restart();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function abandon(): void {
        const xhr = root.request;
        if (!xhr)
            return;
        root.request = null;
        xhr.abort();
        console.warn("weather: timeout");
        root.failed = true;
        timer.interval = 60000;
        timer.restart();
    }

    function apply(r: var): void {
        const c = r.current;
        const d = r.daily;
        const round = v => v === null || v === undefined ? null : Math.round(v);
        root.current = {
            temp: round(c.temperature_2m),
            feels: round(c.apparent_temperature),
            humidity: round(c.relative_humidity_2m),
            wind: round(c.wind_speed_10m),
            rain: round(c.precipitation_probability),
            code: c.weather_code,
            night: c.is_day === 0
        };
        root.days = d.time.slice(1).map((t, i) => ({
                    date: new Date(`${t}T12:00:00`),
                    code: d.weather_code[i + 1],
                    max: round(d.temperature_2m_max[i + 1]),
                    min: round(d.temperature_2m_min[i + 1]),
                    rain: round(d.precipitation_probability_max[i + 1])
                }));
        root.sunrise = d.sunrise[0].slice(11);
        root.sunset = d.sunset[0].slice(11);
        root.updated = new Date();
        root.ready = true;
    }

    Timer {
        id: timer
        interval: 15 * 60000
        running: true
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: watchdog
        interval: 20000
        onTriggered: root.abandon()
    }

    Component.onCompleted: refresh()
}
