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

  required property ChooseSkillModel dataModel

  title.text: dataModel.promptText
  width: Math.max(40 + Math.min(5, dataModel.skillEntries.length) * (88 + (dataModel.generals ? 36 : 0)), 248)
  height: Math.max(60 + Math.min(32, dataModel.skillEntries.length) * 11, 230)

  GridView {
    id: skillsGrid
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 50
    clip: true

    model: root.dataModel.skillEntries
    cellWidth: root.dataModel.generals ? 124 : 88
    cellHeight: 44
    cacheBuffer: 200

    ScrollBar.vertical: ScrollBar {}

    delegate: Item {
      width: skillsGrid.cellWidth
      height: skillsGrid.cellHeight

      required property var modelData
      required property int index

      // 头像容器：预留固定宽度，避免布局跳动
      Item {
        id: avatarContainer
        width: root.dataModel.generals ? 36 : 0
        height: 36
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        Avatar {
          anchors.fill: parent
          visible: modelData._general !== ""
          general: modelData._general
        }
      }

      // 技能按钮外层容器，用于放置 SkillButton 和 MouseArea
      Item {
        id: skillButtonContainer
        width: 88
        height: 36
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: avatarContainer.right
        anchors.leftMargin: root.dataModel.generals ? 4 : 0

        // 原始 SkillButton，仅用于显示
        SkillButton {
          id: skillBtn
          anchors.fill: parent
          enabled: true
          // 创建基础 dataModel，不传入 selected，避免一次性初始化
          dataModel: Ltk.createSkillModel(modelData.name, { isActive: true, enabled: true })
        }

        // 关键：通过 Binding 使 dataModel.selected 与 result 同步
        Binding {
          target: skillBtn.dataModel
          property: "selected"
          value: root.dataModel.result.includes(modelData.name)
          // 确保绑定不被用户交互破坏（如果需要双向同步，可考虑使用 Binding 的 restoreMode）
          restoreMode: Binding.RestoreBindingOrValue
        }

        // 覆盖 MouseArea 处理点击，直接更新 result
        MouseArea {
          anchors.fill: parent
          onClicked: {
            const isSelected = root.dataModel.result.includes(modelData.name)
            root.dataModel.toggleSkill(modelData.name, !isSelected)
            root.updateSelectable()
          }
        }
      }
    }
  }

  // 底部按钮区域保持不变
  Row {
    spacing: 8
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10

    MetroButton {
      id: buttonConfirm
      Layout.alignment: Qt.AlignHCenter
      text: Lua.tr("OK")
      width: 80
      height: 35
      enabled: root.dataModel.feasible

      onClicked: {
        root.dataModel.accepted()
      }
    }

    MetroButton {
      id: detailBtn
      Layout.alignment: Qt.AlignHCenter
      width: 80
      height: 35
      text: Lua.tr("Show General Detail")
      onClicked: {
        let _skills = []
        if (root.dataModel.result.length > 0) {
          _skills = root.dataModel.result
        } else {
          for (let i = 0; i < root.dataModel.skillEntries.length; i++) {
            _skills.push(root.dataModel.skillEntries[i].name)
          }
        }
        root.parent.showInfoPopup(Qt.createComponent(Cpp.path + "/packages/utility/qml/SkillDetail.qml"), {
          skills: _skills
        })
      }
    }

    MetroButton {
      id: buttonCancel
      Layout.alignment: Qt.AlignHCenter
      width: 80
      height: 35
      text: Lua.tr("Cancel")
      visible: root.dataModel.cancelable

      onClicked: {
        root.dataModel.rejected()
      }
    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = dataModel.feasible
  }
}
