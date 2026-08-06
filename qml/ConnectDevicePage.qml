import QtQuick
import QtQuick.Controls
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property bool gLoginSuccess: false
    property bool gGotDbFile: false
    property string gstrStatus: qsTr("Loading")

    ZhomeToolbar {
        id: idToolbar
        winTitle: Global.currDevice.name
        onBackFunc: function () {
            Global.closeWindow()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Device settings")
                actionStr: "actionDeviceSettings"
                }
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("APP settings")
                actionStr: "actionAppSettings" }
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Sign Out")
                actionStr: "actionSignOut" }
        }
        onClickFunc: function(actionStr) {
            if (idRoot.gGotDbFile) {
                if (actionStr === "actionDeviceSettings") {
                    Global.idStack.push("UserServicePage.qml")
                }
                else if (actionStr === "actionAppSettings") {
                    Global.idStack.push("SettingPage.qml")
                }
                else if (actionStr === "actionSignOut") {
                    console.log("signOut")
                    Global.awsAccountCpp.signOut(); // signOut, signOutFromAllDevice
                }
            }
            else { idRoot.gstrStatus = qsTr("Connecting") }
        }
    }

    Connections {
        target: Zpath.dbFilesPrivateCpp
        function onDbFileDownloadSuccess() {
            console.log("Contentmainpage.qml: db file donwload success")
            Zpath.treeItemChanged(0)
            Global.idStack.replace("ContentMainPage.qml")
        }
    }

    Connections {
        target: Global.cmdServiceConnectDeviceCpp
        function onDataReceived(strCmd, strResult) {
            // console.log("ConnectDevicePage.qml: " + strResult)
            if (idRoot.gLoginSuccess) {
                if (idRoot.gGotDbFile === false) {
                    try {
                        var jsonObject = JSON.parse(strResult)
                        if (jsonObject.user_authority) {
                            if (jsonObject.user_authority === "denied") { idNeedAllow.open() }
                            else if (jsonObject.user_authority === "pass") {
                                console.log("share pass: " + jsonObject.share_pwd_for_app + ", update db file")
                                Global.nasApiCpp.sharePwd(jsonObject.share_pwd_for_app)
                                Zpath.dbFilesPrivateCpp.updateDbFile(true)
                            }
                        }
                    }
                    catch(e) { idRoot.gstrStatus = qsTr("Exception: " + e) }
                }
                else {
                    console.log("Received message after got db file: " + strResult)
                }
            }
            else {
                if (Global.nasApiCpp.userLoginSuccess(strResult)) {
                    idRoot.gLoginSuccess = true
                    idRoot.gstrStatus = qsTr("Login success, getting device status")
                    Logic.sendCmdGetUserStatus(Global.cmdServiceConnectDeviceCpp)
                }
                else if (Global.nasApiCpp.userLoginFail(strResult)) {
                    idError.gStrMsg = qsTr("Wrong password")
                    idError.open()
                }
                else if (Global.nasApiCpp.userLoginNeedAllow(strResult)) {
                    idNeedAllow.open()
                }
            }
        }
        function onErrorOccurred(errString, errCode) {
            idRoot.gstrStatus = qsTr("Network error") + ":\n\n" + errString + " " + errCode
            idError.gStrMsg = idRoot.gstrStatus
            idError.open()
        }
    }

    Connections {
        target: Global.awsAccountCpp
        function onIotReady() {
            // idRoot.loginToDevice() // Moved to Component.onCompleted for faster response
        }
        function onSignOutSuccess() {
            console.log("signOut success")
            Global.idStack.replace("AwsLoginPage.qml")
        }
        function onSignOutFailed(info) {
            console.log("signOut fail: " + info)
        }
    }

    Component.onCompleted: {
        idRoot.loginToDevice()
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 120
        height: 120
        running: true
    }

    Text {
        id: idStatusBar
        text: idRoot.gstrStatus
        anchors.centerIn: parent
        color: palette.text
        font.pixelSize: Global.fontSize
        MouseArea { // remote developing
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                idBusy.running = true
                // Global.awsDbServiceCpp.idevicesPost("345766218@qq.com", "12345678", "784476001122", "nas-home")
                Global.awsDbServiceCpp.all()
            }
        }
    }

    ConfirmDialog {
        id: idError
        gTitle: qsTr("Error")
        hasCancelButton: false
        onAcceptClicked: {
            Global.popStackviewPage()
        }
    }

    ConfirmDialog {
        id: idNeedAllow
        gTitle: qsTr("Request permission")
        gStrMsg: qsTr("Please contanct the device's administrator to allow you connect the device.")
        hasCancelButton: false
        onAcceptClicked: {
            Global.popStackviewPage()
        }
    }

    function loginToDevice()
    {
        Logic.sendCmdUserLogin(Global.cmdServiceConnectDeviceCpp)
    }

    function isLocalConnection() {
        return Global.currDevice.ip !== ""
    }
}
