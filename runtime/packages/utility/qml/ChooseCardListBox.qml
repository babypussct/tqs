// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components
import LunarLtk.Models.Popups
import LunarLtk.Pages.Popups

import "models"

GraphicsBox {
  id: root

  required property ChooseCardListModel dataModel

  title.text: dataModel.promptText
  
  width: 600
  height: Math.min(370, 160 * (Math.ceil(dataModel.listNames.length / 2))) + 90

  Flickable {
    id: cardArea
    height: parent.height - 90
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.left: parent.left
    anchors.leftMargin: 5
    anchors.horizontalCenter: parent.horizontalCenter
    contentHeight: gridLayout.implicitHeight
    ScrollBar.horizontal: ScrollBar {}
    flickableDirection: Flickable.VerticalFlick
    clip: true

    GridLayout {
      id: gridLayout
      columns: 2
      width: parent.width
      clip: true

      Repeater {
        id: cardAreaRepeater
        model:dataModel.listCards
        delegate: Item {
          id: listArea
          required property int index
          required property var modelData

          width: 280
          height: 150
          clip: true

          property string listName: dataModel.listNames[index]
          property bool chosen: dataModel.isChosen(listName)
          property int cardNum: modelData.length

          Rectangle {
            id: areaRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: "#EEEEEE"
            opacity: 0.53
          }

          GoodInnerShadow {
            visible: listArea.chosen
            source: areaRect
            color: "gold"
            spread: 0.3
            radius: 32
            opacity: 0.53
          }

          RowLayout {
            width: parent.width - 20
            height: parent.height - 20
            anchors.centerIn: parent
            spacing: (cardNum < 4) ? -28 : (width - 100) / (cardNum - 1) - 100
            clip: true

            Repeater {
              model: modelData

              CardItem {
                required property var modelData
                dataModel: Ltk.createCardModel(modelData)
                autoBack: false
                showDetail: true
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              dataModel.toggleList(listName, cardNum);
              root.updateSelectable();
            }
          }

          Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * 0.25
            color: Qt.rgba(0, 0, 0, 0.7)
            opacity: 0.7

            GlowText {
              text: Ltk.processPrompt(listName) + " (" + cardNum.toString() + ")"
              font.family: Config.libianName
              font.pixelSize: 27
              font.bold: true
              color: "#FEF7D6"
              glow.color: "#845422"
              glow.spread: 0.5
              anchors.centerIn: parent
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
      spacing: 30

      MetroButton {
        id: buttonConfirm
        Layout.fillWidth: true
        text: Lua.tr("OK")
        enabled: dataModel.feasible

        onClicked: {
          root.dataModel.accepted();
        
        }
      }

      MetroButton {
        id: buttonClear
        Layout.fillWidth: true
        enabled: dataModel.result.length > 0
        text: Lua.tr("Clear All")
        onClicked: {
          dataModel.clearAll();
          root.updateSelectable();
        }
      }

      MetroButton {
        id: buttonCancel
        Layout.fillWidth: true
        text: Lua.tr("Cancel")
        enabled: dataModel.cancelable

        onClicked: {
          root.dataModel.rejected();
        }
      }
    }
  }

  function updateSelectable() {
    buttonClear.enabled = dataModel.result.length > 0;
    buttonConfirm.enabled = dataModel.feasible;
  }
}
