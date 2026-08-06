pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "Global"

ToolBar {
    id: idRoot
    anchors.top: parent.top
    width: parent.width
    height: visible ? Global.toolbarHeight : 0
    visible: !Global.isFullscreen

    background: Rectangle {
        color: Global.toolbarBgColor
    }

    property string winTitle: ""
    property var menuModel: []

    signal backFunc()
    signal clickFunc(var actionStr)

    function onClickFunc(actionStr)
    {
        clickFunc(actionStr)
    }

    Item {
        id: idToolbarRow
        anchors.fill: parent

        ToolButton {
            id: buttonBackId
            anchors.left: parent.left
            height: parent.height - 16
            anchors.verticalCenter: parent.verticalCenter
            width: height
            icon.height:height
            icon.width: height / 2
            icon.source: "../icons/fontawesome/svgs/solid/chevron-left.svg"
            icon.color: Global.iconColor
            display: AbstractButton.IconOnly
            onClicked: idRoot.backFunc()
        }

        Text {
            text: idRoot.winTitle
            anchors.centerIn: parent
            font.pixelSize: Global.fontSizeTitle
            color: palette.text
            elide: Text.ElideRight
        }

        Loader {
            anchors.right: parent.right
            height: parent.height - 8
            anchors.verticalCenter: parent.verticalCenter
            width: height
            sourceComponent: idRoot.menuModel.count === 1 ? buttonRightId : (idRoot.menuModel.count > 1 ? buttonMoreId : null)
        }

        Component {
            id: buttonRightId
            ToolButton {
                anchors.fill: parent
                icon.height: Global.toolbarIconSize - 8
                icon.width: Global.toolbarIconSize - 8
                icon.source: idRoot.menuModel.get(0).iconSrc
                icon.color:  Global.iconColor
                display: AbstractButton.IconOnly
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idRoot.clickFunc(idRoot.menuModel.get(0).actionStr)
                    }
                }
            }
        }

        Component {
            id: buttonMoreId
            ToolButton {
                anchors.fill: parent
                icon.height: parent.height - 16
                icon.width: parent.height - 16
                icon.source: "../icons/ionicons/ellipsis-vertical.svg"
                icon.color:  Global.iconColor
                display: AbstractButton.IconOnly
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        idPopup.open()
                    }
                }
            }
        }
    }

    MyPopup {
        id: idPopup
        x: idRoot.width - implicitWidth - 5
        y: Global.idWindow.SafeArea.margins.top + idRoot.height
        gModel: idRoot.menuModel
        onClickFunc: function(actionStr) {
            idRoot.onClickFunc(actionStr)
        }
    }
}
