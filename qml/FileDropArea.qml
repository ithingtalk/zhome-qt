pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Rectangle {
    id: idRoot
    anchors.fill: parent
    color: palette.base

    property real gShareTypeHeight: 40
    property var gDbFilesCpp: Zpath.dbFilesPrivateCpp

    // selectedMyFiles: droparea to upload files ========================================
    DropArea {
        anchors.fill: parent
        enabled: Global.isDesktop && Zpath.selectedMyFiles && Zpath.isUserDirOrFile && Zpath.normalMode || Zpath.selectedOfflineDownload
        onEntered: {
            idDialogShowAddIcon.open()
        }
        onExited: {
            idDialogShowAddIcon.close()
        }
        onDropped: (drop) => {
           idDialogShowAddIcon.close()
            // debug ========================================================
            for (var i = 0; i < drop.urls.length; i++) {
                console.log("拖入文件[" + i + "]:", drop.urls[i].toString())
            }
            // ==============================================================
            if (Zpath.selectedMyFiles) {
                Logic.uploadFiles(drop.urls)
            }
            else if (Zpath.selectedOfflineDownload) {
                Logic.uploadBtFile(drop.urls[0].toString())
            }
        }
    }
    Dialog {
        id: idDialogShowAddIcon
        width: parent.width
        height: parent.height
        background: Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        RoundButton {
            property int iSize: 64
            width: iSize
            height: iSize
            anchors.centerIn: parent
            icon.source: "../icons/ionicons/add.svg"
            icon.color: Global.iconColor
            icon.height: iSize
            icon.width: iSize
        }
    }
    // ==================================================================================

    // selectedShared: share type =======================================================
    Loader {
        id: idShareType
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: sourceComponent === null ? 0 : gShareTypeHeight
        anchors.topMargin: 0
        sourceComponent: Zpath.selectedShared ? idCompShareType : null
    }
    Component {
        id: idCompShareType
        RowLayout {
            anchors.fill: parent
            spacing: 0
            MyRadioButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("Shared")
                gChecked: true
                bLeftButton: true
                padding: 0
                onAcceptClicked: {
                    idRoot.shareTypeOthers(true)
                }
            }
            MyRadioButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                btnText: qsTr("My Shared")
                bRightButton: true
                padding: 0
                onAcceptClicked: {
                    idRoot.shareTypeOthers(false)
                }
            }
        }
    }

    function shareTypeOthers(bShareTypeOthers) {
        Zpath.shareTypeOthers = bShareTypeOthers
        idRoot.gDbFilesCpp.sendChangeSignal()
    }
    // ==================================================================================
}
