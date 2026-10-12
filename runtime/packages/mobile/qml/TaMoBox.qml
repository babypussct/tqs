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
  // 调成浅色背景以便能看清楚座位号...
  // background.color: "#dcce9b"
  // title.color: "#423817"

  property var selectedItem: []
  property var allPlayerIds: []
  property var disabledPlayerIds: []
  property string titleName: ""

  // 压制报错用 暂时想不出办法
  readonly property var roomScene: Ltk.roomScene

  title.text: Lua.tr(titleName)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: photoRow.width + 10
  height: 270

  Rectangle {
    anchors.top: parent.top
    anchors.topMargin: 36
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 66
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 12

    color: "#cce4d5a0"
    radius: 8
  }

  Row {
    id: photoRow
    anchors.top: parent.top
    anchors.topMargin: 30
    spacing: -28

    Repeater {
      id: photoRepeater
      model: ListModel {
        id: playerInfos
      }

      Photo {
        id: photo
        required property var mod
        required property bool disabled

        dataModel: mod
        // scale: 0.65
        scale: selectedItem.some(data => data.playerid === mod.playerid) ? 0.85 : 0.75
        selectable: !disabled

        Behavior on scale { NumberAnimation { duration: 100 } }
        //Behavior on x { NumberAnimation { duration: 280 } }

        Image {
          visible: selectedItem.some(data => data.playerid === mod.playerid)
          source: SkinBank.cardDir + "chosen"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 15
          scale: 1.5
        }

        Image {
          visible: disabled
          source: AppPath + "/image/button/skill/locked.png"
          anchors.centerIn: parent
          // anchors.horizontalCenter: parent.horizontalCenter
          // anchors.top: parent.top
          // anchors.topMargin: -50
        }

        GlowText {
          anchors.centerIn: parent
          text: Lua.tr("click to exchange")
          visible: selectedItem.length && !disabled && selectedItem[0] !== mod
          font.family: Config.libianName
          font.pixelSize: 30
          font.bold: true
          color: "#FEF7D6"
          glow.color: "#845422"
          glow.spread: 0.8
        }

        onSelectedChanged: {
          if (selectedItem.length) {
            if (selectedItem[0].playerid !== mod.playerid) {
              let chosenPhoto;

              for (let i = 0; i < playerInfos.count; i++) {
                const photo = photoRepeater.itemAt(i);
                if (photo.playerid === selectedItem[0].playerid) {
                  chosenPhoto = photo;
                  break;
                }
                continue;
              }
              const cx = chosenPhoto.x;
              const cseat = selectedItem[0].seatNumber;
              selectedItem[0].seatNumber = mod.seatNumber;
              chosenPhoto.x = this.x;
              this.x = cx;
              mod.seatNumber = cseat;
            }

            selectedItem = [];
          } else {
            selectedItem = [mod];
          }
        }

        Component.onCompleted: {
          this.visibleChildren[12].visible = false;
          disabled && (this.children[9].opacity = 1);
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
        enabled: true

        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          const playerIds = [];
          for (let i = 0; i < playerInfos.count; i++) {
            const data = playerInfos.get(i).mod;
            playerIds[data.seatNumber - 1] = data.playerid;
          }
          ClientInstance.replyToServer("", playerIds);
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

      MetroButton {
        Layout.fillWidth: true
        text: Lua.tr("Cancel")
        enabled: true

        onClicked: {
          root.close();
          Ltk.roomModel.deActivate();
          ClientInstance.replyToServer("", "");
        }
      }
    }
  }

  onShown: {
    allPlayerIds.forEach(playerId => {
      const dat = Lua.ev(`ClientInstance:getPlayerById(${playerId}):__toqml().model`);

      const model = Lua.createQmlObject(dat);
      const disabled = disabledPlayerIds.includes(playerId);
      model.state = disabled ? "candidate" : "normal";
      playerInfos.append({ mod: model, disabled });
    });
  }
}
