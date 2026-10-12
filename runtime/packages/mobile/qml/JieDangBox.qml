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
  property string mainGeneral
  property list<string> deputyGenerals: []
  property string disabledGeneral: ""

  title.text: Lua.tr("$JieDang")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 460
  height: 360

  ColumnLayout {
    anchors.top: root.top
    anchors.topMargin: 30
    anchors.left: root.left
    anchors.leftMargin: 10
    width: root.width - 20
    spacing: 10

    RowLayout {
      id: mainGeneralRow
      width: parent.width
      spacing: parent.width / 2.8

      Rectangle {
        Layout.alignment: Qt.AlignVCenter
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: Lua.tr("mainGeneral")
          color: "white"
          font.family: Config.libianName
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      GeneralCardItem {
        Layout.alignment: Qt.AlignHCenter

        dataModel: Ltk.createGeneralCardModel(mainGeneral)
        ToolTip {
          id: descriptionTip
          x: 20
          y: 20
          text: ""
          visible: false
          font.family: Config.libianName
          font.pixelSize: 14
        }

        onClicked: {
          descriptionTip.show(Lua.tr(`:${mainGeneral}-specificSkillDesc`));
        }
      }
    }

    RowLayout {
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: Lua.tr("deputyGeneral")
          color: "white"
          font.family: Config.libianName
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      RowLayout {
        spacing: 10

        Repeater {
          id: deputyGeneralsRepeater
          model: deputyGenerals

          GeneralCardItem {
            required property string modelData
            dataModel: Ltk.createGeneralCardModel(modelData)
            selectable: disabledGeneral !== modelData
            chosenInBox: selectedItem.includes(modelData)

            Rectangle {
              id: taunt
              x: 10
              y: -5
              z: 3
              color: "#F2ECD7"
              radius: 4
              opacity: 0
              width: parent.width + 10
              height: childrenRect.height + 8
              property string text: ""
              visible: false
              Text {
                width: parent.width - 8
                x: 4
                y: 4
                text: parent.text
                wrapMode: Text.WrapAnywhere
                font.family: Config.libianName
                font.pixelSize: 14
              }
              SequentialAnimation {
                id: tauntAnim
                PropertyAnimation {
                  target: taunt
                  property: "opacity"
                  to: 0.9
                  duration: 200
                }
                NumberAnimation {
                  duration: 3500
                }
                PropertyAnimation {
                  target: taunt
                  property: "opacity"
                  to: 0
                  duration: 150
                }
                onFinished: taunt.visible = false;
              }
            }

            onClicked: {
              descriptionTip.show(Lua.tr(`:${modelData}-specificSkillDesc`));
            }

            onSelectedChanged: {
              selectedItem = [modelData];
            }

            function addTaunt(text) {
              taunt.text = text;
              taunt.visible = true;
              tauntAnim.restart();
            }
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
          const reply = { general: selectedItem[0] };
          ClientInstance.replyToServer("", reply);
        }
      }
    }
  }

  onShown: {
    if (disabledGeneral) {
      const disabledIndex = deputyGenerals.findIndex(general => general === disabledGeneral);
      const itemFound = deputyGeneralsRepeater.itemAt(disabledIndex);
      itemFound.z = 2;
      itemFound.addTaunt(Lua.tr(`$${disabledGeneral}_taunt1`));

      const path = `./packages/mobile/audio/skill/${disabledGeneral}_taunt1`;
      if (Backend.exists(path + ".mp3")) {
        Backend.playSound(path);
      }
    }
  }
}
