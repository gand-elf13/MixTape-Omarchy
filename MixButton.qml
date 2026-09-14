import QtQuick
import QtQuick.Controls
import qs.Commons

Button {
    id: root
    property bool highlightedMix: false
    implicitHeight: 30
    implicitWidth: Math.max(48, label.implicitWidth + 18)
    hoverEnabled: true
    contentItem: Text {
        id: label
        text: root.text
        color: root.highlightedMix ? Color.accent : Color.foreground
        opacity: root.enabled ? 1 : 0.35
        font.family: "monospace"; font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 3
        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, root.down ? 0.15 : root.hovered ? 0.08 : 0.03)
        border.color: root.activeFocus || root.highlightedMix ? Color.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.25)
    }
}
