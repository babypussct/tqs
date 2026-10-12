// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups

GraphicsBox {
  id: root

  property var initialNumbers: []
  property var expressionList: []
  property var operatorSequence: []
  
  // 拖拽状态
  property bool isDragging: false
  property var dragData: null
  property int dragSourceIndex: -1
  property bool isHoveringDropZone: false

  title.text: Lua.tr("jingjin_result")
  width: 600
  height: 450

  // ================= 核心逻辑函数 =================

  function isNumberUsed(numId) {
    for (let i = 0; i < expressionList.length; i++) {
      if (expressionList[i].type === 'num' && expressionList[i].id === numId) return true;
    }
    return false;
  }

  function evaluateValues(values, operators) {
    var nums = values.slice();
    var ops = operators.slice();
    var idx = 0;
    while (idx < ops.length) {
      if (ops[idx] === '×' || ops[idx] === '÷') {
        if (ops[idx] === '÷' && nums[idx + 1] === 0) return null;
        var result = ops[idx] === '×' ? nums[idx] * nums[idx + 1] : nums[idx] / nums[idx + 1];
        nums.splice(idx, 2, result);
        ops.splice(idx, 1);
      } else {
        idx++;
      }
    }

    var total = nums[0];
    for (var i = 0; i < ops.length; i++) {
      if (ops[i] === '+') total += nums[i + 1];
      else if (ops[i] === '-') total -= nums[i + 1];
    }
    return total;
  }

  function calculateExpression() {
    if (expressionList.length !== 7) return 0;
    var nums = [], ops = [];
    for (let i = 0; i < expressionList.length; i++) {
      if (i % 2 === 0) nums.push(numberValue(i / 2));
      else ops.push(expressionList[i].value);
    }

    var idx = 0;
    while (idx < ops.length) {
      if (ops[idx] === '×' || ops[idx] === '÷') {
        let res = (ops[idx] === '×') ? nums[idx] * nums[idx+1] : nums[idx] / nums[idx+1];
        nums.splice(idx, 2, res);
        ops.splice(idx, 1);
      } else {
        idx++;
      }
    }

    var finalResult = nums[0];
    for (let j = 0; j < ops.length; j++) {
      if (ops[j] === '+') finalResult += nums[j+1];
      else if (ops[j] === '-') finalResult -= nums[j+1];
    }
    return finalResult;
  }

  function numberValue(numberIndex) {
    var item = expressionList[numberIndex * 2];
    if (item.type === 'num') return item.value;
    var operator = numberIndex === 0 ? operatorSequence[0] : operatorSequence[numberIndex - 1];
    return operator === '+' || operator === '-' ? 0 : 1;
  }

  function formatResult() {
    var result = calculateExpression();
    return result === Math.floor(result) ? result.toString() : result.toFixed(2);
  }

  function checkWin() {
    if (expressionList.length !== 7) return false;
    for (var i = 0; i < expressionList.length; i++) {
      if (i % 2 === 0 && expressionList[i].type !== 'num') return false;
      if (i % 2 !== 0 && expressionList[i].type !== 'op') return false;
    }
    
    var usedCount = 0;
    for (let j = 0; j < initialNumbers.length; j++) {
      if (isNumberUsed(initialNumbers[j].id)) usedCount++;
    }
    if (usedCount !== initialNumbers.length) return false;
    
    return Math.abs(calculateExpression() - 24) < 1e-6;
  }

  function setNumberSlot(index, item) {
    var newList = expressionList.slice();
    newList[index] = item;
    expressionList = newList;
  }

  function fillFirstEmptySlot(item) {
    for (var i = 0; i < expressionList.length; i += 2) {
      if (expressionList[i].type === 'slot') {
        setNumberSlot(i, item);
        return;
      }
    }
  }

  function clearExpression() { 
    var newList = operatorSequence.reduce(function(list, operator) {
      list.push({type: 'slot', value: '?'}, {type: 'op', value: operator, id: -1});
      return list;
    }, []);
    newList.push({type: 'slot', value: '?'});
    expressionList = newList;
  }

  // ================= UI 布局 =================

  ColumnLayout {
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    anchors.topMargin: 50
    anchors.bottomMargin: 15
    anchors.leftMargin: 15
    anchors.rightMargin: 15

    // 1. 可用数字区
    Rectangle {
      Layout.fillWidth: true; Layout.preferredHeight: 60
      color: "#2a2a2a"; border.color: "#555"; radius: 5
      Row {
        anchors.centerIn: parent; spacing: 10
        Repeater {
          model: initialNumbers
          delegate: Rectangle {
            id: availableCard
            width: 50; height: 40
            color: availableMouse.containsMouse ? "#6aaaf0" : "#4a90e2"
            radius: 5
            border.color: availableMouse.containsMouse ? "#ffffff" : "#b9d9ff"
            border.width: availableMouse.containsMouse ? 2 : 1
            visible: !isNumberUsed(modelData.id)
            Text { anchors.centerIn: parent; text: modelData.value; font.pixelSize: 20; font.bold: true; color: "white" }

            MouseArea {
              id: availableMouse
              property bool dragged: false
              anchors.fill: parent
              preventStealing: true
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) {
                dragged = false;
                startDrag(this, mouse, {type: "num", value: modelData.value, id: modelData.id}, -1);
              }
              onPositionChanged: function(mouse) { dragged = true; updateDragPos(this, mouse); }
              onReleased: function(mouse) { endDrag(); }
              onCanceled: function() { cancelDrag(); }
              onClicked: function(mouse) {
                if (!dragged) fillFirstEmptySlot({type: "num", value: modelData.value, id: modelData.id});
              }
            }
          }
        }
      }
    }

    // 2. 表达式构建区
    Rectangle {
      id: dropZone
      Layout.fillWidth: true; Layout.fillHeight: true
      border.color: isHoveringDropZone ? "#4caf50" : (checkWin() ? "#4caf50" : "#555")
      border.width: isHoveringDropZone ? 3 : 2
      color: isHoveringDropZone ? "#252525" : "#1e1e1e"
      radius: 8

      Item {
        anchors.fill: parent
        anchors.margins: 10

        Row {
          id: exprRow
          anchors.centerIn: parent
          spacing: 8
          visible: expressionList.length > 0

          Repeater {
            model: expressionList
            delegate: Rectangle {
              width: modelData.type === 'num' || modelData.type === 'slot' ? 50 : 40; height: 40
              color: modelData.type === 'slot' ? "#383838" : (modelData.type === 'num' ? "#4a90e2" : "#e2a04a"); radius: 5; border.color: "white"
              Text { anchors.centerIn: parent; text: modelData.value; font.pixelSize: 20; font.bold: true; color: modelData.type === 'slot' ? "#888" : "white" }

              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; preventStealing: true
                onPressed: function(mouse) { 
                  if (modelData.type === 'num') startDrag(this, mouse, {type: modelData.type, value: modelData.value, id: modelData.id}, index); 
                }
                onPositionChanged: function(mouse) { updateDragPos(this, mouse); }
                onReleased: function(mouse) { endDrag(); }
                onCanceled: function() { cancelDrag(); }
                
                onClicked: function(mouse) {
                  if (!isDragging && modelData.type === 'num') setNumberSlot(index, {type: 'slot', value: '?'});
                }
              }
            }
          }

          Text {
            text: "= " + formatResult()
            color: "white"
            font.pixelSize: 20
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: exprRow.verticalCenter
          }
        }
        
        Text {
          visible: expressionList.length === 0; anchors.centerIn: parent
          text: Lua.tr("jingjin_result"); color: "#888"; font.pixelSize: 16
        }
      }
    }

    // 3. 底部操作按钮区
    RowLayout {
      Layout.fillWidth: true; Layout.preferredHeight: 50; spacing: 20
      Item { Layout.fillWidth: true }
      MetroButton { Layout.preferredWidth: 100; text: Lua.tr("un-chained"); onClicked: clearExpression() }
      MetroButton { Layout.preferredWidth: 100; text: Lua.tr("Cancel"); onClicked: { close(); Ltk.roomModel.deActivate(); ClientInstance.replyToServer("", "__cancel"); } }
      MetroButton { Layout.preferredWidth: 100; text: Lua.tr("OK"); enabled: checkWin();
        onClicked: {
          close();
          Ltk.roomModel.deActivate();
          ClientInstance.notifyServer("PushRequest", "updatemini,closeFrame");
          let ret = ""
          for (let i = 0; i < expressionList.length; i++) {
            ret += expressionList[i].value;
          }
          ClientInstance.replyToServer("", ret);
        }
      }
      Item { Layout.fillWidth: true }
    }
  }

  // ================= 拖拽核心控制逻辑 =================

  function startDrag(mouseArea, mouse, data, sourceIndex) {
    isDragging = true;
    dragData = data;
    dragSourceIndex = sourceIndex;

    var absPos = mouseArea.mapToItem(root, mouse.x, mouse.y);
    ghostCard.x = absPos.x - ghostCard.width / 2;
    ghostCard.y = absPos.y - ghostCard.height / 2;
    
    ghostCard.cardType = data.type;
    ghostCard.cardValue = data.value;
    ghostCard.visible = true;
  }

  function updateDragPos(mouseArea, mouse) {
    if (!isDragging) return;
    var absPos = mouseArea.mapToItem(root, mouse.x, mouse.y);
    ghostCard.x = absPos.x - ghostCard.width / 2;
    ghostCard.y = absPos.y - ghostCard.height / 2;

    var centerX = ghostCard.x + ghostCard.width / 2;
    var centerY = ghostCard.y + ghostCard.height / 2;
    var dropPos = dropZone.mapToItem(root, 0, 0);
    
    isHoveringDropZone = (centerX >= dropPos.x && centerX <= dropPos.x + dropZone.width &&
                          centerY >= dropPos.y && centerY <= dropPos.y + dropZone.height);
  }

  function endDrag() {
    if (!isDragging) return;

    var centerX = ghostCard.x + ghostCard.width / 2;
    var centerY = ghostCard.y + ghostCard.height / 2;
    var dropPos = dropZone.mapToItem(root, 0, 0);
    
    var inDrop = (centerX >= dropPos.x && centerX <= dropPos.x + dropZone.width && 
                  centerY >= dropPos.y && centerY <= dropPos.y + dropZone.height);

    if (inDrop && dragData.type === 'num') {
      var rowPos = exprRow.mapToItem(root, 0, 0);
      var relativeX = centerX - rowPos.x;
      var slotNumber = Math.max(0, Math.min(3, Math.round((relativeX - 25) / 106)));
      var targetIndex = slotNumber * 2;
      if (dragSourceIndex === -1) {
        setNumberSlot(targetIndex, dragData);
      } else if (targetIndex !== dragSourceIndex) {
        var targetItem = expressionList[targetIndex];
        setNumberSlot(targetIndex, dragData);
        setNumberSlot(dragSourceIndex, targetItem.type === 'num' ? targetItem : {type: 'slot', value: '?'});
      }
    } else {
      if (dragSourceIndex !== -1) {
        setNumberSlot(dragSourceIndex, {type: 'slot', value: '?'});
      }
    }

    cancelDrag();
  }

  function cancelDrag() {
    isDragging = false;
    dragData = null;
    dragSourceIndex = -1;
    isHoveringDropZone = false;
    ghostCard.visible = false;
  }

  // ================= 全局幽灵卡片 =================
  
  Rectangle {
    id: ghostCard
    z: 999
    width: 50; height: 40; visible: false; radius: 5
    border.color: "white"; border.width: 2
    color: cardType === "num" ? "#4a90e2" : "#e2a04a"
    opacity: 0.9 
    
    property string cardType: ""
    property var cardValue: ""

    Text {
      anchors.centerIn: parent
      text: parent.cardValue
      font.pixelSize: 20; font.bold: true; color: "white"
    }
    
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton }
  }

  // ================= 接口函数 =================

  function loadData(data) {
    if (data && data.numbers) {
      initialNumbers = data.numbers.map(function(val, idx) { return { id: idx, value: val }; });
      operatorSequence = data.operators;
      clearExpression();
    }
  }

  function updateData(data) {
    if (data === "closeFrame") { close(); Ltk.roomModel.deActivate(); ClientInstance.replyToServer("", "__cancel"); }
  }
}
