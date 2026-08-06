import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Sign in")
    property string infoSignin: qsTr("1 Sign In.\n\n2 Forget Password if you forget your password.\n\n3 Sign Up if the Account is not exists.")
    property string infoForgetAndResetPasswd: qsTr("Forget password and reset: \n\n1 Send Confirm Code to your Email.\n\n2 Reset Password by the Confirm Code.")
    property string infoSignup: qsTr("Sign up new Account")
    property string infoConfirmAccount: qsTr("Please Confirm your Account, Confirm Code has been sended to your Email.")
    // iMode default: modeSignin
    property int iMode: modeSignin
    property int modeSignin: 0
    property int modeForgetAndReset: 1
    property int modeSignup: 2              // SignUp Stage1: signUp
    property int modeConfirmAccount: 3      // SignUp Stage2: confirm
    // show item
    property bool bShowConfirmAccount: false
    property bool bShowSignup: true
    property bool bShowForget: true
    property bool bShowSignin: true

    states: [
        State {
            when: idRoot.iMode === idRoot.modeSignin
            PropertyChanges {
                idRoot.title: qsTr("Sign In")
                idInfo.text: infoSignin
                idPassword.visible: true
                idButtonOk.text: qsTr("Sign In")
                idButtonOk.enabled: (idUsername.text !== "") && (idPassword.text !== "")
                idNavSignIn.font.italic: true
            }
        },
        State {
            when: idRoot.iMode === idRoot.modeForgetAndReset
            PropertyChanges {
                idRoot.title: qsTr("Forget Password")
                idInfo.text: infoForgetAndResetPasswd
                idPasswordNew.visible: true
                idConfirm.visible: true
                idButtonOk.text: qsTr("Reset Password")
                idButtonOk.enabled: (idUsername.text !== "") && (idPasswordNew.text !== "") && (idConfirmCode.text !== "")
                idNavForgetAndReset.font.italic: true
            }
        },
        State {
            when: idRoot.iMode === idRoot.modeSignup
            PropertyChanges {
                idRoot.title: qsTr("Sign Up")
                idInfo.text: infoSignup
                idPasswordNew.visible: true
                idButtonOk.text: qsTr("Sign Up")
                idButtonOk.enabled: (idUsername.text !== "") && (idPasswordNew.text !== "")
                idNavSignUp.font.italic: true
            }
        },
        State {
            when: idRoot.iMode === idRoot.modeConfirmAccount
            PropertyChanges {
                idRoot.title: qsTr("Confirm Account")
                idInfo.text: infoConfirmAccount
                idConfirm.visible: true
                idButtonOk.text: qsTr("Confirm")
                idButtonOk.enabled: (idUsername.text !== "") && (idConfirmCode.text !== "")
                idNavConfirmAccount.font.italic: true
            }
        }
    ]

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.closeWindow()
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
        anchors.topMargin: 8
        spacing: 20

        Text {
            id: idInfo
            text: idRoot.infoSignin
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
            // text: Global.localAccountCpp ? Global.localAccountCpp.getUser() : ""
            placeholderText: qsTr("Username (Email Address)")
            padding: 8
        }

        Item {
            id: idConfirm
            visible: false
            Layout.fillWidth: true
            Layout.preferredHeight: idUsername.implicitHeight

            TextField {
                id: idConfirmCode
                // echoMode: TextInput.PasswordEchoOnEdit
                placeholderText: qsTr("Confirm Code from Email")
                padding: 8
                anchors.left: parent.left
                anchors.right: idButtonResendconfirmCode.left
                anchors.rightMargin: 4
                height: parent.height
            }

            Button {
                id: idButtonResendconfirmCode
                anchors.right: parent.right
                height: parent.height
                text: qsTr("Send")
                width: 80
                onClicked: {
                    if (idRoot.iMode === idRoot.modeForgetAndReset) {
                        Global.awsAccountCpp.forgotPassword(idUsername.text.toString());
                    }
                    else if (idRoot.iMode === idRoot.modeConfirmAccount) {
                        Global.awsAccountCpp.resendConfirmationCode(idUsername.text.toString())
                    }
                    idConfirmCode.text = ""
                    idButtonResendconfirmCode.enabled = false
                    idCountdownTimer.start()
                }
            }
        }

        TextField {
            id: idPassword
            visible: false
            Layout.fillWidth: true
            // echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("Password")
            padding: 8
        }

        TextField {
            id: idPasswordNew
            visible: false
            Layout.fillWidth: true
            // echoMode: TextInput.PasswordEchoOnEdit
            placeholderText: qsTr("New Password")
            padding: 8
        }

        Button {
            id: idButtonOk
            Layout.fillWidth: true
            enabled: false
            text: qsTr("Sign In")
            padding: 8
            onClicked: {
                idBusy.running = true
                if (idRoot.iMode === idRoot.modeSignin) {
                    Global.awsAccountCpp.autoSignIn(idUsername.text.toString(), idPassword.text.toString())
                }
                else if (idRoot.iMode === idRoot.modeForgetAndReset) {
                    Global.awsAccountCpp.resetPassword(idUsername.text.toString(), idConfirmCode.text.toString(), idPasswordNew.text.toString());
                }
                else if (idRoot.iMode === idRoot.modeSignup) {
                    Global.awsAccountCpp.signUp(idUsername.text.toString(), "", idPasswordNew.text.toString())
                }
                else if (idRoot.iMode === idRoot.modeConfirmAccount) {
                    Global.awsAccountCpp.confirmAccount(idUsername.text.toString(), idConfirmCode.text.toString())
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: Global.bottomPad + 8

            Text {
                id: idNavSignIn
                text: qsTr("Sign In")
                visible: idRoot.bShowSignin
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeSignin
                    }
                }
            }

            Text {
                id: idNavForgetAndReset
                text: qsTr("Forget Password")
                visible: idRoot.bShowForget
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.gotoForgetAndReset()
                    }
                }
            }

            Text {
                id: idNavSignUp
                text: qsTr("Sign Up")
                visible: idRoot.bShowSignup
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeSignup
                    }
                }
            }

            Text {
                id: idNavConfirmAccount
                text: qsTr("Confirm Account")
                visible: idRoot.bShowConfirmAccount
                color: Global.iconColor
                Layout.fillWidth: true
                font.underline: true
                font.pixelSize: Global.fontSizeSmall3
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.iMode = idRoot.modeConfirmAccount
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
        id: idDialogInvalidPasswd
        gTitle: qsTr("Invalid Password")
        gStrMsg: qsTr("Do you Forget your Password?")
        onAcceptClicked: {
            idRoot.gotoForgetAndReset()
        }
    }

    ConfirmDialog {
        id: idDialogMsg
        hasCancelButton: false
        onAcceptClicked: {}
    }

    function showMsg(strTitle, strMsg) {
        idDialogMsg.gTitle = strTitle
        idDialogMsg.gStrMsg = strMsg
        idDialogMsg.open()
    }

    function saveAccount() {
        Global.localAccountCpp.setUser(idUsername.text.toString())
        Global.localAccountCpp.setPass(idPassword.text.toString())
    }

    function signinSuccess()
    {
        Global.dbDevicesCpp.reset()
        Global.dbFileTransferCpp.reset()
        Zpath.dbFilesPrivateCpp.reset()
        Zpath.dbFilesSharedCpp.reset()
        // Global.idStack.replace("DevicesPage.qml")
        idBusy.running = false
        // Global.idStack.replace("ConnectDevicePage.qml")
        Global.idStack.replace("DevicesPage.qml")
    }

    function newSignin()
    {
        idRoot.saveAccount()
        signinSuccess()
    }

    function gotoConfirmAccount() {
        idConfirmCode.text = ""
        idRoot.iMode = idRoot.modeConfirmAccount
    }

    function gotoSignIn(passVal = "") {
        idPassword.text = passVal
        idRoot.iMode = idRoot.modeSignin
    }

    function gotoForgetAndReset() {
        idPasswordNew.text = idPassword.text
        idConfirmCode.text = ""
        idRoot.iMode = idRoot.modeForgetAndReset
    }

    Connections {
        target: Global.awsAccountCpp

        function onSignUpFailed(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Sign Up failed, pls try later.\n\n") + strInfo)
            console.log(strInfo)
        }

        function onResendCodeSuccess(strInfo) {
            idRoot.gotoConfirmAccount()
            idBusy.running = false
            idRoot.showMsg(qsTr("Confirm your Account"), qsTr("The Confirm Code has been send to your Email."))
        }

        function onResendCodeFailed(strInfo) {
            idRoot.gotoConfirmAccount()
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Send Confirm Code failed, pls try later.\n\n") + strInfo)
        }

        function onConfirmAccountSuccess(strInfo) {
            idRoot.gotoSignIn()
            idBusy.running = false
            idRoot.showMsg(qsTr("Success"), qsTr("Your can Sign In now"))
        }

        function onConfirmAccountFailed(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Confirm Account fail, pls try later.\n\n") + strInfo)
        }

        function onSignInSuccess(strInfo) {
            idBusy.running = false
            // Product
            idRoot.newSignin()
            // Develop
            //idRoot.showMsg(qsTr("Success"), qsTr("Sign In Success."))
        }

        function onSignInFailed(strInfo) {
            idBusy.running = false
            if (strInfo === "UserNotConfirmed") {
                idRoot.gotoConfirmAccount()
                idRoot.showMsg(qsTr("Confirm your Account"), qsTr("The Confirm Code has been send to your Email."))
            }
            else {
                idRoot.showMsg(qsTr("Fail"), qsTr("Sign In failed, pls try later.\n\n") + strInfo)
            }
        }

        function onSignoutUserSuccess(strInfo) {
            idBusy.running = false
            console.log("Sign out all users connected to the account ...")
            // TODO: show waiting info: ...
        }

        function onSignoutUserFailed(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Sign Out all users Failed, pls try later.\n\n") + strInfo)
        }

        function onForgotPasswordSuccess(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Success"), qsTr("The Confirm Code has been sended to your Email."))
        }

        function onForgotPasswordFailed(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Request Reset Password Failed, pls try later.\n\n") + strInfo)
        }

        function onResetPasswordSuccess(strInfo) {
            idRoot.gotoSignIn(idPasswordNew.text)
            idBusy.running = false
            idRoot.showMsg(qsTr("Reset password success"), qsTr("You can Sign In with the New Password now."))
        }

        function onResetPasswordFailed(strInfo) {
            idBusy.running = false
            idRoot.showMsg(qsTr("Fail"), qsTr("Reset password Failed, pls try later.\n\n") + strInfo)
        }

        function onInvalidPasswd() {
            idBusy.running = false
            idDialogInvalidPasswd.open()
        }
    }

    Timer {
        id: idCountdownTimer
        running: false
        triggeredOnStart: false
        repeat: true
        interval: 1000
        property int timerCount: 59
        onTriggered: {
            timerCount -= 1
            idButtonResendconfirmCode.text = timerCount.toString()
            if (timerCount === 0) {
                idCountdownTimer.stop()
                timerCount = 59
                idButtonResendconfirmCode.text = qsTr("Send")
                idButtonResendconfirmCode.enabled = true
            }
        }
    }

    Component.onCompleted: {
        idUsername.text = Global.awsAccountCpp.getUser()
        idPassword.text = Global.awsAccountCpp.getPass()
        /*if (idPassword.text !== "") {
            idBusy.running = true
            Global.awsAccountCpp.signIn(idUsername.text.toString(), idPassword.text.toString())
        }*/
    }
}
