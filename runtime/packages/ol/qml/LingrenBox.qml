// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components
import LunarLtk.Pages.Popups

GraphicsBox {
  id: root

  // 目标角色名（用于提示）
  property string prompt: ""

  // 三种类别的随机卡牌图片名（由 Lua 传入）
  property string basicPic: ""
  property string trickPic: ""
  property string equipPic: ""

  // 已选类别（元素为 "basic" | "trick" | "equip"，无重复，可空）
  property var selectedTypes: []

  title.text: Ltk.processPrompt(prompt)
  width: Math.max(title.width, body.width) + 50
  height: body.height + title.height + buttons.height + 50

  Component.onCompleted: {
    root.selectedTypes = [];
  }

  ColumnLayout {
    id: body
    anchors.horizontalCenter: parent.horizontalCenter
    x: 0
    y: title.height + 12
    spacing: 14

    // 三个类别按钮（卡牌比例 93:130）
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 24

      Repeater {
        model: [
          {
            key: "basic",
            label: Lua.tr("#lingren-box-basic"),
            pic: root.basicPic
          },
          {
            key: "trick",
            label: Lua.tr("#lingren-box-trick"),
            pic: root.trickPic
          },
          {
            key: "equip",
            label: Lua.tr("#lingren-box-equip"),
            pic: root.equipPic
          }
        ]

        Item {
          id: typeButton
          Layout.preferredWidth: 93
          Layout.preferredHeight: 130

          readonly property string typeKey: modelData.key

          // 该类别是否已选
          property bool isSelected: {
            for (let i = 0; i < root.selectedTypes.length; i++) {
              if (root.selectedTypes[i] === modelData.key) return true;
            }
            return false;
          }

          // 卡牌图片背景（半透明效果）
          Image {
            anchors.fill: parent
            source: SkinBank.getCardPicture(modelData.pic)
            fillMode: Image.PreserveAspectCrop
            opacity: typeButton.isSelected ? 0.85 : 0.4
          }

          // 半透明遮罩（保证文字可读）
          Rectangle {
            anchors.fill: parent
            color: typeButton.isSelected ? "#A0FDF2C8" : "#80252621"
            radius: 8
            border.width: typeButton.isSelected ? 3 : 2
            border.color: {
              if (typeButton.isSelected) return "#FFFFFF";
              if (typeHover.hovered) return "#C4B48A";
              return "#A6967A";
            }

            Behavior on color {
              ColorAnimation { duration: 120 }
            }
            Behavior on border.color {
              ColorAnimation { duration: 120 }
            }
          }

          // 竖排文字（用 \n 换行实现）
          Text {
            anchors.centerIn: parent
            z: 2
            text: modelData.label.split("").join("\n")
            color: typeButton.isSelected ? "#1D1E19" : "#FFF8E0"
            font.pixelSize: 24
            font.bold: true
            font.family: Config.libianName
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.1
            style: Text.Outline
            styleColor: typeButton.isSelected ? "#FDF2C8" : "#000000"
          }

          // 选中标记（左上角）
          Rectangle {
            visible: typeButton.isSelected
            width: 22
            height: 22
            radius: 11
            color: "#1D1E19"
            border.width: 1
            border.color: "#FDF2C8"
            x: 6
            y: 6
            z: 3

            Text {
              anchors.centerIn: parent
              text: "✓"
              color: "#FDF2C8"
              font.pixelSize: 14
              font.bold: true
              font.family: Config.libianName
            }
          }

          // 点击切换选中状态（不能重复选，再次点击取消）
          TapHandler {
            onTapped: {
              const key = modelData.key;
              const arr = root.selectedTypes.slice();
              const idx = arr.indexOf(key);
              if (idx >= 0) {
                arr.splice(idx, 1);
              } else {
                arr.push(key);
              }
              root.selectedTypes = arr;
            }
          }

          HoverHandler {
            id: typeHover
            cursorShape: Qt.PointingHandCursor
          }
        }
      }
    }

    // 已选类别显示
    Item {
      Layout.fillWidth: true
      height: 40 // 和方块高度保持一致，消除依赖循环

      // 方块组容器：水平居中
      Row {
        id: boxGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Repeater {
          model: 3
          Rectangle {
            width: 40
            height: 40
            radius: 6
            color: index < root.selectedTypes.length ? "#FDF2C8" : "#252621"
            border.width: 1
            border.color: "#A6967A"

            Text {
              anchors.centerIn: parent
              text: {
                if (index >= root.selectedTypes.length) return "";
                const key = root.selectedTypes[index];
                if (key === "basic") return Lua.tr("#lingren-box-basic-short");
                if (key === "trick") return Lua.tr("#lingren-box-trick-short");
                if (key === "equip") return Lua.tr("#lingren-box-equip-short");
                return "";
              }
              color: "#1D1E19"
              font.pixelSize: 16
              font.bold: true
              font.family: Config.libianName
            }
          }
        }
      }

      // 文字紧贴方块组左侧
      Text {
        color: "#A6967A"
        font.pixelSize: 15
        font.family: Config.libianName
        text: Lua.tr("#lingren-box-selected")
        anchors.verticalCenter: boxGroup.verticalCenter
        anchors.right: boxGroup.left
        anchors.rightMargin: 8 // 文字与方块之间的间距，按需微调
      }
    }
  }

  // 底部操作按钮（仅确定，不选即猜三类全无）
  Row {
    id: buttons
    anchors.margins: 8
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 32

    MetroButton {
      width: 120
      height: 40
      text: Lua.tr("OK")
      textFont.pixelSize: 18
      textFont.bold: true
      textColor: "#F0D68A"
      backgroundColor: "#2A1F1F"
      border.width: 1
      border.color: "#6B4F3A"

      onClicked: {
        close();
        Ltk.roomModel.deActivate();
        ClientInstance.replyToServer("", root.selectedTypes);
      }
    }
  }
}
