import QtQuick
import Qt5Compat.GraphicalEffects
import Fk

Item {
  id: root
  height: 90
  width: height / bg.sourceSize.height * bg.sourceSize.width

  property string value: ""
  property real num: value ? Number(value) : 0

  Image {
    id: bgCaomao
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    source: Cpp.path + "/packages/mobile/image/personalMark/qianlong/qianlong-bg.png"
  }

  Rectangle {
    x: 41; y: 66
    color: "#6dffcd"
    height: 7
    width: parent.num * 1.05
  }

  Row {
    x: 42
    y: 50
    spacing: 28
    Repeater {
      model: 4
      Rectangle {
        width: 4.3
        height: 15
        color: "#6dffcd"
        radius: 2
        opacity: root.num >= (index * 33) ? 1 : 0
      }
    }
  }

  Image {
    id: bg
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    source: Cpp.path + "/packages/mobile/image/personalMark/qianlong/qianlong.png"
  }

  Glow {
    source: text
    anchors.fill: text
    color: "#5c3422"
    spread: 0.9
    radius: 3
  }

  Text {
    id: text
    text: String(parent.num)
    font.pixelSize: 20
    font.family: "LiSu"
    font.bold: true
    color: '#f5ca53'
    x: 110
    y: 27
  }

}