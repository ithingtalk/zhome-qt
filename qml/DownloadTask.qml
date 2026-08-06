pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Rectangle {
    id: idRoot
    color: palette.base

    Connections {
        target: Zpath.btFileServiceCpp
        function onUploadFinish(remotePath, fileSize, fileDate) {
            console.log("offlinedownload.qml, upload bt file finished: " + remotePath)
            Logic.sendCmdUploadBtFile(Logic.getFileName(remotePath))
        }
        function onDownloadFinish(localFile) {
            // console.log("offlinedownload.qml, download file finished: " + localFile)
            var strPlain = Global.utilsCpp.readFile(localFile)
            if (strPlain !== "") {
                // console.log("Raw Text:", strPlain)
                idRoot.getStatusSuccess(strPlain)
            }
        }
    }

    FileDropArea {
        anchors.fill: parent
    }

    ListView {
        id: idList
        anchors.fill: parent
        clip: true
        model: ListModel {}

        delegate: SwipeDelegate {
            id: idItem
            width: ListView.view.width
            leftPadding: 0
            rightPadding: 0
            topPadding: 30
            bottomPadding: 0

            required property var index
            required property var btId
            required property var btName
            required property var btStatus
            required property var btPercent
            required property var btSpeed
            required property var btDownloaded
            required property var btTotalSize

            contentItem: RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Button {
                    icon.height: 51
                    icon.width: 38
                    icon.source: "../icons/fontawesome/svgs/solid/file-arrow-down.svg"
                    icon.color: Global.iconColor
                    background: null
                    Layout.leftMargin: 4
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        id: idBtName
                        text: idItem.btName
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        color: palette.text
                        elide: Text.ElideMiddle
                    }
                    Text {
                        id: idBtStatus
                        text: idItem.btStatus === "Stopped" ? qsTr("Stopped") : (idItem.btStatus === "Idle" ? qsTr("Idle") : qsTr("Downloading")) + " ( " + idItem.btSpeed + " )"
                        font.pixelSize: Global.fontSizeSmall3
                        Layout.fillWidth: true
                        color: palette.text
                    }
                    Text {
                        id: idBtDownloaded
                        text: idItem.btPercent + " ( " + idItem.btDownloaded + " / " + idItem.btTotalSize + " )"
                        font.pixelSize: Global.fontSizeSmall3
                        Layout.fillWidth: true
                        color: palette.text
                    }
                    ProgressBar {
                        id: idPrograss
                        font.pixelSize: Global.fontSizeSmall3
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        Layout.preferredHeight: 8
                        from: 0
                        to: 100
                        value: 0.0 + idItem.btPercent.replace("%", "")
                    }
                }
            }

            onClicked: {
                if (idItem.swipe.position === 0) {
                    idItem.checkItem()
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    if (idItem.swipe.enabled) {
                        if (idItem.swipe.position !== 0) {
                            idItem.swipe.close()
                        } else {
                            idItem.swipe.open(SwipeDelegate.Right)
                        }
                    }
                }
            }

            function checkItem() {
                idItem.highlightItem(true)
            }

            function highlightItem(bOpenfile = false) {
                idItem.ListView.view.currentIndex = idItem.index
                Zpath.fileSelectedIndex = index
            }

            function onAction(actionStr) {
                console.log("action: " + actionStr)
                idItem.swipe.close()
                switch(actionStr) {
                case "actionStart":
                    Logic.sendCmdStartBt(idItem.btId)
                    break;
                case "actionStop":
                    Logic.sendCmdStopBt(idItem.btId)
                    break;
                case "actionDelete":
                    idDialogDelBt.open()
                    break;
                default:
                    console.log("unknown action: " + actionStr)
                    break;
                }
            }
            // ==========================================================================
            ConfirmDialog {
                id: idDialogDelBt
                gTitle: qsTr("Delete download")
                gStrMsg: idItem.btName
                confirmButtonText: qsTr("Delete")
                confirmButtonColor: "tomato"
                onAcceptClicked: {
                    Logic.sendCmdDelBt(idItem.btId)
                }
            }
            // ============================================================================

            swipe.right: Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 2

                SwipeLabel {
                    id: idStartLabel
                    text: qsTr("Start")
                    bcolor: "green"
                    actionStr: "actionStart"
                    onClicked: function(actionStr) { idItem.onAction(actionStr) }
                }

                SwipeLabel {
                    id: idStopLabel
                    text: qsTr("Stop")
                    bcolor: "blue"
                    actionStr: "actionStop"
                    onClicked: function(actionStr) { idItem.onAction(actionStr) }
                }

                SwipeLabel {
                    id: idDeleteLabel
                    text: qsTr("Delete")
                    bcolor: "tomato"
                    actionStr: "actionDelete"
                    onClicked: function(actionStr) { idItem.onAction(actionStr) }
                }
            }
        }
    }

    Connections {
        target: Global.cmdServiceBtCpp
        function onDataReceived(strCmd, strResult) {
            // console.log("OfflineDownload.qml, onDataReceived: " + strResult)
            if (idRoot.getStatusSuccess(strResult)) {
                // console.log("refresh list ok")
            }
            else if (Global.nasApiCpp.addBtFail(strResult)) {
                console.log("add url fail")
                idDialogResult.gStrMsg = qsTr("Add Url Fail")
                idDialogResult.open()
            }
            else {
                console.log("unknown ret message: " + strResult)
                idRefreshTimer.start()
            }
        }
        function onErrorOccurred(errString, errCode) {
            idDialogResult.gStrMsg = qsTr("Network error") + ":\n\n" + errString + " " + errCode
            idDialogResult.open()
        }
    }

    ConfirmDialog {
        id: idDialogResult
        gTitle: "Fail"
        hasCancelButton: false
        onAcceptClicked: {}
    }

    function getStatusSuccess(strPlain) {
        var bRet = false
        try {
            var jsonObject = JSON.parse(strPlain)
            if (jsonObject.msg_type === "string" && jsonObject.download_status === "success" && jsonObject.items !== undefined) {
                var sModel = []
                for (var idx = 0; idx < jsonObject.total_number; idx++) {
                    var sItem = jsonObject.items[idx]
                    sModel.push({
                                    btId: sItem.Torrent_ID,
                                    btName: sItem.Name,
                                    btStatus: sItem.Status,
                                    btPercent: sItem.Percent,
                                    btSpeed: sItem.Speed,
                                    btDownloaded: sItem.Downloaded,
                                    btTotalSize: sItem.Total_Size
                    });
                }
                sModel.sort(function (a, b) {
                    return (a.btName || "").localeCompare(b.btName || "", undefined, { sensitivity: "base" })
                })
                idList.model = sModel
                bRet = true
            }
            else if (jsonObject.msg_type === "file" && jsonObject.user_id === Global.localAccountCpp.getUser()) {
                Logic.downloadBtFile()
                bRet = true
            }
        }
        catch(e) {
            console.log(qsTr("Exception") + e)
        }
        return bRet
    }

    Timer {
        id: idRefreshTimer
        running: false
        repeat: false
        interval: 500
        onTriggered: {
            Logic.sendCmdGetBtStatus()
        }
    }

    Component.onCompleted: {
        idRefreshTimer.start()
    }
}
