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
  property string prompt: "Please arrange cards"
  property list<var> cards: []
  property var result: []
  property var handcards: []
  property list<var> areaCards: [[], [], []]
  property list<var> areaExcavated: [false, false, false]
  property int padding: 25
  property int itemHeight: 170

  title.text: Ltk.processPrompt(prompt)
  width: body.width + padding * 2
  height: title.height + body.height + padding * 2
  scale: 0.9

  ColumnLayout {
    id: body
    x: padding
    y: parent.height - padding - height
    spacing: 10

      Row {
        spacing: 5

        Rectangle {
          id: tuoyu1
          anchors.verticalCenter: parent.verticalCenter
          color: areaExcavated[0] ? "#79440F" : "#7F7F7F"
          width: 300
          height: itemHeight
          radius: 5

          Text {
            anchors.fill: parent
            anchors.topMargin: 145
            width: 20
            height: 100
            text: qsTr(Lua.tr("tuoyu1") + "：" + Lua.tr(":tuoyu1"))
            color: "white"
            font.family: Config.libianName
            font.pixelSize: 18
            style: Text.Outline
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Rectangle {
          id: tuoyu2
          anchors.verticalCenter: parent.verticalCenter
          color: areaExcavated[1] ? "#14708A" : "#7F7F7F"
          width: 300
          height: itemHeight
          radius: 5

          Text {
            anchors.fill: parent
            anchors.topMargin: 145
            width: 20
            height: 100
            text: qsTr(Lua.tr("tuoyu2") + "：" + Lua.tr(":tuoyu2"))
            color: "white"
            font.family: Config.libianName
            font.pixelSize: 18
            style: Text.Outline
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Rectangle {
          id: tuoyu3
          anchors.verticalCenter: parent.verticalCenter
          color: areaExcavated[2] ? "#468349" : "#7F7F7F"
          width: 300
          height: itemHeight
          radius: 5

          Text {
            anchors.fill: parent
            anchors.topMargin: 145
            width: 20
            height: 100
            text: qsTr(Lua.tr("tuoyu3") + "：" + Lua.tr(":tuoyu3"))
            color: "white"
            font.family: Config.libianName
            font.pixelSize: 18
            style: Text.Outline
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      Item {
        id: handcardsArea
        width: root.width
        height: itemHeight
      }


    MetroButton {
      Layout.alignment: Qt.AlignHCenter
      id: buttonConfirm
      text: Lua.tr("OK")
      width: 120
      height: 35

      onClicked: {
        const reply = getResult();
        ClientInstance.replyToServer("", reply);
        close();
        Ltk.roomModel.deActivate();
      }
    }
  }

  Repeater {
    id: cardItem
    model: cards

    CardItem {
      required property var modelData
      dataModel: Ltk.createCardModel(modelData, { selectable: true })
      x: 20
      y: 220
      draggable: true
      onReleased: updateCardReleased(modelData);
    }
  }

  // FIXME
  function arrangeCards() {
    let i, j;
    let card;

    let overflow = handcards.length > 9;
    for (i = 0; i < handcards.length; i++) {
      card = handcards[i];
      card.origX = overflow ? (830 / (handcards.length - 1) * i + 20) : (20 + 100 * i);
      card.origY = 250;
      card.z = i + 1;
      card.initialZ = i + 1;
      card.maxZ = handcards.length;
      card.goBack(true);
    }

    for (j = 0; j < 3; j++) {
      overflow = result[j].length > 2
      for (i = 0; i < result[j].length; i++) {
        card = result[j][i];
        card.origX = overflow ? (180 / (result[j].length - 1) * i + 40 + 305 * j) : (40 + 305 * j + 100 * i);
        card.origY = 60;
        card.z = i + 1;
        card.initialZ = i + 1;
        card.maxZ = result[j].length;
        card.goBack(true);
      }
    }

  }

  function updateCardReleased(cid) {
    let i, j;
    let card;
    let findOne = true;
    let inHand = false;


    for (i = 0; i < handcards.length; i++) {
      card = handcards[i];
      if (card.dataModel.cardId == cid) {
        handcards.splice(i, 1);
        findOne = false;
        inHand = true;
        break;
      }
    }
    if (findOne) {
      for (j = 0; j < result.length; j++) {
        for (i = 0; i < result[j].length; i++) {
          card = result[j][i];
          if (card.dataModel.cardId == cid) {
            result[j].splice(i, 1);
            findOne = false;
            break;
          }
        }
        if (!findOne) break;
      }
    }

    if (card.y < (inHand ? (handcardsArea.y + 40) : (handcardsArea.y - 40))) {
      if (card.x < 280) {
        if (areaExcavated[0] && result[0].length < 5)
          result[0].push(card);
        else
          handcards.push(card);
      } else if (card.x < 580) {
        if (areaExcavated[1] && result[1].length < 5)
          result[1].push(card);
        else
          handcards.push(card);
      } else {
        if (areaExcavated[2] && result[2].length < 5)
          result[2].push(card);
        else
          handcards.push(card);
      }
    } else {
      handcards.push(card);
    }
    arrangeCards();
  }

  function getResult() {
    const ret = [];
    result.forEach(t => {
      const t2 = [];
      t.forEach(v => t2.push(v.dataModel.cardId));
      ret.push(t2);
    });
    return ret;
  }

  onShown: {
    result = new Array(3);
    let i, j;
    for (i = 0; i < 3; i++){
      result[i] = [];
    }
    let card;
    let findOne = false;

    for (i = 0; i < cardItem.count; i++) {
      card = cardItem.itemAt(i);
      for (j = 0; j < 3; j++) {
        if (areaCards[j].includes(card.dataModel.cardId)) {
          result[j].push(card);
          findOne = true;
          break;
        }
      }
      if (findOne)
        findOne = false;
      else
        handcards.push(card);
    }
    arrangeCards();
  }
}
