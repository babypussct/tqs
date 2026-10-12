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
    text: Object.entries(root.value).map(suitNumber => {
      const numberList = suitNumber[1];
      numberList.sort((a, b) => a - b);
      let lastNumber = -1;
      let numberSequence = [];
      numberList.forEach((number, index) => {
        const numberStr = Ltk.convertNumber(number);
        if (lastNumber === number - 1) {
          const lastMember = numberSequence[numberSequence.length - 1];
          if (typeof(lastMember) === 'string') {
            numberSequence[numberSequence.length - 1] = [lastMember, numberStr];
          } else {
            numberSequence[numberSequence.length - 1].push(numberStr);
          }
        } else {
          numberSequence.push(numberStr);
        }

        lastNumber = number;
      });

      numberSequence = numberSequence.map(val => {
        if (val instanceof Array) {
          return val[0] + '~' + val[val.length - 1];
        }

        return val;
      })

      return (Lua.tr(suitNumber[0]) + '：' + numberSequence.join('、'))
    }).join('<br />')
    wrapMode: Text.WordWrap
    textFormat: Text.RichText
  }
}
