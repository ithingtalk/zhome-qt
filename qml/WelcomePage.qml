import QtQuick
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Welcome")

    Text {
        id: idTextSkip
        text: qsTr("Skip")
        color: Global.iconColor
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        font.pixelSize: Global.fontSize
        MouseArea {
            anchors.fill: parent
            onClicked: {
                idRoot.gotoNextPage()
            }
        }
    }

    Image {
        id: idImage
        width: 200
        height: 200
        anchors.centerIn: parent
        source: "../icons/logo.png"
        fillMode: Image.PreserveAspectFit
    }

    Text {
        text: "Zhome " + ( Global.utilsCpp?.appVer() ?? "" )
        font.pixelSize: Global.fontSize
        color: palette.text
        anchors.top: idImage.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Timer {
        id: countdownTimer
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 1000
        property int timerCount: 10
        onTriggered: {
            timerCount -= 1
            idTextSkip.text = qsTr("Skip") + " ( " + timerCount.toString() + " )"
            if (timerCount <= 0) {
                idRoot.gotoNextPage()
            }
        }
    }

    function gotoNextPage() {
        countdownTimer.stop()
        // Global.idStack.replace("DevicesPage.qml")
        Global.idStack.replace("AwsLoginPage.qml")
    }
}
