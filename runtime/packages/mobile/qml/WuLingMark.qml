// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  property var value: ({})
  property int playerid
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(root.name)
  }

  GridView {
    cellWidth: 93 + 4
    cellHeight: 130 + 4
    Layout.preferredWidth: root.width - root.width % 97
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
    clip: true

    model: root.value[0]

    delegate: CardItem {
      required property var modelData
      required property var index
      dataModel: Ltk.createCardModelFromName(modelData, { selectable: root.value[1] - 1 === index })
      autoBack: false
      suit: ''
      number: 0
    }
  }
}
