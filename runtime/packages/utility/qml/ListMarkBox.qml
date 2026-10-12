// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components
import LunarLtk.Components.Photo

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  property var value: []
  signal finish()

  // 压制报错用
  readonly property var roomScene: Ltk.roomScene

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height

    text: Lua.tr(name)
  }

  GridView {
    id: grid
    cellWidth: 93 + 4
    cellHeight: 130 + 4
    Layout.preferredWidth: root.width - root.width % 97
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
    clip: true

    model: root.value.map(function(item) { return Lua.toQml(item).model; })
    delegate: Photo {
      scale: 0.65
      required property var modelData
      dataModel: Lua.createQmlObject(modelData)
      Component.onCompleted: {
        dataModel.state = "normal";
      }
    }
  }
}