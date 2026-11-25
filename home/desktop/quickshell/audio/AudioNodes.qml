pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values

    readonly property var sinks: root.nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var sources: root.nodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
    readonly property var outStreams: root.nodes.filter(n => n.isStream && n.type === PwNodeType.AudioOutStream)
    readonly property var recorders: root.nodes.filter(n => n.type === PwNodeType.AudioInStream && !n.name.startsWith("capture."))

    function appName(n: var): string {
        return n.properties["application.name"] || n.description || n.name;
    }
}
