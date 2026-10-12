// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk.Pages.Popups
import LunarLtk
import LunarLtk.Components
import Fk.Components.Common

import "models"

GraphicsBox {
  id: root

  required property ChooseSkillFromGeneralModel dataModel

  title.text: Lua.tr(dataModel.titleName)
  width: 585
  height: 210 + Math.min(270, Math.ceil(dataModel.generals.length / 7) * 110)

  Rectangle {
    id: generalArea
    width: parent.width
    height: parent.height - 180
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    border.color: "#FEF7D6"
    border.width: 3
    radius: 4
    color: "#88EEEEEE"

    GridView {
      id: generalCard
      anchors.centerIn: parent
      width: parent.width - 10
      height: parent.height - 14
      cellWidth: 80
      cellHeight: 110
      Layout.alignment: Qt.AlignHCenter
      clip: true
      model: dataModel.generals

      delegate: GeneralCardItem {
        id: cardItem
        required property string modelData
        required property int index

        autoBack: false
        dataModel: Ltk.createGeneralCardModel(modelData)
        scale: 0.8

        Image {
          visible: root.dataModel.selectedGeneral.length > 0 && root.dataModel.selectedGeneral === modelData
          source: SkinBank.cardDir + "chosen"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          scale: 1.2
        }

        onSelectedChanged: {
          if (selected) {
            root.dataModel.setGeneral(modelData, index);
          }
        }

        onRightClicked: {
          root.parent.showInfoPopup(
            Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
            { generals: [modelData] }
          );
        }
      }
    }
  }

  Rectangle {
    id: skillArea
    width: parent.width
    height: 90
    anchors.top: generalArea.bottom
    anchors.topMargin: 5
    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    border.color: "#FEF7D6"
    border.width: 3
    radius: 4
    color: "#88EEEEEE"

    GridView {
      id: skillShown
      width: parent.width - 10
      height: parent.height - 8
      anchors.centerIn: parent
      cellWidth: 80
      cellHeight: 40
      Layout.alignment: Qt.AlignHCenter
      clip: true
      model: dataModel.shownSkills

      delegate: SkillButton {
        id: skillBtn
        required property string modelData

        dataModel: Ltk.createSkillModel(modelData,{isActive: true,enabled: true})
        scale: 0.85

        Connections {
          target: skillBtn.dataModel
          function onSelectedChanged() {
            if (skillBtn.dataModel.selected) {
              for (let i = 0; i < skillShown.count; i++) {
                const other = skillShown.itemAtIndex(i);
                if (other && other !== skillBtn)
                  other.dataModel.selected = false;
              }
              root.dataModel.setSkillOrig(modelData);
            } else {
              dataModel.clearSkill();
            }
            root.updateSelectable();
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
          dataModel.doAccept();
        }
      }

      MetroButton {
        id: buttonDetail
        enabled: dataModel.selectedGeneral.length > 0
        text: Lua.tr("Show General Detail")
        onClicked: {
          if (dataModel.selectedSkillOrig.length) {
            root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "SkillDetail"), {
              "skills": [dataModel.selectedSkillOrig]
            });
          } else {
            root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
              { generals: [dataModel.selectedGeneral] 
            });
          }
        }
      }

      MetroButton {
        Layout.fillWidth: true
        text: Lua.tr("Cancel")
        enabled: true

        onClicked: {
          dataModel.rejected();
        }
      }
    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = dataModel.feasible;
    buttonDetail.enabled = dataModel.selectedGeneral.length > 0;
  }
}
