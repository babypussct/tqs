// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups
import LunarLtk.Components

GraphicsBox {
  id: root

  property var cards: []

  property int result
  property string prompt: ""

  title.text: prompt === "" ? Lua.tr("$Choice") : Ltk.processPrompt(prompt)
  width: 440
  height: 220

  Row {
    id: cardArea
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 30
    spacing: 5

    Repeater {
      id: to_select
      model: cards

      CardItem {
        required property var modelData
        dataModel: Ltk.createCardModel(modelData, { known: false })
        selectable: true
        onSelectedChanged: {
          root.result = dataModel.cardId;
          root.updateCardSelectable();
        }
      }
    }
  }
  
  Row {
    id: buttons
    anchors.margins: 8
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: root.horizontalCenter
    spacing: 32

    MetroButton {
      width: 100
      Layout.fillWidth: true
      text: Lua.tr("OK")
      id: buttonConfirm
      enabled : false

      onClicked: {
        close();
        Ltk.roomModel.deActivate();
        ClientInstance.replyToServer("", result);
      }
    }
  }

  function updateCardSelectable() {
    buttonConfirm.enabled = true;
    let item;
    for (let i = 0; i < to_select.count; i++) {
      item = to_select.itemAt(i);
      item.chosenInBox = (i < result);
    }
  }
}
