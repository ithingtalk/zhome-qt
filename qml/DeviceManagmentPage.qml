import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property string title: qsTr("Device Managment")
    property string adminPasswd: ""
    property bool loginSuccess: false
    property string gHddStatus: "none"
    property string gHddFormatingProgress: ""
    property int userNum: 0

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.popStackviewPage()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Refresh")
                actionStr: "actionRefresh"
                }
        }
        onClickFunc: function(actionStr) {
            switch (actionStr) {
                case "actionRefresh":
                    idRoot.getAdminDeviceStatus()
                    break
                default:
                    console.log("Unknown action:", actionStr)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: idToolbar.height
        color: palette.base

        ColumnLayout {
            visible: !idRoot.loginSuccess
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: qsTr("Administrator's password:")
                color: palette.text
                Layout.margins: 8
            }

            TextField {
                id: idLoginText
                text: idRoot.adminPasswd
                echoMode: TextInput.PasswordEchoOnEdit
                Layout.fillWidth: true
                Layout.margins: 8
                placeholderText: qsTr("Administrator's password")
                padding: 10
            }

            Button {
                id: idLoginButton
                text: qsTr("Login")
                Layout.fillWidth: true
                Layout.margins: 8
                onClicked: {
                    idDialogConfirmLogin.open()
                }
            }
        }

        ColumnLayout {
            visible: idRoot.loginSuccess && ( idRoot.gHddStatus != "hdd_ok" )
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            TextArea {
                id: idHddStatus
                text: qsTr("HDD status: ") + ( idRoot.gHddFormatingProgress !== "" ? idRoot.formatingInfo() : idRoot.gHddStatus )
                Layout.fillWidth: true
                padding: 10
                Layout.topMargin: 40
                color: "red"
                wrapMode: TextArea.WordWrap
            }

            Button {
                id: idButtonManageHdd
                visible: idRoot.gHddStatus === "hdd_uninit"
                Layout.fillWidth: true
                text: qsTr("Init HDD")
                onClicked: {
                    console.log(text)
                    idConfirmInitHdd.open()
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            visible: idRoot.loginSuccess && ( idRoot.gHddStatus === "hdd_ok" )
            spacing: 8

            TextField {
                id: idDeviceName
                text: Global.currDevice.name
                Layout.fillWidth: true
                placeholderText: qsTr("Device name")
                padding: 10
                Layout.topMargin: 30
            }

            Button {
                id: idButtonChangeDeviceName
                Layout.fillWidth: true
                text: qsTr("Change device name")
                onClicked: {
                    idDialogConfirmChangeDeviceName.open()
                }
            }

            TextField {
                id: idAdminPasswd
                text: idRoot.adminPasswd
                Layout.fillWidth: true
                placeholderText: qsTr("Administrator's password")
                padding: 10
                Layout.topMargin: 30
            }

            Button {
                id: idButtonChangeAdminPasswd
                Layout.fillWidth: true
                text: qsTr("Change administrator's password")
                onClicked: {
                    idDialogConfirmChangeAdminPasswd.open()
                }
            }

            Text {
                text: qsTr("Replace Disk")
                font.pixelSize: Global.fontSize
                Layout.fillWidth: true
                padding: 10
                Layout.topMargin: 20
                color: palette.text
            }
            Text {
                text: qsTr("Copy data to a new disk connected via USB, then install it in the NAS.")
                font.pixelSize: Global.fontSize - 2
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: palette.placeholderText
            }
            Button {
                Layout.fillWidth: true
                text: qsTr("Replace Disk")
                onClicked: {
                    Global.idStack.push("DiskReplaceWizardPage.qml", {adminPasswd: idRoot.adminPasswd})
                }
            }

            Text {
                id: idTextUserList
                text: qsTr("Users: ") + idRoot.userNum
                font.pixelSize: Global.fontSize
                Layout.fillWidth: true
                padding: 10
                Layout.topMargin: 20
                color: palette.text // green,red,yellow for different status
            }

            Button {
                id: idButtonUserList
                Layout.fillWidth: true
                text: qsTr("Manage users")
                onClicked: {
                    console.log("Manage users")
                    Global.idStack.push("DeviceUserPage.qml", {adminPasswd: idRoot.adminPasswd})
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    ConfirmDialog {
        id: idConfirmInitHdd
        gTitle: qsTr("Initialize HDD")
        gStrMsg: qsTr("Format the HDD and all data will lost! please backup if any data exists on HDD!")
        onAcceptClicked: {
            console.log(gStrMsg)
            Logic.sendCmdInitHdd(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd)
        }
    }

    ConfirmDialog {
        id: idDialogConfirmChangeDeviceName
        gTitle: qsTr("Change device name")
        gStrMsg: Global.currDevice.name + "\n\n==> " + idDeviceName.text.toString()
        onAcceptClicked: {
            console.log(gStrMsg)
            Logic.sendCmdChangeDeviceName(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd, idDeviceName.text.toString())
        }
    }

    ConfirmDialog {
        id: idDialogResultSuccess
        gTitle: qsTr("Success")
        hasCancelButton: false
        onAcceptClicked: {
            console.log(gStrMsg)
        }
    }

    ConfirmDialog {
        id: idDialogResultChangePassFail
        gTitle: qsTr("Change admin password error")
        gStrMsg: qsTr("Please check password format")
        hasCancelButton: false
        onAcceptClicked: {
            console.log(gStrMsg)
        }
    }

    ConfirmDialog {
        id: idDialogConfirmChangeAdminPasswd
        gTitle: qsTr("Change admin password")
        gStrMsg: idRoot.adminPasswd + "\n\n==> " + idAdminPasswd.text.toString()
        onAcceptClicked: {
            console.log(gStrMsg)
            Logic.sendCmdChangeAdminPass(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd, idAdminPasswd.text.toString())
        }
    }

    ConfirmDialog {
        id: idDialogConfirmLogin
        gTitle: qsTr("Login with password")
        gStrMsg: idLoginText.text.toString()
        onAcceptClicked: {
            console.log(gStrMsg)
            idRoot.adminPasswd = idLoginText.text.toString()
            Logic.sendCmdLogin(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd)
        }
    }

    ConfirmDialog {
        id: idDialogOnNeedLogin
        gTitle: qsTr("Request Login")
        gStrMsg: qsTr("Please login")
        hasCancelButton: false
        onAcceptClicked: {
            console.log(gStrMsg)
        }
    }

    ConfirmDialog {
        id: idDialogOnError
        gTitle: qsTr("Error")
        gStrMsg: ""
        hasCancelButton: false
        onAcceptClicked: {
            //Global.popStackviewPage()
        }
    }
    
    Timer {
        id: idTimerGetHddFormatingProgress
        repeat: false
        interval: 3000
        onTriggered: {
            idRoot.getAdminDeviceStatus()
        }
    }

    Connections {
        target: Global.cmdServiceDeviceManagmentCpp
        function onDataReceived(strCmd, strResult) {
            console.log("DeviceManagmentPage.qml: " + strResult)
            if (idRoot.loginSuccess) {
                // got user number result
                var userNum = Global.nasApiCpp.parseUserNumFromResult(strResult)
                if (userNum > -1) {
                    idRoot.userNum = userNum
                }
                // got hdd status result
                var hddStatus = Global.nasApiCpp.parseHddStatusFromResult(strResult)
                if (hddStatus !== "") {
                    idRoot.gHddStatus = hddStatus
                    idRoot.gHddFormatingProgress = Global.nasApiCpp.parseHddFormatingProgressFromResult(strResult)
                    if (idRoot.gHddStatus !== "hdd_ok") {
                        idTimerGetHddFormatingProgress.start()
                    }
                }
                // got change device name result
                if (Global.nasApiCpp.parseSaveDeviceNameResult(strResult)) {
                    Global.currDevice.name = idDeviceName.text.toString()
                    Global.dbDevicesCpp.add(Global.currDevice.mac,
                                            Global.currDevice.sn,
                                            Global.currDevice.name,
                                            Global.currDevice.cfg,
                                            Global.currDevice.ip)
                    idDialogResultSuccess.gStrMsg = qsTr("New name") + ": " + Global.currDevice.name
                    idDialogResultSuccess.open()
                }
                // got change admin password result
                if (Global.nasApiCpp.parseChangeAdminPassFail(strResult)) {
                    idDialogResultChangePassFail.open()
                }
                else if (Global.nasApiCpp.parseChangeAdminPassSuccess(strResult)) {
                    idRoot.adminPasswd = idAdminPasswd.text.toString()
                    idDialogResultSuccess.gStrMsg = qsTr("Login success")
                    idDialogResultSuccess.open()
                }
            }
            else {
                idRoot.loginSuccess = Global.nasApiCpp.adminLoginSuccess(strResult)
                if (!idRoot.loginSuccess) {
                    idDialogOnNeedLogin.open()
                }
                else {
                    console.log("login success, getting device status")
                    idRoot.getAdminDeviceStatus()
                }
            }
        }
        function onErrorOccurred(errString, errCode) {
            console.log("===> " + errString + errCode)
            idDialogOnError.gStrMsg = errCode !== 204 ? errString : qsTr("Wrong administrator's password")
            idDialogOnError.open()
        }
    }

    function getAdminDeviceStatus()
    {
        if (idRoot.loginSuccess) {
            Logic.sendCmdGetAdminDeviceStatus(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd)
        }
    }

    function formatingInfo()
    {
        return qsTr("Initializing") +
                "\n\n<" +
                (gHddFormatingProgress === "done" ? qsTr("Applying changes") : gHddFormatingProgress) +
                ">\n\n" +
                qsTr("!!!Please donot do any other operation and waiting for several minutes !!!")
    }

}
