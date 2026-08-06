import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Dialog {
    id: idRoot
    width:  dialogWidth - 40
    height: implicitHeight + 20
    parent: Overlay.overlay
    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2
    padding: 0
    property int dialogWidth: Math.min(Global.idWindow.width, Global.minWindowWidth)

    property string gTitle: ""
    property string gInitTextValue: ""
    property string gStrMsg: ""
    property bool hasCancelButton: true
    property bool hasInputTextEdit: false

    property string confirmButtonText: qsTr("OK")
    property color confirmButtonColor: Global.iconColor

    signal acceptClicked()
    signal acceptClickedWithResult(string strRet)

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
            text: idRoot.gTitle
            color: palette.text
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 30
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Global.fontSize
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 0
            Layout.bottomMargin: 20
            Layout.maximumHeight: 200
            visible: !idRoot.hasInputTextEdit

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentHeight: idMsg.implicitHeight
            contentWidth: availableWidth

            background: Rectangle {
                color: Global.bgColor2
            }

            Text {
                id: idMsg
                text: idRoot.gStrMsg
                wrapMode: Text.WrapAnywhere
                padding: 8
                color: palette.text
                font.pixelSize: Global.fontSize
            }
        }

        TextField {
            id: idText
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 0
            Layout.bottomMargin: 20
            visible: idRoot.hasInputTextEdit
            placeholderText: idRoot.gStrMsg
            text: idRoot.gInitTextValue
            padding: 8
            font.pixelSize: Global.fontSize
        }

        RoundButton {
            id: idOk
            Layout.fillWidth: true
            Layout.leftMargin: parent.width / 5
            Layout.rightMargin: parent.width / 5
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            background: Rectangle {
                anchors.fill: parent
                color: idRoot.confirmButtonColor
                radius: 5
            }
            contentItem: Text {
                text: idRoot.confirmButtonText
                color: palette.text
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Global.fontSize
            }
            padding: 2
            radius: 5
            onClicked: {
                if (idRoot.hasInputTextEdit) {
                    idRoot.acceptClickedWithResult(idText.text)
                  }
                  else {
                    idRoot.acceptClicked()
                  }
                  idRoot.close()
            }
        }

        RoundButton {
            id: idCancle
            visible: idRoot.hasCancelButton
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
    }
}
