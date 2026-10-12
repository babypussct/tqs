import QtQuick

import Fk
import Fk.Widgets as W

Item {
  id: root

  // 二维数组
  property var mapData: [
    ["#", "D1", "#", "+4", "."],
    ["#", ".", "P", "H9", "#"],
    [".", "+7", ".", "#", "#"],
    [".", ".", "L1", "#", "#"]
  ]

  // 格子大小
  property int cellSize: 80
  property int spacing: -2

  // 行列数
  readonly property int rows: mapData ? mapData.length : 0
  readonly property int cols: (rows > 0 && mapData[0]) ? mapData[0].length : 0

  // 目前正查看的技能，默认为地图技能
  property string mapSkillName: ""
  property string activeSkillName: mapSkillName

  // 根据内容获取颜色
  function cellColor(value) {
    if (value === "#") return "transparent"    // 障碍
    if (value === ".") return "#4a453d"    // 普通地块
    if (value === "P") return "#2f5d87"    // 玩家所在
    if (value.startsWith("+")) return "#7a5a1f" // 摸牌
    if (value.startsWith("H")) return "#2f6b3d" // 回复
    if (value.startsWith("U") ||
      value.startsWith("D") ||
      value.startsWith("L") ||
      value.startsWith("R")) return "#5a4b8a" // 移动
    return "#4a453d"
  }

  // 根据内容获取文字
  function displayText(value) {
    value = value.substr(0, 2)
    if (value === "#") return ""
    if (value === ".") return ""
    if (value === "P") return "你"

    if (value.startsWith("+"))
      return "摸" + value.substring(1)

    if (value.startsWith("H"))
      return "回" + value.substring(1)

    if (value.startsWith("U"))
      return "↑" + value.substring(1)

    if (value.startsWith("D"))
      return "↓" + value.substring(1)

    if (value.startsWith("L"))
      return "←" + value.substring(1)

    if (value.startsWith("R"))
      return "→" + value.substring(1)

    return value
  }

  // 字体颜色
  function textColor(value) {
    if (value === "P")
      return "#f6d365"
    if (value.startsWith("H"))
      return "#b8f7c2"
    if (value.startsWith("+"))
      return "#ffd27d"
    if (value.startsWith("U") ||
      value.startsWith("D") ||
      value.startsWith("L") ||
      value.startsWith("R"))
      return "#c4b5fd"
    return "#f3efe6"
  }

  // 自动计算组件尺寸
  implicitWidth: cols * cellSize + Math.max(0, cols - 1) * spacing
  implicitHeight: rows * cellSize + Math.max(0, rows - 1) * spacing

  Grid {
    id: grid
    anchors.centerIn: parent
    rows: root.rows
    columns: root.cols
    rowSpacing: root.spacing
    columnSpacing: root.spacing

    Repeater {
      model: root.rows * root.cols

      delegate: Rectangle {
        required property int index

        readonly property int row: Math.floor(index / root.cols)
        readonly property int col: index % root.cols
        readonly property string value: root.mapData[row][col]

        width: root.cellSize
        height: root.cellSize
        radius: 0

        color: root.cellColor(value)
        border.width: value === "#" ? 0 : 2
        border.color: "#8a8175"

        Behavior on scale {
          NumberAnimation {
            duration: 150
          }
        }

        // 主文本
        Text {
          anchors.centerIn: parent
          text: root.displayText(parent.value)
          color: root.textColor(parent.value)
          font.pixelSize: parent.value === "P" ? 36 : 24
          font.bold: true
        }

        Text {
          visible: parent.value === "P"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: -2

          text: "♦"
          color: "#ff7b7b"      // 柔和红色
          font.pixelSize: 18
          font.bold: true
        }

        Text {
          visible: parent.value === "P"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: -2

          text: "♣"
          color: root.textColor(parent.value)
          font.pixelSize: 18
          font.bold: true
        }

        Text {
          visible: parent.value === "P"
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: 2

          text: "♥"
          color: "#ff7b7b"      // 柔和红色
          font.pixelSize: 18
          font.bold: true
        }

        Text {
          visible: parent.value === "P"
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: 2

          text: "♠"
          color: root.textColor(parent.value)
          font.pixelSize: 18
          font.bold: true
        }

        // 城池技能（左上角小字）
        Text {
          id: skillNameText
          visible: value.search(":") !== -1
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.leftMargin: 6
          anchors.topMargin: 4
          text: visible ? Lua.tr(value.substr(3)) : ""
          property string origText: value.substr(3)
          color: "snow"
          font.pixelSize: 14
        }

        // 原始指令（右下角小字）
        Text {
          visible: value !== "#" &&
                   value !== "." &&
                   value !== "P"
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: 6
          anchors.bottomMargin: 4
          text: value.substr(0,2)
          color: "snow"
          font.pixelSize: 14
        }

        W.TapHandler {
          enabled: skillNameText.visible
          onTapped: {
            if (root.activeSkillName === skillNameText.origText) {
              root.activeSkillName = root.mapSkillName;
            } else {
              root.activeSkillName = skillNameText.origText;
            }
          }
        }
      }
    }
  }
}
