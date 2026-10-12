// 割圆的例子
import QtQuick
import QtQuick.Layouts
import Fk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  signal finish()
  property string name
  property var all: []
  property var ok: []

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(root.name)
  }

  PathView {
    id: pathView
    Layout.fillWidth: true
    Layout.fillHeight: true
    model: root.all
    delegate: Rectangle{
      width: 42; height: 42
      color: root.ok.includes(modelData) ? "yellow" : "#CCEEEEEE"
      radius: 2
      Text {
        anchors.centerIn: parent
        text: modelData
        font.pixelSize: 24
      }
    }
    path: Path {
      // 默认横屏了，应该没人用竖屏玩这游戏
      startX: pathView.width / 2
      startY: 40
      PathArc {
        x: pathView.width / 2
        y: pathView.height - 40
        radiusX: (pathView.height - 80) / 2
        radiusY: (pathView.height - 80) / 2
        direction: PathArc.Clockwise
      }
      PathArc {
        x: pathView.width / 2
        y: 40
        radiusX: (pathView.height - 80) / 2
        radiusY: (pathView.height - 80) / 2
        direction: PathArc.Clockwise
      }
    }
  }
}
