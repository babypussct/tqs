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

  property bool ignore_money: true
  property var result: []
  property int money: 0
  property int rest_money: 0
  property var choices: []
  property int refresh_count: 0

  title.text: Lua.tr("#rouge_shop") + "\n" + Ltk.processPrompt("#rouge_current:::" + Lua.tr("rouge_money") + "x" + money)
  width: Math.max(140, body.width + 20)
  height: buttons.height + body.height + title.height + 20

  Component {
    id: talentOrSkill
    Flickable {
      property var modelValue: [0, 0, "slash"]
      x: 4
      contentHeight: detail.height
      clip: true
      Text {
        id: detail
        width: parent.width
        text: `<h3>${Lua.tr(modelValue[2])}</h3>${Lua.tr(":" + modelValue[2])}`
        color: "white"
        wrapMode: Text.WordWrap
        font.pixelSize: 16
        textFormat: TextEdit.RichText
      }
    }
  }

  ListView {
    id: body
    x: 10
    y: title.height + 5
    width: 880
    height: 300
    orientation: ListView.Horizontal
    clip: true
    spacing: 20

    model: choices

    delegate: Item {
      width: 200
      height: 290

      MetroButton {
        id: choicetitle
        width: parent.width
        text: Lua.tr("rouge_money") + "x" + modelData[1]
        checked: root.result.includes(index)
        textFont.pixelSize: 24
        anchors.top: choiceDetail.bottom
        anchors.topMargin: 8
        enabled: checked || ( root.result.length === 0 && ( root.ignore_money || root.rest_money >= modelData[1] ) )

        onClicked: {
          if (root.result.includes(index)) {
            if (!root.ignore_money) {
              root.rest_money += modelData[1];
            }
            root.result.splice(root.result.indexOf(index), 1);
          } else {
            if (!root.ignore_money) {
              root.rest_money -= modelData[1];
            }
            root.result.push(index);
          }
          root.resultChanged();
        }
      }

      Loader {
        id: choiceDetail
        width: parent.width
        height: parent.height - choicetitle.height
        sourceComponent: {
          switch (modelData[0]) {
          case 'talent':
            return talentOrSkill;
          default:
            return;
          }
        }
        Binding {
          target: choiceDetail.item
          property: "modelValue"
          value: modelData
        }
      }
    }
  }

  Row {
    id: buttons
    anchors.margins: 8
    anchors.horizontalCenter: root.horizontalCenter
    anchors.top: body.bottom
    spacing: 32

    MetroButton {
      id: buttonConfirm
      width: 200
      Layout.fillWidth: true
      text: Lua.tr("rouge_shop_ok")

      onClicked: {
        close();
        Ltk.roomModel.deActivate();
        const result = [1, root.result.map(idx => body.model[idx])];
        ClientInstance.replyToServer("", result);
      }
    }
  }
}
