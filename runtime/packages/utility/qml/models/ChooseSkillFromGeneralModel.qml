// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import Fk

QtObject {
  id: root

  property var generals: ["liubei"]
  property var skillList: []
  property string selectedGeneral: ""
  property var shownSkills: []
  property string selectedSkillOrig: ""
  property string titleName: ""
  property var result: []
  
  signal accepted()
  signal rejected()

  readonly property bool feasible: selectedGeneral.length > 0 && selectedSkillOrig.length > 0

  function setGeneral(name, index) {
    if (selectedGeneral && selectedGeneral !== name) {
      selectedSkillOrig = "";
    }
    selectedGeneral = name;
    shownSkills = skillList[index] ?? [];
  }

  function setSkillOrig(orig) {
    selectedSkillOrig = orig;
  }

  function clearSkill() {
    selectedSkillOrig = "";
  }

  function doAccept() {
    result = [selectedGeneral, selectedSkillOrig];
    accepted();
  }



}
