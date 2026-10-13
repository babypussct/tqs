// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components
import LunarLtk.Pages.Popups

GraphicsBox {
  id: root

  property var generals: []
  property var selectedItem: []
  property int num : 1
  property string prompt : ""
  property var my_selected: []
  property var ur_selected: []
  property bool no_convert

  title.text: Ltk.processPrompt(prompt)
  width: 620
  height: 370

  Flickable {
    id : cardArea
    height : 280
    width : 600
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter

    // for choose more than 12 cards
    contentHeight: gridLayout.implicitHeight
    ScrollBar.horizontal: ScrollBar {}
    flickableDirection: Flickable.VerticalFlick
    
    clip: true

    GridLayout {
      id : gridLayout
      columns : 6
      width: parent.width
      height: parent.height
      clip: true

      Repeater {
        id: generalRepeater
        model: generals

        delegate: GeneralCardItem {
          required property string modelData
          required property int index
          dataModel: Ltk.createGeneralCardModel(modelData)
          selectable: !my_selected.includes(index) && !ur_selected.includes(index)
          chosenInBox : selectedItem.includes(index)

          onClicked: {
            if (!selectable || num == 0) return;

            if (chosenInBox) {
              selectedItem.splice(root.selectedItem.indexOf(index), 1);
              chosenInBox = false;
            } else {
              chosenInBox = true;
              root.selectedItem.push(index);
              if (selectedItem.length > num) {
                generalRepeater.itemAt(selectedItem[0]).chosenInBox = false;
                selectedItem.splice(0, 1);
              }
            }
            updateSelectable();
          }

          onRightClicked: {
            // 自选似乎必须需要model
            // if (Lua.evaluate('ClientInstance:getSettings("enableFreeAssign")'))
              // Ltk.roomScene.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "FreeAssign"),
              //  { oldName: dataModel.name });
          }
        }
      }

    }
  }


  Item {
    id: buttonArea
    height: 40
    width: parent.width
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    
    
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      MetroButton {
        id: convertBtn
        visible: false
        enabled: false
        text: Lua.tr("Same General Convert")
        onClicked: {
          // 同名替换也需要model
          // cheatLoader.sourceComponent = Qt.createComponent("./SameConvertFrame.qml");
          // cheatLoader.item.extra_data = { cards: generals };
          // cheatDrawer.open();
        }
      }

      MetroButton {
        id: buttonConfirm
        width: 120
        text: Lua.tr("OK")
        enabled: selectedItem.length == num

        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          ClientInstance.replyToServer("",
            { ids : selectedItem, generals : selectedItem.map(id => generalRepeater.itemAt(id).dataModel.name) }
          );
        }
      }

      MetroButton {
        id: buttonDetail
        enabled: selectedItem.length
        text: Lua.tr("Show General Detail")
        onClicked: Ltk.roomScene.showInfoPopup(
          Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
          { generals: selectedItem.map(id => generalRepeater.itemAt(id).dataModel.name) }
        );
      }

    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = selectedItem.length == num;
    buttonDetail.enabled = selectedItem.length;
  }

  // 现在框在展示后会触发shown信号，适合进行数据加载后的一些处理
  onShown: {
    for (var i = 0; i < generals.length; i++) {
      let generalName = generals[i]
      if (!no_convert && !my_selected.includes(i) && !ur_selected.includes(i) && Ltk.getSameGenerals(generalName).length) {
        convertBtn.visible = true;
        convertBtn.enabled = true;
        break;
      }
    }
  }
}
