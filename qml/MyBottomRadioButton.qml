import QtQuick
import QtQuick.Controls
import "Global"

RadioButton {
    id: idRoot
    property string btnText: ""
    property color textColor: palette.windowText
    property color bgColor: Global.toolbarBgColor
    property int bgRadius: 0
    property bool gChecked: false
    property int gSize: 36
    property string gIconSrc: ""
    checked: gChecked
    padding: 0

    signal acceptClicked()

    indicator.visible: false

    contentItem: Rectangle {
        id: idContentRect
        color: idRoot.bgColor
        radius: idRoot.bgRadius

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
                display: Button.TextUnderIcon
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
                when: idRoot.checked
                PropertyChanges {
                    idImage.icon.color: Global.differIconColor
                }
            },
            State {
                when: idMouseArea.pressed
                PropertyChanges {
                    idContentRect.color: Global.toolbarBgColor2
                }
            }
        ]
    }
}
