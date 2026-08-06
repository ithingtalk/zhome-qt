import QtQuick
import QtQuick.Controls
import "Global"

Rectangle {
    id: idRoot
    color: Global.toolbarBgColor

    property string btnText: ""
    property string gIconSrc: ""
    property color textColor: palette.text
    property int gSize: 30

    signal acceptClicked()

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Column {
        anchors.centerIn: parent
        Button {
            id: idImage
            icon.height: idRoot.gSize
            icon.width: idRoot.gSize
            icon.source: idRoot.gIconSrc
            icon.color: Global.iconColor
            display: Button.IconOnly
            background: null
            padding: 0
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: idRoot.btnText
            font.pixelSize: Global.fontSizeFooter
            color: palette.text
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: idMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            idRoot.acceptClicked()
        }
    }

    states: [
        State {
            when: idMouseArea.pressed
            PropertyChanges {
                idRoot.color: Global.toolbarBgColor2
            }
        }
    ]
}
