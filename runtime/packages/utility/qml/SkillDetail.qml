// SPDX-License-Identifier: GPL-3.0-or-later
//疑似搬运到本体了，废弃
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Fk

Flickable {
  id: root
  anchors.fill: parent
  property var skills : []

  signal finish()

  contentHeight: details.height
  ScrollBar.vertical: ScrollBar {}

  ColumnLayout {
    id: details
    width: parent.width - 40
    x: 20

    TextEdit {
      id: skillDesc

      Layout.fillWidth: true
      font.pixelSize: 18
      color: "#E4D5A0"
      text: skills.map((t) => "<b>" + Lua.tr(t) + "</b>: " + Lua.tr(":" + t)).join("<br/>")
      readOnly: true
      selectByKeyboard: true
      selectByMouse: false
      wrapMode: TextEdit.WordWrap
      textFormat: TextEdit.RichText
    }
  }


}
