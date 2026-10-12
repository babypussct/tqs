import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent

  property string name: ""
  property var value: []
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(name)
  }

  ListView {
    id: body
    Layout.fillWidth: true
    Layout.fillHeight: true

    clip: true
    spacing: 20

    model: value

    delegate: TextEdit {
      id: skillDesc

      width: body.width
      font.pixelSize: 18
      color: "#E4D5A0"
      text: '<b>' + Lua.tr(modelData) + "</b>: " + Lua.tr(":" + modelData)

      readOnly: true
      selectByKeyboard: true
      selectByMouse: false
      wrapMode: TextEdit.WordWrap
      textFormat: TextEdit.RichText
    }
  }

}

