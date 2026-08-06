import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

ToolButton {
    visible: gVisible
    text: gText
    icon.source: gIcon
    icon.color:  gColor
    icon.height: iconH
    icon.width: iconW
    height: gSize
    width: Math.max(gSize, implicitWidth + 4)
    padding: 0
    display: gDisplay
    anchors.verticalCenter: parent.verticalCenter

    property string gText: ""
    property string gIcon: ""
    property string gTipText: ""
    property bool gVisible: true
    property real gSize: 48
    property int gDisplay: AbstractButton.IconOnly
    property real iconH: Global.toolbarIconSize
    property real iconW: Global.toolbarIconSize
    property color gColor: Global.iconColor

    signal toolButtonClicked()

    property bool showTooltip: false
    ToolTip.visible: (Global.isDesktop && gTipText !== "") ? showTooltip : false
    ToolTip.text: gTipText
    ToolTip.delay: 1000  // 1 second delay
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: parent.showTooltip = true
        onExited: parent.showTooltip = false
    }
    onClicked: {
        toolButtonClicked()
    }
}
