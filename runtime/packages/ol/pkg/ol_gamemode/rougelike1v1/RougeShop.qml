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

  property bool can_refresh: true
  property var result: []
  property int money: 0
  property int rest_money: 0
  property list<var> items: []
  property int refresh_count: 0

  // 压制报错用
  readonly property var roomScene: Ltk.roomScene

  title.text: Lua.tr("#rouge_shop") + "\n" + Ltk.processPrompt("#rouge_current:::" + Lua.tr("rouge_money") + "×" + money)
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

  Component {
    id: cardDelegate
    Item {
      property var modelValue: [0, 0, "slash", 7, 0]
      CardItem {
        anchors.centerIn: parent
        dataModel: Ltk.createCardModelFromName(parent.modelValue[2]);
        number: parent.modelValue[3]
        suit: (["spade", "club", "heart", "diamond"])[parent.modelValue[4] - 1]
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

    model: items

    delegate: Item {
      width: 200
      height: 290

      MetroButton {
        id: choicetitle
        width: parent.width
        text: Lua.tr("rouge_money") + "×" + modelData[1]
        checked: root.result.includes(index)
        textFont.pixelSize: 24
        anchors.top: choiceDetail.bottom
        anchors.topMargin: 8
        enabled: checked || root.rest_money >= modelData[1]

        onClicked: {
          if (root.result.includes(index)) {
            root.rest_money += modelData[1];
            root.result.splice(root.result.indexOf(index), 1);
          } else {
            root.rest_money -= modelData[1];
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
          case 'skill':
            return talentOrSkill;
          case 'card':
            return cardDelegate;
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
      id: buttonRefresh
      width: 200
      Layout.fillWidth: true
      text: Lua.tr("rouge_shop_refresh") + "（" + Lua.tr("rouge_money") + "×" + 1 + "）"
      enabled: root.money >= 1
      visible: can_refresh

      onClicked: {
        close();
        Ltk.roomModel.deActivate();
        const result = [-1, root.result.map(idx => body.model[idx])];
        ClientInstance.replyToServer("", result);
      }
    }

    MetroButton {
      id: buttonConfirm
      width: 200
      Layout.fillWidth: true
      text: Lua.tr("rouge_shop_ok")

      onClicked: {
        close();
        Ltk.roomModel.deActivate();
        const result = [1, root.result.map(idx => body.model[idx])];
        if (buttonLock.checked)
          result.push(body.model);
        ClientInstance.replyToServer("", result);
      }
    }

    MetroButton {
      id: buttonLock
      width: 200
      Layout.fillWidth: true
      text: Lua.tr("rouge_shop_lock")
      onClicked: {
        checked = !checked;
      }
    }
  }
}
