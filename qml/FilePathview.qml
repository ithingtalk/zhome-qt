pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "Global"
import "global.js" as Logic

ToolBar {
    id: idRoot

    property int pmTrashEntryCount: 0
    function updateToolbarTrashCount() {
        var n = 0
        if (Zpath.selectedMyFiles)
            n += Zpath.dbFilesPrivateCpp.trashItemCount()
        if (Zpath.selectedShared)
            n += Zpath.dbFilesSharedCpp.trashItemCount()
        idRoot.pmTrashEntryCount = n
    }

    Connections {
        target: Zpath.dbFilesPrivateCpp
        function onDataChanged() { idRoot.updateToolbarTrashCount() }
    }
    Connections {
        target: Zpath.dbFilesSharedCpp
        function onDataChanged() { idRoot.updateToolbarTrashCount() }
    }
    Connections {
        target: Zpath
        function onPp_selectedIndexChanged() { idRoot.updateToolbarTrashCount() }
    }
    Component.onCompleted: idRoot.updateToolbarTrashCount()

    background: Rectangle {
        color: Global.toolbarBgColor
    }

    function backFunc() {
        if (Zpath.isUserDirOrFile && Zpath.pp_subdirItems.length > 1) {
            Zpath.popSubdir()
        }
        else {
            Global.popStackviewPage()
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: idToolbarTitle.right
        height: parent.height
        anchors.margins: 0

        ToolButton {
            id: idBack
            anchors.left: parent.left
            height: parent.height - 16
            anchors.verticalCenter: parent.verticalCenter
            width: height
            icon.height: height
            icon.width: height / 2
            icon.source: "../icons/fontawesome/svgs/solid/chevron-left.svg"
            icon.color: Global.iconColor
            display: AbstractButton.IconOnly
            onClicked: {
                idRoot.backFunc()
            }
        }

        Text {
            id: idLastSubdir
            anchors.left: idBack.right
            width: idToolbarTitle.x - x
            anchors.verticalCenter: parent.verticalCenter
            text: Zpath.pp_subdirItems.length > 1 ? Zpath.pp_subdirItems[Zpath.pp_subdirItems.length - 1] : ""
            elide: Text.ElideMiddle
            color: Global.iconColor
            font.pixelSize: Global.fontSizeTitle
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    idRoot.backFunc()
                }
            }
        }
    }

    Text {
        id: idToolbarTitle
        anchors.centerIn: parent
        text: Zpath.fileTitle
        font.pixelSize: Global.fontSizeTitle
        color: palette.text
    }

    Row { // toolbutton
        id: idToolsRight
        visible: Zpath.selectedMyFiles || Zpath.selectedShared || Zpath.selectedTrash
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        // edit mode =======================================================
        CheckBox {
            id: idSelectAll
            text: qsTr("select all")
            visible: Zpath.editMode && (Zpath.isUserDirOrFile || Zpath.selectedTrash)
            checked: Zpath.selectedShared ? Zpath.dbFilesSharedCpp.getSelectAll() : Zpath.dbFilesPrivateCpp.getSelectAll()
            height: parent.height - 8
            anchors.verticalCenter: parent.verticalCenter
            onToggled: {
                var dbFilesCpp = Zpath.selectedShared ? Zpath.dbFilesSharedCpp : Zpath.dbFilesPrivateCpp
                dbFilesCpp.setSelectAll(checked)
            }
        }

        MyToolButton {
            id: idSelectAllCancel
            gText: qsTr("Cancel")
            gVisible: Zpath.editMode && (Zpath.isUserDirOrFile || Zpath.selectedTrash)
            gIcon: "../icons/ionicons/swap-vertical.svg"
            gSize: parent.height - 8
            gTipText: qsTr("Cancel edit")
            gDisplay: AbstractButton.TextOnly
            onToolButtonClicked: {
                Zpath.exitEditMode()
            }
        }
        // ===================================================================

        // moving file =======================================================
        MyToolButton {
            id: idMovingPaste
            gText: qsTr("Paste")
            gVisible: Zpath.movingMode && Zpath.moveFilePathFrom !== Zpath.currentFileDirWithoutFirstChar() && (Zpath.isUserDirOrFile)
            gIcon: "../icons/ionicons/refresh.svg"
            gSize: parent.height - 8
            gTipText: qsTr("Move file to here")
            gDisplay: AbstractButton.TextOnly
            onToolButtonClicked: {
                if (Zpath.movingFiles.length > 0) {
                    Logic.moveFiles(Zpath.movingFiles, Zpath.currentFileDirWithoutFirstChar())
                }
                Zpath.exitMovingMode()
            }
        }

        MyToolButton {
            id: idMovingCancel
            gText: qsTr("Cancel")
            gVisible: Zpath.movingMode && (Zpath.isUserDirOrFile)
            gIcon: "../icons/ionicons/swap-vertical.svg"
            gSize: parent.height - 8
            gTipText: qsTr("Cancel move")
            gDisplay: AbstractButton.TextOnly
            onToolButtonClicked: {
                Zpath.exitMovingMode()
            }
        }
        // ===================================================================

        /*MyToolButton {
            id: idPlay
            gText: qsTr("Play")
            gVisible: Zpath.normalMode && (Zpath.selectedMyFiles || Zpath.selectedShared) && Zpath.isUserDirOrFile && Zpath.selectedDocAudio && !idSearch.gSearching
            gIcon: "../icons/ionicons/play.svg"
            gSize: parent.height - 8
            gTipText: qsTr("Play")
            onToolButtonClicked: {
                Zpath.playAudioFiles()
            }
        }*/

        MyToolButton {
            id: idSharedRefresh
            gText: qsTr("Refresh")
            gVisible: Zpath.normalMode && Zpath.selectedShared && !Zpath.editMode && !Zpath.movingMode
            gIcon: "../icons/ionicons/refresh.svg"
            gSize: parent.height - 8
            gTipText: qsTr("Reload shared database")
            gDisplay: AbstractButton.IconOnly
            onToolButtonClicked: {
                Zpath.dbFilesSharedCpp.updateDbFile(true)
            }
        }

        ToolButton {
            id: idRecycleBinEntry
            visible: Zpath.normalMode && (Zpath.selectedMyFiles || Zpath.selectedShared) && !Zpath.selectedTrash
                    && idRoot.pmTrashEntryCount > 0
            height: parent.height - 8
            anchors.verticalCenter: parent.verticalCenter
            width: height
            icon.height: height - 10
            icon.width: height - 10
            icon.source: "../icons/fontawesome/svgs/solid/recycle.svg"
            icon.color: Global.iconColor
            display: AbstractButton.IconOnly
            padding: 0
            onClicked: Zpath.openRecycleBin()
        }

        ToolButton {
            id: idMore
            visible: Zpath.normalMode && (Zpath.selectedMyFiles || Zpath.selectedShared)
            height: parent.height - 8
            anchors.verticalCenter: parent.verticalCenter
            width: height
            icon.height: height - 10
            icon.width: height - 10
            icon.source: "../icons/ionicons/add.svg"
            icon.color:  Global.iconColor
            display: AbstractButton.IconOnly
            padding: 0
            onClicked: {
                idRoot.showPopup()
            }
            states: [
                State {
                    when: Zpath.selectedShared
                    PropertyChanges {
                        idMore.icon.height: Global.toolbarIconSize - 4
                        idMore.icon.width: Global.toolbarIconSize - 4
                        idMore.icon.source: "../icons/ionicons/ellipsis-vertical.svg"
                    }
                },
                State {
                    when: !Zpath.isUserDirOrFile
                    PropertyChanges {
                        idMore.visible: true
                        idMore.icon.height: Global.toolbarIconSize - 4
                        idMore.icon.width: Global.toolbarIconSize - 4
                        idMore.icon.source: "../icons/ionicons/options.svg"
                    }
                }
            ]
        }
    }

    states: [
        State {
            when: idSearch.gSearching
            PropertyChanges {
                // idPlay.gVisible: false
                idToolbarTitle.visible: false
                idLastSubdir.visible: false
            }
        }
    ]

    // search files ======================================================
    MySearch {
        id: idSearch
        anchors.fill: parent
        anchors.leftMargin: idBack.width
        anchors.rightMargin: (idMore.visible ? idMore.width : 0) + (idSharedRefresh.visible ? idSharedRefresh.width : 0)
            + (idRecycleBinEntry.visible ? idRecycleBinEntry.width : 0)
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        gHideSearchText: true
        onSearchFile: {
            Zpath.sendChangeSignal()
        }
    }
    // ===================================================================

    Row {
        id: idBtToolbarMore
        visible: Zpath.selectedOfflineDownload
        anchors.right: parent.right
        height: parent.height
        spacing: 0

        MyToolButton {
            id: idBtAddNew
            gText: qsTr("Add")
            icon.source: "../icons/ionicons/add.svg"
            gSize: parent.height - 8
            gDisplay: AbstractButton.IconOnly
            onToolButtonClicked: {
                idDialogInputBtUrl.open()
            }
            AddBtDialog {
                id: idDialogInputBtUrl
                onAddUrl: function(strUrl) {
                    console.log("Add BT Url: " + strUrl)
                    Logic.sendCmdAddBt(strUrl)
                }
                onAddFile: function(filePath) {
                    console.log("Add BT File: " + filePath)
                    Logic.uploadBtFile(filePath)
                }
            }
        }
    }

    Row {
        id: idBtDownloaded
        visible: Zpath.selectedOfflineDownloaded
        anchors.right: parent.right
        height: parent.height
        spacing: 0

        MyToolButton {
            gText: qsTr("Refresh")
            icon.source: "../icons/ionicons/refresh.svg"
            gSize: parent.height - 8
            gDisplay: AbstractButton.IconOnly
            onToolButtonClicked: {
                Logic.sendCmdGetBtFiles()
            }
        }
    }

    function uploadFiles() {
        if (Global.isIos) {
            Global.iosUtilsCpp?.uploadFiles(Zpath.getSelectedFileType(), Zpath.currentFileDir())
        }
        else if (Global.isAndroid) {
            Global.androidUtilsCpp?.uploadFiles(Zpath.getSelectedFileType(), Zpath.currentFileDir())
        }
        else { // pc
            idUploadFileDialog.open()
        }
    }

    FileDialog {
        id: idUploadFileDialog
        title: qsTr("Select Files to upload")
        // nameFilters: ["All Files (*)", "Text Files (*.txt)", "Images (*.png *.jpg *.jpeg)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: { // selectedFiles, selectedFile
            Logic.uploadFiles(selectedFiles)
        }
    }

    function showPopup() {
        var menus = []
        if (Zpath.hasAudioFile()) {
            menus.push( { iconSrc: "../icons/ionicons/play.svg", itemText: qsTr("Play All"), actionStr: "actionPlayAll" } )
            menus.push( { iconSrc: "", itemText: "", actionStr: "" } )
        }
        if (Zpath.selectedMyFiles && Zpath.isUserDirOrFile) {
            menus.push( { iconSrc: "../icons/ionicons/arrow-up.svg", itemText: qsTr("Upload files"), actionStr: "actionUploadFiles" } )
            menus.push( { iconSrc: "../icons/ionicons/bag-add-outline.svg", itemText: qsTr("Create new folder"), actionStr: "actionNewFolder" } )
            menus.push( { iconSrc: "../icons/fontawesome/svgs/solid/database.svg", itemText: qsTr("Rebuild database"), actionStr: "actionRebuildDatabase" } )
            menus.push( { iconSrc: "", itemText: "", actionStr: "" } )
        }
        if (Zpath.isUserDirOrFile) {
            // menus.push( { iconSrc: "../icons/ionicons/refresh.svg", itemText: qsTr("Refresh"), actionStr: "actionRefresh" } )
            // menus.push( { iconSrc: "", itemText: "", actionStr: "" } )
            menus.push( { iconSrc: "../icons/ionicons/swap-vertical.svg", itemText: qsTr("Transfering"), actionStr: "actionTransfering" } )
            menus.push( { iconSrc: "", itemText: "", actionStr: "" } )
            // menus.push( { iconSrc: "../icons/fontawesome/svgs/solid/trash-can.svg", itemText: qsTr("Clean Cache"), actionStr: "actionCleanCache" } )
            // menus.push( { iconSrc: "", itemText: "", actionStr: "" } )
        }
        menus.push( { iconSrc: "../icons/fontawesome/svgs/solid/list.svg", itemText: qsTr("List view"), actionStr: "actionSetListTypeList" } )
        menus.push( { iconSrc: "../icons/fontawesome/svgs/solid/icons.svg", itemText: qsTr("Icon view"), actionStr: "actionSetListTypeIcon" } )
        idPopupMore.gModel = menus
        idPopupMore.open()
    }

    MyPopup {
        id: idPopupMore
        x: idRoot.width - implicitWidth - 5
        y: Global.idWindow.SafeArea.margins.top + idRoot.height
        gModel: []
        onClickFunc: function(actionStr) {
            idRoot.popupActions(actionStr)
        }
    }

    function popupActions(actionStr) {
        switch (actionStr) {
            case "actionNewFolder":
                idDialogInputNewFolderName.open()
                break;
            case "actionUploadFiles":
                uploadFiles()
                break;
            case "actionRebuildDatabase":
                Global.cmdServiceDbFilesCpp.send(Global.nasApiCpp.repairUserDatabase(Zpath.currentFileDirWithoutFirstChar()))
                break;
            case "actionTransfering":
                Global.idStack.push("FileTransfer.qml")
                break;
            case "actionRefresh":
                var dbFilesCpp = Zpath.selectedShared ? Zpath.dbFilesSharedCpp : Zpath.dbFilesPrivateCpp
                dbFilesCpp.updateDbFile(true)
                break;
            case "actionSetListTypeList":
                Zpath.dbFilesPrivateCpp.setDisplayType(0)
                break;
            case "actionSetListTypeIcon":
                Zpath.dbFilesPrivateCpp.setDisplayType(1)
                break;
            case "actionCleanCache":
                Global.utilsCpp.delCache()
                break;
            case "actionPlayAll":
                Zpath.playAudioFiles()
                break;
            default:
                console.log("Unknown action:", actionStr)
        }
    }

    ConfirmDialog {
        id: idDialogInputNewFolderName
        gTitle: qsTr("Create new folder")
        gInitTextValue: qsTr("new folder")
        hasInputTextEdit: true
        onAcceptClickedWithResult: function(new_folder_name) {
            Logic.createNewFolder(Zpath.currentFileDirWithoutFirstChar(), new_folder_name)
        }
    }
}
