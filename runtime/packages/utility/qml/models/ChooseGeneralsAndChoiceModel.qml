// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk

QtObject {
  id: root

  property var result: []
  property var ok_options: []
  property var cards: []
  property var all_cards: []
  property var disable_cards: []
  property string prompt: ""
  property int min: 1
  property int max: 1
  property var cancel_options: []

  property bool isSearching: false
  property bool okEnabled: false

  
  signal accepted()
  signal rejected()

  signal requestGeneralUnselect(string name)

  function toggleGeneral(name, selected) {
    if (ok_options.length === 0)
      return;

    if (selected) {
      result = result.concat([name]);
    } else {
      const i = result.indexOf(name);
      if (i !== -1) {
        const next = result.slice();
        next.splice(i, 1);
        result = next;
      }
    }

    afterSelectionChange();
  }

  function afterSelectionChange() {
    if (result.length > max) {
      requestGeneralUnselect(result[0]);
    } else {
      syncOkEnabled();
    }
  }

  function syncOkEnabled() {
    root.okEnabled = result.length >= min && result.length <= max;
  }

  function applySearchToggle(currentWord) {
    result = [];
    if (isSearching) {
      cards = all_cards;
      isSearching = false;
    } else {
      cards = all_cards.filter(name => Lua.tr(name).indexOf(currentWord) !== -1);
      isSearching = true;
    }
    syncOkEnabled();
  }

  function doAccepted(choice) {
    result = { cards: result.slice(), choice: choice };
    accepted();
  }

}
