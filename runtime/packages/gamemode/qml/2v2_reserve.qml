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

// 2v2 十周年禁将BP：选将备将阶段
// 轮询顺序 2→1→3→4；被询问玩家头像右上角有数字倒计时；
// 中间播报"预选N将"，背景色按当前玩家身份（loyalist 土黄 / rebel 青绿）；
// 当前玩家从中间将池选中对应数量武将放入队伍备选池；超时则随机补入
GraphicsBox {
  id: root

  readonly property var roomScene: Ltk.roomScene

  property var generals: []
  property var reserved: []
  property int turnId: -1
  property int count: 0
  property var rebelBanned: []
  property var rebelReserve: []
  property var loyalBanned: []
  property var loyalReserve: []
  property int reserveNum: 5
  property int timeout: 30
  property int remainSec: 30
  property string myRole: "loyalist"
  property string turnRole: "loyalist"
  property int selfId: -1
  property var controlledIds: []
  property var selected: []
  property bool autoTurn: false
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

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    running: false
    onTriggered: {
      root.remainSec--;
      if (root.remainSec <= 0) {
        countdownTimer.stop();
        // 所有客户端都会触发；服务端只处理当前轮玩家的 timeout
        ClientInstance.notifyServer("PushRequest", "updatemini,timeout," + root.turnId);
      }
    }
  }

  // 单个玩家信息：头像 + 名称 + 汉字座位号；当前轮玩家头像右上角显示数字倒计时
  Component {
    id: playerItem

    Column {
      required property var modelData
      readonly property bool isLeftTeam: modelData.seatNumber === 2 || modelData.seatNumber === 3
      spacing: 0
      width: parent.width

      Rectangle {
        width: 56
        height: 56
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

        // 被询问玩家右上角的数字倒计时
        Rectangle {
          visible: modelData.playerid === root.turnId
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: -5
          anchors.rightMargin: -5
          width: 42
          height: 26
          radius: 8
          color: "#E67E22"
          border.color: "white"
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: root.remainSec + "s"
            color: "white"
            font.pixelSize: 14
            font.bold: true
          }
        }
      }

      GlowText {
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        text: modelData.screenName
        font.pixelSize: 13
        elide: Text.ElideMiddle
        horizontalAlignment: Qt.AlignHCenter
        glow.radius: 6
      }

      GlowText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          const seatChr = [
            "一", "二", "三", "四", "五", "六",
            "七", "八", "九", "十", "十一", "十二",
          ]
          return seatChr[modelData.seatNumber - 1];
        }
        font.family: Config.li2Name
        font.pixelSize: 22
        glow.color: "brown"
        glow.spread: 0.2
        glow.radius: 6
      }
    }
  }

  Row {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    anchors.topMargin: 8
    anchors.bottomMargin: 8

    // ===== 左：玩家列（反贼 2、3 号位，约 1/8 宽）=====
    Column {
      width: parent.width / 8
      height: parent.height
      spacing: 6

      Repeater {
        model: {
          const ret = [];
          const players = root.roomScene.dataModel.players;
          for (let i = 0; i < players.length; i++) {
            const s = players[i].seatNumber;
            if (s === 2 || s === 3) ret.push(players[i]);
          }
          ret.sort((a, b) => a.seatNumber - b.seatNumber);
          return ret;
        }

        delegate: playerItem
      }
    }

    // ===== 左：队伍面板（上方禁将横滑，下方备选竖滑）=====
    Column {
      width: parent.width / 8
      height: parent.height
      spacing: 8

      // 队伍禁将（超过 3 个可左右滑动）
      Rectangle {
        width: parent.width
        height: 58
        radius: 6
        color: "#55000000"
        border.width: 1
        border.color: "#66C9A063"
        clip: true

        ListView {
          anchors.fill: parent
          orientation: ListView.Horizontal
          spacing: 4
          clip: true
          model: root.rebelBanned

          delegate: Item {
            required property string modelData
            width: 44
            height: 50

            Avatar {
              anchors.fill: parent
              general: modelData
            }

            Rectangle {
              anchors.fill: parent
              color: "#80000000"
            }

            // "禁"字（无填充背景，置于暗化遮罩之上）
            Text {
              text: "禁"
              anchors.centerIn: parent
              color: "#FF5252"
              font.family: Config.li2Name
              font.pixelSize: 22
              style: Text.Outline
              styleColor: "black"
            }
          }
        }
      }

      // 队伍备选将（超过 5 个可上下滑动）
      Rectangle {
        width: parent.width
        height: Math.min(root.reserveNum, 5) * 70
        radius: 6
        color: "#55000000"
        border.width: 1
        border.color: "#66C9A063"
        clip: true

        ListView {
          anchors.fill: parent
          spacing: 6
          clip: true
          model: root.reserveSlots(root.rebelReserve)

          delegate: Column {
            required property string modelData
            width: parent.width
            spacing: 0

            // 头像式备选槽（反贼绿）
            Rectangle {
              width: 48
              height: 48
              anchors.horizontalCenter: parent.horizontalCenter
              radius: 6
              color: "transparent"
              border.width: 2
              border.color: "#4CAF50"

              Avatar {
                anchors.fill: parent
                anchors.margins: 2
                visible: modelData !== ""
                general: modelData
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: modelData !== ""
              text: Lua.tr(modelData)
              color: "white"
              font.pixelSize: 10
            }
          }
        }
      }
    }

    // ===== 中间：播报 + 剩余将池 + 确认（约占 1/2 宽）=====
    Column {
      width: parent.width / 2
      height: parent.height
      spacing: 6

      // 中间播报：预选N将，背景按当前玩家身份（loyalist 土黄 / rebel 青绿）
      Rectangle {
        id: promptBox
        width: parent.width
        height: 38
        radius: 6
        color: root.turnRole === "loyalist" ? "#C4A255" : "#4DB6AC"
        border.width: 1
        border.color: root.turnRole === "loyalist" ? "#88B8860B" : "#882E7D76"

        Text {
          anchors.centerIn: parent
          text: Lua.tr("2v2_reserve_prepick").arg(root.count)
          color: "white"
          font.family: Config.libianName
          font.pixelSize: 20
          style: Text.Outline
          styleColor: "black"
        }
      }

      // 将池网格（剔除禁将/已备选后的剩余武将）
      Item {
        id: centerGridArea
        width: parent.width
        height: parent.height - 85

        // FreeKill 风格暗色面板
        Rectangle {
          anchors.fill: parent
          radius: 10
          color: "#33000000"
          border.width: 1
          border.color: "#66C9A063"
        }

        Grid {
          id: centerGrid
          anchors.fill: parent
          columns: Math.max(1, Math.ceil(root.generals.length / root.calcRows(root.generals.length)))
          columnSpacing: 0
          rowSpacing: 0

          Repeater {
            model: root.generals

            delegate: Item {
              required property string modelData
              required property int index
              readonly property bool isReserved: root.reserved.includes(modelData)
              readonly property bool isSelected: root.selected.includes(modelData)
              width: centerGridArea.width / centerGrid.columns
              height: centerGridArea.height / root.calcRows(root.generals.length)

              // 已被备选走的武将：原地留空，不刷新网格位置
              Rectangle {
                anchors.fill: parent
                visible: isReserved
                color: "#00000033"
                radius: 4
                border.width: 1
                border.color: "#55777777"
              }

              GeneralCardItem {
                id: card
                anchors.centerIn: parent
                visible: !isReserved
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
                    // 自己是当前备选玩家：正常选中
                    if (isSelected) {
                      root.selected = root.selected.filter(n => n !== modelData);
                    } else if (root.selected.length < root.count) {
                      const sel = root.selected.slice();
                      sel.push(modelData);
                      root.selected = sel;
                    }
                  } else if (root.isSameTeam(root.selfId, root.turnId)) {
                    // 同队队友：点击向当前备选玩家推荐
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

      // 确认按钮（当前轮玩家选中数量达标后显示）
      RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter

        MetroButton {
          text: Lua.tr("2v2_reserve_confirm")
          height: 35
          visible: root.controlsPlayer(root.turnId) && root.count > 0 && root.selected.length === root.count
          onClicked: {
            ClientInstance.notifyServer("PushRequest", "updatemini,select," + root.turnId + "," + root.selected.join(","));
            root.selected = [];
          }
        }
      }
    }

    // ===== 右：队伍面板（上方禁将横滑，下方备选竖滑）=====
    Column {
      width: parent.width / 8
      height: parent.height
      spacing: 8

      // 队伍禁将（超过 3 个可左右滑动）
      Rectangle {
        width: parent.width
        height: 58
        radius: 6
        color: "#55000000"
        border.width: 1
        border.color: "#66C9A063"
        clip: true

        ListView {
          anchors.fill: parent
          orientation: ListView.Horizontal
          spacing: 4
          clip: true
          model: root.loyalBanned

          delegate: Item {
            required property string modelData
            width: 44
            height: 50

            Avatar {
              anchors.fill: parent
              general: modelData
            }

            Rectangle {
              anchors.fill: parent
              color: "#80000000"
            }

            // "禁"字（无填充背景，置于暗化遮罩之上）
            Text {
              text: "禁"
              anchors.centerIn: parent
              color: "#FF5252"
              font.family: Config.li2Name
              font.pixelSize: 22
              style: Text.Outline
              styleColor: "black"
            }
          }
        }
      }

      // 队伍备选将（超过 5 个可上下滑动）
      Rectangle {
        width: parent.width
        height: Math.min(root.reserveNum, 5) * 70
        radius: 6
        color: "#55000000"
        border.width: 1
        border.color: "#66C9A063"
        clip: true

        ListView {
          anchors.fill: parent
          spacing: 6
          clip: true
          model: root.reserveSlots(root.loyalReserve)

          delegate: Column {
            required property string modelData
            width: parent.width
            spacing: 0

            // 头像式备选槽（忠臣土黄）
            Rectangle {
              width: 48
              height: 48
              anchors.horizontalCenter: parent.horizontalCenter
              radius: 6
              color: "transparent"
              border.width: 2
              border.color: "#C4A255"

              Avatar {
                anchors.fill: parent
                anchors.margins: 2
                visible: modelData !== ""
                general: modelData
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: modelData !== ""
              text: Lua.tr(modelData)
              color: "white"
              font.pixelSize: 10
            }
          }
        }
      }
    }

    // ===== 右：玩家列（忠臣 1、4 号位，约 1/8 宽）=====
    Column {
      width: parent.width / 8
      height: parent.height
      spacing: 6

      Repeater {
        model: {
          const ret = [];
          const players = root.roomScene.dataModel.players;
          for (let i = 0; i < players.length; i++) {
            const s = players[i].seatNumber;
            if (s === 1 || s === 4) ret.push(players[i]);
          }
          ret.sort((a, b) => a.seatNumber - b.seatNumber);
          return ret;
        }

        delegate: playerItem
      }
    }
  }

  function calcRows(count) {
    return Math.max(3, Math.ceil(count / 5));
  }

  function reserveSlots(list) {
    const ret = [];
    for (let i = 0; i < root.reserveNum; i++) {
      ret.push(list[i] ?? "");
    }
    return ret;
  }

  // 机器人/离线回合使用 2 秒倒计时，真人回合使用禁将时间
  function effectiveTimeout() {
    return root.autoTurn ? 2 : root.timeout;
  }

  function restartCountdown() {
    countdownTimer.stop();
    root.remainSec = root.effectiveTimeout();
    countdownTimer.start();
  }

  function loadData(data) {
    // 全屏铺满：修正 showPopup 的居中偏移
    root.x = 0;
    root.y = 0;
    root.generals = data.generals ?? [];
    root.reserved = data.reserved ?? [];
    root.turnId = data.turnId ?? -1;
    root.count = data.count ?? 0;
    root.turnRole = data.turnRole ?? "loyalist";
    root.autoTurn = data.autoTurn ?? false;
    root.rebelBanned = data.rebelBanned ?? [];
    root.rebelReserve = data.rebelReserve ?? [];
    root.loyalBanned = data.loyalBanned ?? [];
    root.loyalReserve = data.loyalReserve ?? [];
    root.reserveNum = data.reserveNum ?? 5;
    root.timeout = data.timeout ?? 30;
    root.myRole = data.myRole ?? "loyalist";
    root.selfId = data.selfId ?? -1;
    root.controlledIds = data.controlledIds ?? [root.selfId];
    root.selected = [];
    root.restartCountdown();
  }

  function updateData(data) {
    const type = data[0];
    if (type === "state") {
      const st = data[1];
      root.generals = st.generals;
      root.reserved = st.reserved ?? [];
      root.turnId = st.turnId;
      root.count = st.count;
      root.turnRole = st.turnRole;
      root.autoTurn = st.autoTurn ?? false;
      root.rebelBanned = st.rebelBanned ?? [];
      root.rebelReserve = st.rebelReserve ?? [];
      root.loyalBanned = st.loyalBanned ?? [];
      root.loyalReserve = st.loyalReserve ?? [];
      root.reserveNum = st.reserveNum ?? root.reserveNum;
      root.selected = [];
      root.recommendGeneral = "";
      root.restartCountdown();
    } else if (type === "recommend") {
      // 同队队友推荐/取消推荐的武将（仅同队成员收到）
      root.recommendGeneral = data[1].general;
      root.recommendFrom = data[1].fromId ?? -1;
    } else if (type === "finished") {
      // 全部轮次完成，回复并关闭本窗口
      ClientInstance.replyToServer("", "");
      root.close();
    }
  }
}
