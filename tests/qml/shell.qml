import QtQuick
import Quickshell
import "../../" as Mixtape

// Run through the isolated harness described in tests/check-qml.py.
ShellRoot {
    property real before: 0
    property real stopped: 0
    property var reel: null
    property int phase: 0
    property int wait: 0
    function findReel(item) {
        if (item.objectName === "cassetteReel0") return item
        for (var i = 0; i < item.children.length; i++) {
            var found = findReel(item.children[i])
            if (found) return found
        }
        return null
    }
    function findByName(item, name) {
        if (item.objectName === name) return item
        for (var i = 0; i < item.children.length; i++) {
            var found = findByName(item.children[i], name)
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
            id: probeBrowser
            width: 396; height: 510
            listing: ({path: "/tmp", parent: "/", entries: [
                {name: "Songs", path: "/tmp/Songs", directory: true},
                {name: "Track one.wav", path: "/tmp/one.wav", directory: false}
            ]})
            albums: ({path: "/music", entries: [
                {name: "Album A", path: "/music/A", trackCount: 3}
            ]})
        }
        Mixtape.Widget { id: widget; moduleName: "mixtape-test" }
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
                check(findByName(probeBrowser, "browserTabCustom") !== null, "custom tab exists")
                check(findByName(probeBrowser, "browserTabAlbums") !== null, "albums tab exists")
                check(!probeBrowser.albumView, "eject opens on custom tab")
                probeBrowser.toggleTabs()
            } else if (phase === 8) {
                check(probeBrowser.albumView, "Tab switches to albums")
                var albumsList = findByName(probeBrowser, "albumList")
                check(albumsList !== null, "album list exists")
                check(albumsList.count === 1, "album tape rendered from folder")
                check(!findByName(probeBrowser, "fileList").visible, "file list hidden on albums tab")
                probeBrowser.toggleTabs()
            } else if (phase === 9) {
                check(!probeBrowser.albumView, "Tab switches back to custom")
                check(findByName(probeBrowser, "fileList").visible, "file list restored on custom tab")
                check(findByName(probeBrowser, "searchLine") !== null, "search line exists")
                check(findByName(probeBrowser, "searchField") !== null, "search field exists")
                probeBrowser.searchQuery = "Songs"
                check(probeBrowser.displayEntries.length === 2, "filter narrows the custom list")
                check(probeBrowser.searchActive, "filtered state is active")
                probeBrowser.startSearch()
            } else if (phase === 10) {
                check(probeBrowser.searchTyping, "/ starts typing mode")
                probeBrowser.confirmSearch()
                check(!probeBrowser.searchTyping && probeBrowser.searchQuery === "Songs", "Enter confirms the filter")
                check(probeBrowser.searchActive, "confirmed filter stays active")
            } else if (phase === 11) {
                probeBrowser.clearSearch()
                check(!probeBrowser.searchActive, "Escape clears the filter")
                check(probeBrowser.displayEntries.length === 3, "list restored after clear")
                widget.eject()
            } else if (phase === 12) {
                check(widget.view === "browser", "eject opens the browser")
            } else if (phase === 13) {
                if (widget.listing.entries.length === 0 && wait < 40) {
                    wait++
                    phase = 12
                } else {
                    check(widget.listing.entries.length === 1, "custom tab lists saved mixes")
                    console.log("PASS: reel close/reopen and pause/resume; tab switching, dynamic album tapes, filtering, and eject library")
                    Qt.quit()
                }
            }
        }
    }
}
