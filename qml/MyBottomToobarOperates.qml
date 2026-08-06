import QtQuick
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Rectangle {
    id: idRoot
    color: Global.toolbarBgColor
    visible: Zpath.selectedFileCount > 0 && Zpath.editMode && !Zpath.selectedTrash && (!Zpath.selectedFilesHasDir || Zpath.selectedMyFiles || Zpath.selectedShared && !Zpath.shareTypeOthers)

    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: Global.bottomPad
        spacing: 0

        MyBottomButton {
            visible: Zpath.selectedMyFiles
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Remove")
            gIconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg"
            textColor: "tomato"
            onAcceptClicked: {
                Logic.removeFiles(Zpath.getSelectedFilesPath())
                Zpath.exitEditMode()
            }
        }

        MyBottomButton {
            visible: !Zpath.selectedFilesHasDir && Zpath.selectedMyFiles
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Move")
            gIconSrc: "../icons/ionicons/move.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                Zpath.moveFilePathFrom = Zpath.currentFileDirWithoutFirstChar()
                Zpath.saveMovingFiles()
                Zpath.exitEditMode()
            }
        }

        MyBottomButton {
            visible: Zpath.selectedMyFiles && ( Zpath.selectedFileCount === 1 )
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Rename")
            gIconSrc: "../icons/fontawesome/svgs/solid/pencil.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                console.log("rename: " + Zpath.currentFileDirWithoutFirstChar() + " / " + Logic.getFileName(Zpath.selectedRemotePath()))
                idDialogFileRename.gInitTextValue = Logic.getFileName(Zpath.selectedRemotePath())
                idDialogFileRename.open()
                // Zpath.exitEditMode()
            }
            ConfirmDialog {
                id: idDialogFileRename
                gTitle: qsTr("Rename file")
                gInitTextValue: Logic.getFileName(Zpath.selectedRemotePath())
                hasInputTextEdit: true
                onAcceptClickedWithResult: function(new_name_ret) {
                    var old_name = Zpath.currentFileDirWithoutFirstChar() + "/" + Logic.getFileName(Zpath.selectedRemotePath())
                    var new_name = Zpath.currentFileDirWithoutFirstChar() + "/" + new_name_ret
                    console.log("file rename from: " + old_name + " to " + new_name)
                    Logic.fileRename(old_name, new_name)
                }
            }
        }

        MyBottomButton {
            visible: !Zpath.selectedFilesHasDir
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Download")
            gIconSrc: "../icons/ionicons/download-outline.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                Logic.downloadFiles(Zpath.getSelectedFilesPath())
                Zpath.exitEditMode()
            }
        }

        MyBottomButton {
            id: idRemoveShare
            visible:  Zpath.selectedShared && !Zpath.shareTypeOthers
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Remove share")
            gIconSrc: "../icons/ionicons/share-social-outline.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                Logic.deleteShared(Zpath.getSharedSelectedFilesPath())
                Zpath.exitEditMode()
            }
        }

        MyBottomButton {
            visible:  Zpath.selectedMyFiles
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Share")
            gIconSrc: "../icons/ionicons/share-social.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                Logic.shareFiles(Zpath.getSharedSelectedFilesPath())
                Zpath.exitEditMode()
            }
        }
    }
}
