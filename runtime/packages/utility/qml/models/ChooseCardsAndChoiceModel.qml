// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk
import LunarLtk
QtObject {
  id: root

  property var selected_ids: []
  property var ok_options: []
  property var cards: []
  property var disable_cards: []
  property string prompt: ""
  property int min: 1
  property int max: 1
  property var cancel_options: []

  readonly property string promptText: prompt !== "" ? Ltk.processPrompt(prompt) : Lua.tr("$ChooseCard")

  readonly property bool okEnabled: selected_ids.length >= min && selected_ids.length <= max

  signal requestCardUnselect(int cid)

  function toggleCard(cid, selected) {
    if (ok_options.length === 0)
      return;

    if (selected) {
      selected_ids = selected_ids.concat([cid]);
    } else {
      const i = selected_ids.indexOf(cid);
      if (i !== -1) {
        const next = selected_ids.slice();
        next.splice(i, 1);
        selected_ids = next;
      }
    }
    afterSelectionChange();
  }

  function afterSelectionChange() {
    if (selected_ids.length > max) {
      requestCardUnselect(selected_ids[0]);
    }
  }

  function loadData(data) {
    const d = data;
    cards = d[0].map(cid => {
      if (typeof cid === "object") {
        return cid;
      }
      return Lua.call("GetCardData", cid);
    });
    ok_options = d[1];
    prompt = d[2] ?? "";
    cancel_options = d[3] ?? [];
    min = d[4] ?? 1;
    max = d[5] ?? 1;
    disable_cards = d[6] ?? [];
    selected_ids = [];
  }
}
