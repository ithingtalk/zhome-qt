import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Login")
    property string infoNormal: qsTr("Input username and password Login to APP and Devices")
    property string infoChangePasswd: qsTr("Change password from old to new")
    property string infoForgetPasswd: qsTr("Forget password, will send a confirm code from device to your email, used to reset password")
    property string infoResetPasswd: qsTr("Reset password by confirm code from your email")
    property int modeNormal: 0 // 0: normal, 1: change password, 2: forget password
    property int modeChangePasswd: 1
    property int modeForgetPasswd: 2
    property int modeResetPasswd: 3 // change to modeResetPasswd when forgetPasswordCmd success
    property int iMode: modeNormal

    states: [
        State {
            when: idRoot.iMode === idRoot.modeChangePasswd
            PropertyChanges {
                idRoot.title: qsTr("Change password")
                idInfo.text: infoChangePasswd
                idPasswordNew.visible: true
                idPasswordNewConfirm.visible: true
                idButtonLogin.text: qsTr("Change Password")
                idButtonLogin.enabled: (idUsername.text !== "") && (idPassword.text !== "") && (idPasswordNew.text !== "") && (idPasswordNew.text === idPasswordNewConfirm.text)
            }
        },
        State {
            when: idRoot.iMode === idRoot.modeForgetPasswd
            PropertyChanges {
                idRoot.title: qsTr("Forget password")
                idInfo.text: infoForgetPasswd
                idPassword.visible: false
                idButtonLogin.text: qsTr("Forget Password")
                idButtonLogin.enabled: idUsername.text !== ""
            }
        },
        State {
            when: idRoot.iMode === idRoot.modeResetPasswd
            PropertyChanges {
                idRoot.title: qsTr("Forget password stage2: reset")
                idInfo.text: infoResetPasswd
                idPassword.visible: false
                idPasswordNew.visible: true
                idPasswordNewConfirm.visible: true
                idConfirmCode.visible: true
                idButtonLogin.text: qsTr("Reset Password")
                idButtonLogin.enabled: (idUsername.text !== "") && (idPasswordNew.text !== "") && (idPasswordNew.text === idPasswordNewConfirm.text) && (idConfirmCode.text !== "")
            }
        }
    ]

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.closeWindow()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Settings")
                actionStr: "actionSettings"
                }
            ListElement {
                iconSrc: "../icons/ionicons/information-circle-outline.svg"
                itemText: qsTr("About")
                actionStr: "actionAbout" }
            ListElement {
                iconSrc: "../icons/ionicons/information-circle-outline.svg"
                itemText: qsTr("About QT")
                actionStr: "actionAboutQT" }
        }
        onClickFunc: function(actionStr) {
            switch (actionStr) {
                case "actionSettings":
                    Global.idStack.push("SettingPage.qml")
                    break;
                case "actionAbout":
                    console.log("TODO: About")
                    break;
                case "actionAboutQT":
                    console.log("TODO: About QT")
                    break;
                default:
                    console.log("Unknown action:", actionStr)
            }
        }
    }

    ColumnLayout {
        anchors.top: idToolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: Global.bottomPad + 8
        spacing: 10

        Text {
            id: idInfo
            text: idRoot.infoNormal
            font.italic: true
            color: palette.text
            font.pixelSize: Global.fontSizeSmall3
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.fillWidth: true
            Layout.margins: {
                top: 20
                bottom: 20
                left: 10
                right: 10
            }
        }

        Item { Layout.fillHeight: true }

        Image {
            Layout.fillWidth: false
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            source: "../icons/logo.png"
            fillMode: Image.PreserveAspectFit
        }

        TextField {
            id: idUsername
            Layout.fillWidth: true
            text: Global.localAccountCpp ? Global.localAccountCpp.getUser() : ""
            placeholderText: qsTr("Username (email address)")
            padding: 8
        }

        TextField {
            id: idPassword
            Layout.fillWidth: true
            echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("Password")
            padding: 8
        }

        TextField {
            id: idPasswordNew
            visible: false
            Layout.fillWidth: true
            echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("New Password")
            padding: 8
        }

        TextField {
            id: idPasswordNewConfirm
            visible: false
            Layout.fillWidth: true
            echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("New Password again")
            padding: 8
        }

        TextField {
            id: idConfirmCode
            visible: false
            Layout.fillWidth: true
            echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("Confirm Code from email")
            padding: 8
        }

        Button {
            id: idButtonLogin
            Layout.fillWidth: true
            enabled: (idUsername.text !== "") && (idPassword.text !== "")
            text: qsTr("Login")
            padding: 8
            onClicked: {
                if (idRoot.iMode === idRoot.modeNormal) {
                    // Login
                    if ( (idUsername.text.toString() === Global.localAccountCpp.getUser()) &&
                            (idPassword.text.toString() === Global.localAccountCpp.getPass()) ) {
                        idRoot.loginSuccess()
                    }
                    else {
                        idDialogNewAccountLogin.open()
                    }
                }
                else if (idRoot.iMode === idRoot.modeChangePasswd) {
                    idDialogChangePasswd.open()
                }
                else if (idRoot.iMode === idRoot.modeForgetPasswd) {
                    idDialogForgetPasswd.open()
                }
                else if (idRoot.iMode === idRoot.modeResetPasswd) {
                    idDialogResetPasswd.open()
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8

            Text {
                text: qsTr("Login")
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeNormal
                    }
                }
            }

            Text {
                text: qsTr("Change password")
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeChangePasswd
                    }
                }
            }

            Text {
                text: qsTr("Forget password")
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeForgetPasswd
                    }
                }
            }
        }
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 120
        height: 120
        running: false
    }

    ConfirmDialog {
        id: idDialogNewAccountLogin
        gTitle: qsTr("Login")
        gStrMsg: qsTr("Username") + ": " + idUsername.text.toString()
                 + "\n" + qsTr("Password") + ": " + idPassword.text.toString()
        onAcceptClicked: {
            console.log("Accept button clicked in Confirm_Dialog")
            idRoot.newLogin()
        }
    }

    ConfirmDialog {
        id: idDialogChangePasswd
        gTitle: qsTr("Change Password")
        gStrMsg: qsTr("Username") + ": " + idUsername.text.toString()
                + "\n" + qsTr("Password") + ": " + idPassword.text.toString()
                + "\n" + qsTr("New Password") + ": " + idPasswordNew.text.toString()
        onAcceptClicked: {
            Global.localAccountCpp.setUser(idUsername.text.toString())
            Global.localAccountCpp.setPass(idPassword.text.toString())
            Global.cmdServiceLoginCpp.send(Global.nasApiCpp.userChangePasswd(idPasswordNew.text.toString()))
            idBusy.running = true
        }
    }

    ConfirmDialog {
        id: idDialogForgetPasswd
        gTitle: qsTr("Forget and Reset password for user")
        gStrMsg: qsTr("Username") + ": " + idUsername.text.toString()
        onAcceptClicked: {
            Global.localAccountCpp.setUser(idUsername.text.toString())
            Global.localAccountCpp.setPass(idPassword.text.toString())
            Global.cmdServiceLoginCpp.send(Global.nasApiCpp.userForgetPasswd())
            idBusy.running = true
        }
    }

    ConfirmDialog {
        id: idDialogResetPasswd
        gTitle: qsTr("Reset password")
        gStrMsg: qsTr("Username") + ": " + idUsername.text.toString()
                + "\n" + qsTr("New Password") + ": " + idPasswordNew.text.toString()
                + "\n" + qsTr("Confirm Code") + ": " + idConfirmCode.text.toString()
        onAcceptClicked: {
            Global.localAccountCpp.setUser(idUsername.text.toString())
            Global.localAccountCpp.setPass(idPassword.text.toString())
            Global.cmdServiceLoginCpp.send(Global.nasApiCpp.userResetPasswd(idPasswordNew.text.toString(), idConfirmCode.text.toString()))
            idBusy.running = true
        }
    }

    function loginSuccess()
    {
        Global.dbDevicesCpp.reset()
        Global.dbFileTransferCpp.reset()
        Zpath.dbFilesPrivateCpp.reset()
        Zpath.dbFilesSharedCpp.reset()
        Global.idStack.replace("DevicesPage.qml")
    }

    function newLogin()
    {
        Global.localAccountCpp.setUser(idUsername.text.toString())
        Global.localAccountCpp.setPass(idPassword.text.toString())
        loginSuccess()
    }

    Connections {
        target: Global.cmdServiceLoginCpp
        function onDataReceived(strCmd, strResult) {
            idBusy.running = false
            console.log("LoginPage.qml: " + strResult)
            if (idRoot.iMode === idRoot.modeChangePasswd) {
                if (Global.nasApiCpp.userChangePasswdSuccess(strResult)) {
                    idRoot.iMode = idRoot.modeNormal
                    idPassword.text = ""
                    idDialogResult.gTitle = qsTr("Success")
                    idDialogResult.gStrMsg = qsTr("Change password success")
                    idDialogResult.open()
                }
                else if (Global.nasApiCpp.userLoginFail(strResult)) {
                    idDialogResult.gTitle = qsTr("Error")
                    idDialogResult.gStrMsg = qsTr("Wrong password")
                    idDialogResult.open()
                }
                else {
                    idDialogResult.gTitle = qsTr("Error")
                    idDialogResult.gStrMsg = qsTr("Change password error")
                    idDialogResult.open()
                }
            }
            else if (idRoot.iMode === idRoot.modeForgetPasswd) {
                if (Global.nasApiCpp.userForgetPasswdSuccess(strResult)) {
                    idRoot.iMode = idRoot.modeResetPasswd
                    idConfirmCode.text = ""
                    idPasswordNew.text = ""
                    idPasswordNewConfirm.text = ""
                    idDialogResult.gTitle = qsTr("Success")
                    idDialogResult.gStrMsg = qsTr("Success, next step: reset password")
                    idDialogResult.open()
                }
                else {
                    idDialogResult.gStrMsg = qsTr("Forget password error")
                    idDialogResult.open()
                }
            }
            else if (idRoot.iMode === idRoot.modeResetPasswd) {
                if (Global.nasApiCpp.userResetPasswdSuccess(strResult)) {
                    idRoot.iMode = idRoot.modeNormal
                    idPassword.text = ""
                    idDialogResult.gTitle = qsTr("Success")
                    idDialogResult.gStrMsg = qsTr("Reset password success")
                    idDialogResult.open()
                }
                else {
                    idDialogResult.gStrMsg = qsTr("Reset password error")
                    idDialogResult.open()
                }
            }
        }
        function onErrorOccurred(errString, errCode) {
            idBusy.running = false
            idDialogResult.gTitle = qsTr("Error")
            idDialogResult.gStrMsg = qsTr("Network error") + ":\n\n" + errString + " " + errCode
            idDialogResult.open()
        }
    }

    ConfirmDialog {
        id: idDialogResult
        hasCancelButton: false
        onAcceptClicked: {}
    }
}
