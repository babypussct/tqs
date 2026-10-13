// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Components
import LunarLtk.Pages.Popups

// 2v2 十周年禁将BP：全屏禁将页面
// 轮询顺序 3、1、4、2 号位；第一次点击选中（忠臣黄/反贼绿），再次点击同一武将禁将（灰遮罩+禁）
GraphicsBox {
  id: root

  readonly property var roomScene: Ltk.roomScene

  property var pool: []
  property var banned: []
  property int turnId: -1
  property int banNum: 2
  property int reserveNum: 5
  property int timeout: 30
  property string myRole: "loyalist"
  property int selfId: -1
  property int selectedIdx: -1
  property bool autoTurn: false
  property var controlledIds: []
  property string recommendGeneral: ""
  property int recommendFrom: -1

  // 判断两个玩家是否同队（1、4号位忠臣，2、3号位反贼）
  function isSameTeam(aId, bId) {
    const ps = root.roomScene.dataModel.players;
    let aSeat = -1, bSeat = -1;
    for (let i = 0; i < ps.length; i++) {
      if (ps[i].playerid === aId) aSeat = ps[i].seatNumber;
      if (ps[i].playerid === bId) bSeat = ps[i].seatNumber;
    }
    const team = s => (s === 1 || s === 4) ? 1 : 2;
    return team(aSeat) === team(bSeat);
  }

  function controlsPlayer(playerId) {
    return root.controlledIds.includes(playerId);
  }

  movable: false
  width: roomScene.width
  height: roomScene.height

  title.text: Lua.tr("2v2_bp_title")

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    anchors.topMargin: 34
    anchors.bottomMargin: 12
    spacing: 8

    // 倒计时（弹窗中间最上方，含数字倒计时）
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 28

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Lua.tr("2v2_bp_banning")
          color: "#FFD700"
          font.family: Config.libianName
          font.pixelSize: 20
          style: Text.Outline
          styleColor: "black"
        }

        Text {
          id: countdownText
          anchors.verticalCenter: parent.verticalCenter
          text: Math.max(0, Math.ceil(progress.value / 100 * root.effectiveTimeout())) + "s"
          color: "#FFD700"
          font.pixelSize: 22
          font.bold: true
          style: Text.Outline
          styleColor: "black"
        }

        ProgressBar {
          id: progress
          anchors.verticalCenter: parent.verticalCenter
          width: 260
          height: 12
          from: 0
          to: 100
          value: 100

          background: Rectangle {
            implicitHeight: 12
            color: "#66000000"
            radius: 6
            border.width: 1
            border.color: "#88C9A063"
          }

          contentItem: Rectangle {
            radius: 6
            gradient: Gradient {
              GradientStop { position: 0.0; color: "#F7C873" }
              GradientStop { position: 1.0; color: "#D4A642" }
            }
          }
        }

        NumberAnimation {
          id: countdownAnim
          target: progress
          property: "value"
          from: 100
          to: 0
          running: false

          onFinished: {
            // 所有客户端都会触发；服务端只处理当前禁将者的 timeout
            ClientInstance.notifyServer("PushRequest", "updatemini,timeout," + root.turnId);
          }
        }
      }
    }

    // 武将头像网格区域
    Item {
      id: gridArea
      Layout.fillWidth: true
      Layout.fillHeight: true

      // FreeKill 风格暗色面板
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#33000000"
        border.width: 1
        border.color: "#66C9A063"
      }

      Grid {
        id: generalGrid
        anchors.fill: parent
        columns: Math.max(1, Math.ceil(root.pool.length / root.calcRows(root.pool.length)))
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
          model: root.pool

          delegate: Item {
            required property string modelData
            required property int index
            readonly property bool isBanned: root.banned.includes(modelData)
            readonly property bool isSelected: root.selectedIdx === index
            width: gridArea.width / generalGrid.columns
            height: gridArea.height / root.calcRows(root.pool.length)

            GeneralCardItem {
              id: card
              anchors.centerIn: parent
              width: 93
              height: 130
              dataModel: Ltk.createGeneralCardModel(modelData)
              selectable: true
              scale: Math.min(parent.width / 93, parent.height / 130)
              transformOrigin: Item.Center

              // 选中边框：loyalist 黄色，rebel 绿色
              Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 3
                border.color: root.myRole === "loyalist" ? "#FFD700" : "#4CAF50"
                visible: isSelected
                z: 4
              }

              // 禁将遮罩（暗化）
              Rectangle {
                anchors.fill: parent
                color: "#444444"
                opacity: 0.55
                visible: isBanned
                z: 5
              }

              // "禁"字（无填充背景，置于暗化遮罩之上）
              Text {
                text: "禁"
                anchors.centerIn: parent
                color: "#FF5252"
                font.family: Config.li2Name
                font.pixelSize: 34
                style: Text.Outline
                styleColor: "black"
                visible: isBanned
                z: 6
              }

              // 队友推荐标记（与选将阶段推荐样式一致，置于卡框内部底部；同队可见）
              Image {
                source: AppPath + "/packages/gamemode/image/" +
                  (root.recommendFrom === root.selfId ? "recommend2.png" : "recommend.png")
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                scale: 0.75
                z: 8
                visible: root.isSameTeam(root.selfId, root.turnId) && root.recommendGeneral === modelData
              }

              onClicked: {
                if (root.controlsPlayer(root.turnId)) {
                  // 自己是当前禁将者：正常选中/禁将
                  if (isBanned) return;
                  if (isSelected) {
                    root.selectedIdx = -1;
                  ClientInstance.notifyServer("PushRequest", "updatemini,ban," + modelData + "," + root.turnId);
                  } else {
                    root.selectedIdx = index;
                  }
                } else if (root.isSameTeam(root.selfId, root.turnId)) {
                  // 同队队友：点击向当前禁将者推荐
                  ClientInstance.notifyServer("PushRequest", "updatemini,recommend," + modelData);
                }
              }

              // 右键或长按弹出武将技能详情
              onRightClicked: {
                root.roomScene.showInfoPopup(
                  Qt.createComponent("LunarLtk.Pages.InfoPopups", "GeneralDetail"),
                  { generals: [modelData] });
              }
            }
          }
        }
      }
    }

    // 玩家信息栏：头像 + 名称 + 汉字座位号，当前禁将者高亮
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: 140
      radius: 10
      color: "#33000000"
      border.width: 1
      border.color: "#66C9A063"
      implicitWidth: playerBar.width + 24

      Row {
        id: playerBar
        anchors.centerIn: parent
        spacing: 48

      Repeater {
        model: {
          const order = [3, 1, 4, 2]; // 按禁将轮询顺序排列
          const ps = [];
          const players = root.roomScene.dataModel.players;
          for (let i = 0; i < players.length; i++) {
            ps.push(players[i]);
          }
          ps.sort((a, b) => order.indexOf(a.seatNumber) - order.indexOf(b.seatNumber));
          return ps;
        }

        delegate: Column {
          required property var modelData
          spacing: 0
          width: 90

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lua.tr("2v2_bp_banning")
            visible: modelData.playerid === root.turnId
            font.pixelSize: 11
            color: "#FFD700"
            style: Text.Outline
            styleColor: "black"
          }

          Rectangle {
            id: avatarFrame
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 6
            color: "#1E1E1E"
            border.width: 3
            // 边框按身份：忠臣（1、4号位）土黄，反贼（2、3号位）绿
            border.color: (modelData.seatNumber === 1 || modelData.seatNumber === 4) ? "#C4A255" : "#4CAF50"

            Avatar {
              anchors.fill: parent
              anchors.margins: 3
              general: modelData.avatar
            }
          }

          GlowText {
            id: playerName
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: modelData.screenName
            font.pixelSize: 14
            elide: Text.ElideMiddle
            horizontalAlignment: Qt.AlignHCenter
            glow.radius: 6
          }

          GlowText {
            id: seatNum
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              const seatChr = [
                "一", "二", "三", "四", "五", "六",
                "七", "八", "九", "十", "十一", "十二",
              ]
              return seatChr[modelData.seatNumber - 1];
            }
            font.family: Config.li2Name
            font.pixelSize: 24
            glow.color: "brown"
            glow.spread: 0.2
            glow.radius: 6
          }
        }
      }
    }
    }
  }

  function calcRows(count) {
    return count > 30 ? 4 : 3;
  }

  // 机器人/离线回合使用 2 秒倒计时，真人回合使用禁将时间
  function effectiveTimeout() {
    return root.autoTurn ? 2 : root.timeout;
  }

  function restartCountdown() {
    countdownAnim.stop();
    progress.value = 100;
    countdownAnim.duration = root.effectiveTimeout() * 1000;
    countdownAnim.start();
  }

  function loadData(data) {
    // 全屏铺满：修正 showPopup 的居中偏移
    root.x = 0;
    root.y = 0;
    root.pool = data.generals ?? [];
    root.banned = data.banned ?? [];
    root.turnId = data.turnId ?? -1;
    root.autoTurn = data.autoTurn ?? false;
    root.banNum = data.banNum ?? 2;
    root.reserveNum = data.reserveNum ?? 5;
    root.timeout = data.timeout ?? 30;
    root.myRole = data.myRole ?? "loyalist";
    root.selfId = data.selfId ?? -1;
    root.controlledIds = data.controlledIds ?? [root.selfId];
    root.selectedIdx = -1;
    root.restartCountdown();
  }

  function updateData(data) {
    const type = data[0];
    if (type === "state") {
      const st = data[1];
      root.pool = st.generals;
      root.banned = st.banned;
      root.turnId = st.turnId;
      root.autoTurn = st.autoTurn ?? false;
      root.selectedIdx = -1;
      root.recommendGeneral = "";
      root.restartCountdown();
    } else if (type === "recommend") {
      // 同队队友推荐/取消推荐的武将（仅同队成员收到）
      root.recommendGeneral = data[1].general;
      root.recommendFrom = data[1].fromId ?? -1;
    } else if (type === "finished") {
      // 所有队伍轮询禁将完毕，回复并关闭本窗口
      ClientInstance.replyToServer("", "");
      root.close();
    }
  }
}
