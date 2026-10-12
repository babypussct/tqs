// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import LunarLtk.Pages.Popups
import LunarLtk
import LunarLtk.Components
import Fk.Components.Common

import "models"

GraphicsBox {
  id: root

  required property ChooseGeneralsAndChoiceModel dataModel

  width: 40 + Math.min(7, Math.max(4, dataModel.cards.length)) * 100
  height: 120 + Math.min(2.2, Math.ceil(dataModel.cards.length / 7)) * 140

  Rectangle {
    id: cardArea
    anchors.fill: parent
    anchors.topMargin: 60
    anchors.leftMargin: 15
    anchors.rightMargin: 15
    anchors.bottomMargin: 55
    color: "#88EEEEEE"
    radius: 10

    GridView {
      id: generalContainer
      anchors.fill: parent
      anchors.topMargin: 5
      anchors.leftMargin: 5
      anchors.rightMargin: 5
      anchors.bottomMargin: 5
      clip: true
      cellWidth: 93 + 5
      cellHeight: 130 + 5
      model: dataModel.cards

      delegate: GeneralCardItem {
        id: gItem
        required property string modelData

        dataModel: Ltk.createGeneralCardModel(modelData)
        selectable: !root.dataModel.disable_cards.includes(modelData)
        autoBack: false

        onSelectedChanged: {
          if (selected) {
            chosenInBox = true;
            root.dataModel.toggleGeneral(modelData, selected);
          } else {
            chosenInBox = false;
            root.dataModel.toggleGeneral(modelData, false);
          }
        }
        Connections {
          target: root.dataModel
          function onRequestGeneralUnselect(name) {
            if (name === modelData)
              selected = false;
          }
        }
        onRightClicked: {
          root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"), {
            generals: [modelData]
          });
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
        id: ok_buttons
        model: dataModel.ok_options

        MetroButton {
          required property string modelData
          Layout.fillWidth: true
          text: Ltk.processPrompt(modelData)
          enabled: dataModel.okEnabled

          onClicked: {
            root.dataModel.doAccepted(modelData);
          }
        }
      }

      Repeater {
        id: cancel_buttons
        model: dataModel.cancel_options

        MetroButton {
          required property string modelData
          Layout.fillWidth: true
          text: Ltk.processPrompt(modelData)
          enabled: true

          onClicked: {
            dataModel.rejected();
          }
        }
      }
    }
  }

  Item {
    id: titleArea
    anchors.top: parent.top
    anchors.topMargin: 5
    anchors.horizontalCenter: parent.horizontalCenter
    height: 40
    width: parent.width - 30

    RowLayout {
      anchors.fill: parent

      Text {
        font.pixelSize: 20
        color: "#E4D5A0"
        text: Ltk.processPrompt(dataModel.prompt)
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }

      TextField {
        visible: dataModel.cards.length > 21
        enabled: !dataModel.isSearching
        id: word
        placeholderText: dataModel.isSearching ? "" : "Search..."
        clip: true
        verticalAlignment: Qt.AlignVCenter
        background: Rectangle {
          implicitHeight: 20
          implicitWidth: 120
          color: "#88EEEEEE"
          radius: 5
        }
      }

      ToolButton {
        text: dataModel.isSearching ? Lua.tr("Back") : Lua.tr("Search")
        enabled: word.text !== "" || dataModel.isSearching
        onClicked: {
          dataModel.applySearchToggle(word.text);
          if (!dataModel.isSearching)
            word.text = "";
        }
        background: Rectangle {
          implicitHeight: 35
          implicitWidth: 40
          color: "#88EEEEEE"
          radius: 5
        }
      }
    }

    Component.onCompleted: {
      dataModel.syncOkEnabled();
    }
  }
}
