// SPDX-License-Identifier: GPL-3.0-or-later
//疑似搬运到本体了，废弃
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import LunarLtk
import LunarLtk.Pages.Popups
import LunarLtk.Components
import Fk.Components.Common

import "models"

GraphicsBox {
  id: root

  required property ChooseCardsAndChoiceModel dataModel

  title.text: dataModel.promptText
  width: 40 + Math.min(8.5, Math.max(4, dataModel.cards.length)) * 100
  height: 260

  Rectangle {
    id: right
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 15
    anchors.rightMargin: 15
    anchors.bottomMargin: 50
    color: "#88EEEEEE"
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
            model: dataModel.cards

            delegate: CardItem {
              id: cItem
              required property var modelData

              Component.onCompleted: setData(modelData)
              autoBack: false
              showDetail: true
              selectable: !dataModel.disable_cards.includes(cid)

              Connections {
                target: dataModel
                function onRequestCardUnselect(id) {
                  if (id === cid)
                    cItem.selected = false;
                }
              }

              onSelectedChanged: {
                if (dataModel.ok_options.length === 0)
                  return;

                if (selected) {
                  origY = origY - 20;
                  dataModel.toggleCard(cid, true);
                } else {
                  origY = origY + 20;
                  dataModel.toggleCard(cid, false);
                }
                origX = x;
                goBack(true);
              }
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

      Repeater {
        model: dataModel.ok_options

        MetroButton {
          required property string modelData
          Layout.fillWidth: true
          text: Ltk.processPrompt(modelData)
          enabled: dataModel.okEnabled

          onClicked: {
            close();
            roomScene.state = "notactive";
            ClientInstance.replyToServer("", {
              "cards": dataModel.selected_ids,
              "choice": modelData
            });
          }
        }
      }

      Repeater {
        model: dataModel.cancel_options

        MetroButton {
          required property string modelData
          Layout.fillWidth: true
          text: Ltk.processPrompt(modelData)
          enabled: true

          onClicked: {
            close();
            roomScene.state = "notactive";
            ClientInstance.replyToServer("", {
              "cards": [],
              "choice": modelData
            });
          }
        }
      }
    }
  }
}
