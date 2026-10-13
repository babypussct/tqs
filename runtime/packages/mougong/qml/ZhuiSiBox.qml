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

  property var selectedItem: []
  property var allPlayerIds: []
  property string titleName: ""

  // 压制报错用 暂时想不出办法
  readonly property var roomScene: Ltk.roomScene

  title.text: Lua.tr(titleName)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 700
  height: 360

  Flickable {
    anchors.fill: parent
    contentWidth: photoRow.width
    ScrollBar.horizontal: ScrollBar {}
    clip: true

    flickableDirection: Flickable.HorizontalFlick

    RowLayout {
      id: photoRow
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        id: photoRepeater
        model: ListModel {
          id: playerInfos
        }

        Photo {
          required property var mod
          dataModel: mod

          scale: selectedItem.some(data => data.playerid === mod.playerid) ? 0.85 : 0.75
          Behavior on scale { NumberAnimation { duration: 100 } }

          Image {
            visible: selectedItem.some(data => data.playerid === mod.playerid)
            source: SkinBank.cardDir + "chosen"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 15
            scale: 1.5
          }

          onSelectedChanged: {
            if (selectedItem.some(data => data.playerid === mod.playerid))
              selectedItem = [];
            else
              selectedItem = [mod];
          }

          Component.onCompleted: {
            this.visibleChildren[12].visible = false;
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    anchors.fill: parent
    anchors.bottomMargin: 10
    height: 40

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: 8

      MetroButton {
        Layout.fillWidth: true
        text: Lua.tr("OK")
        enabled: selectedItem.length

        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          const reply = { playerId: selectedItem[0].playerid };
          ClientInstance.replyToServer("", reply);
        }
      }

      MetroButton {
        id: detailBtn
        enabled: selectedItem.length
        text: Lua.tr("Show General Detail")
        onClicked: {
          const { general, deputyGeneral } = selectedItem[0];
          const generals = [general];
          deputyGeneral && generals.push(deputyGeneral);

          Ltk.roomScene.showInfoPopup(
            Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
            { generals });
        }
      }
    }
  }

  onShown: {
    allPlayerIds.forEach(playerId => {
      const dat = Lua.ev(`ClientInstance:getPlayerById(${playerId}):__toqml().model`);

      const model = Lua.createQmlObject(dat);
      model.state = "candidate";
      model.role = "hidden";
      playerInfos.append({ mod: model });
    });
  }
}
