// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import LunarLtk


QtObject {
  id: root

  property var listNames: []
  property var listCards: []
  property int min: 0
  property int max: 0
  property string prompt: ""
  property bool allowEmpty: false
  property bool cancelable: true

  property var result: []
  
  signal accepted()
  signal rejected()

    readonly property string promptText: Ltk.processPrompt(prompt || "#ChooseCardNames")


  readonly property bool feasible: result.length >= min

  function toggleList(listName, cardNum) {
    const idx = result.indexOf(listName);
    if (idx !== -1) {
      const next = result.slice();
      next.splice(idx, 1);
      result = next;
    } else if (result.length < max && (cardNum || allowEmpty)) {
      result = result.concat([listName]);
    }
  }

  function isChosen(listName) {
    return result.includes(listName);
  }

  function clearAll() {
    result = [];
  }


}
