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

    GridView {
        id: idList
        anchors.fill: parent
        anchors.topMargin: idShareType.gShareTypeHeight + 4
        anchors.leftMargin: idList.itemAdd / 2
        anchors.rightMargin: idList.itemAdd / 2
        anchors.bottomMargin: 0
        cellWidth: Global.cellSize
        cellHeight: Global.cellSize
        clip: true
        model: ListModel {}

        property int itemNum: idRoot.width / Global.cellSize
        property real itemAdd: idRoot.width % Global.cellSize

        delegate: ItemDelegate {
            id: idItem
            width: idList.cellWidth - 8
            height: idList.cellHeight - 8
            focusPolicy: Qt.ClickFocus
            highlighted: idItem.GridView.view.currentIndex === idItem.index
            padding: 0

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

            background: Rectangle {
                id: idBg
                anchors.fill: parent
                anchors.margins: 8
                radius: 20
                color: palette.base
            }

            Item {
                id: idContent
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8

                CheckBox {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 0
                    visible: Zpath.editMode
                    checkable: false
                    checked: Zpath.isFileSelected(idItem.filepath)
                }

                Loader {
                    id: idImage
                    anchors.top: parent.top
                    anchors.margins: 0
                    width: parent.width
                    height: Global.cellSize - 80
                    sourceComponent: hasImageCache ? idImageImage : idImageButton
                }

                Component {
                    id: idImageButton
                    Button {
                        icon.source: idItem.iconSrc
                        icon.height: Layout.preferredHeight
                        icon.width: Layout.preferredHeight
                        icon.color: Global.iconColor
                        display: AbstractButton.IconOnly
                        background: null
                        padding: 0
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

                Text {
                    id: idDisplayName
                    text: Zpath.isUserDirOrFile ? idItem.filedisplay : (Zpath.getDisplayName(idItem.filedisplay))
                    color: palette.text
                    font.pixelSize: Global.fontSize
                    anchors.top: idImage.bottom
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 0
                    bottomPadding: 0
                }

                states: [
                    State {
                        when: Zpath.searchMode
                        PropertyChanges {
                            idDisplayName.text: idItem.filedisplay
                        }
                    }
                ]
            }

            MouseArea {
                id: idMouseer
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton                
                onClicked: {
                    idItem.checkItem()
                }

                onPressAndHold: {
                    idItem.intoEditMode()
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    idItem.highlightItem()
                    let globalPos = mapToGlobal(mouse.x, mouse.y)
                    let windowRelativePos = Qt.point(globalPos.x - Global.idWindow.x, globalPos.y - Global.idWindow.y)
                    idItem.showMenu(windowRelativePos)
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
                        // Open immediately — do not set GridView.currentIndex (that
                        // highlights the cell as "selected" before PlayPage appears).
                        Logic.openFile(idItem.filepath, idItem.isdir)
                    } else {
                        idItem.GridView.view.currentIndex = idItem.index
                    }
                }
            }

            function onAction(actionStr) {
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

            function showMenu(ms) {
                var menus = []
                if (Zpath.selectedMyFiles && Zpath.isUserDirOrFile) {
                    menus.push( { iconSrc: "", itemText: qsTr("Rename"), actionStr: "actionRename" } )
                }
                if (Zpath.selectedMyFiles && Zpath.isUserDirOrFile) {
                    menus.push( { iconSrc: "", itemText: qsTr("Move"), actionStr: "actionMove" } )
                }
                if (Zpath.selectedMyFiles && Zpath.isUserDirOrFile) {
                    menus.push( { iconSrc: "", itemText: qsTr("Share"), actionStr: "actionShare" } )
                }
                if (Zpath.isUserDirOrFile && !Zpath.selectedFilesHasDir && !idItem.isdir) {
                    menus.push( { iconSrc: "", itemText: qsTr("Download"), actionStr: "actionDownload" } )
                }
                if (Zpath.selectedShared && !Zpath.shareTypeOthers) {
                    menus.push( { iconSrc: "", itemText: qsTr("Remove share"), actionStr: "actionRemoveShare" } )
                }
                if (Zpath.selectedMyFiles && Zpath.isUserDirOrFile) {
                    menus.push( { iconSrc: "", itemText: qsTr("Remove"), actionStr: "actionMoveToTrash" } )
                }
                if (Zpath.selectedTrash) {
                    menus.push( { iconSrc: "", itemText: qsTr("Delete"), actionStr: "actionDelete" } )
                }
                if (Zpath.selectedTrash) {
                    menus.push( { iconSrc: "", itemText: qsTr("Recover"), actionStr: "actionRecover" } )
                }
                if (menus.length > 0) {
                    idPopupMore.gModel = menus
                    popupX = ms.x
                    popupY = ms.y
                    idPopupMore.open()
                }
            }

            property real popupX: 0
            property real popupY: 0

            MyPopup {
                id: idPopupMore
                x: Math.min(idItem.popupX, Global.idWindow.width - implicitWidth - 5)
                y: Math.min(idItem.popupY, Global.idWindow.height - implicitHeight - 5)
                gModel: []
                onClickFunc: function(actionStr) {
                    idItem.onAction(actionStr)
                }
            }

            states: [
                State {
                    when: Global.isDesktop && Zpath.isFileSelected(idItem.filepath)
                    PropertyChanges {
                        idBg.color: palette.highlight
                    }
                },
                State {
                    when: Global.isDesktop && idMouseer.pressed && !Zpath.isFileSelected(idItem.filepath)
                    PropertyChanges {
                        idBg.color: Global.bgColor2
                    }
                }
            ]
        }
    }
}
