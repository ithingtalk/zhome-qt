import QtQuick
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Rectangle {
    id: idRoot
    color: Global.toolbarBgColor
    visible: Zpath.selectedTrash && Zpath.pp_hasFileList
    
    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: Global.bottomPad
        spacing: 0
        
        MyBottomButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: qsTr("Restore")
            gIconSrc: "../icons/fontawesome/svgs/solid/window-restore.svg"
            textColor: Global.iconColor
            onAcceptClicked: {
                if (Zpath.editMode) {
                    Logic.recoverFiles(Zpath.getSelectedFilesPath())
                }
                else {
                    Logic.recoverFiles(Zpath.getAllFilesPath())
                }
                Zpath.exitEditMode()
            }
        }
        
        MyBottomButton {
            Layout.fillWidth: true
            Layout.fillHeight: true
            btnText: Zpath.editMode ? qsTr("Delete") : qsTr("Empty")
            gIconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg"
            textColor: "tomato"
            onAcceptClicked: {
                if (Zpath.editMode) {
                    idDialogConfirmDelete.gStrMsg = idRoot.deleteConfirmMsg + "\n" + Zpath.printSelectedFiles()
                    idDialogConfirmDelete.open()
                }
                else {
                    idDialogConfirmEmpty.gStrMsg = idRoot.deleteConfirmMsg + "\n" + Zpath.printRecycleBinFiles()
                    idDialogConfirmEmpty.open()
                }
            }
        }
    }

    property string deleteConfirmMsg: qsTr("Permanently deleting these files from the recycle bin, and they cannot be restored!")

    ConfirmDialog {
        id: idDialogConfirmDelete
        gTitle: qsTr("Delete")
        confirmButtonText: qsTr("Delete")
        confirmButtonColor: "tomato"
        onAcceptClicked: function() {
            Logic.deleteFiles(Zpath.getSelectedFilesPath());
            Zpath.exitEditMode()
        }
    }    

    ConfirmDialog {
        id: idDialogConfirmEmpty
        gTitle: qsTr("Empty")
        confirmButtonText: qsTr("Empty")
        confirmButtonColor: "tomato"
        onAcceptClicked: function() {
            Logic.deleteFiles(Zpath.getAllFilesPath());
            Zpath.exitEditMode()
        }
    }
}
