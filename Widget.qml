import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "local.mixtape"
    manageIpc: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    property var state: ({loaded: false, paused: true, title: "Insert a mixtape", volume: 70})
    property string errorMessage: ""
    property string view: "deck"
    property bool adding: false
    property string browserReturn: "deck"
    property string pendingView: ""
    property string notice: ""
    property var listing: ({path: "", parent: "", entries: []})
    property string currentDirectory: Quickshell.env("HOME")
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("player.py").toString().replace(/^file:\/\//, ""))
    readonly property bool playing: state.loaded && !state.paused && !state.ended

    function clock(seconds) {
        var value = Math.max(0, Math.floor(Number(seconds) || 0))
        return Math.floor(value / 60) + ":" + (value % 60 < 10 ? "0" : "") + value % 60
    }
    function refresh() {
        if (!poll.running && !action.running) poll.running = true
    }
    function act(command, value) {
        if (action.running) return
        errorMessage = ""
        action.command = ["python3", helper, command]
        if (value !== undefined) action.command = action.command.concat([typeof value === "object" ? JSON.stringify(value) : String(value)])
        action.actionName = command
        action.running = true
    }
    function browse(path) {
        if (browser.running) return
        errorMessage = ""
        browser.command = ["python3", helper, "browse", path]
        browser.running = true
    }
    function eject() {
        openBrowser(false, false)
    }
    function openBrowser(append, saved) {
        browserReturn = view
        adding = append
        view = "browser"
        if (saved) showLibrary()
        else browse(currentDirectory)
    }
    function showLibrary() {
        if (browser.running) return
        browser.command = ["python3", helper, "library"]
        browser.running = true
    }
    function submitFiles(command, value) {
        if (action.running) return
        pendingView = command === "load-many" ? "deck" : "queue"
        act(command, value)
    }
    function acceptState(data, showErrors) {
        try {
            var next = JSON.parse(data)
            if (next.error) {
                if (showErrors) {
                    errorMessage = next.error
                    queueView.overwriteRequired = next.overwriteRequired === true
                    pendingView = ""
                }
            } else {
                if (JSON.stringify(next.queue) === JSON.stringify(state.queue)) next.queue = state.queue
                state = next
                if (showErrors) {
                    if (pendingView) { view = pendingView; pendingView = "" }
                    if (action.actionName === "save") {
                        queueView.saving = false
                        queueView.overwriteRequired = false
                        notice = "Saved “" + next.name + "”"
                        noticeTimer.restart()
                    }
                }
            }
        } catch (e) { if (showErrors) errorMessage = "Could not read player response" }
    }
    function open() {
        controller.show()
        playerWindow.visible = true
        Qt.callLater(function() { deck.forceActiveFocus() })
    }
    function close() {
        controller.hide()
        playerWindow.visible = false
    }
    onOpenedChanged: if (opened) refresh()
    Component.onCompleted: refresh()

    Process {
        id: poll
        command: ["python3", root.helper, "status"]
        stdout: StdioCollector { onStreamFinished: root.acceptState(text, false) }
    }
    Process {
        id: action
        property string actionName: ""
        stdout: StdioCollector { onStreamFinished: root.acceptState(text, true) }
        onExited: root.refresh()
    }
    Process {
        id: browser
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text)
                    if (result.error) root.errorMessage = result.error
                    else {
                        root.listing = result
                        root.currentDirectory = result.path
                    }
                } catch (e) { root.errorMessage = "Could not read directory" }
            }
        }
    }
    Timer { id: noticeTimer; interval: 4000; onTriggered: root.notice = "" }
    Timer { interval: root.opened ? 500 : 3000; running: true; repeat: true; onTriggered: root.refresh() }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        fixedWidth: Style.space(32)
        active: root.playing
        CassetteIcon {
            anchors.centerIn: parent
            width: Style.spaceReal(16.2)
            height: Style.spaceReal(12.15)
            ink: button.active ? button.activeColor : button.foreground
        }
        tooltipText: "Mixtape · " + String(root.state.title).replace(/</g, "‹").replace(/>/g, "›")
        onPressed: function(b) {
            if (b === Qt.MiddleButton) root.act("toggle")
            else if (b === Qt.RightButton) root.act("stop")
            else root.toggle()
        }
    }

    FloatingWindow {
        id: playerWindow
        title: "Mixtape"
        visible: false
        color: Color.background
        implicitWidth: 440
        implicitHeight: 610
        // Fixed-size utility windows float automatically in Hyprland.
        minimumSize: Qt.size(440, 610)
        maximumSize: Qt.size(440, 610)
        onClosed: root.close()

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Color.accent
            border.width: 1
        }
        Rectangle {
            id: titleBar
            width: parent.width
            height: 34
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.05)
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "MIXTAPE · drag to move"
                color: Color.foreground; font.family: "monospace"; font.pixelSize: 11
            }
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 42
                cursorShape: Qt.SizeAllCursor
                onPressed: if (titleBar.Window.window) titleBar.Window.window.startSystemMove()
            }
            MixButton {
                anchors.right: parent.right; anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 32; implicitHeight: 26
                text: "×"
                Accessible.name: "Close player"
                onClicked: root.close()
            }
        }

        Item {
            id: deck
            anchors.fill: parent
            anchors.margins: 18
            anchors.topMargin: titleBar.height + 16
            focus: true
            Keys.onEscapePressed: { if (root.view === "browser") root.view = root.browserReturn; else if (root.view === "queue") root.view = "deck"; else root.close() }
            Keys.onSpacePressed: if (root.view === "deck") root.act("toggle")
            Keys.onLeftPressed: if (root.view === "deck") root.act("seek", -10)
            Keys.onRightPressed: if (root.view === "deck") root.act("seek", 10)

            Column {
                anchors.fill: parent
                spacing: 14
                visible: root.view === "deck"
                Row {
                    width: parent.width
                    Text { width: parent.width - 65; text: "MIXTAPE / PORTABLE STEREO"; color: Color.foreground; font.family: "monospace"; font.pixelSize: 12; font.bold: true }
                    Text { text: root.playing ? "● PLAY" : "○ IDLE"; color: root.playing ? Color.accent : Color.foreground; font.family: "monospace"; font.pixelSize: 11 }
                }
                Cassette { width: parent.width; height: 210; playing: root.playing; animationVisible: root.opened && root.view === "deck"; title: root.state.name || "Untitled mixtape" }
                Column {
                    width: parent.width; spacing: 5
                    Text { width: parent.width; text: root.state.title || "Insert a mixtape"; textFormat: Text.PlainText; elide: Text.ElideRight; color: Color.foreground; font.family: "monospace"; font.pixelSize: 15; font.bold: true }
                    Text { width: parent.width; text: root.state.artist || (root.state.loaded ? "LOCAL AUDIO / TRACK " + ((root.state.index || 0) + 1) + " OF " + (root.state.count || 1) : "Press EJECT to choose music or a playlist"); textFormat: Text.PlainText; elide: Text.ElideRight; color: Color.foreground; opacity: 0.55; font.family: "monospace"; font.pixelSize: 11 }
                }
                Column {
                    width: parent.width; spacing: 7
                    Rectangle {
                        width: parent.width; height: 4; color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)
                        Rectangle { height: parent.height; width: parent.width * Math.min(1, (root.state.position || 0) / Math.max(1, root.state.duration || 0)); color: Color.accent }
                    }
                    Item {
                        width: parent.width; height: 14
                        Text { anchors.left: parent.left; text: root.clock(root.state.position); color: Color.foreground; font.family: "monospace"; font.pixelSize: 11 }
                        Text { anchors.right: parent.right; text: root.clock(root.state.duration); color: Color.foreground; font.family: "monospace"; font.pixelSize: 11 }
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    DeckButton { width: (parent.width - 32) / 5; text: "⏏"; caption: "EJECT"; hint: "Choose an audio file or playlist"; onClicked: root.eject() }
                    DeckButton { width: (parent.width - 32) / 5; transportDirection: -1; caption: "REW"; hint: "Previous track · hold to rewind 10 seconds"; enabled: root.state.loaded; onClicked: if (!didHold) root.act("previous"); onHeld: root.act("seek", -10) }
                    DeckButton { width: (parent.width - 32) / 5; text: root.playing ? "Ⅱ" : "▶"; caption: root.playing ? "PAUSE" : "PLAY"; enabled: root.state.loaded; ink: Color.accent; onClicked: root.act("toggle") }
                    DeckButton { width: (parent.width - 32) / 5; text: "■"; caption: "STOP"; enabled: root.state.loaded; onClicked: root.act("stop") }
                    DeckButton { width: (parent.width - 32) / 5; transportDirection: 1; caption: "FF"; hint: "Next track · hold to advance 10 seconds"; enabled: root.state.loaded; onClicked: if (!didHold) root.act("next"); onHeld: root.act("seek", 10) }
                }
                Row {
                    width: parent.width; spacing: 12
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "VOL"; color: Color.foreground; font.family: "monospace"; font.pixelSize: 10 }
                    Controls.Slider {
                        width: parent.width - 100; from: 0; to: 100; value: root.state.volume || 0
                        onPressedChanged: if (!pressed) root.act("volume", Math.round(value))
                        onMoved: if (!pressed) root.act("volume", Math.round(value))
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Math.round(root.state.volume || 0) + "%"; color: Color.foreground; font.family: "monospace"; font.pixelSize: 10 }
                }
                Row {
                    spacing: 8
                    MixButton { text: "Queue (" + (root.state.count || 0) + ")"; onClicked: root.view = "queue" }
                    MixButton { text: root.state.shuffle ? "Shuffle ON" : "Shuffle"; highlightedMix: root.state.shuffle === true; enabled: !action.running && (root.state.count || 0) > 1; onClicked: root.act("shuffle") }
                    MixButton {
                        text: "Repeat: " + (root.state.repeat || "off")
                        highlightedMix: root.state.repeat !== undefined && root.state.repeat !== "off"
                        enabled: !action.running && (root.state.count || 0) > 0
                        onClicked: root.act("repeat", root.state.repeat === "off" ? "all" : root.state.repeat === "all" ? "one" : "off")
                    }
                }
            }

            QueueView {
                id: queueView
                anchors.fill: parent
                anchors.bottomMargin: 26
                visible: root.view === "queue"
                state: root.state
                busy: action.running
                onBack: root.view = "deck"
                onAdd: root.openBrowser(true, false)
                onLoad: root.openBrowser(false, true)
                onAction: function(command, value) { root.act(command, value) }
            }
            MusicBrowser {
                anchors.fill: parent
                anchors.bottomMargin: 26
                visible: root.view === "browser"
                listing: root.listing
                adding: root.adding
                busy: browser.running || action.running
                onBack: root.view = root.browserReturn
                onBrowse: function(path) { root.browse(path) }
                onLibrary: root.showLibrary()
                onSubmit: function(command, value) { root.submitFiles(command, value) }
            }
            Text {
                anchors.bottom: parent.bottom; width: parent.width
                visible: root.errorMessage !== "" || root.notice !== ""
                text: root.errorMessage || root.notice; textFormat: Text.PlainText; wrapMode: Text.Wrap
                color: root.errorMessage ? Color.urgent : Color.accent; font.pixelSize: 11
            }
        }
    }
}
