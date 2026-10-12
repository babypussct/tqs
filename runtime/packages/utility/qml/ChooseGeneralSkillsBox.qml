// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import LunarLtk.Pages.Popups
import LunarLtk.Pages
import LunarLtk
import LunarLtk.Components
import Fk.Components.Common
import LunarLtk.Components.Photo
import "models"

GraphicsBox {
  id: root

  required property ChooseGeneralSkillsModel dataModel

  title.text: dataModel.promptText
  width: 50 + Math.max(4, dataModel.cards.length) * 100
  height: 340

  Component {
    id: cardDelegate
    GeneralCardItem {
      required property string modelData
      dataModel: Ltk.createGeneralCardModel(modelData)

      autoBack: false
      selectable: true

      onRightClicked: root.parent.showInfoPopup(
        Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
        { generals: [modelData] }
      );
    }
  }

  Row {
    id: generalArea
    x: 20
    y: 35
    spacing: 5

    Repeater {
      id: to_select
      model: dataModel.cards
      delegate: cardDelegate
    }
  }

  Flickable {
    id: flickableContainer
    ScrollBar.horizontal: ScrollBar {}
    flickableDirection: Flickable.VerticalFlick
    anchors.fill: parent
    anchors.topMargin: 175
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    anchors.bottomMargin: 50
    contentWidth: skillColumn.width
    contentHeight: skillColumn.height
    clip: true

    RowLayout {
      id: skillColumn
      x: 22
      y: 0
      spacing: 18

      Repeater {
        id: skillList
        model: dataModel.skills

        ColumnLayout {
          required property var modelData
          spacing: 5
          Layout.alignment: Qt.AlignTop

          Repeater {
            model: modelData

            SkillButton {
              id: skillBtn
              required property string modelData
              dataModel: Ltk.createSkillModel(modelData,{isActive: true,enabled: true})
              enabled: true
              Connections {
                target: root.dataModel
                function onRequestUnpress(o) {
                  if (o === modelData)
                    skillBtn.dataModel.selected = false;
                }
              }

              Connections {
                target: skillBtn.dataModel
                function onSelectedChanged() {
                  root.dataModel.onSkillPressed(modelData, skillBtn.dataModel.selected);
                  root.updateSelectable();
                }
              }
            }
          }
        }
      }
    }
  }

  Row {
    id: buttons
    anchors.margins: 8
    anchors.top: flickableContainer.bottom
    anchors.horizontalCenter: root.horizontalCenter
    spacing: 32

    MetroButton {
      id: buttonConfirm
      width: 100
      Layout.fillWidth: true
      text: Lua.tr("OK")
      enabled: dataModel.feasible

      onClicked: {
        dataModel.accepted();
      }
    }

    MetroButton {
      width: 100
      Layout.fillWidth: true
      text: Lua.tr("Cancel")
      visible: dataModel.cancelable

      onClicked: {
        dataModel.rejected();
      }
    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = dataModel.feasible;
  }
}
