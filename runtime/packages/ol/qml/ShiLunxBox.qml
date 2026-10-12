import QtQuick
import QtQuick.Layouts
import Fk
import Fk.Components.Common
import LunarLtk
import LunarLtk.Pages.Popups

GraphicsBox {
    id: root

    property var targetWords: []
    property string charPool: ""
    
    property int gridSize: 6
    property var gridData: []
    property var selectedCells: []
    property var foundWords: []
    property bool isDragging: false
    property int timeLimit: 60000

    title.text: Lua.tr("#shilunx-ask")
    width: 600
    height: 600

    signal gameFinished(var foundWordsList)

    function initGame() {
        foundWords = []
        selectedCells = []
        isDragging = false
        
        var newData = []
        for (var i = 0; i < gridSize * gridSize; i++) {
            newData.push({ char: "", found: false, isTarget: false, targetId: -1 })
        }

        var maxAttempts = 200
        for (var w = 0; w < targetWords.length; w++) {
            var word = targetWords[w]
            var success = false
            
            for (var attempt = 0; attempt < maxAttempts; attempt++) {
                var dir = Math.random() < 0.5 ? 'H' : 'V' 
                var maxR = dir === 'H' ? gridSize : gridSize - word.length
                var maxC = dir === 'H' ? gridSize - word.length : gridSize
                
                var r = Math.floor(Math.random() * maxR)
                var c = Math.floor(Math.random() * maxC)
                
                var conflict = false
                for (var i = 0; i < word.length; i++) {
                    var idx = (dir === 'H' ? r : r + i) * gridSize + (dir === 'H' ? c + i : c)
                    if (newData[idx].char !== "" && newData[idx].char !== word[i]) {
                        conflict = true
                        break
                    }
                }
                
                if (!conflict) {
                    for (var i = 0; i < word.length; i++) {
                        var idx = (dir === 'H' ? r : r + i) * gridSize + (dir === 'H' ? c + i : c)
                        newData[idx] = { char: word[i], found: false, isTarget: true, targetId: w }
                    }
                    success = true
                    break
                }
            }
            if (!success) return initGame()
        }

        var poolLen = charPool.length
        for (var i = 0; i < gridSize * gridSize; i++) {
            if (newData[i].char === "") {
                newData[i] = { char: charPool[Math.floor(Math.random() * poolLen)], found: false, isTarget: false, targetId: -1 }
            }
        }
        
        gridData = []
        gridData = newData
        timeoutTimer.restart()
    }

    function getIndexFromPos(x, y) {
        var localX = x - gridContainer.x
        var localY = y - gridContainer.y
        
        if (localX < 0 || localY < 0 || localX >= gridContainer.width || localY >= gridContainer.height) return -1

        var totalSpacing = (gridSize - 1) * gridContainer.spacing
        var cellWidth = (gridContainer.width - totalSpacing) / gridSize
        var cellHeight = (gridContainer.height - totalSpacing) / gridSize
        
        var col = Math.floor(localX / (cellWidth + gridContainer.spacing))
        var row = Math.floor(localY / (cellHeight + gridContainer.spacing))
        
        var cellStartX = col * (cellWidth + gridContainer.spacing)
        var cellStartY = row * (cellHeight + gridContainer.spacing)
        
        if (localX - cellStartX > cellWidth || localY - cellStartY > cellHeight) return -1

        return row * gridSize + col
    }

    function isAdjacent(idx1, idx2) {
        var r1 = Math.floor(idx1 / gridSize), c1 = idx1 % gridSize
        var r2 = Math.floor(idx2 / gridSize), c2 = idx2 % gridSize
        return (Math.abs(r1 - r2) + Math.abs(c1 - c2)) === 1
    }

    function getWordFromIndices(indices) {
        var word = ""
        for (var i = 0; i < indices.length; i++) {
            if (gridData[indices[i]]) word += gridData[indices[i]].char
        }
        return word
    }

    function validateAndLockSelection() {
        var word = getWordFromIndices(selectedCells)
        var targetIdx = targetWords.indexOf(word)
        
        if (targetIdx !== -1 && foundWords.indexOf(word) === -1) {
            var newData = gridData.slice()
            for (var i = 0; i < selectedCells.length; i++) {
                var idx = selectedCells[i]
                newData[idx] = { char: gridData[idx].char, found: true, isTarget: true, targetId: targetIdx }
            }
            gridData = newData
            foundWords = foundWords.concat([word])
            
            if (foundWords.length === targetWords.length) {
                timeoutTimer.stop()
                gameFinished(foundWords)
            }
        }
        selectedCells = []
        isDragging = false
    }

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            var idx = getIndexFromPos(mouse.x, mouse.y)
            if (idx !== -1 && gridData[idx] && !gridData[idx].found) {
                isDragging = true
                selectedCells = [idx]
            }
        }
        onPositionChanged: function(mouse) {
            if (!isDragging) return
            var currentIdx = getIndexFromPos(mouse.x, mouse.y)
            if (currentIdx === -1) return
            
            var lastIdx = selectedCells[selectedCells.length - 1]
            if (selectedCells.length > 1 && currentIdx === selectedCells[selectedCells.length - 2]) {
                selectedCells = selectedCells.slice(0, -1)
                return
            }
            if (isAdjacent(lastIdx, currentIdx) && selectedCells.indexOf(currentIdx) === -1 && gridData[currentIdx] && !gridData[currentIdx].found) {
                selectedCells = selectedCells.concat([currentIdx])
            }
        }
        onReleased: function() {
            if (isDragging) validateAndLockSelection()
        }
        onCanceled: function() {
            if (isDragging) {
                selectedCells = []
                isDragging = false
            }
        }
    }

    Grid {
        id: gridContainer
        anchors.centerIn: parent
        width: (Math.min(parent.width, parent.height) - 40) * 2 / 3
        height: width
        columns: gridSize
        rows: gridSize
        spacing: 8 / 3

        Repeater {
            model: gridData
            delegate: Rectangle {
                id: cellRect
                width: (gridContainer.width - (gridSize - 1) * gridContainer.spacing) / gridSize
                height: width
                radius: 4
                
                property int cellIndex: index
                property var cellData: modelData

                color: {
                    if (cellData && cellData.found) return "#2d4a2d"
                    if (selectedCells.indexOf(cellIndex) !== -1) return "#4a90e2"
                    return "#2a2a2a"
                }
                border.color: {
                    if (cellData && cellData.found) return "#4caf50"
                    if (selectedCells.indexOf(cellIndex) !== -1) return "#ffffff"
                    return "#555555"
                }
                border.width: (cellData && cellData.found) ? 3 : 1

                Text {
                    anchors.centerIn: parent
                    text: cellData ? cellData.char : ""
                    font.pixelSize: parent.width * 0.45
                    font.bold: cellData ? cellData.found : false
                    color: (cellData && cellData.found) ? "#4caf50" : "white"
                    
                    opacity: selectedCells.indexOf(cellIndex) !== -1 ? 0.7 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    Timer {
        id: timeoutTimer
        interval: root.timeLimit
        repeat: false
        onTriggered: { gameFinished(foundWords) }
    }

    onGameFinished: { reportResult() }

    function loadData(data) {
        targetWords = data.words
        charPool = data.charPool
        initGame()
    }

    function updateData(data) {
        if (data === "closeFrame") {
            timeoutTimer.stop()
            close()
            Ltk.roomModel.deActivate()
            ClientInstance.replyToServer("", "__cancel")
        }
    }

    function reportResult() {
        close()
        Ltk.roomModel.deActivate()
        ClientInstance.notifyServer("PushRequest", "updatemini,closeFrame")
        var resultStr = foundWords.join(",")
        ClientInstance.replyToServer("", resultStr)
    }
}