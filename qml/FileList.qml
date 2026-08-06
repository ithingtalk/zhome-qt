pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Rectangle {
    id: idRoot
    color: palette.base

    property var dbFilesCpp: Zpath.dbFilesPrivateCpp

    Connections {
        target: idRoot.dbFilesCpp
        function onDataChanged() {
            idList.model = Logic.getFiles()
        }
        Component.onCompleted: {
            idList.model = Logic.getFiles()
            idRoot.dbFilesCpp.updateDbFile()
        }
        function onDbFileDownloadSuccess() {
            idList.model = Logic.getFiles()
            Zpath.gotoInitPage()
        }
        function onSelectAllChanged() {
            Zpath.selectAll(idRoot.dbFilesCpp.getSelectAll())
            idList.model = Zpath.fileList
        }
    }

    FileDropArea {
        id: idShareType
        anchors.fill: parent
        gShareTypeHeight: Zpath.selectedShared ? 40 : 0
        gDbFilesCpp: idRoot.dbFilesCpp
    }

    RoundButton {
        id: idRefresh
        text: qsTr("Folder is Empty")
        anchors.centerIn: parent
        visible: idList.model.length === 0
        display: Button.TextUnderIcon
        icon.source: "../icons/ionicons/refresh.svg"
        icon.height: 96
        icon.width: 96
        icon.color: Global.iconColor
        background: null
        z: 9
        MouseArea {
            id: idMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                console.log("refresh")
                var dbFilesCpp = Zpath.selectedShared ? Zpath.dbFilesSharedCpp : Zpath.dbFilesPrivateCpp
                dbFilesCpp.updateDbFile(true)
            }
        }
        states: [
            State {
                when: idMouseArea.pressed
                PropertyChanges {
                    idRefresh.icon.color: Global.bgColor3
                }
            }
        ]
    }

    ListView {
        id: idList
        anchors.fill: parent
        anchors.topMargin: idShareType.gShareTypeHeight + 4
        clip: true
        model: ListModel {}

        delegate: SwipeDelegate {
            id: idItem
            width: ListView.view.width
            leftPadding: 0
            rightPadding: 0
            topPadding: Global.filelistPadding
            bottomPadding: Global.filelistPadding
            swipe.enabled: Zpath.normalMode && (Zpath.isUserDirOrFile || Zpath.selectedTrash)

            required property var index
            required property var fileuser
            required property var filepath
            required property var filesize
            required property var filedate
            required property bool isdir
            required property var filedisplay
            required property bool selected
            property string pathDir: filepath.replace("/" + filedisplay, "")
            property string iconSrc: isdir ? "../icons/ionicons/folder.svg" : Zpath.getThumbnail(filepath, filesize)
            property bool hasImageCache: !isdir && Zpath.hasImageCache(filepath, filesize)

            contentItem: RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                CheckBox {
                    id: idCheck
                    visible: Zpath.editMode
                    checkable: false
                    // Look up by filepath + selectionRevision — do not write required property `selected`
                    // (that breaks model binding and breaks after ListView recycle/scroll).
                    checked: Zpath.isFileSelected(idItem.filepath)
                    Layout.leftMargin: 10
                }

                Loader {
                    id: idImage
                    Layout.preferredHeight: 64
                    Layout.preferredWidth: 64
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    sourceComponent: idItem.hasImageCache ? idImageImage : idImageButton
                }

                Component {
                    id: idImageButton
                    Button {
                        icon.height: 64
                        icon.width: 64
                        icon.source: idItem.iconSrc
                        icon.color: Global.iconColor
                        background: null
                        Layout.leftMargin: 10
                    }
                }

                Component {
                    id: idImageImage
                    Image {
                        source: idItem.iconSrc
                        fillMode: Image.PreserveAspectFit
                        autoTransform: true
                        // Small Image look more clear
                        mipmap: true
                        // Image show more smooth
                        asynchronous: true
                        layer.enabled: true
                        layer.smooth: true
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Text {
                        id: idDisplayName
                        text: Zpath.isUserDirOrFile ? idItem.filedisplay : (Zpath.getDisplayName(idItem.filedisplay))
                        font.pixelSize: Global.fontSize
                        Layout.fillWidth: true
                        color: palette.text
                        elide: Text.ElideMiddle
                    }
                    Text {
                        visible: Zpath.searchMode && text !== ""
                        text: idItem.pathDir
                        opacity: 0.6
                        font.pixelSize: Global.fontSizeSmall3
                        color: palette.text
                    }
                    Text {
                        text: ( idItem.isdir ? idItem.filesize : idRoot.dbFilesCpp.formatFileSize(idItem.filesize) ) + " | " + Logic.formatDate(idItem.filedate)
                        opacity: 0.6
                        font.pixelSize: Global.fontSizeSmall3
                        color: palette.text
                    }
                    Text {
                        visible: Zpath.selectedShared && Zpath.shareTypeOthers
                        text: "<" + idItem.fileuser + ">"
                        opacity: 0.6
                        font.pixelSize: Global.fontSizeSmall3
                        color: palette.text
                    }
                    states: [
                        State {
                            when: Zpath.getFilesFilter !== ""
                            PropertyChanges {
                                idDisplayName.text: idItem.filedisplay
                            }
                        }
                    ]
                }

                Item { implicitWidth: 16 }
            }

            onClicked: {
                if (Zpath.editMode) {
                    // Swipe may stay non-zero on recycled delegates after scroll.
                    idItem.checkItem()
                    return
                }
                // Normal mode: always open; close leftover swipe so one click plays.
                if (idItem.swipe.position !== 0)
                    idItem.swipe.close()
                idItem.highlightItem(true)
            }

            onPressAndHold: {
                idItem.intoEditMode()
            }

            Connections {
                target: Zpath
                function onEditModeChanged() {
                    if (Zpath.editMode)
                        idItem.swipe.close()
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

            function intoEditMode() {
                if (Zpath.normalMode && Zpath.isUserDirOrFile || Zpath.selectedTrash) {
                    if (!Zpath.editMode) {
                        Zpath.enableEditMode(true)
                    }
                    // long pressed: select this file
                    idItem.selectFile()
                }
            }

            function selectFile() {
                Zpath.selectFile(idItem.filepath)
            }

            function checkItem() {
                if (Zpath.editMode) {
                    selectFile()
                }
                else {
                    idItem.highlightItem(true)
                }
            }

            function highlightItem(bOpenfile = false) {
                if (Zpath.selectedMyFiles || Zpath.selectedShared) {
                    Zpath.fileSelectedIndex = index
                    if (bOpenfile) {
                        // Open immediately — avoid currentIndex highlight before play.
                        Logic.openFile(idItem.filepath, idItem.isdir)
                    } else {
                        idItem.ListView.view.currentIndex = idItem.index
                    }
                }
            }

            function onAction(actionStr) {
                idItem.swipe.close()
                var astrFiles = []
                astrFiles.push(idItem.filepath)
                console.log(actionStr + " ==> " + idItem.filepath)
                switch(actionStr) {
                case "actionDelete":
                    Logic.deleteFiles(astrFiles);
                    break;
                case "actionRecover":
                    Logic.recoverFiles(astrFiles)
                    break;
                case "actionRename":
                    idDialogFileRename.open()
                    break;
                case "actionDownload":
                    Logic.downloadFiles(astrFiles)
                    break;
                case "actionMove":
                    Zpath.moveFilePathFrom = Zpath.currentFileDirWithoutFirstChar()
                    Zpath.movingFiles = astrFiles
                    break;
                case "actionPaste":
                    if (Zpath.movingFiles.length > 0) {
                        Logic.moveFiles(Zpath.movingFiles, Zpath.currentFileDirWithoutFirstChar())
                    }
                    break;
                case "actionMoveToTrash":
                    Logic.removeFiles(astrFiles)
                    break;
                case "actionShare":
                    Logic.shareFiles(astrFiles)
                    break;
                case "actionRemoveShare":
                    Logic.deleteShared(astrFiles)
                    break;
                case "actionEdit":
                    intoEditMode()
                    break;
                default:
                    console.log("unknown action: " + actionStr)
                    break;
                }
            }

            // selectedMyFiles ============================================================
            ConfirmDialog {
                id: idDialogFileRename
                gTitle: qsTr("Rename file")
                gInitTextValue: Logic.getFileName(idItem.filepath)
                hasInputTextEdit: true
                onAcceptClickedWithResult: function(new_name_ret) {
                    var old_name = Zpath.currentFileDirWithoutFirstChar() + "/" + Logic.getFileName(idItem.filepath)
                    var new_name = Zpath.currentFileDirWithoutFirstChar() + "/" + new_name_ret
                    console.log("file rename from: " + old_name + " to " + new_name)
                    Logic.fileRename(old_name, new_name)
                }
            }
            // ============================================================================

            Component {
                id: normalActions
                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 2

                    SwipeLabel {
                        id: idRenameLabel
                        visible: Zpath.selectedMyFiles
                        width: visible ? height + 8 : 0
                        text: qsTr("Rename")
                        bcolor: "blue"
                        actionStr: "actionRename"
                        onClicked: function(actionStr) { idItem.onAction(actionStr) }
                    }

                    SwipeLabel {
                        text: qsTr("Edit")
                        bcolor: Global.iconColor
                        width: height + 20
                        actionStr: "actionEdit"
                        onClicked: function(actionStr) { idItem.onAction(actionStr) }
                    }
                }
            }

            Component {
                id: recycleBinActions
                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 2

                    SwipeLabel {
                        id: idDeleteLabel
                        text: qsTr("Delete")
                        bcolor: "tomato"
                        actionStr: "actionDelete"
                        onClicked: function(actionStr) { idItem.onAction(actionStr) }
                    }

                    SwipeLabel {
                        id: idRecoverLabel
                        text: qsTr("Recover")
                        bcolor: "green"
                        actionStr: "actionRecover"
                        onClicked: function(actionStr) { idItem.onAction(actionStr) }
                    }
                }
            }

            swipe.right: Loader {
                anchors.right: parent?.right ?? idList.right
                height: parent?.height ?? 0
                sourceComponent: Zpath.selectedTrash ? recycleBinActions : normalActions
            }
        }
    }
}
