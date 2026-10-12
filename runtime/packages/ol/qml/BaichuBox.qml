import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Fk
import Fk.Components.Common
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  signal finish()
  property string name
  property var value: []

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(root.name)
  }

  // 懒得起名，功能是根据index从对象中取得牌名
  function getNameFromIdx(idx) {
    const tab = root.value;
    const suit = ["spade", "heart", "club", "diamond"][Math.floor(idx / 3)];
    const type = ["basic", "trick", "equip"][idx % 3];
    return (tab && tab[suit] && tab[suit][type]) ?? "";
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    GridLayout {
      id: table
      anchors.centerIn: parent
      columns: 3
      Repeater {
        model: 12
        Rectangle {
          height: 40
          width: 160
          color: "grey"
          opacity: 0.8
          radius: 8
          border.width: 2

          property string cardName: getNameFromIdx(index)

          Loader {
            anchors.fill: parent
            active: Boolean(cardName)
            sourceComponent: cardItemOverlay
          }

          Component {
            id: cardItemOverlay
            Rectangle {
              anchors.fill: parent
              radius: 6
              border.color: "#FEF7D6"
              border.width: 2
              clip: true

              layer.enabled: true
              layer.effect: DropShadow {
                color: "#845422"
                radius: 5
                samples: 25
                spread: 0.7
              }

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 2 / 3
                anchors.margins: 2
                color: "transparent"
                clip: true
                radius: 5

                Image {
                  anchors.fill: parent
                  source: SkinBank.getCardPicture(cardName)
                  property double sx: sourceSize.width
                  property double sy: sourceSize.height
                  sourceClipRect: Qt.rect(sx*6/93, sy*53/130, sx*81/93, sx*81/93/width*height)
                  fillMode: Image.Stretch
                }

                Rectangle {
                  anchors.fill: parent
                  gradient: Gradient {
                    orientation: Gradient.Horizontal  // ✅ 水平：左→右
                    GradientStop { position: 0.0; color: "#00ffffff" }
                    GradientStop { position: 0.5; color: "#00ffffff" }
                    GradientStop { position: 0.8; color: "#80ffffff" }
                    GradientStop { position: 1.0; color: "#ffffffff" }
                  }

                  layer.enabled: true
                  layer.effect: OpacityMask {
                    maskSource: parent
                  }
                }
              }

              GlowText {
                text: Lua.tr(cardName)
                font.family: Config.li2Name
                // 至多支持6个字的显示，超出时自动缩小字号
                font.pixelSize: 24
                font.bold: true
                color: "#111111"
                glow.color: "#EEEEEE"
                glow.spread: 0.6

                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.bottomMargin: 1

                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignBottom
                transformOrigin: Item.BottomRight

                scale: 1.0
                Component.onCompleted: {
                  // 超出150px强制缩小到适配
                  if (childrenRect.width > 150) {
                    scale = 150 / childrenRect.width
                  }
                  // 最小缩放0.6，防止太小
                  scale = Math.max(scale, 0.6)
                }
              }
            }
          }
        }
      }
    }

    RowLayout {
      anchors.left: table.left
      anchors.bottom: table.top
      anchors.bottomMargin: 4
      Repeater {
        model: ["基本牌", "锦囊牌", "装备牌"]
        Item {
          width: 160
          height: childrenRect.height
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData
            font.pixelSize: 24
            color: "#E4D5A0"
          }
        }
      }
    }

    ColumnLayout {
      anchors.top: table.top
      anchors.right: table.left
      anchors.rightMargin: 4
      Repeater {
        model: ["♠", '<font color="red">♥</font>', "♣", '<font color="red">♦</font>']
        Item {
          width: childrenRect.width
          height: 40
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData
            font.pixelSize: 24
            color: "#E4D5A0"
          }
        }
      }
    }
  }
}
