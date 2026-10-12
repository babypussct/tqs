// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import LunarLtk

QtObject {
  id: root

  property var cards: []
  property var skills: []
  property int min: 0
  property int max: 0
  property string prompt: ""
  property bool cancelable: false

  property var result: []
  
  signal accepted()
  signal rejected()

  readonly property string promptText: Ltk.processPrompt(prompt)

  readonly property bool feasible: result.length <= max && result.length >= min

  signal requestUnpress(string orig)

  function onSkillPressed(orig, pressed) {
    if (pressed) {
      result = result.concat([orig]);
      if (result.length > max) {
        requestUnpress(result[0]);
      }
    } else {
      const i = result.indexOf(orig);
      if (i !== -1) {
        const next = result.slice();
        next.splice(i, 1);
        result = next;
      }
    }
  }

}
