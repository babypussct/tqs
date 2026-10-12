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
  property string prompt: ""
  property list<var> cards: []
  property var result: []
  property var areaNames: []
  property var sums: []
  property bool operable : false
  property int padding: 25
  scale: 0.8

  title.text: Lua.tr(operable == true ? prompt : "Only Watch")
  width: body.width + padding * 2
  height: title.height + body.height + padding * 2

  ColumnLayout {
    id: body
    x: padding
    y: parent.height - padding - height
    spacing: 10

    Repeater {
      id: areaRepeater
      model: [cards.length, cards.length, cards.length]

      Row {
        spacing: 5

        property int areaCapacity: modelData
        property string areaName: index < areaNames.length ? Lua.tr(areaNames[index]) : ""
        property string sum: index < sums.length ? sums[index].toString() : "0"

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          color: "#6B5D42"
          width: 20
          height: 100
          radius: 5

          Text {
            anchors.fill: parent
            width: 20
            height: 100
            text: areaName + sum
            color: "white"
            font.family: Config.libianName
            font.pixelSize: 18
            style: Text.Outline
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Repeater {
          id: cardRepeater
          model: areaCapacity

          Rectangle {
            color: "#1D1E19"
            width: 93
            height: 130

            Text {
              anchors.centerIn: parent
              text: areaName
              color: "#59574D"
              width: parent.width * 0.8
              wrapMode: Text.WordWrap
            }
          }
        }
        property alias cardRepeater: cardRepeater
      }
    }

    Row {
      Layout.alignment: Qt.AlignHCenter
      spacing: 32

      MetroButton {
        Layout.alignment: Qt.AlignHCenter
        id: buttonConfirm
        text: Lua.tr("OK")
        width: 120
        height: 35
        visible: root.operable

        onClicked: {
          const reply = getResult();
          close();
          Ltk.roomModel.deActivate();
          ClientInstance.replyToServer("", reply);
          ClientInstance.notifyServer("PushRequest", "updatemini,confirm");
        }
      }

      MetroButton {
        Layout.alignment: Qt.AlignHCenter
        text: Lua.tr("Cancel")
        width: 120
        height: 35
        visible: root.operable

        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          ClientInstance.replyToServer("", "");
          ClientInstance.notifyServer("PushRequest", "updatemini,confirm");
        }
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
      y: -1
      draggable: root.operable
      onReleased: {
        arrangeCards();
        if (root.operable)
          ClientInstance.notifyServer("PushRequest", "updatemini," + JSON.stringify(getResult()));
      }
    }
  }

  function arrangeCards() {
    result = new Array(3);
    let i;
    for (i = 0; i < result.length; i++){
      result[i] = [];
    }

    let card, j, area, cards, stay;
    for (i = 0; i < cardItem.count; i++) {
      card = cardItem.itemAt(i);

      stay = true;
      for (j = areaRepeater.count - 1; j >= 0; j--) {
        area = areaRepeater.itemAt(j);
        cards = result[j];
        if (card.y >= area.y) {
          cards.push(card);
          stay = false;
          break;
        }
      }

      if (stay) {
        for (j = 0; j < areaRepeater.count; j++) {
          result[j].push(card);
          break;
        }
      }
    }
    for(i = 0; i < result.length; i++)
      result[i].sort((a, b) => a.x - b.x);


    let line_sums = [0, 0, 0];
    let box, pos, pile;
    for (j = 0; j < areaRepeater.count; j++) {
      pile = areaRepeater.itemAt(j);
      if (pile.y === 0){
        pile.y = j * 150
      }
      for (i = 0; i < result[j].length; i++) {
        box = pile.cardRepeater.itemAt(i);
        pos = mapFromItem(pile, box.x, box.y);
        card = result[j][i];
        card.origX = pos.x;
        card.origY = pos.y;
        card.goBack(true);
        line_sums[j] = line_sums[j] + card.number
      }
    }
    sums = line_sums;
    
    buttonConfirm.enabled = (line_sums[1] == line_sums[2] && line_sums[1] > 0);
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
  
  function loadData(data) {
    prompt = "#yanjiao-distribute";

    cards = data[0];

    areaNames = [Lua.tr("Top"), Lua.tr(data[1]), Lua.tr(data[2])];

    operable = data[3];
    if (!operable) {
      ClientInstance.replyToServer("", "");
    }

    arrangeCards();

  }
  
  function updateData(data) {
    if (data.length == 0) {
      close();
      roomScene.state = "notactive";
      ClientInstance.replyToServer("", "");
    }
    let i, j, k, card;
    result = new Array(3);
    for (i = 0; i < result.length; i++){
      result[i] = [];
    }
    for (j = 0; j < data.length; j++){
      for (i = 0; i < data[j].length; i++) {
        for (k = 0; k < cardItem.count; k++) {
          card = cardItem.itemAt(k);
          if (card.dataModel.cardId == data[j][i]) {
            result[j].push(card);
            break;
          }
        }
      }
    }

    let box, pos, pile;
    let line_sums = [0, 0, 0];
    for (j = 0; j < areaRepeater.count; j++) {
      pile = areaRepeater.itemAt(j);
      if (pile.y === 0){
        pile.y = j * 150
      }
      for (i = 0; i < result[j].length; i++) {
        box = pile.cardRepeater.itemAt(i);
        pos = mapFromItem(pile, box.x, box.y);
        card = result[j][i];
        card.origX = pos.x;
        card.origY = pos.y;
        card.goBack(true);
        line_sums[j] = line_sums[j] + card.number
      }
    }
    sums = line_sums;
  }
}
