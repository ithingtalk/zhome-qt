pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "Global"

Rectangle {
    id: idRoot
    color: "transparent"
    property bool gSearching: idSearchText.visible
    property bool gHideSearchText: false
    signal searchFile()

    TextField {
        id: idSearchText
        visible: idRoot.gHideSearchText ? false : true
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: idSearchButton.left
        anchors.rightMargin: 8
        height: parent.height
        placeholderText: qsTr("Search File")
        text: Zpath.getFilesFilter
        leftPadding: 8
        rightPadding: 8
        Keys.onReturnPressed: { idRoot.filterSearch() }
        Keys.onEscapePressed: { idRoot.quitSearch() }
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    Button {
        id: idSearchButton
        visible: Zpath.normalMode && (Zpath.selectedMyFiles || Zpath.selectedShared)
        height: parent.height
        anchors.right: parent.right
        icon.height: parent.height
        icon.width: parent.height
        icon.source: "../icons/ionicons/search.svg"
        icon.color: Global.iconColor
        display: AbstractButton.IconOnly
        background: null
        padding: 0
        onClicked: {
            if (!idSearchText.visible) {
                idSearchText.visible = true
            }
            else {
                console.log("search: " + idSearchText.text)
                idRoot.filterSearch()
                if (Zpath.getFilesFilter === "" && idRoot.gHideSearchText) {
                    idSearchText.visible = false
                }
            }
        }
        anchors.verticalCenter: parent.verticalCenter
    }

    states: [
        State {
            when: Zpath.getFilesFilter !== ""
            PropertyChanges {
                idSearchText.visible: true
            }
        }
    ]

    function filterSearch() {
        Zpath.getFilesFilter = idSearchText.text
        idRoot.searchFile()
    }

    function quitSearch() {
        idSearchText.text = ""
        idRoot.filterSearch()
        if (gHideSearchText) {
            idSearchText.visible = false
        }
    }
}
