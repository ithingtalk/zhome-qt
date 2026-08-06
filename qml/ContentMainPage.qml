pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property int gListItemHeight: 60
    property int gMarginInner: 8
    property int gMarginOuter: 16
    property int gMarginPageLeftRight: 10
    property int gMarginTextLeft: 20
    property int gImageNum: 0
    property int gVideoNum: 0
    property int gAudioNum: 0
    property int gDocNum: 0

    ZhomeToolbar {
        id: idToolbar
        winTitle: Global.currDevice.name
        onBackFunc: function () {
            Global.popStackviewPage()
        }
        menuModel: ListModel {
            ListElement { iconSrc: "../icons/fontawesome/svgs/solid/display.svg"; itemText: qsTr("出示设备二维码"); actionStr: "actionShowDeviceQr" }
            ListElement { iconSrc: "../icons/fontawesome/svgs/solid/tablet-button.svg"; itemText: qsTr("Device manage"); actionStr: "actionDeviceManage" }
            ListElement { iconSrc: "../icons/fontawesome/svgs/solid/database.svg"; itemText: qsTr("Rebuild database"); actionStr: "actionRepairFileDb" }
        }
        onClickFunc: function(actionStr) {
            switch (actionStr) {
                case "actionShowDeviceQr":
                    // 与 Android 一致：zh2: + JSON 全量设备信息，对方 App 扫码直接入库。
                    Global.idStack.push("Qrcode.qml", null, StackView.Immediate)
                    break
                case "actionDeviceManage":
                    Global.idStack.push("DeviceManagmentPage.qml")
                    break
                case "actionRepairFileDb":
                    // NAS: repair file.db for current folder (e.g. MyFiles/Video), same as file browser overflow menu
                    Global.cmdServiceDbFilesCpp.send(Global.nasApiCpp.repairUserDatabase(Zpath.currentFileDirWithoutFirstChar()))
                    break
                default:
                    console.log("Unknown action:", actionStr)
            }
        }
    }

    Rectangle {
        anchors.top: idToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: (Global.isWindows) && Global.isDarkTheme ? palette.window : palette.base

        Flickable {
            id: idContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 0
            contentHeight: implicitHeight

            Rectangle {
                id: idLogo
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 100
                anchors.margins: idRoot.gMarginPageLeftRight
                radius: 8
                color: Global.iconColor

                Text {
                    text: Global.localAccountCpp.getUser()
                    verticalAlignment: Text.AlignVCenter
                    color: palette.text
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: idRoot.gMarginOuter
                }

                Button {
                    icon.source: "../icons/logo.png"
                    icon.width: 48
                    icon.height: 48
                    icon.color: "red"
                    background: null
                    anchors.right: parent.right
                    anchors.rightMargin: idRoot.gMarginInner
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: idFunctionList
                text: qsTr("Function List")
                anchors.top: idLogo.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: idRoot.gMarginOuter
                anchors.bottomMargin: 0
                anchors.leftMargin: idRoot.gMarginTextLeft
                anchors.rightMargin: idRoot.gMarginPageLeftRight
                font.pixelSize: Global.fontSize
                color: palette.text
            }

            ListView {
                id: idListTools
                anchors.top: idFunctionList.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: idRoot.gMarginInner
                anchors.bottomMargin: 0
                anchors.leftMargin: idRoot.gMarginPageLeftRight
                anchors.rightMargin: idRoot.gMarginPageLeftRight
                height: idRoot.gListItemHeight + 8
                orientation: ListView.Horizontal
                spacing: idRoot.gMarginInner
                model: ListModel {}

                delegate: Rectangle {
                    id: idItemTools
                    width: 180
                    height: ListView.view.height
                    color: Global.bgColor
                    radius: 8

                    required property var index
                    required property string iconSrc
                    required property string itemText
                    required property string actionStr

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Button {
                            icon.source: idItemTools.iconSrc
                            icon.width: 24
                            icon.height: 24
                            height: 24
                            width: 24
                            icon.color: Global.iconColor
                            display: Button.IconOnly
                            background: null
                            anchors.verticalCenter: parent.verticalCenter
                            padding: 0
                        }

                        Text {
                            text: idItemTools.itemText
                            font.pixelSize: Global.fontSize
                            color: palette.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: idMouserFunctions
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("Clicked on:", parent.actionStr)
                            Zpath.treeItemChanged(idItemTools.actionStr)
                            Global.idStack.push("FilePage.qml")
                        }
                    }

                    states: [
                        State {
                            when: idMouserFunctions.pressed
                            PropertyChanges {
                                idItemTools.color: Global.bgColor2
                            }
                        }
                    ]
                }
            }

            Rectangle {
                id: idTextMyFiles
                anchors.top: idListTools.bottom
                anchors.topMargin: idRoot.gMarginOuter
                anchors.bottomMargin: 0
                anchors.left: parent.left
                anchors.right: parent.right
                height: Global.toolbarIconSize
                color: "transparent"

                Text {
                    id: idMyDoc
                    text: qsTr("My Documents")
                    leftPadding: idRoot.gMarginTextLeft
                    rightPadding: idRoot.gMarginInner
                    bottomPadding: 0
                    topPadding: 0
                    font.pixelSize: Global.fontSize
                    color: palette.text
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    anchors.left: parent.left
                    anchors.margins: 0
                }

                Button {
                    id: idRefresh
                    icon.source: "../icons/ionicons/refresh.svg"
                    icon.width: parent.height
                    icon.height: parent.height
                    icon.color: Global.iconColor
                    background: null
                    padding: 0
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: idMyDoc.right
                    onClicked: {
                        console.log("refresh")
                        Zpath.dbFilesPrivateCpp.updateDbFile(true)
                    }
                }

                MySearch {
                    id: idMySearch
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.left: idRefresh.right
                    gHideSearchText: true
                    onSearchFile: {
                        Zpath.sendChangeSignal()
                    }
                }
            }

            ListView {
                id: idListMyFiles
                anchors.top: idTextMyFiles.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: idRoot.gMarginInner
                anchors.bottomMargin: 0
                anchors.leftMargin: idRoot.gMarginPageLeftRight
                anchors.rightMargin: idRoot.gMarginPageLeftRight
                spacing: idRoot.gMarginInner
                height: idRoot.gListItemHeight * 4 + 24
                interactive: false

                model: ListModel {}

                delegate: ItemDelegate {
                    id: idItem
                    width: ListView.view.width
                    height: idRoot.gListItemHeight
                    leftPadding: 0
                    rightPadding: 0
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

                    background: Rectangle {
                        id: idBgMyFiles
                        color: Global.bgColor
                        radius: 8
                    }

                    contentItem: RowLayout {
                        spacing: 0

                        Button {
                            icon.source: Zpath.getDefaultFileIcon(idItem.filepath)
                            icon.width: 24
                            icon.height: 24
                            icon.color: Global.iconColor
                            display: Button.IconOnly
                            background: null
                            padding: 0
                            Layout.leftMargin: idRoot.gMarginInner
                        }

                        Text {
                            text: Zpath.getDisplayName(idItem.filedisplay)
                            font.pixelSize: Global.fontSize
                            color: palette.text
                            verticalAlignment: Text.AlignVCenter
                            Layout.leftMargin: idRoot.gMarginInner
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: idItem.filesize
                            font.pixelSize: Global.fontSize
                            color: palette.text
                            verticalAlignment: Text.AlignVCenter
                        }

                        Button {
                            icon.source: "../icons/ionicons/chevron-forward.svg"
                            icon.width: 12
                            icon.height: 12
                            Layout.preferredHeight: 12
                            Layout.preferredWidth: 12
                            icon.color: Global.bgColor3
                            display: Button.IconOnly
                            background: null
                            padding: 0
                            Layout.rightMargin: idRoot.gMarginInner
                        }
                    }

                    MouseArea {
                        id: idMouserMyFiles
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("Clicked on:", idItem.filedisplay)
                            idItem.ListView.view.currentIndex = idItem.index
                            Zpath.treeItemChanged(0, idItem.filepath.replace("/MyFiles", ""))
                            Global.idStack.push("FilePage.qml")
                        }
                    }

                    states: [
                        State {
                            when: idMouserMyFiles.pressed
                            PropertyChanges {
                                idBgMyFiles.color: Global.bgColor2
                            }
                        }
                    ]
                }
            }

            Text {
                id: idTextGame
                text: qsTr("Small Game")
                anchors.top: idListMyFiles.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: idRoot.gMarginOuter
                anchors.bottomMargin: 0
                anchors.leftMargin: idRoot.gMarginTextLeft
                anchors.rightMargin: idRoot.gMarginPageLeftRight
                font.pixelSize: Global.fontSize
                color: palette.text

                visible: false
            }

            Rectangle {
                id: idGame
                anchors.top: idTextGame.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: idRoot.gMarginInner
                anchors.bottomMargin: Global.bottomPad + 10
                anchors.leftMargin: idRoot.gMarginPageLeftRight
                anchors.rightMargin: idRoot.gMarginPageLeftRight
                height: idRoot.gListItemHeight
                color: Global.bgColor
                radius: 8

                visible: false

                RowLayout {
                    id: idGameContent
                    anchors.fill: parent
                    Button {
                        icon.source: "../icons/ionicons/game-controller-outline.svg"
                        icon.width: 24
                        icon.height: 24
                        icon.color: Global.iconColor
                        display: Button.IconOnly
                        background: null
                        padding: 0
                        Layout.leftMargin: idRoot.gMarginInner
                    }

                    Text {
                        text: qsTr("Small Game")
                        font.pixelSize: Global.fontSize
                        color: palette.text
                        verticalAlignment: Text.AlignVCenter
                        Layout.leftMargin: idRoot.gMarginInner
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        icon.source: "../icons/ionicons/chevron-forward.svg"
                        icon.width: 12
                        icon.height: 12
                        Layout.preferredHeight: 12
                        Layout.preferredWidth: 12
                        icon.color: Global.bgColor3
                        display: Button.IconOnly
                        background: null
                        padding: 0
                        Layout.rightMargin: idRoot.gMarginInner
                    }
                }

                MouseArea {
                    id: idMouserSmallGame
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Clicked on: small game")
                        Global.idStack.push("../../SameGameModule/Main.qml")
                    }
                }

                states: [
                    State {
                        when: idMouserSmallGame.pressed
                        PropertyChanges {
                            idGame.color: Global.bgColor2
                        }
                    }
                ]
            }
        }
    }

    function updateMyFilesList() {
        // console.log("Contentmainpage.qml: update file list")
        idListMyFiles.model = Zpath.dbFilesPrivateCpp.myFiles(Zpath.getFilesFilter)
    }

    Connections {
        target: Zpath.dbFilesPrivateCpp
        function onDataChanged() {
            // console.log("Contentmainpage.qml: ondatachanged")
            idRoot.updateMyFilesList()
        }
    }

    Component.onCompleted: {
        Global.idWindow.title = " "
        idListTools.model = Zpath.mainPageToolsModel()
        Zpath.getFilesFilter = ""
        idRoot.updateMyFilesList()
    }
}
