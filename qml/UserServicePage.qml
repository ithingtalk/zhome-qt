import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property bool loginSuccess: false

    ZhomeToolbar {
        id: idToolbar
        winTitle: Global.currDevice.name
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 120
        height: 120
        running: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: idToolbar.height
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 10
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.topMargin: 40
            color: palette.base
            radius: 5

            Text {
                text: qsTr("IP Address")
                font.pixelSize: Global.fontSize
                color: palette.text
                padding: 10
            }

            Text {
                id: idIp
                text: ""
                font.pixelSize: Global.fontSize
                color: palette.text
                padding: 10
                anchors.right: parent.right
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.topMargin: 1
            color: palette.base
            radius: 5

            Text {
                text: qsTr("Version")
                font.pixelSize: Global.fontSize
                color: palette.text
                padding: 10
            }

            Text {
                id: idVersion
                text: ""
                font.pixelSize: Global.fontSize
                color: palette.text
                padding: 10
                anchors.right: parent.right
                MouseArea {
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        console.log("Already is newest")
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.topMargin: 40
            color: palette.base
            radius: 5

            Text {
                text: qsTr("Samba service")
                font.pixelSize: Global.fontSize
                color: palette.text
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
            }

            Switch {
                id: idSmbEnabled
                checked: false
                display: AbstractButton.IconOnly
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onCheckedChanged: {
                    idBusy.running = true
                    Logic.sendCmdSetSmb(Global.cmdServiceUserServiceCpp, idSmbEnabled.checked ? "1" : "0", "share123")
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    ConfirmDialog {
        id: idDialogError
        gTitle: qsTr("Error")
        hasCancelButton: false
        onAcceptClicked: {
            Global.popStackviewPage()
        }
    }

    ConfirmDialog {
        id: idDialogNeedAllow
        gTitle: qsTr("Request permission")
        gStrMsg: qsTr("please contanct the device's administrator to allow you connect the device.")
        hasCancelButton: false
        onAcceptClicked: {
            Global.popStackviewPage()
        }
    }

    Connections {
        target: Global.cmdServiceUserServiceCpp
        onDataReceived: function(strCmd, strResult) {
            console.log("UserServicePage.qml: " + strResult)
            idBusy.running = false
            if (idRoot.loginSuccess) {
                var strHddStatus = Global.nasApiCpp.parseGetStatusResult(strResult)
                if (strHddStatus === "hdd_ok") {
                    console.log("hdd ok")
                    try {
                        var jsonObject = JSON.parse(strResult)
                        idVersion.text = jsonObject.fw_version
                        idSmbEnabled.checked = (jsonObject.samba_enabled === "1")
                        idIp.text = jsonObject.ip_addr
                    }
                    catch(e) { console.log("===> " + e) }
                }
                else { console.log("get device status fail.") }
            }
            else {
                if (Global.nasApiCpp.userLoginSuccess(strResult)) {
                    idRoot.loginSuccess = true
                    console.log("user login success, get device status")
                    Logic.sendCmdGetUserStatus(Global.cmdServiceUserServiceCpp)
                }
                else if (Global.nasApiCpp.userLoginFail(strResult)) {
                    idDialogError.open()
                }
                else if (Global.nasApiCpp.userLoginNeedAllow(strResult)) {
                    idDialogNeedAllow.open()
                }
            }
        }
        onErrorOccurred: function(errString, errCode) {
            idDialogError.gStrMsg = errCode !== 204 ? errString : qsTr("Wrong password")
            idDialogError.open()
        }
    }

    Component.onCompleted: {
        Logic.sendCmdUserLogin(Global.cmdServiceUserServiceCpp)
    }
}
