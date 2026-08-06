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
        function onDownloadFinish(localFile) {
            // console.log("offlinedownloaded.qml, download file finished: " + localFile)
            var strPlain = Global.utilsCpp.readFile(localFile)
            if (strPlain !== "") {
                console.log("Raw Text:", strPlain)
                idRoot.getStatusSuccess(strPlain)
            }
        }
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
            swipe.enabled: !bDownloaded

            required property var index
            required property var btPath
            required property var btSize

            property bool bDownloaded: btPath.endsWith(".part")

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
                    spacing: 4
                    Text {
                        id: idName
                        text: Logic.getFileName(idItem.btPath)
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        color: palette.text
                        elide: Text.ElideMiddle
                    }
                    Text {
                        id: idSize
                        text: Zpath.dbFilesPrivateCpp.formatFileSize(idItem.btSize)
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        color: palette.text
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
                idItem.ListView.view.currentIndex = idItem.index
                Zpath.fileSelectedIndex = index
            }

            function onAction(actionStr) {
                console.log("action: " + actionStr)
                idItem.swipe.close()
                switch(actionStr) {
                case "actionMoveToMyFiles":
                    console.log("move to myfiles: " + idItem.btPath)
                    var old_name = Logic.lastPathStartWithMyFiles(idItem.btPath)
                    var new_name = "MyFiles/Video/" + idName.text
                    // console.log("file rename from: " + old_name + " to " + new_name)
                    Logic.sendCmdBtMoveToMyFiles(old_name, new_name)
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
                gTitle: qsTr("Delete File")
                gStrMsg: idName.text
                confirmButtonText: qsTr("Delete")
                confirmButtonColor: "tomato"
                onAcceptClicked: {
                    console.log("delete file: " + idItem.btPath)
                    var astrFiles = []
                    astrFiles.push(Logic.lastPathStartWithMyFiles(idItem.btPath))
                    Logic.sendCmdBtDeleteFile(astrFiles)
                }
            }
            // ============================================================================

            swipe.right: Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 2

                SwipeLabel {
                    id: idStopLabel
                    text: qsTr("Move To My Video Folder")
                    bcolor: "blue"
                    actionStr: "actionMoveToMyFiles"
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
            else {
                console.log("ret message: " + strResult)
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
            if (jsonObject.msg_type === "string" && jsonObject.get_download_file_result === "success" && jsonObject.file_list !== undefined) {
                var sModel = []
                for (var idx = 0; idx < jsonObject.file_list.length; idx++) {
                    var sItem = jsonObject.file_list[idx]
                    sModel.push({
                                    btPath: sItem.file_path,
                                    btSize: sItem.file_size
                    });
                }
                sModel.sort(function (a, b) {
                    return Logic.getFileName(a.btPath).localeCompare(Logic.getFileName(b.btPath), undefined, { sensitivity: "base" })
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
            Logic.sendCmdGetBtFiles()
        }
    }

    Component.onCompleted: {
        idRefreshTimer.start()
    }
}
