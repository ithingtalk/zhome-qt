import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "Global"

Dialog {
    id: idRoot
    width:  dialogWidth - 40
    height: implicitHeight + 20
    parent: Overlay.overlay
    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2
    padding: 0
    property bool bUrl: true

    signal addUrl(string btUrl)
    signal addFile(string filePath)
    property int dialogWidth: Math.min(Global.idWindow.width, Global.minWindowWidth)

    background: Rectangle {
        anchors.fill: parent
        color: Global.bgColor
        radius: 12
        border.color: Global.bgColor2
        border.width: 3
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: {
            top: 0
            bottom: 0
            left: 12
            right: 12
        }
        spacing: 0

        Text {
            text: qsTr("Add Download Task")
            color: palette.text
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 30
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Global.fontSize
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            Layout.preferredHeight: 30
            color: Global.bgColor2
            MyRadioButton {
                anchors.left: parent.left
                height: parent.height
                width: parent.width / 2
                btnText: qsTr("Add Link")
                gChecked: true
                bTopLeftButton: true
                bBottomRightButton: true
                padding: 0
                bgColor: Global.bgColor3
                onAcceptClicked: {
                    idRoot.bUrl = true
                    idText.text = ""
                }
            }
            MyRadioButton {
                anchors.right: parent.right
                height: parent.height
                width: parent.width / 2
                btnText: qsTr("Add File")
                bTopRightButton: true
                bBottomLeftButton: true
                padding: 0
                bgColor: Global.bgColor3
                onAcceptClicked: {
                    idRoot.bUrl = false
                    idText.text = ""
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 0
            Layout.bottomMargin: 20
            Layout.minimumHeight: 200
            Layout.maximumHeight: 200
            color: Global.bgColor2
            topLeftRadius: 0
            bottomLeftRadius: 5
            topRightRadius: 0
            bottomRightRadius: 5

            TextArea {
                id: idText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                wrapMode: Text.WrapAnywhere
                enabled: false
                padding: 8
                font.pixelSize: Global.fontSize
                background: Rectangle {
                    color: Global.bgColor2
                    radius: 0
                }
            }

            RoundButton {
                id: idSelectFileButton
                visible: idText.text === ""
                anchors.centerIn: parent
                icon.source: "../icons/fontawesome/svgs/solid/paste.svg"
                icon.height: 48
                icon.width: 48
                icon.color: Global.iconColor
                width: 48
                height: 48
                radius: 5
                text: qsTr("Paste Link")
                font.pixelSize: Global.fontSize
                display: Button.IconOnly
                padding: 4
                background: Rectangle {
                    anchors.fill: parent
                    color: Global.bgColor3
                    radius: 8
                }
                onClicked: {
                    idText.paste()
                }
            }
        }

        FileDialog {
            id: idSelectFile
            title: qsTr("Select File")
            fileMode: FileDialog.OpenFile
            onAccepted: {
                idText.text = selectedFile
            }
        }

        RoundButton {
            id: idOk
            Layout.fillWidth: true
            Layout.leftMargin: parent.width / 5
            Layout.rightMargin: parent.width / 5
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            enabled: idText.text !== ""
            background: Rectangle {
                color: Global.iconColor
                radius: 5
            }
            padding: 2
            radius: 5
            contentItem: Text {
                text: qsTr("Add")
                color: palette.text
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Global.fontSize
            }
            onClicked: {
                if (idText.text !== "") {
                    if (idRoot.bUrl) {
                        idRoot.addUrl(idText.text)
                    }
                    else {
                        idRoot.addFile(idText.text)
                    }
                }
                idRoot.close()
            }
        }

        RoundButton {
            id: idCancle
            Layout.fillWidth: true
            Layout.leftMargin: parent.width / 5
            Layout.rightMargin: parent.width / 5
            Layout.topMargin: 0
            Layout.bottomMargin: 20
            background: Rectangle {
                anchors.fill: parent
                color: Global.bgColor
                radius: 5
                border.width: 1
                border.color: Global.bgColor2
            }
            contentItem: Text {
                text: qsTr("Cancel")
                color: palette.text
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Global.fontSize
            }
            padding: 2
            radius: 5
            onClicked: {
                idRoot.close()
            }
        }

        states: [
            State {
                when: !idRoot.bUrl
                PropertyChanges {
                    idSelectFileButton.icon.source: "../icons/fontawesome/svgs/solid/folder-open.svg"
                    idSelectFileButton.text: qsTr("Open File")
                    idSelectFileButton.onClicked: {
                        idSelectFile.open()
                    }
                }
            }
        ]
    }
}
