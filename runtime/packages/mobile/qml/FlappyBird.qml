// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups

GraphicsBox {
  id: root

  property bool gameRunning: false
  property int score: 0
  property real birdY: 250
  property real birdVelocity: 0
  property real birdX: 100
  property real birdSize: 30
  property real gravity: 0.125
  property real flapStrength: -8 / 3
  property real mountainSpeed: 3
  property real starSize: 28
  property int mountainIdCounter: 0
  property int totalStarsToSpawn: 0
  property int starsSpawned: 0

  property var cloudList: []
  property var starSpawnDelays: []
  property var mountainVines: ({})

  property int countdownValue: 3

  ListModel {
    id: mountainModel
  }

  ListModel {
    id: starModel
  }

  Timer {
    id: gameTimer
    interval: 16
    repeat: true
    running: gameRunning
    onTriggered: updateGame()
  }

  Timer {
    id: mountainSpawnTimer
    interval: 1500
    repeat: true
    running: false
    onTriggered: spawnMountain()
  }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    running: false
    onTriggered: {
      if (countdownValue > 1) {
        countdownValue--
      } else if (countdownValue === 1) {
        countdownValue--
        countdownTimer.stop()
        startGame()
      }
    }
  }

  Timer {
    id: gameDurationTimer
    interval: 15000
    repeat: false
    running: false
    onTriggered: gameOver(false)
  }

  title.text: "FlappyBird"
  width: 800
  height: 600

  function initGame() {
    score = 0
    birdY = gameCanvas.height / 2 - birdSize / 2
    birdVelocity = 0
    mountainModel.clear()
    starModel.clear()
    mountainVines = {}
    mountainIdCounter = 0
    starsSpawned = 0
    totalStarsToSpawn = 0
    starSpawnDelays = []
    cloudList = [
      { x: 80, y: 50, scale: 1.0 },
      { x: 400, y: 120, scale: 1.2 },
      { x: 650, y: 30, scale: 0.8 },
      { x: 200, y: 220, scale: 0.9 },
      { x: 550, y: 180, scale: 1.1 }
    ]
  }

  function startGame() {
    gameRunning = true

    totalStarsToSpawn = 3
    starsSpawned = 0

    spawnStar()

    starSpawnDelays = [4000, 8000]

    spawnMountainAtPosition(gameCanvas.width / 2, false)

    mountainSpawnTimer.start()
    gameDurationTimer.start()
  }

  function updateGame() {
    if (!gameRunning) return

    birdVelocity += gravity
    birdY += birdVelocity

    if (birdY < 0 || birdY + birdSize > gameCanvas.height) {
      gameOver(true)
      return
    }

    var birdCenterX = birdX + birdSize / 2
    var birdCenterY = birdY + birdSize / 2
    var birdRadius = birdSize / 2

    for (var i = 0; i < mountainModel.count; i++) {
      var m = mountainModel.get(i)
      var newX = m.x - mountainSpeed

      if (newX + m.width < 0) {
        delete mountainVines[m.id]
        mountainModel.remove(i)
        i--
        continue
      }

      mountainModel.setProperty(i, "x", newX)

      var triangle = getMountainTriangle({
        x: newX,
        baseY: m.baseY,
        width: m.width,
        height: m.height,
        inverted: m.inverted,
        apexOffset: m.apexOffset
      })
      if (circleTriangleIntersect(birdCenterX, birdCenterY, birdRadius, triangle)) {
        gameOver(true)
        return
      }
    }

    for (var d = starSpawnDelays.length - 1; d >= 0; d--) {
      starSpawnDelays[d] -= 16
      if (starSpawnDelays[d] <= 0) {
        spawnStar()
        starSpawnDelays.splice(d, 1)
      }
    }

    for (var j = 0; j < starModel.count; j++) {
      var star = starModel.get(j)
      var newStarX = star.x - mountainSpeed

      if (newStarX + starSize < 0) {
        starModel.remove(j)
        j--
        continue
      }

      starModel.setProperty(j, "x", newStarX)

      var starCenterX = newStarX + starSize / 2
      var starCenterY = star.y + starSize / 2
      var dist = Math.sqrt(Math.pow(birdCenterX - starCenterX, 2) + Math.pow(birdCenterY - starCenterY, 2))
      if (dist < birdRadius + starSize / 2) {
        score++
        starModel.remove(j)
        j--
      }
    }
  }

  function getMountainTriangle(m) {
    var apexX = m.x + m.width / 2 + (m.apexOffset || 0) * m.width
    if (m.inverted) {
      return [
        { x: m.x, y: m.baseY },
        { x: m.x + m.width, y: m.baseY },
        { x: apexX, y: m.baseY + m.height }
      ]
    } else {
      return [
        { x: m.x, y: m.baseY },
        { x: m.x + m.width, y: m.baseY },
        { x: apexX, y: m.baseY - m.height }
      ]
    }
  }

  function circleTriangleIntersect(cx, cy, r, triangle) {
    if (pointInTriangle(cx, cy, triangle)) return true
    for (var i = 0; i < 3; i++) {
      var p1 = triangle[i]
      var p2 = triangle[(i + 1) % 3]
      var dist = distancePointSegment(cx, cy, p1.x, p1.y, p2.x, p2.y)
      if (dist <= r) return true
    }
    return false
  }

  function pointInTriangle(px, py, t) {
    var a = t[0], b = t[1], c = t[2]
    var areaOrig = Math.abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y))
    var area1 = Math.abs((a.x - px) * (b.y - py) - (b.x - px) * (a.y - py))
    var area2 = Math.abs((b.x - px) * (c.y - py) - (c.x - px) * (b.y - py))
    var area3 = Math.abs((c.x - px) * (a.y - py) - (a.x - px) * (c.y - py))
    return Math.abs(area1 + area2 + area3 - areaOrig) < 0.01
  }

  function distancePointSegment(px, py, x1, y1, x2, y2) {
    var dx = x2 - x1
    var dy = y2 - y1
    if (dx === 0 && dy === 0) return Math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1))
    var t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = Math.max(0, Math.min(1, t))
    var projX = x1 + t * dx
    var projY = y1 + t * dy
    return Math.sqrt((px - projX) * (px - projX) + (py - projY) * (py - projY))
  }

  function spawnMountain() {
    spawnMountainAtPosition(gameCanvas.width, false)
  }

  function spawnMountainAtPosition(xPos, withStar) {
    var minWidth = birdSize * 4
    var maxWidth = birdSize * 8
    var width = minWidth + Math.random() * (maxWidth - minWidth)
    var height = width * 0.8

    var inverted = Math.random() < 0.5

    var baseY
    if (inverted) {
      baseY = Math.random() * (gameCanvas.height - height)
    } else {
      baseY = height + Math.random() * (gameCanvas.height - height)
    }

    var apexOffset = (Math.random() - 0.5) * 0.6   // -0.3 ~ 0.3
    var domeFactor = 0.2 + Math.random() * 0.6     // 0.2 ~ 0.8

    var mountainId = mountainIdCounter++

    // 生成藤蔓数据：起点在山体内部，基本垂直向下，微小角度
    var vineData = []
    var vineCount = 1 + Math.floor(Math.random() * 3) // 1~3条
    for (var vi = 0; vi < vineCount; vi++) {
      var startX = width * (0.3 + Math.random() * 0.4)   // 30%~70% 宽度
      var startY = height * (0.2 + Math.random() * 0.3)  // 20%~50% 高度（山体上部）
      var length = height * (0.3 + Math.random() * 0.3)  // 长度为高度的30%~60%
      var angle = (Math.random() - 0.5) * 0.1            // 微小角度（弧度约±5.7°）
      var endX = startX + Math.sin(angle) * length
      var endY = startY + Math.cos(angle) * length       // 近似垂直向下
      var ctrlX = startX + (endX - startX) * 0.3         // 控制点轻微偏移
      var ctrlY = startY + length * 0.5
      var leafCount = 2 + Math.floor(Math.random() * 3)   // 2~4片叶子
      var leafRatios = []
      for (var li = 0; li < leafCount; li++) {
        leafRatios.push(Math.random())
      }
      vineData.push({
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        ctrlX: ctrlX,
        ctrlY: ctrlY,
        leafRatios: leafRatios
      })
    }
    mountainVines[mountainId] = vineData

    mountainModel.append({
      id: mountainId,
      x: xPos,
      baseY: baseY,
      width: width,
      height: height,
      inverted: inverted,
      apexOffset: apexOffset,
      domeFactor: domeFactor,
      hasStar: false
    })
  }

  function spawnStar() {
    if (!gameRunning) return
    if (starsSpawned >= totalStarsToSpawn) return

    var minY = gameCanvas.height * 0.25
    var maxY = gameCanvas.height * 0.75
    var starY = minY + Math.random() * (maxY - minY)

    var starCenterX = gameCanvas.width + 20 + starSize / 2
    var starCenterY = starY + starSize / 2
    var starRadius = starSize / 2
    var attempts = 0
    var overlap = false
    while (attempts < 5) {
      overlap = false
      for (var i = 0; i < mountainModel.count; i++) {
        var m = mountainModel.get(i)
        var triangle = getMountainTriangle({
          x: m.x,
          baseY: m.baseY,
          width: m.width,
          height: m.height,
          inverted: m.inverted,
          apexOffset: m.apexOffset
        })
        if (circleTriangleIntersect(starCenterX, starCenterY, starRadius, triangle)) {
          overlap = true
          break
        }
      }
      if (!overlap) break
      starY = minY + Math.random() * (maxY - minY)
      starCenterY = starY + starSize / 2
      attempts++
    }

    if (overlap) return

    starModel.append({
      x: gameCanvas.width + 20,
      y: starY
    })
    starsSpawned++
  }

  function flapUp() {
    if (!gameRunning) return
    birdVelocity = flapStrength
  }

  function gameOver(failed) {
    if (!gameRunning) return
    gameRunning = false
    mountainSpawnTimer.stop()
    countdownTimer.stop()
    gameDurationTimer.stop()

    close()
    Ltk.roomModel.deActivate()
    ClientInstance.notifyServer("PushRequest", "updatemini,closeFrame")

    var resultStr = score.toString() + "," + (failed ? "true" : "false")
    ClientInstance.replyToServer("", resultStr)
  }

  ColumnLayout {
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    anchors.topMargin: 50
    anchors.bottomMargin: 15
    anchors.leftMargin: 15
    anchors.rightMargin: 15

    Rectangle {
      id: gameCanvas
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#87CEEB"
      border.color: "#555"
      border.width: 2
      radius: 5
      clip: true

      Repeater {
        model: cloudList
        delegate: Text {
          x: modelData.x
          y: modelData.y
          text: "☁"
          font.pixelSize: 40 * modelData.scale
          color: "white"
          opacity: 0.7
        }
      }

      Repeater {
        model: mountainModel
        delegate: Item {
          x: model.x
          y: model.inverted ? model.baseY : model.baseY - model.height
          width: model.width
          height: model.height

          property bool inverted: model.inverted
          property real apexOffset: model.apexOffset
          property real domeFactor: model.domeFactor

          Canvas {
            anchors.fill: parent
            property var vines: root.mountainVines[model.id]

            onPaint: {
              var ctx = getContext("2d")
              ctx.clearRect(0, 0, width, height)
              ctx.beginPath()

              var apexX = width / 2 + apexOffset * width
              var domeHeight = height * 0.15 * domeFactor

              if (inverted) {
                ctx.moveTo(0, 0)
                ctx.lineTo(width, 0)

                var rightEndX = apexX + width * 0.08
                var rightEndY = height - domeHeight
                var rightCtrlX = width * 0.75 - apexOffset * width * 0.2
                var rightCtrlY = height * 0.45
                ctx.quadraticCurveTo(rightCtrlX, rightCtrlY, rightEndX, rightEndY)

                var leftEndX = apexX - width * 0.08
                var leftEndY = height - domeHeight
                var domeCtrlX = apexX
                var domeCtrlY = height + domeHeight * 1.8
                ctx.quadraticCurveTo(domeCtrlX, domeCtrlY, leftEndX, leftEndY)

                var leftCtrlX = width * 0.25 + apexOffset * width * 0.2
                var leftCtrlY = height * 0.45
                ctx.quadraticCurveTo(leftCtrlX, leftCtrlY, 0, 0)
              } else {
                ctx.moveTo(0, height)
                ctx.lineTo(width, height)

                var rightEndX2 = apexX + width * 0.08
                var rightEndY2 = domeHeight
                var rightCtrlX2 = width * 0.75 - apexOffset * width * 0.2
                var rightCtrlY2 = height * 0.55
                ctx.quadraticCurveTo(rightCtrlX2, rightCtrlY2, rightEndX2, rightEndY2)

                var leftEndX2 = apexX - width * 0.08
                var leftEndY2 = domeHeight
                var domeCtrlX2 = apexX
                var domeCtrlY2 = -domeHeight * 1.8
                ctx.quadraticCurveTo(domeCtrlX2, domeCtrlY2, leftEndX2, leftEndY2)

                var leftCtrlX2 = width * 0.25 + apexOffset * width * 0.2
                var leftCtrlY2 = height * 0.55
                ctx.quadraticCurveTo(leftCtrlX2, leftCtrlY2, 0, height)
              }

              ctx.closePath()

              var gradient
              if (inverted) {
                gradient = ctx.createLinearGradient(0, 0, 0, height)
                gradient.addColorStop(0, "#8B5A2B")
                gradient.addColorStop(1, "#228B22")
              } else {
                gradient = ctx.createLinearGradient(0, height, 0, 0)
                gradient.addColorStop(0, "#8B5A2B")
                gradient.addColorStop(1, "#228B22")
              }
              ctx.fillStyle = gradient
              ctx.fill()

              // 绘制藤蔓
              if (typeof vines !== 'undefined' && vines !== null && vines.length > 0) {
                ctx.strokeStyle = "#2E8B57"
                ctx.lineWidth = 2
                ctx.fillStyle = "#3CB371"
                for (var vi = 0; vi < vines.length; vi++) {
                  var vine = vines[vi]
                  ctx.beginPath()
                  ctx.moveTo(vine.startX, vine.startY)
                  ctx.quadraticCurveTo(vine.ctrlX, vine.ctrlY, vine.endX, vine.endY)
                  ctx.stroke()

                  // 绘制叶片
                  for (var li = 0; li < vine.leafRatios.length; li++) {
                    var ratio = vine.leafRatios[li]
                    var leafX = Math.pow(1 - ratio, 2) * vine.startX + 2 * (1 - ratio) * ratio * vine.ctrlX + ratio * ratio * vine.endX
                    var leafY = Math.pow(1 - ratio, 2) * vine.startY + 2 * (1 - ratio) * ratio * vine.ctrlY + ratio * ratio * vine.endY
                    ctx.beginPath()
                    ctx.arc(leafX, leafY, 3, 0, Math.PI * 2)
                    ctx.fill()
                  }
                }
              }
            }
          }
        }
      }

      Repeater {
        model: starModel
        delegate: Rectangle {
          x: model.x
          y: model.y
          width: starSize
          height: starSize
          color: "transparent"
          Text {
            anchors.centerIn: parent
            text: "★"
            font.pixelSize: starSize * 0.8
            color: "#FFD700"
          }
        }
      }

      Item {
        id: bird
        x: birdX
        y: birdY
        width: birdSize
        height: birdSize

        Rectangle { x: 8; y: 12; width: 14; height: 10; color: "#FFD700"; radius: 2 }
        Rectangle { x: 16; y: 6; width: 10; height: 8; color: "#FFD700"; radius: 2 }
        Rectangle { x: 10; y: 12; width: 8; height: 6; color: "#FFA500"; radius: 1 }
        Rectangle { x: 2; y: 14; width: 6; height: 4; color: "#FFA500"; radius: 1 }
        Rectangle { x: 20; y: 8; width: 3; height: 3; color: "black" }
      }

      Text {
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Stars: " + score
        font.pixelSize: 24
        font.bold: true
        color: "white"
      }

      Text {
        anchors.centerIn: parent
        text: countdownValue > 0 ? countdownValue.toString() : ""
        font.pixelSize: 72
        font.bold: true
        color: "white"
        visible: countdownValue > 0
      }

      MouseArea {
        anchors.fill: parent
        onClicked: flapUp()
      }
    }
  }

  function loadData(data) {
    initGame()
    countdownValue = 3
    countdownTimer.start()
  }

  function updateData(data) {
    if (data === "closeFrame") {
      gameRunning = false
      mountainSpawnTimer.stop()
      countdownTimer.stop()
      gameDurationTimer.stop()
      close()
      Ltk.roomModel.deActivate()
      ClientInstance.replyToServer("", "__cancel")
    }
  }
}