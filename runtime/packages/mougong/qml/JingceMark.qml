import QtQuick
import QtQuick.Layouts

import Fk
import Fk.Components.Common
import LunarLTK
import LunarLTK.Components

ColumnLayout {
  id: root
  anchors.fill: parent

  property string name: ""
  property var value: []
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(name)
  }

  GridView {
    cellWidth: 93 + 4
    cellHeight: 130 + 4
    Layout.preferredWidth: root.width - root.width % 97
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
    clip: true

    model: value

    delegate: ColumnLayout {
      width: parent.width
      spacing: 5
      required property var modelData
      CardItem {
        id: cardItem
        autoBack: false
        dataModel: Ltk.createCardModel(modelData.cardId, { selectable: true });
        Avatar { // 角色头像
          visible: modelData.general !== ""
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          width: 40
          height: 40
          general: modelData.general
        }
      }
      Text { // 预测角色名字
        text: Lua.tr("@predict_to") + Lua.tr(modelData.name)
        color: "white"
        font.pixelSize: 15
        wrapMode: Text.WordWrap
      }
    }
  }

}

