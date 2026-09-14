import QtQuick
import Quickshell
import "../../" as Mixtape

// Run through the isolated harness described in tests/check-qml.py.
ShellRoot {
    property real before: 0
    property real stopped: 0
    property var reel: null
    property int phase: 0
    function findReel(item) {
        if (item.objectName === "cassetteReel0") return item
        for (var i = 0; i < item.children.length; i++) {
            var found = findReel(item.children[i])
            if (found) return found
        }
        return null
    }
    function check(condition, message) {
        if (!condition) { console.error("FAIL: " + message); Qt.exit(1) }
    }
    Item {
        Mixtape.Cassette { id: tape; width: 396; height: 210; playing: true }
        Mixtape.QueueView {
            width: 396; height: 510
            state: ({name: "Test mix", count: 2, queue: [
                {id: 10, title: "Track one", path: "/tmp/one.wav", current: true},
                {id: 11, title: "Track two", path: "/tmp/two.wav", current: false}
            ]})
        }
        Mixtape.MusicBrowser {
            width: 396; height: 510
            listing: ({path: "/tmp", parent: "/", entries: [
                {name: "Songs", path: "/tmp/Songs", directory: true},
                {name: "Track one.wav", path: "/tmp/one.wav", directory: false}
            ]})
        }
    }
    Timer {
        interval: 180; repeat: true; running: true
        onTriggered: {
            phase++
            if (phase === 1) {
                reel = findReel(tape)
                check(reel !== null, "reel exists")
                before = reel.rotation
            } else if (phase === 2) {
                check(reel.rotation !== before, "spins during playback")
                tape.animationVisible = false
            } else if (phase === 3) {
                tape.animationVisible = true
                before = reel.rotation
            } else if (phase === 4) {
                check(reel.rotation !== before, "resumes after reopening")
                tape.playing = false
            } else if (phase === 5) {
                stopped = reel.rotation
            } else if (phase === 6) {
                check(reel.rotation === stopped, "stops while paused")
                tape.playing = true
                before = reel.rotation
            } else if (phase === 7) {
                check(reel.rotation !== before, "resumes after pause")
                console.log("PASS: reel close/reopen and pause/resume; populated queue and browser loaded")
                Qt.quit()
            }
        }
    }
}
