pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property string title: qsTr("File transferring")

    property int giType: Global.dbFileTransferCpp.download_type()
    property string gstrStatus: ""

    property string uploadFileName: ""
    property real uploadCurrentValue: 0.0
    property real uploadTotalValue: 100.0
    property int uploadPercent: (uploadCurrentValue * 1000 / (uploadTotalValue > 0 ? uploadTotalValue : 1)).toFixed()

    property string downloadFileName: ""
    property real downloadCurrentValue: 0.0
    property real downloadTotalValue: 100.0
    property int downloadPercent: (downloadCurrentValue * 1000 / (downloadTotalValue > 0 ? downloadTotalValue : 1 )).toFixed()

    property bool isUploadType: idRoot.giType === Global.dbFileTransferCpp.upload_type()
    property string fileName: isUploadType ? uploadFileName : downloadFileName
    property real currentValue: isUploadType ? uploadCurrentValue : downloadCurrentValue
    property real totalValue: isUploadType ? uploadTotalValue : downloadTotalValue
    property int percentValue: isUploadType ? uploadPercent : downloadPercent

    property string percentWithUnit: (percentValue / 10.0) + (percentValue % 10 === 0 ? ".0" : "") + " % "

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.popStackviewPage()
        }
        menuModel: ListModel {
            ListElement {
                iconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg"
                itemText: qsTr("Clear All List")
                actionStr: "ActionClearDatabase" }
            ListElement {
                iconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg"
                itemText: qsTr("Clear Cache")
                actionStr: "actionCleanCache" }
        }
        onClickFunc: function(actionStr) {
            if (actionStr === "ActionClearDatabase") {
                Global.dbFileTransferCpp.empty_all()
            }
            else if (actionStr === "actionCleanCache") {
                Global.utilsCpp.delCache()
            }
        }
    }

    Connections {
        target: Global.dbFileTransferCpp
        function onDataChanged(iType) {
            console.log("Update file transfering list: " + iType + ", giType=" + idRoot.giType)
            if (iType === idRoot.giType) {
                idRoot.updateList()
            }
        }
        Component.onCompleted: {
            onDataChanged(idRoot.giType)
        }
    }

    Connections {
        target: Global.uploadingListCpp
        function onUploadProgress(fileName, bytesSent, bytesTotal) {
            idRoot.uploadFileName = fileName
            if (bytesSent === bytesTotal) {
                idRoot.uploadCurrentValue = 100
                idRoot.uploadTotalValue = 100
            }
            else {
                idRoot.uploadCurrentValue = bytesSent
                idRoot.uploadTotalValue = bytesTotal
            }
        }
    }

    Connections {
        target: Global.downloadingListCpp
        function onDownloadProgress(fileName, bytesSent, bytesTotal) {
            idRoot.downloadFileName = fileName
            if (bytesSent === bytesTotal) {
                idRoot.downloadCurrentValue = 100
                idRoot.downloadTotalValue = 100
            }
            else {
                idRoot.downloadCurrentValue = bytesSent
                idRoot.downloadTotalValue = bytesTotal
            }
        }
    }

    function updateList() {
        console.log("updateList: " + giType)
        idList.model = Global.dbFileTransferCpp.getAll(giType)
    }

    RowLayout {
        id: idType
        visible: Zpath.selectedMyFiles
        anchors.top: idToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 0
        height: visible ? 40 : 0
        spacing: 0

        MyRadioButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Uploading")
            bLeftButton: true
            padding: 0
            onAcceptClicked: {
                idRoot.giType = Global.dbFileTransferCpp.upload_type()
                idRoot.updateList()
            }
        }

        MyRadioButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Downloading")
            gChecked: true
            bRightButton: true
            padding: 0
            onAcceptClicked: {
                idRoot.giType = Global.dbFileTransferCpp.download_type()
                idRoot.updateList()
            }
        }
    }

    Rectangle {
        anchors.top: idType.bottom
        anchors.bottom: idBottomToolbar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: {
            top: 0
            bottom: 10
            left: 0
            right: 0
        }
        color: palette.base
        // radius: 5

        ListView {
            id: idList
            anchors.fill: parent
            clip: true

            model: ListModel {}
            delegate: SwipeDelegate {
                id: idItem
                width: ListView.view.width
                height: 80

                required property var index
                required property var transferPath
                required property var transferStatus
                required property var transferLPath

                property bool isStarted: transferStatus === Global.dbFileTransferCpp.started_status()
                property bool isTransfering: transferPath === idRoot.fileName

                contentItem: ColumnLayout {
                    width: parent.width
                    height: parent.height
                    spacing: 2

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 4

                        Text {
                            id: idTextValue
                            text: Logic.getFileName(idItem.transferPath)
                            color: palette.text
                            font.pixelSize: Global.fontSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: idItem.isStarted ? ( idItem.isTransfering ? idRoot.percentWithUnit : qsTr("Waiting") ) : qsTr("Paused")
                            color: palette.text
                            Layout.rightMargin: 8
                        }
                    }

                    /*Text {
                        text: idItem.transferLPath
                        color: palette.text
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        Layout.margins: 4
                        elide: Text.ElideRight
                    }*/

                    ProgressBar {
                        id: idPrograss
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        Layout.margins: 4
                        from: 0
                        to: 1000
                        value: idItem.isTransfering ? idRoot.percentValue : 0
                    }

                    Item { Layout.fillHeight: true }
                }

                swipe.right: Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 2
                    Label {
                        id: idDeleteLabel
                        text: qsTr("Delete")
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height
                        width: height + 8
                        SwipeDelegate.onClicked: {
                            idItem.swipe.close()
                            console.log("delete from transfer list: " + idItem.transferPath)
                            Global.dbFileTransferCpp.del(idRoot.giType, idItem.transferPath)
                        }
                        background: Rectangle { color: idDeleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.2) : "tomato" }
                    }
                    Label {
                        id: idStartStopLabel
                        text: idItem.isStarted ? qsTr("Stop") : qsTr("Start")
                        color: "white"
                        verticalAlignment: Label.AlignVCenter
                        horizontalAlignment: Label.AlignHCenter
                        height: parent.height
                        width: height + 8
                        SwipeDelegate.onClicked: {
                            idItem.swipe.close()
                            if (idItem.isStarted) {
                                Global.dbFileTransferCpp.stop(idRoot.giType, idItem.transferPath)
                            }
                            else {
                                Global.dbFileTransferCpp.start(idRoot.giType, idItem.transferPath)
                            }
                        }
                        background: Rectangle { color: idStartStopLabel.SwipeDelegate.pressed ? Qt.darker("blue", 1.2) : "blue" }
                    }
                }

                onClicked: {
                    if (idItem.swipe.position === 0) {
                        idItem.ListView.view.currentIndex = idItem.index
                        console.log("clicked: " + transferPath)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (idItem.swipe.position !== 0) {
                            idItem.swipe.close()
                        } else {
                            idItem.swipe.open(SwipeDelegate.Right)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: idBottomToolbar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: hasItem || showDownloaded
        height: visible ? Global.bottomButtonHeight + 16 : 0
        anchors.margins: {
            top: 0
            left: 0
            right: 0
            bottom: Global.bottomPad
        }
        color: palette.base

        property bool hasItem: idList.model.length > 0
        property bool showDownloaded: Global.isDesktop && idRoot.giType === Global.dbFileTransferCpp.download_type()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            MyBottomButton {
                visible: idBottomToolbar.hasItem
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("Start all")
                gIconSrc: "../icons/ionicons/play.svg"
                textColor: Global.iconColor
                onAcceptClicked: {
                    Global.dbFileTransferCpp.start(idRoot.giType)
                }
            }

            MyBottomButton {
                visible: idBottomToolbar.hasItem
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("Pause all")
                gIconSrc: "../icons/ionicons/pause.svg"
                textColor: Global.iconColor
                onAcceptClicked: {
                    Global.dbFileTransferCpp.stop(idRoot.giType)
                }
            }

            MyBottomButton {
                visible: idBottomToolbar.hasItem
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("Remove")
                gIconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg"
                textColor: "tomato"
                onAcceptClicked: {
                    Global.dbFileTransferCpp.empty(idRoot.giType)
                }
            }

            MyBottomButton {
                id: idShowDownloaded
                visible: idBottomToolbar.showDownloaded
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("Show downloaded")
                gIconSrc: "../icons/fontawesome/svgs/solid/folder-open.svg"
                textColor: Global.iconColor
                onAcceptClicked: {
                    Global.dbFileTransferCpp.openDownloadDir()
                }
            }
        }
    }
}
