pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components
import LunarLtk.Pages.Popups
import LunarLtk.Models.Popups
GraphicsBox {
  id: root

  property var friend_cards: []
  property var my_cards: []
  property int friend_recommend: -1
  property int friend_not_determ: -1
  property int friend_selected: -1
  property int my_recommend: -1
  property int selected: -1
  property bool initial: true
  property bool shared: false

  width: 70 + 100 * my_cards.length
  height: 360

  ChooseGeneralModel {
    id: chooseGeneralModel
  }

  Connections {
    target: chooseGeneralModel
    function onGeneralChanged(idx, newname) {
      root.my_cards = chooseGeneralModel.generals.slice();
    }
  }

  ColumnLayout {
    id: cardView
    anchors.fill: parent
    anchors.margins: 20
    anchors.bottomMargin: 50
    anchors.topMargin: 30

    RowLayout {
      spacing: 8

      Rectangle {
        color: "#6B5D42"
        implicitWidth: 20
        implicitHeight: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: "队友"
          color: "white"
          font.family: Config.libianName
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Repeater {
        model: root.friend_cards

        GeneralCardItem {
          required property string modelData
          required property int index
          dataModel: Ltk.createGeneralCardModel(modelData)
          selectable: root.friend_selected === -1
          onClicked: {
            if (!selectable) return;
            if (root.friend_recommend == index) {
              root.friend_recommend = -1;
            } else {
              root.friend_recommend = index;
            }
            ClientInstance.notifyServer("PushRequest", "updatemini,recommend," + root.friend_recommend);
          }

          onRightClicked: {root.parent.showInfoPopup(
            Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),{ generals: [modelData] });
          }

          Image {
            source: AppPath + "/packages/gamemode/image/determ.png"
            visible: friend_selected == index
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }

          Image {
            source: AppPath + "/packages/gamemode/image/not_determ.png"
            visible: friend_not_determ == index
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }

          Image {
            source: AppPath + "/packages/gamemode/image/recommend2.png"
            visible: friend_recommend == index
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }
        }
      }
    }

    RowLayout {
      spacing: 8

      Rectangle {
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: "你"
          color: "white"
          font.family: Config.libianName
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Repeater {
        model: my_cards

        GeneralCardItem {
          required property string modelData
          required property int index
          dataModel: Ltk.createGeneralCardModel(modelData)
          // 同队共用将池时：队友确认选择的武将，本方不可再选
          selectable: root.shared ? (root.friend_selected !== index) : true
          chosenInBox: root.selected == index
          selected: root.selected == index
          onClicked: {
            if (!selectable) return;
            if (root.selected == index) {
              root.selected = -1;
            } else {
              root.selected = index;
            }
            ClientInstance.notifyServer("PushRequest", "updatemini,preselect," + root.selected);
          }

          onRightClicked: {
            if (Lua.client.getSettings("enableFreeAssign")) {
              root.parent.showInfoPopup(Qt.createComponent("LunarLtk.Pages.InfoPopups", "FreeAssign"),
                { dataModel: chooseGeneralModel, index: index });
            }
          }

          Image {
            source: AppPath + "/packages/gamemode/image/recommend.png"
            visible: my_recommend == index
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }

          // 队友已确认该武将：置灰并标记，不可再选
          Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: root.shared && root.friend_selected === index
            z: 5
          }

          Text {
            anchors.centerIn: parent
            text: "队友已选"
            color: "#FFD700"
            font.pixelSize: 16
            style: Text.Outline
            styleColor: "black"
            visible: root.shared && root.friend_selected === index
            z: 6
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    width: parent.width
    height: 40
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 5

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      MetroButton {
        id: convertBtn
        visible: !Lua.client.getSettings("disableSameConvert")
        enabled: visible && chooseGeneralModel.canConvert
        text: Lua.tr("Same General Convert")
        onClicked: {
          roomScene.showInfoPopup(
            Qt.createComponent("LunarLtk.Pages.InfoPopups", "SameConvert"),
            { dataModel: chooseGeneralModel }
          );
        }
      }

      MetroButton {
        id: fightButton
        text: Lua.tr("Fight")
        width: 120
        height: 35
        enabled: root.selected >= 0

        onClicked: {
          close();
          roomScene.state = "notactive";
          ClientInstance.notifyServer("PushRequest", "updatemini,select," + root.selected);
          ClientInstance.replyToServer("", root.my_cards[root.selected]);
        }
      }

      MetroButton {
        id: detailBtn
        enabled: root.selected >= 0
        text: Lua.tr("Show General Detail")
          onClicked: {root.parent.showInfoPopup(
            Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),{ generals: [root.my_cards[root.selected]] });
          }
      }
    }
  }

  function loadData(data) {
    root.title.text = ("你的座次是 %1 , 请选择")
      .arg(Lua.tr("seat#" + roomScene.getPhoto(Cpp.self.id).seatNumber))
    root.friend_cards = data.friend;
    root.my_cards = data.me;
    root.shared = data.shared ?? false;
    chooseGeneralModel.generals = root.my_cards;
    chooseGeneralModel.initGeneralModels();

    root.initial = false;
  }

  onMy_cardsChanged: {
    if (root.initial) {
      return;
    }

    chooseGeneralModel.generals = root.my_cards;
    chooseGeneralModel.initGeneralModels();

    ClientInstance.notifyServer("PushRequest", "updatemini,updateFriendCards," + my_cards.join("|"));
    /* if (root.selected && !my_cards.includes(root.selected)) {
      root.selected = -1;
      ClientInstance.notifyServer("PushRequest", "updatemini,preselect," + root.selected);
    } */
  }

  function updateData(data) {
    let [type, value] = data;
    value = value ?? -1;
    if (type == "preselect") {
      friend_not_determ = value;
    } else if (type == "select") {
      friend_not_determ = -1;
      friend_recommend = -1;
      friend_selected = value;
      // 同队共用将池：若队友已确认的武将与我方当前预选相同，清空我方预选
      if (root.shared && root.selected === value) {
        root.selected = -1;
        ClientInstance.notifyServer("PushRequest", "updatemini,preselect,-1");
      }
    } else if (type == "recommend") {
      my_recommend = value;
    } else if (type == "updateFriendCards") {
      friend_cards = value.split("|");
    }
  }
}
