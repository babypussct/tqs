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

  Text {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    font.pixelSize: 18
    color: "#E4D5A0"
    text: '<b>' + Lua.tr(value[1]) + "</b>: " + Lua.tr(":" + value[1])

    wrapMode: Text.WordWrap
    textFormat: Text.RichText
  }
  
}

