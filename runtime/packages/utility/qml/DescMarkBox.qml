import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(name)
  }

  ListView {
    Layout.fillWidth: true
    Layout.fillHeight: true

    clip: true
    spacing: 20
    TextEdit {
      id: skillDesc

      width: parent.width
      font.pixelSize: 18
      color: "#E4D5A0"
      text: name == ""  ? "" : Lua.tr(":" + name.slice(7))

      readOnly: true
      selectByKeyboard: true
      selectByMouse: false
      wrapMode: TextEdit.WordWrap
      textFormat: TextEdit.RichText
    }
  }

}

