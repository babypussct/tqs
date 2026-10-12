// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups
import LunarLtk.Components

GraphicsBox {
  id: root

  property var selected_ids: []
  property var cards: []
  property var fake_index: 0
  property string fake_name: ""

  // 压制报错用 暂时想不出办法
  readonly property var roomScene: Ltk.roomScene

  title.text: Ltk.processPrompt("#mobile__daoshu-guess")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 40 + Math.min(8.5, Math.max(4, cards.length)) * 100
  height: 260

  Component {
    id: cardDelegate
    CardItem {
      required property var modelData
      required property var index
      dataModel: {
        if (index === fake_index) { // 假牌
          return Ltk.createCardModelFromName(fake_name, {
            selectable: true,
            cardId: 0,
            number: modelData.number,
            suit: modelData.suit,
            color: modelData.color,
            extension: modelData.extension,
          });
        } else {
          return Ltk.createCardModel(modelData, { selectable: true });
        }
      }
      autoBack: false
      showDetail: true
      onSelectedChanged: {
        const cardId = dataModel.cardId;
        if (selected) {
          origY = origY - 20;
          root.selected_ids.push(cardId);
        } else {
          origY = origY + 20;
          root.selected_ids.splice(root.selected_ids.indexOf(cardId), 1);
        }
        origX = x;
        goBack(true);
        root.selected_idsChanged();

        root.updateCardSelectable();
      }
    }
  }

  Rectangle {
    id: cardbox
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 15
    anchors.rightMargin: 15
    anchors.bottomMargin: 50

    color: "#1D1E19"
    radius: 10

    Flickable {
      id: flickableContainer
      ScrollBar.horizontal: ScrollBar {}

      flickableDirection: Flickable.HorizontalFlick
      anchors.fill: parent
      anchors.topMargin: 0
      anchors.leftMargin: 5
      anchors.rightMargin: 5
      anchors.bottomMargin: 10

      contentWidth: cardsList.width
      contentHeight: cardsList.height
      clip: true

      ColumnLayout {
        id: cardsList
        anchors.top: parent.top
        anchors.topMargin: 25

        Row {
          spacing: 5
          Repeater {
            id: to_select
            model: cards
            delegate: cardDelegate
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.fill: parent
    anchors.bottomMargin: 10
    height: 40

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: 8

      MetroButton {
        Layout.fillWidth: true
        text: Ltk.processPrompt("OK")
        enabled: root.selected_ids.length == 1

        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          ClientInstance.replyToServer("", root.selected_ids[0]);
        }
      }
    }
  }

  function updateCardSelectable() {
    if (selected_ids.length > 1) {
      let item;
      for (let i = 0; i < to_select.count; i++) {
        item = to_select.itemAt(i);
        if (item.cid == selected_ids[0]) {
          item.selected = false;
          break;
        }
      }
    }
  }

  function loadData(data) {
    cards = d[0].map(cid => {
      if (typeof cid === 'object') {
        return cid;
      }
      return Lua.call("GetCardData", cid);
    });
  }
}

