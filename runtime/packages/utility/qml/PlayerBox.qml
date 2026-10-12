// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import LunarLtk
import LunarLtk.Components
import LunarLtk.Components.Photo

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  property var value: []
  signal finish()

  // 压制报错用
  readonly property var roomScene: Ltk.roomScene

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height

    text: Lua.tr(name)
  }

  GridView {
    cellWidth: 130
    cellHeight: 170
    Layout.preferredWidth: root.width - root.width % 97
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
    clip: true

    model: value.map(playerId => {
      const player = Lua.evaluate(
        `(function()
          local player = ClientInstance:getPlayerById(${playerId})

          local model = {
            uri = "LunarLtk.Models",
            name = "PhotoModel",

            prop = {
              playerid = player.id,
              avatar = player.player:getAvatar(),
              screenName = player.player:getScreenName(),
              general = player.general,
              deputyGeneral = player.deputyGeneral,
              role = player.role,
              kingdom = player.kingdom,
              seatNumber = player.seat == 0 and 1 or player.seat,
            },
          }
          return model
        end)()`
      );
      return player;
    });

    delegate: Photo {
      scale: 0.65
      required property var modelData
      dataModel: Lua.createQmlObject(modelData)
      Component.onCompleted: {
        this.visibleChildren[12].visible = false;
      }
    }
      
  }
}
