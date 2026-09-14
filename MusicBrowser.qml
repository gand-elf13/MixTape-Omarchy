import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Item {
    id: root
    property var listing: ({path: "", parent: "", entries: []})
    property var selected: []
    property bool busy: false
    property bool adding: false
    signal back()
    signal browse(string path)
    signal library()
    signal submit(string command, var value)

    function resetSelection() { selected = [] }
    function select(path, checked) {
        var next = selected.filter(function(p) { return p !== path })
        if (checked) next.push(path)
        selected = next
    }
    onListingChanged: resetSelection()

    Column {
        anchors.fill: parent; spacing: 10
        Row {
            spacing: 8
            MixButton { text: "‹ Back"; onClicked: root.back() }
            MixButton { text: "↑ Up"; enabled: !root.busy; onClicked: root.browse(root.listing.parent) }
            MixButton { text: "Saved mixes"; enabled: !root.busy; onClicked: root.library() }
        }
        Text { text: root.adding ? "ADD TO YOUR MIXTAPE" : "LOAD A MIXTAPE"; color: Color.foreground; font.family: "monospace"; font.pixelSize: 12; font.bold: true }
        Controls.TextField {
            width: parent.width
            text: root.listing.path
            placeholderText: "Directory path — press Enter"
            onAccepted: root.browse(text)
        }
        Row {
            spacing: 8
            MixButton {
                text: "Select all"
                enabled: !root.busy
                onClicked: root.selected = root.listing.entries.filter(function(e) { return !e.directory }).map(function(e) { return e.path })
            }
            MixButton { text: "None"; onClicked: root.resetSelection() }
            MixButton {
                text: "+ Folder"
                enabled: !root.busy
                onClicked: root.submit("add-folder", root.listing.path)
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: "Add audio files in this folder (not subfolders)"
            }
        }
        ListView {
            id: files
            width: parent.width; height: Math.max(100, root.height - y - 76); clip: true
            model: root.listing.entries
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
            delegate: Row {
                required property var modelData
                width: files.width; height: 36
                Controls.CheckBox {
                    width: 34; height: 36
                    visible: !modelData.directory
                    enabled: !root.busy
                    checked: root.selected.indexOf(modelData.path) !== -1
                    Accessible.name: "Select " + modelData.name
                    onClicked: root.select(modelData.path, checked)
                }
                Controls.ItemDelegate {
                    width: parent.width - (modelData.directory ? 0 : 34); height: 36
                    enabled: !root.busy
                    contentItem: Text {
                        text: (modelData.directory ? "▸  " : "") + modelData.name
                        textFormat: Text.PlainText; elide: Text.ElideMiddle
                        color: Color.foreground; font.family: "monospace"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (modelData.directory) root.browse(modelData.path)
                        else root.select(modelData.path, root.selected.indexOf(modelData.path) === -1)
                    }
                }
            }
            Text { anchors.centerIn: parent; visible: !root.busy && files.count === 0; text: "No music here yet."; color: Color.foreground; font.family: "monospace"; font.pixelSize: 12 }
        }
        Row {
            spacing: 8
            MixButton {
                text: (root.adding ? "Add selected (" : "Play selected (") + root.selected.length + ")"
                enabled: !root.busy && root.selected.length > 0
                highlightedMix: true
                onClicked: root.submit(root.adding ? "append" : "load-many", root.selected)
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: root.adding ? "Keeps current playback" : "Replaces current queue"; color: Color.foreground; opacity: 0.55; font.pixelSize: 10 }
        }
    }
}
