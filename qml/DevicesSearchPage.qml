pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Search Local Devices")
    property int iCounter: 0
    /** 局域网发现结果，按设备名称排序后同步到 ListView */
    property var discoveredDevices: []

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.closeWindow()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/ionicons/search.svg"
                itemText: qsTr("Search Local device")
                actionStr: "SearchLocalIdevice" }
        }
        onClickFunc: function(actionStr) {
            switch (actionStr) {
            case "SearchLocalIdevice":
                prepareSearch()
                break
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
            clip: true

            model: ListModel {}
            delegate: ItemDelegate {
                id: idItem
                width: ListView.view.width
                height: 90
                leftPadding: 0
                rightPadding: 0

                required property var index
                required property string devmac
                required property string devsn
                required property string devname
                required property string devcfg
                required property string devip

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
                        text: idItem.devname
                        color: palette.text
                        font.pixelSize: Global.fontSize
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: idItem.devcfg === "0" ? qsTr("Configure") : ( idItem.devip === "" ? qsTr("Connecting") : qsTr("Connected") )
                        color: idItem.devcfg === "0" ? "red" : ( idItem.devip === "" ? "grey" : "green" )
                        font.pixelSize: Global.fontSize
                        Layout.rightMargin: 16
                    }
                }

                onClicked: {
                    if (idItem.devcfg === "0")
                        idItem.operation("configureDevice")
                    else {
                        idBusy.running = true
                        idItem.operation("connectDevice")
                    }
                }

                function operation(op) {
                    Global.currDevice = { mac: devmac, sn: devsn, name: devname, cfg: devcfg, ip: devip }
                    Global.dbDevicesCpp.intoDevice(devmac, devsn, devname, devcfg, devip);
                    switch (op) {
                    case "connectDevice":
                        Global.dbDevicesCpp.add(devmac, devsn, devname, devip)
                        break
                    case "configureDevice":
                        Global.idStack.push("DeviceConfigureNewPage.qml")
                        break
                    default:
                        console.log("unknown operation: " + op)
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: idDialogAddSuccess
        gTitle: qsTr("Success")
        gStrMsg: qsTr("Add Success")
        hasCancelButton: false
        onAcceptClicked: {
            Global.idStack.pop()
        }
    }

    Timer {
        id: idTimerSearch
        repeat: true
        interval: 2000
        onTriggered: {
            iCounter ++
            if (iCounter < 2) {
                Global.searchLocalIdeviceCpp.startServer()
            }
            else {
                idBusy.running = false
                idTimerSearch.stop()
            }
        }
    }

    function prepareSearch() {
        iCounter = 0
        idBusy.running = true
        Global.dbDevicesCpp.clearIp()
        idList.model.clear()
        discoveredDevices = []
        Global.searchLocalIdeviceCpp.startServer()
        idTimerSearch.start()
    }

    function rebuildDeviceListModel() {
        var sorted = discoveredDevices.slice()
        sorted.sort(function (a, b) {
            return (a.devname || "").localeCompare(b.devname || "", undefined, { sensitivity: "base" })
        })
        idList.model.clear()
        for (var i = 0; i < sorted.length; i++)
            idList.model.append(sorted[i])
    }

    Component.onCompleted: {
        prepareSearch()
    }

    Connections {
        target: Global.searchLocalIdeviceCpp
        function onFoundNewDevice(mac, sn, name, cfg, ip) {
            console.log("search new: mac = " + mac + ", sn = " + sn + ", name = " + name + ", cfg = " + cfg + ", ip = " + ip);
            discoveredDevices.push({ devmac: mac, devsn: sn, devname: name, devcfg: cfg, devip: ip })
            idRoot.rebuildDeviceListModel()
            idTimerSearch.stop()
            idBusy.running = false
        }
    }

    Connections { // should use iot and p2p
        target: Global.awsDbServiceCpp
        function onAddSuccess() {
            idBusy.running = false
            idDialogAddSuccess.open()
        }
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 120
        height: 120
        running: false
    }
}

