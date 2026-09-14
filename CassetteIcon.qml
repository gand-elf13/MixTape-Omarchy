import QtQuick

Canvas {
    id: icon
    property color ink: "white"
    implicitWidth: 24
    implicitHeight: 18
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.scale(width / 24, height / 18)
        ctx.strokeStyle = ink
        ctx.lineWidth = 1.4
        ctx.lineJoin = "round"

        // Cassette shell with rounded corners.
        ctx.beginPath()
        ctx.moveTo(3, 1)
        ctx.lineTo(21, 1)
        ctx.quadraticCurveTo(23, 1, 23, 3)
        ctx.lineTo(23, 15)
        ctx.quadraticCurveTo(23, 17, 21, 17)
        ctx.lineTo(3, 17)
        ctx.quadraticCurveTo(1, 17, 1, 15)
        ctx.lineTo(1, 3)
        ctx.quadraticCurveTo(1, 1, 3, 1)
        ctx.closePath()
        ctx.stroke()

        // Two reels joined by a visible strip of tape.
        ctx.beginPath()
        ctx.arc(7, 7, 2.5, 0, Math.PI * 2)
        ctx.moveTo(19.5, 7)
        ctx.arc(17, 7, 2.5, 0, Math.PI * 2)
        ctx.moveTo(9.5, 7)
        ctx.lineTo(14.5, 7)
        ctx.stroke()

        // The sloped lower tape-head opening makes the silhouette distinct.
        ctx.beginPath()
        ctx.moveTo(5, 16.5)
        ctx.lineTo(7, 12)
        ctx.lineTo(17, 12)
        ctx.lineTo(19, 16.5)
        ctx.stroke()
    }
}
