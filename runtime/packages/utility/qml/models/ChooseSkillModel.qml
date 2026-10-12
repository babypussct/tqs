// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import LunarLtk

QtObject {
  id: root

  property var skills: []
  property var generals: null
  property var skillEntries: {
    const entries = [];
    if (!generals) {
      for (let i = 0; i < skills.length; i++) {
        entries.push({
          name: skills[i],
          _general: ""
        });
      }
    } else {
      for (let i = 0; i < skills.length; i++) {
        entries.push({
          name: skills[i],
          _general: generals[i] ?? ""
        });
      }
    }
    return entries;
  }
  property var result: []
  property int min: 0
  property int max: 0
  property string prompt: ""
  property bool cancelable: false


  signal accepted()
  signal rejected()
  readonly property string promptText: prompt === "" ? Lua.tr("$Choice") : Ltk.processPrompt(prompt)

  readonly property bool feasible: result.length <= max && result.length >= min

  function toggleSkill(orig, pressed) {
    if (pressed) {
      result = result.concat([orig]);
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
