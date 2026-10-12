import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  property var value: ({})
  property int playerid
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Lua.tr(root.name)
  }

  Text {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    font.pixelSize: 18
    color: '#E4D5A0'
    text: Object.entries(root.value).map(val => {
      const key = val[0];
      const record = val[1];
      let title = '#JingMouRemoved';
      if (key === 'suits') {
        title = '#JingMouSuits';
      } else if (key === 'types') {
        title = '#JingMouTypes';
      }

      return (Lua.tr(title) + '：' + (record ? record.map(rec => Lua.tr(rec)).join('、') : Lua.tr('#JingMouNone')));
    }).join('<br />')
    wrapMode: Text.WordWrap
    textFormat: Text.RichText
  }
}
