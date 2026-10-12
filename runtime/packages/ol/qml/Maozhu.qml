import QtQuick
import QtQuick.Layouts
import Fk
import LunarLtk
import LunarLtk.Components

Item {
  id: root
  anchors.fill: parent
  signal finish()
  property string name
  property var value: ({ name: "", map: [] })
  property int playerid

  BigGlowText {
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.leftMargin: 20
    anchors.topMargin: 20
    width: skillDesc.width
    height: childrenRect.height + 4

    text: Lua.tr(root.name) + ' - ' + Lua.tr(root.value.name)
  }

  RowLayout {
    width: parent.width - 40
    height: parent.height - 40
    anchors.top: parent.top 
    anchors.topMargin: 20
    anchors.horizontalCenter: parent.horizontalCenter

    Text {
      id: skillDesc
      color: "#E4D5A0"
      font.pixelSize: 18
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      wrapMode: Text.WrapAnywhere
      text: {
        const skillName = Lua.tr(theMap.activeSkillName);
        const skillDesc = Lua.tr(":" + theMap.activeSkillName);
        const hint = "<i>点击地块查看城市技能描述<br>再次点击同一地块返回地图技能描述</i>";
        return `<b>〖${skillName}〗</b><br>${skillDesc}<br><br>${hint}`;
      }
    }

    PeixiuMap {
      id: theMap
      Layout.fillHeight: true
      mapSkillName: {
        const name = root.value?.name;
        if (!name) return "";
        const suffix = name.substr(4);
        return "peixiu_" + suffix;
      }
      mapData: root.value?.map ?? []
    }
  }
}
