import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "Global"
import "global.js" as Logic

Item {
    id: idPlayPage
    property string title: Logic.getFileName(gTrackName)
    property bool mouseInToolbar: false
    property var gVideoUrls
    property int gRepeatMode: 2

    property bool gbPlaying: false
    property int gDuration: 0
    property int gPosition: 0
    property string gTrackName: ""

    ZhomeToolbar {
        id: idToolbar
        winTitle: idPlayPage.title
        z: 2
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    ColumnLayout {
        // visible: Zpath.selectedDocAudio
        anchors.centerIn: parent
        width: parent.width
        spacing: 16

        Text {
            text: title
            visible: Global.isDesktop
            color: Global.iconColor
            font.pixelSize: Global.fontSize
            Layout.alignment: Qt.AlignHCenter
        }

        Image {
            id: record
            source: "../icons/changpian.png"
            Layout.preferredHeight: 360
            Layout.preferredWidth: 360
            Layout.alignment: Qt.AlignHCenter

            RotationAnimation on rotation {
                id: rotateAnimation
                from: 0
                to: 360
                duration: 36000 // one circle
                loops: Animation.Infinite // endless loop
                running: gbPlaying
            }
        }
    }

    ToolBar {
        id: toolBarId
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Global.bottomPad
        height: idPlayToolbar.implicitHeight
        z: 2

        background: Rectangle {
            color: "transparent"
        }

        ColumnLayout {
            id: idPlayToolbar
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                spacing: 4

                Text {
                    Layout.minimumWidth: idEndTime.implicitWidth + 2
                    Layout.maximumWidth: idEndTime.implicitWidth + 2
                    color: Global.iconColor
                    font.bold: true
                    font.pixelSize: Global.fontSize
                    text: Logic.getHumanTime(gPosition)
                }

                Item { Layout.fillWidth: true }

                ToolButton {
                    // 0:no, 1:repeat one, 2: repeat all
                    icon.height: 48
                    icon.width: 48
                    implicitWidth: 48
                    implicitHeight: 48
                    icon.source: gRepeatMode === 1 ? "../icons/repeatOne.svg" : (gRepeatMode === 2 ? "../icons/repeatAll.svg" : "../icons/ionicons/repeat.svg")
                    icon.color: gRepeatMode === 0 ? "grey" : Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            gRepeatMode++
                            if (gRepeatMode > 2) {
                                gRepeatMode = 0
                            }
                            idAudioService.setRepeatMode(gRepeatMode)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: idEndTime
                    color: Global.iconColor
                    font.bold: true
                    font.pixelSize: Global.fontSize
                    text: Logic.getHumanTime(gDuration)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 0
                Slider {
                    id: idSeekSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    from: 0
                    to: gDuration
                    stepSize: 1

                    ToolTip {
                        parent: idSeekSlider.handle
                        visible: idSeekSlider.pressed
                        text: Logic.getHumanTime(idSeekSlider.value.toFixed(1))
                    }
                    
                    Binding {
                        id: positionBinding
                        target: idSeekSlider
                        property: "value"
                        value: gPosition
                        when: !idSeekSlider.pressed
                    }

                    onPressedChanged: {
                        if (!pressed) {
                            idAudioService.setPosition(position * gDuration)
                        }
                    }

                    background: Rectangle {
                            x: idSeekSlider.leftPadding
                            y: idSeekSlider.topPadding + idSeekSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: idSeekSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#bdbebf"

                            Rectangle {
                                width: idSeekSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#21be2b"
                                radius: 2
                            }
                        }

                    handle: Rectangle {
                        x: idSeekSlider.leftPadding + idSeekSlider.visualPosition * (idSeekSlider.availableWidth - width)
                        y: idSeekSlider.topPadding + idSeekSlider.availableHeight / 2 - height / 2
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: idSeekSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: "#bdbebf"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                spacing: 4

                Item { Layout.fillWidth: true }

                ToolButton {
                    icon.height: 48
                    icon.width: 48
                    implicitWidth: 48
                    implicitHeight: 48
                    icon.source: "../icons/ionicons/play-skip-back.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    //visible: gVideoUrls !== undefined
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idAudioService.prev() }
                    }
                }

                ToolButton {
                    icon.height: 56
                    icon.width: 56
                    implicitWidth: 56
                    implicitHeight: 56
                    icon.source: gbPlaying ? "../icons/ionicons/pause.svg" : "../icons/ionicons/play.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            gbPlaying = !gbPlaying
                            idAudioService.play()
                        }
                    }
                }

                ToolButton {
                    icon.height: 48
                    icon.width: 48
                    implicitWidth: 48
                    implicitHeight: 48
                    icon.source: "../icons/ionicons/play-skip-forward.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    //visible: gVideoUrls !== undefined
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idAudioService.next() }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    Keys.onSpacePressed: {
        console.log("Space key pressed")
        idAudioService.play()
    }

    Timer {
        id: idTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            var sItem = idAudioService.allStatus()
            gTrackName = sItem["trackName"]
            gbPlaying = sItem["isPlaying"]
            gDuration = sItem["timeTotal"]
            gPosition = sItem["timeNow"]
        }
    }

    AudioService {
        id: idAudioService
    }

    Component.onCompleted: {
        idAudioService.configure(true)
        var urls = []
        for (var i = 0; i < gVideoUrls.length; i++) {
            urls.push(Global.nasApiCpp.getPlayerUrl(gVideoUrls[i]))
        }
        idAudioService.load(urls)
        idTimer.start()
    }
}
