import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Particles
import "content/samegame.js" as Logic
import "content"
import "../Zhome/qml/Global"
import "../Zhome"

Item {
    id: idRoot
    property int acc: 0

    ZhomeToolbar {
        id: idToolbar
        winTitle: qsTr("Small Game")
        onBackFunc: function () {
            Global.popStackviewPage()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/ionicons/menu.svg"
                itemText: qsTr("Menu")
                actionStr: "actionShowMenu"
                // gVisible: idRoot.state === "in-game"
            }
        }
        onClickFunc: function(actionStr) {
            if (actionStr === "actionShowMenu") {
                    idRoot.state = ""
                    Logic.cleanUp()
                    gameCanvas.mode = ""
            }
        }
    }

    Rectangle {
        id: idScopeBar
        anchors.bottom: parent.bottom
        width: parent.width
        height: (idRoot.state === "in-game") ? Math.max(Global.idWindow.SafeArea.margins.bottom, Settings.headerHeight) : 0
        z: 6
        color: Global.toolbarBgColor
        Behavior on opacity { NumberAnimation {} }
        SamegameText {
            id: arcadeScore
            anchors { right: parent.right; rightMargin: 30 }
            text: gameCanvas.score
            font.pixelSize: Settings.fontPixelSize
            textFormat: Text.StyledText
            color: palette.text
            opacity: gameCanvas.mode == "arcade" ? 1 : 0
            Behavior on opacity { NumberAnimation {} }
            anchors.verticalCenter: parent.verticalCenter
        }
        SamegameText {
            id: arcadeHighScore
            anchors { left: parent.left; leftMargin: 30 }
            text: gameCanvas.highScore
            color: palette.text
            opacity: gameCanvas.mode == "arcade" ? 1 : 0
            anchors.verticalCenter: parent.verticalCenter
        }
        SamegameText {
            id: p1Score
            anchors { right: parent.right; rightMargin: 30 }
            text: gameCanvas.score
            color: palette.text
            opacity: gameCanvas.mode == "multiplayer" ? 1 : 0
            anchors.verticalCenter: parent.verticalCenter
        }
        SamegameText {
            id: p2Score
            anchors { left: parent.left; leftMargin: 30 }
            text: gameCanvas.score2
            color: palette.text
            opacity: gameCanvas.mode == "multiplayer" ? 1 : 0
            rotation: 180
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        anchors.top: idToolbar.bottom
        anchors.bottom: idScopeBar.top
        anchors.margins: 2
        width: parent.width
        color: palette.base

        GameArea {
            id: gameCanvas
            anchors.fill: parent
            z: 1

            onModeChanged: {}
            Age {
                groups: ["redspots", "greenspots", "bluespots", "yellowspots"]
                enabled: idRoot.state === ""
                system: gameCanvas.ps
            }
        }
    }

    Item {
        id: idChooseGameMenuContentWindow
        z: 2
        anchors.top: idToolbar.bottom
        anchors.bottom: parent.bottom
        width: parent.width

        ColumnLayout {
            anchors.fill: parent
            spacing: Settings.menuButtonSpacing

            Item { Layout.fillHeight: true }

            RowLayout {
                Item { Layout.fillWidth: true }
                Image { source: "content/gfx/logo-g.png" }
                Image { source: "content/gfx/logo-a.png" }
                Image { source: "content/gfx/logo-m.png" }
                Image { source: "content/gfx/logo-e.png" }
                Item { Layout.fillWidth: true }
            }

            Button {
                Layout.fillWidth: true
                rotatedButton: true
                imgSrc: Qt.resolvedUrl("content/gfx/but-game-1.png")
                onClicked: {
                    if (idRoot.state === "in-game")
                        return //Prevent double clicking
                    idRoot.state = "in-game"
                    gameCanvas.blockFile = "Block.qml"
                    arcadeTimer.start()
                }
                //Emitted particles don't fade out, because ImageParticle is on the GameArea
                system: gameCanvas.ps
                group: "green"
                Timer {
                    id: arcadeTimer
                    interval: Settings.menuDelay
                    running : false
                    repeat  : false
                    onTriggered: Logic.startNewGame(gameCanvas)
                }
            }

            Button {
                Layout.fillWidth: true
                rotatedButton: true
                imgSrc: Qt.resolvedUrl("content/gfx/but-game-2.png")
                onClicked: {
                    if (idRoot.state === "in-game")
                        return
                    idRoot.state = "in-game"
                    gameCanvas.blockFile = "Block.qml"
                    twopTimer.start()
                }
                system: gameCanvas.ps
                group: "green"
                Timer {
                    id: twopTimer
                    interval: Settings.menuDelay
                    running : false
                    repeat  : false
                    onTriggered: Logic.startNewGame(gameCanvas, "multiplayer")
                }
            }

            Button {
                Layout.fillWidth: true
                rotatedButton: true
                imgSrc: Qt.resolvedUrl("content/gfx/but-game-3.png")
                onClicked: {
                    if (idRoot.state === "in-game")
                        return
                    idRoot.state = "in-game"
                    gameCanvas.blockFile = "SimpleBlock.qml"
                    endlessTimer.start()
                }
                system: gameCanvas.ps
                group: "blue"
                Timer {
                    id: endlessTimer
                    interval: Settings.menuDelay
                    running : false
                    repeat  : false
                    onTriggered: Logic.startNewGame(gameCanvas, "endless")
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    states: [
        State {
            name: "in-game"
            PropertyChanges {
                idChooseGameMenuContentWindow {
                    opacity: 0
                    visible: false
                }
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {properties: "x,y,opacity"}
        }
    ]

    Component.onDestruction: {
        Logic.cleanUp()
    }

    // "Debug mode"
    focus: true
    Keys.onAsteriskPressed: Logic.nuke()
}
