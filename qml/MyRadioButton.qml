pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "Global"

RadioButton {
    id: idRoot
    property string btnText: ""
    property color textColor: palette.text
    property color bgColor: Global.bgColor2
    property bool bLeftButton: false
    property bool bRightButton: false
    property bool bTopLeftButton: false
    property bool bTopRightButton: false
    property bool bBottomLeftButton: false
    property bool bBottomRightButton: false

    property bool gChecked: false
    checked: gChecked

    signal acceptClicked()

    indicator.visible: false

    contentItem: Rectangle {
        id: idBg
        color: idRoot.bgColor
        property int bgRadius: 2
        topLeftRadius: idRoot.bLeftButton || idRoot.bTopLeftButton ? bgRadius : 0
        bottomLeftRadius: idRoot.bLeftButton || idRoot.bBottomLeftButton ? bgRadius : 0
        topRightRadius: idRoot.bRightButton || idRoot.bTopRightButton ? bgRadius : 0
        bottomRightRadius: idRoot.bRightButton || idRoot.bBottomRightButton ? bgRadius : 0

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Row {
            anchors.centerIn: parent
            Button {
                id: idImage
                icon.source: "../icons/ionicons/checkmark-circle-outline.svg"
                icon.width: 12
                icon.height: 12
                icon.color: idBg.color
                display: Button.IconOnly
                background: null
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: idText
                text: idRoot.btnText
                font.pixelSize: Global.fontSize
                color: idRoot.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: idMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                idRoot.checked = true
                idRoot.acceptClicked()
            }
        }

        states: [
            State {
                when: idMouseArea.pressed
                PropertyChanges {
                    idBg.color: Qt.darker(idRoot.bgColor, 1.2)
                }
            },
            State {
                when: idRoot.checked
                PropertyChanges {
                    //idBg.color: Global.bgColor2
                    //idText.font.bold: true
                    idImage.icon.color: palette.text
                }
            }
        ]
    }
}
