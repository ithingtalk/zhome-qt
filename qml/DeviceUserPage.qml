pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property string title: qsTr("User Managment")
    property string adminPasswd: ""

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
                actionStr: "actionGetUserList"
                }
        }
        onClickFunc: function(actionStr) {
            switch (actionStr) {
                case "actionGetUserList":
                    Logic.sendCmdGetUserList(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd);
                    break;
                default:
                    console.log("Unknown action:", actionStr)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: idToolbar.height
        color: palette.base

        ListView {
            id: idList
            anchors.fill: parent
            //anchors.margins: 8
            focus: true
            model: ListModel {}

            delegate: SwipeDelegate {
                id: idSwipe
                width: ListView.view.width
                height: 80
                leftPadding: 0
                rightPadding: 0

                required property var index
                required property string username
                required property string nickname
                required property string filesize
                required property string userstatus

                contentItem: RowLayout {
                    width: parent.width
                    height: parent.height

                    Text {
                        text: idSwipe.username
                        color: palette.text
                        font.pixelSize: Global.fontSize
                        Layout.leftMargin: 10
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Text {
                        text: idSwipe.filesize
                        color: palette.text
                        font.pixelSize: Global.fontSize
                        Layout.rightMargin: 10
                    }

                }
                swipe.right: Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 2
                    Label {
                        id: deleteRejectLabel
                        text: idSwipe.userstatus === "pass" ? qsTr("Delete") : qsTr("Reject")
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height - 8
                        width: height + 8
                        SwipeDelegate.onClicked: idSwipe.operation("deleteRejectAction")
                        background: Rectangle { color: deleteRejectLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.2) : "tomato" }
                    }
                    Label {
                        id: allowLabel
                        text: qsTr("Allow")
                        visible: idSwipe.userstatus !== "pass"
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height - 8
                        width: height + 8
                        SwipeDelegate.onClicked: idSwipe.operation("allowAction")
                        background: Rectangle { color: allowLabel.SwipeDelegate.pressed ? Qt.darker("blue", 1.2) : "blue" }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    acceptedButtons: Qt.RightButton
                    onPressed: (idSwipe.swipe.complete) ? idSwipe.swipe.close() : idSwipe.swipe.open(SwipeDelegate.Right)
                }

                function operation(op) {
                    idSwipe.swipe.close()
                    Global.currUser = { name: username, nick: nickname, size: filesize, status: userstatus }
                    switch (op) {
                    case "deleteRejectAction":
                        if (userstatus === "pass") {
                            idConfirmDelete.open()
                        }
                        else {
                            idDialogConfirmReject.open()
                        }
                        break
                    case "allowAction":
                        Logic.sendCmdAllowUser(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd);
                        break
                    default:
                        console.log("unknown operation: " + op)
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: idDialogConfirmReject
        gTitle: qsTr("Reject the user")
        gStrMsg: (Global.currUser && Global.currUser.name ? Global.currUser.name : "")
        confirmButtonText: "Reject"
        onAcceptClicked: {
            Logic.sendCmdRejectUser(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd);
        }
    }

    ConfirmDialog {
        id: idConfirmDelete
        gTitle: qsTr("Delete the user and all it's files")
        gStrMsg: (Global.currUser && Global.currUser.name ? Global.currUser.name + "\n\n" + Global.currUser.size : "")
        confirmButtonText: qsTr("Delete")
        confirmButtonColor: "tomato"
        onAcceptClicked: {
            Logic.sendCmdDeleteUser(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd);
        }
    }

    ConfirmDialog {
        id: idDialogOnError
        gTitle: qsTr("Error")
        gStrMsg: ""
        hasCancelButton: false
        onAcceptClicked: {
            Global.popStackviewPage()
        }
    }

    Rectangle {
        id: idOperationToast
        z: 100
        opacity: 0
        visible: opacity > 0.01
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        width: Math.min(parent.width - 48, toastLabel.implicitWidth + 24)
        height: toastLabel.implicitHeight + 16
        radius: 8
        color: "#DD323232"
        Behavior on opacity { NumberAnimation { duration: 150 } }
        function showToast(msg) {
            toastLabel.text = msg
            opacity = 1
            toastHideTimer.restart()
        }
        Text {
            id: toastLabel
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: Global.fontSize
        }
        Timer {
            id: toastHideTimer
            interval: 1000
            onTriggered: idOperationToast.opacity = 0
        }
    }

    Connections {
        target: Global.cmdServiceDeviceUserCpp
        function onDataReceived(strCmd, strResult) {
            console.log("DeviceUserPage.qml: " + strResult)
            // update device_user_list
            var userModelArray = Logic.getDeviceUsersListModel(strResult);
            idList.model.clear();
            for (var i = 0; i < userModelArray.length; i++) {
                idList.model.append(userModelArray[i]);
            }
            var isUserMutation = (strCmd.indexOf('"allow_user"') >= 0
                || strCmd.indexOf('"reject_user"') >= 0
                || strCmd.indexOf('"delete_user"') >= 0)
            var hasUserList = (strResult.indexOf('"user_list"') >= 0)
            if (isUserMutation && hasUserList) {
                idOperationToast.showToast(qsTr("操作成功"))
            }
            // update hdd status
        }
        function onErrorOccurred(errString, errCode) {
            console.log("===> " + errString + errCode)
            // QNetworkReply::TimeoutError === 4 (Qt 6); refresh list once — command may still have applied on device.
            var errLower = errString.toLowerCase()
            var isTimeout = (errCode === 4) || errLower.indexOf("timeout") >= 0
            if (isTimeout) {
                Logic.sendCmdGetUserList(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd)
                return
            }
            if (errCode === 399) { // error: "connection closed"
                idDialogOnError.gStrMsg = qsTr("Success")
            }
            else if (errCode === 204) {
                idDialogOnError.gStrMsg = qsTr("Wrong administrator's password")
            }
	    else {
	    	idDialogOnError.gStrMsg = errString
	    }
	    idDialogOnError.open()
        }
    }

    Component.onCompleted: {
        Logic.sendCmdGetUserList(Global.cmdServiceDeviceUserCpp, idRoot.adminPasswd);
    }
}
