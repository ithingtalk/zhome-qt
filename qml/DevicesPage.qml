pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("My Devices")

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.closeWindow()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/fontawesome/svgs/solid/plus.svg"
                itemText: qsTr("Add New Device")
                actionStr: "addNewDeviceAction" }
            ListElement {
                iconSrc: "../icons/fontawesome/svgs/solid/minus.svg"
                itemText: qsTr("Empty devices")
                actionStr: "EmptyDevices" }
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Settings")
                actionStr: "GoToSettings" }
            ListElement {
                iconSrc: "../icons/ionicons/game-controller-outline.svg"
                itemText: qsTr("Small Game")
                actionStr: "GoToGame" }
            ListElement {
                iconSrc: "../icons/ionicons/settings-sharp.svg"
                itemText: qsTr("Sign Out")
                actionStr: "actionSignOut" }
            ListElement {
                iconSrc: "../icons/ionicons/refresh.svg"
                itemText: qsTr("Refresh remote status")
                actionStr: "actionRefreshRemoteStatus" }
            /* ListElement {
                iconSrc: "../icons/ionicons/refresh.svg"
                itemText: qsTr("Test util_t_s")
                actionStr: "actionUtilTS" } */
        }

        onClickFunc: function(actionStr) {
            switch (actionStr) {
            case "addNewDeviceAction":
                idTimerSearch.stop()
                Global.idStack.push("DevicesSearchPage.qml")
                break
            case "EmptyDevices":
                Global.dbDevicesCpp.empty_devices()
                break
            case "GoToSettings":
                Global.idStack.push("SettingPage.qml")
                break
            case "GoToGame":
                Global.idStack.push("../../SameGameModule/Main.qml")
                break
            case "actionSignOut":
                console.log("signOut")
                Global.awsAccountCpp.signOut(); // signOut, signOutFromAllDevice
                break;
            case "actionRefreshRemoteStatus":
                console.log("Refresh remote status")
                Global.awsDbServiceCpp.all()
                break;
            /* case "actionUtilTS":
                Global.awsAccountCpp.testTS()
                break; */
            default:
                console.log("Unknown action:", actionStr)
            }
        }
    }

    Rectangle {
        color: palette.base
        anchors.top: idToolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 0

        ListView {
            id: idList
            anchors.fill: parent
            //anchors.margins: 8
            clip: true

            model: ListModel {}
            delegate: SwipeDelegate {
                id: idSwipe
                width: ListView.view.width
                height: 90
                leftPadding: 0
                rightPadding: 0

                required property var index
                required property string devmac
                required property string devsn
                required property string devname
                required property string devip
                required property string online

                contentItem: RowLayout {
                    width: parent.width
                    height: parent.height
                    spacing: 0

                    Image {
                        source: "../icons/device.png"
                        Layout.preferredHeight: parent.height - 20
                        Layout.preferredWidth: parent.height - 20
                        Layout.leftMargin: 10
                    }

                    Text {
                        text: idSwipe.devname
                        color: palette.text
                        font.pixelSize: Global.fontSize
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text:  idSwipe.devip !== "" ? idSwipe.devip : (idSwipe.online === "connected" ? qsTr("Remote Connected") : qsTr("disconnected"))
                        color: ( idSwipe.devip !== "" || idSwipe.online === "connected" ) ? "green" : "grey"
                        font.pixelSize: Global.fontSize
                        Layout.rightMargin: 16
                    }
                }

                swipe.right: Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 2
                    Label {
                        id: manageLabel
                        text: qsTr("Manage")
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height
                        width: height + 8
                        SwipeDelegate.onClicked: idSwipe.operation("managmentDevice")
                        background: Rectangle { color: manageLabel.SwipeDelegate.pressed ? Qt.darker("blue", 1.2) : "blue" }
                    }
                    Label {
                        id: deleteLabel
                        text: qsTr("Delete")
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height
                        width: height + 8
                        SwipeDelegate.onClicked: idSwipe.operation("deleteDevice")
                        background: Rectangle { color: deleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.2) : "tomato" }
                    }
                }

                onClicked: {
                    if (idSwipe.swipe.position === 0) {
                        if (idSwipe.devcfg === "0")
                            idSwipe.operation("configureDevice")
                        else // if (idSwipe.devip !== "") // support local and remote connection
                            idSwipe.operation("connectDevice")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (idSwipe.swipe.position !== 0) {
                            idSwipe.swipe.close()
                        } else {
                            idSwipe.swipe.open(SwipeDelegate.Right)
                        }
                    }
                }

                function operation(op) {
                    idSwipe.swipe.close()
                    var intoSameDevice = ( devmac === Global.currDevice.mac )
                    Global.currDevice = { mac: devmac, sn: devsn, name: devname, cfg: "1", ip: devip }
                    //=====================================================================================
                    if (!Global.localAccountCpp.getForceP2p())
                        Global.dbDevicesCpp.intoDevice(devmac, devsn, devname, "1", devip); // release
                    else
                        Global.dbDevicesCpp.intoDevice(devmac, devsn, devname, "1", ""); // debug p2p
                    //=====================================================================================
                    switch (op) {
                    case "connectDevice":
                        if (Global.localAccountCpp.getPass() === "") {
                            Global.idStack.replace("LoginPage.qml")
                            return;
                        }
                        if(intoSameDevice) {
                            Global.idStack.push("ContentMainPage.qml")
                        }
                        else {
                            Global.idStack.push("ConnectDevicePage.qml")
                        }
                        break
                    case "managmentDevice":
                        Global.idStack.push("DeviceManagmentPage.qml")
                        break
                    case "deleteDevice":
                        idDialogConfirmDelete.gStrMsg = idSwipe.devname
                        idDialogConfirmDelete.open()
                        break
                    default:
                        console.log("unknown operation: " + op)
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: idDialogConfirmDelete
        gTitle: qsTr("Delete device")
        gStrMsg: ""
        confirmButtonText: qsTr("Delete")
        confirmButtonColor: "tomato"
        onAcceptClicked: {
            console.log("Accept button clicked in Confirm_Dialog")
            Global.dbDevicesCpp.del(Global.currDevice.mac)
        }
    }

    Timer {
        id: idTimerSearch
        repeat: true
        interval: 2000
        onTriggered: {
            idRoot.iCounter ++
            if (idRoot.iCounter < 2) {
                Global.searchLocalIdeviceCpp.startServer()
            }
            else {
                idTimerSearch.stop()
            }
        }
    }

    function prepareSearch() {
        Global.dbDevicesCpp.clearIp()
        idList.model.clear()
        idRoot.loadData()
        Global.searchLocalIdeviceCpp.startServer()
        idTimerSearch.start()
    }

    Connections {
        target: Global.searchLocalIdeviceCpp
        function onIpUpdated() {
            idTimerSearch.stop()
        }
    }

    property int iCounter: 0

    Component.onCompleted: {
        iCounter = 0
        prepareSearch()
    }

    function loadData() {
        var devices = Global.dbDevicesCpp.getAll()
        idList.model.clear()
        for (var i = 0; i < devices.length; i++) {
            idList.model.append(devices[i])
        }
    }

    Connections {
        target: Global.dbDevicesCpp
        function onDataChanged() {
            idRoot.loadData()
        }
    }

    Connections { // sign out
        target: Global.awsAccountCpp
        function onSignOutSuccess() {
            console.log("signOut success")
            Global.idStack.replace("AwsLoginPage.qml")
        }
    }
}
