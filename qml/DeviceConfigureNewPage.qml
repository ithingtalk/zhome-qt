import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Configure new devices")

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 20

        Text {
            Layout.fillWidth: true
            text: idRoot.title + ": " + Global.currDevice.ip
            color: palette.text
            font.pixelSize: Global.fontSize
        }

        TextField {
            id: textDeviceName
            Layout.fillWidth: true
            text: Global.currDevice.name
            placeholderText: qsTr("Device name")
            padding: 10
            font.pixelSize: Global.fontSize
        }

        TextField {
            id: textAdminPassword
            Layout.fillWidth: true
            echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("Administrator's  Password")
            padding: 10
            font.pixelSize: Global.fontSize
        }

        Button {
            id: buttonLogin
            Layout.fillWidth: true
            text: qsTr("Configure")
            onClicked: {
                idConfirm.open()
            }
        }
    }

    ConfirmDialog {
        id: idConfirm
        gTitle: "Configure device"
        gStrMsg: qsTr("Administrator's password:") + " " + textAdminPassword.text.toString()
                 + "\n" + qsTr("Device name:") + " " + textDeviceName.text.toString()
                 + "\n" + qsTr("Username:") + " " + Global.localAccountCpp.getUser()
                 + "\n" + qsTr("Password:") + " " + Global.localAccountCpp.getPass()
        onAcceptClicked: {
            console.log(gStrMsg)
            idRoot.sendConfigureCmd()
            idBusy.running = true
        }
    }

    ConfirmDialog {
        id: idError
        gTitle: "Error"
        hasCancelButton: false
        onAcceptClicked: {
            console.log("gStrMsg")
        }
    }

    CmdService { // configure new device use local link 
        id: idCmd
        onDataReceived: function(strCmd, strResult) {
            console.log("===> ConfigureNewDevicePage.qml: Configure return = " + strResult)
            idBusy.running = false
            if (Global.nasApiCpp.configureNewDeviceSuccess(strResult)) {
                idRoot.updateCurrentDevice()
            }
            else {
                idError.gStrMsg = qsTr("Configure failure, please try later.")
                idError.open()
            }
        }
        onErrorOccurred: function(errString, errCode) {
            console.log("===> " + errString + errCode)
            idBusy.running = false
            idError.gStrMsg = errString
            idError.open()
        }
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 80
        height: 80
        running: false
    }

    function updateCurrentDevice() {
        Global.currDevice.name = textDeviceName.text.toString()
        Global.dbDevicesCpp.add(Global.currDevice.mac,
                                Global.currDevice.sn,
                                Global.currDevice.name,
                                Global.currDevice.ip)
        Global.idStack.pop() // pop to DevicesSearchPage.qml
        Global.idStack.pop() // pop to DevicePage.qml
    }

    function sendConfigureCmd() {
        idCmd.send ( Global.nasApiCpp.configureNewDevice (
                       textAdminPassword.text.toString(),
                       textDeviceName.text.toString(),
                       Global.localAccountCpp.getUser(),
                       Global.localAccountCpp.getPass() )
                   )
    }
}
